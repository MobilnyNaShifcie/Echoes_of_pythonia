from __future__ import annotations

import argparse
import asyncio
import json
import os
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

from config import (
    REPO_ROOT,
    REVIEWER_MODEL,
    REVIEWER_REASONING,
)
from context_loader import load_project_context
from repo_brief import build_repo_brief
from validation_prompts import reviewer_validation_instructions
from validation_runner import (
    ValidationError,
    ensure_tests_did_not_change_tracked_files,
    inspect_current_diff,
    run_canonical_validation,
    validation_passed,
    zero_cost_smoke,
)
from validation_schemas import ValidationReview


MODEL_PRICES = {
    "gpt-5.6-sol": {
        "input": 4.00,
        "cached": 0.40,
        "cache_write": 5.00,
        "output": 20.00,
    },
}


@dataclass
class RequestRecord:
    model: str
    input_tokens: int
    cached_tokens: int
    cache_write_tokens: int
    output_tokens: int
    reasoning_tokens: int

    def estimated_cost_usd(self) -> float | None:
        price = MODEL_PRICES.get(self.model)
        if price is None:
            return None

        cached = min(self.cached_tokens, self.input_tokens)
        cache_write = min(
            self.cache_write_tokens,
            max(0, self.input_tokens - cached),
        )
        regular = max(
            0,
            self.input_tokens - cached - cache_write,
        )

        return (
            regular * price["input"]
            + cached * price["cached"]
            + cache_write * price["cache_write"]
            + self.output_tokens * price["output"]
        ) / 1_000_000.0


@dataclass
class UsageLedger:
    records: list[RequestRecord] = field(default_factory=list)

    def add_result(self, model: str, result: object) -> None:
        wrapper = getattr(result, "context_wrapper", None)
        usage = getattr(wrapper, "usage", None)

        if usage is None:
            return

        entries = getattr(
            usage,
            "request_usage_entries",
            None,
        ) or []

        if entries:
            for entry in entries:
                input_details = getattr(
                    entry,
                    "input_tokens_details",
                    None,
                )
                output_details = getattr(
                    entry,
                    "output_tokens_details",
                    None,
                )

                self.records.append(
                    RequestRecord(
                        model=model,
                        input_tokens=int(
                            getattr(
                                entry,
                                "input_tokens",
                                0,
                            )
                            or 0
                        ),
                        cached_tokens=int(
                            getattr(
                                input_details,
                                "cached_tokens",
                                0,
                            )
                            or 0
                        ),
                        cache_write_tokens=int(
                            getattr(
                                input_details,
                                "cache_write_tokens",
                                0,
                            )
                            or 0
                        ),
                        output_tokens=int(
                            getattr(
                                entry,
                                "output_tokens",
                                0,
                            )
                            or 0
                        ),
                        reasoning_tokens=int(
                            getattr(
                                output_details,
                                "reasoning_tokens",
                                0,
                            )
                            or 0
                        ),
                    )
                )
            return

        requests = int(
            getattr(usage, "requests", 0) or 0
        )
        if requests == 1:
            input_details = getattr(
                usage,
                "input_tokens_details",
                None,
            )
            output_details = getattr(
                usage,
                "output_tokens_details",
                None,
            )

            self.records.append(
                RequestRecord(
                    model=model,
                    input_tokens=int(
                        getattr(
                            usage,
                            "input_tokens",
                            0,
                        )
                        or 0
                    ),
                    cached_tokens=int(
                        getattr(
                            input_details,
                            "cached_tokens",
                            0,
                        )
                        or 0
                    ),
                    cache_write_tokens=int(
                        getattr(
                            input_details,
                            "cache_write_tokens",
                            0,
                        )
                        or 0
                    ),
                    output_tokens=int(
                        getattr(
                            usage,
                            "output_tokens",
                            0,
                        )
                        or 0
                    ),
                    reasoning_tokens=int(
                        getattr(
                            output_details,
                            "reasoning_tokens",
                            0,
                        )
                        or 0
                    ),
                )
            )

    def totals(self) -> dict:
        input_tokens = sum(
            x.input_tokens for x in self.records
        )
        cached_tokens = sum(
            x.cached_tokens for x in self.records
        )
        cache_write_tokens = sum(
            x.cache_write_tokens for x in self.records
        )
        output_tokens = sum(
            x.output_tokens for x in self.records
        )
        reasoning_tokens = sum(
            x.reasoning_tokens for x in self.records
        )

        costs = [
            x.estimated_cost_usd()
            for x in self.records
        ]

        estimated = None
        if costs and all(
            cost is not None for cost in costs
        ):
            estimated = sum(costs)  # type: ignore[arg-type]

        return {
            "requests": len(self.records),
            "input_tokens": input_tokens,
            "cached_tokens": cached_tokens,
            "cache_write_tokens": cache_write_tokens,
            "output_tokens": output_tokens,
            "reasoning_tokens": reasoning_tokens,
            "total_tokens": input_tokens + output_tokens,
            "estimated_cost_usd": estimated,
        }


def _settings(reasoning_effort: str) -> dict:
    return {
        "reasoning": {
            "effort": reasoning_effort,
        },
        "verbosity": "low",
        "preserve_raw_usage": True,
    }


def _json_text(model: object) -> str:
    payload = (
        model.model_dump()
        if hasattr(model, "model_dump")
        else model
    )
    return json.dumps(
        payload,
        ensure_ascii=False,
        indent=2,
    )


def _write_json(path: Path, value: object) -> None:
    if hasattr(value, "model_dump"):
        value = value.model_dump()

    path.write_text(
        json.dumps(
            value,
            ensure_ascii=False,
            indent=2,
        )
        + "\n",
        encoding="utf-8",
    )


def _run_dir() -> Path:
    stamp = datetime.now().strftime(
        "%Y%m%d-%H%M%S"
    )
    path = (
        REPO_ROOT
        / "output"
        / "ai-team"
        / f"VALIDATE-{stamp}"
    )
    path.mkdir(
        parents=True,
        exist_ok=True,
    )
    return path


def _require_api_key() -> None:
    if not os.getenv(
        "OPENAI_API_KEY",
        "",
    ).strip():
        raise RuntimeError(
            "Brak OPENAI_API_KEY w "
            "tools\\echoes_ai_team\\.env."
        )


def _print_usage(
    ledger: UsageLedger,
) -> None:
    totals = ledger.totals()

    print("\n=== COST / USAGE REPORT ===")
    print(
        f"Model requests:       "
        f"{totals['requests']}"
    )
    print(
        f"Input tokens:         "
        f"{totals['input_tokens']:,}"
    )
    print(
        f"  cached input:       "
        f"{totals['cached_tokens']:,}"
    )
    print(
        f"  cache writes:       "
        f"{totals['cache_write_tokens']:,}"
    )
    print(
        f"Output tokens:        "
        f"{totals['output_tokens']:,}"
    )
    print(
        f"  reasoning tokens:   "
        f"{totals['reasoning_tokens']:,}"
    )
    print(
        f"Total tokens:         "
        f"{totals['total_tokens']:,}"
    )

    cost = totals["estimated_cost_usd"]
    if cost is None:
        print(
            "Estimated API cost:   unavailable"
        )
    else:
        print(
            f"Estimated API cost:   "
            f"${cost:.4f} USD"
        )


def safety_smoke() -> int:
    print(
        "\n=== STAGE 4 — "
        "LOCAL VALIDATION SAFETY SMOKE ==="
    )

    results = zero_cost_smoke()

    for item in results:
        print(item)

    if any(
        "FAIL" in item for item in results
    ):
        print(
            "\nVALIDATION SAFETY SMOKE: FAIL"
        )
        return 2

    print(
        "\nVALIDATION SAFETY SMOKE: PASS "
        "— API nie zostało wywołane."
    )
    print(
        "No validation suite was executed."
    )
    return 0


def validation_preview(
    task: str,
) -> int:
    working = inspect_current_diff()

    print(
        "\n=== STAGE 4 — "
        "ZERO-COST VALIDATION PREVIEW ==="
    )
    print(
        f"Branch:        {working.branch}"
    )
    print(
        f"HEAD:          {working.head}"
    )
    print(
        "Changed files:"
    )

    for path in working.changed_paths:
        print(f" - {path}")

    print(
        "\nWill run locally:"
    )
    print(
        "  1. git diff --check"
    )
    print(
        r"  2. .\scripts\check.ps1"
    )

    print(
        "\nThen, only if validation PASS:"
    )
    print(
        f"  3. {REVIEWER_MODEL} "
        "reviews actual diff + test log"
    )
    print(
        "\nMaximum model calls: 1"
    )
    print(
        "API calls now: 0"
    )
    return 0


async def validate_current(
    task: str,
) -> int:
    _require_api_key()

    from agents import (
        Agent,
        RunConfig,
        Runner,
    )

    working = inspect_current_diff()

    # Important: build repo brief before tests, but current working tree is dirty
    # by design in Stage 4. repo_brief's normal preflight requires CLEAN, so
    # reuse the already-generated task context without calling build_repo_brief.
    # For Reviewer grounding, the real diff is authoritative.
    pack = load_project_context(task)

    run_dir = _run_dir()

    (run_dir / "task.txt").write_text(
        task + "\n",
        encoding="utf-8",
    )
    (run_dir / "before_diff.patch").write_text(
        working.diff_text + "\n",
        encoding="utf-8",
    )

    print(
        "\n=== ECHOES AI TEAM — "
        "STAGE 4 / CONTROLLED VALIDATION ==="
    )
    print(
        f"Reviewer:      "
        f"{REVIEWER_MODEL} "
        f"({REVIEWER_REASONING})"
    )
    print(
        "Model calls:   maximum 1"
    )
    print(
        f"Branch:        {working.branch}"
    )
    print(
        f"HEAD:          {working.head}"
    )
    print(
        "Changed files:"
    )
    for path in working.changed_paths:
        print(f" - {path}")

    print(
        "\n[Local validator] "
        "running allowlisted validation..."
    )

    results, validation_text = (
        run_canonical_validation(
            working
        )
    )

    (run_dir / "validation.log").write_text(
        validation_text + "\n",
        encoding="utf-8",
    )

    # If tests/editor subprocess unexpectedly changed tracked files, stop
    # before paying for a Reviewer call.
    ensure_tests_did_not_change_tracked_files(
        working.changed_paths
    )

    passed = validation_passed(results)

    print(validation_text)

    if not passed:
        print(
            "\n===================================="
        )
        print(
            "STAGE 4 VALIDATION: FAIL ❌"
        )
        print(
            "Reviewer API call skipped — "
            "oszczędzamy koszt."
        )
        print(
            "Zmiana pozostaje NIEZACOMMITOWANA "
            "do inspekcji/naprawy."
        )
        print(
            f"Logi: {run_dir}"
        )
        return 5

    print(
        "\n[Local validator] "
        "ALL ALLOWLISTED CHECKS PASSED ✅"
    )

    # Stage 4 avoids a second large repo brief. The real diff + compact
    # AI_CONTEXT + real validation log are enough for Reviewer.
    repo_stub = (
        "<REPO_VALIDATION_CONTEXT>\n"
        f"branch: {working.branch}\n"
        f"head: {working.head}\n"
        "changed_paths:\n"
        + "\n".join(
            f"- {path}"
            for path in working.changed_paths
        )
        + "\n</REPO_VALIDATION_CONTEXT>"
    )

    reviewer = Agent(
        name="Echoes Reviewer — Sol",
        model=REVIEWER_MODEL,
        model_settings=_settings(
            REVIEWER_REASONING
        ),
        instructions=(
            reviewer_validation_instructions(
                project_context=pack.text,
                repo_brief=repo_stub,
                task=task,
                diff_text=working.diff_text,
                validation_text=validation_text,
            )
        ),
        output_type=ValidationReview,
    )

    ledger = UsageLedger()

    print(
        "\n[Reviewer/Sol] "
        "reviewing actual diff + real test log..."
    )

    reviewer_result = await Runner.run(
        reviewer,
        (
            "Zweryfikuj aktualną zmianę po "
            "lokalnej walidacji. "
            "Nie zakładaj, że wykonano review "
            "wizualne."
        ),
        max_turns=1,
        run_config=RunConfig(
            tracing_disabled=True,
            workflow_name=(
                "Echoes AI Team - "
                "Stage 4 validation review"
            ),
        ),
    )

    ledger.add_result(
        REVIEWER_MODEL,
        reviewer_result,
    )

    review = reviewer_result.final_output
    _write_json(
        run_dir / "review.json",
        review,
    )

    print(
        "\n[Reviewer]"
    )
    print(
        _json_text(review)
    )

    print(
        "\n===================================="
    )

    if review.verdict != "APPROVED":
        print(
            f"STAGE 4 REVIEW: "
            f"{review.verdict}"
        )
        print(
            "Zmiana pozostaje "
            "NIEZACOMMITOWANA."
        )
        print(
            "Stage 4 nie wykonuje "
            "automatycznego rollbacku "
            "po testach — zachowujemy diff "
            "do naprawy/inspekcji."
        )
        _print_usage(ledger)
        print(
            f"\nLogi: {run_dir}"
        )
        return (
            6
            if review.verdict
            == "CHANGES_REQUESTED"
            else 4
        )

    print(
        "CODE VALIDATION: APPROVED ✅"
    )

    if review.visual_review_required:
        print(
            "VISUAL GATE: PENDING ⚠️"
        )
        print(
            "Kod/testy są zaakceptowane, "
            "ale zmiana wizualna NIE jest "
            "jeszcze gotowa do automatycznego "
            "commita."
        )
    else:
        print(
            "VISUAL GATE: NOT REQUIRED"
        )

    print(
        "Zmiany pozostają "
        "NIEZACOMMITOWANE."
    )
    print(
        "Nie wykonano commita ani push."
    )

    _print_usage(ledger)
    print(
        f"\nLogi: {run_dir}"
    )

    return (
        8
        if review.visual_review_required
        else 0
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Echoes of Pythonia — "
            "Stage 4 controlled validation."
        )
    )

    parser.add_argument(
        "--validation-smoke",
        action="store_true",
    )
    parser.add_argument(
        "--validation-preview",
        action="store_true",
    )
    parser.add_argument(
        "--validate-current",
        type=str,
        metavar="TASK",
    )

    return parser.parse_args()


async def async_main() -> int:
    args = parse_args()

    if args.validation_smoke:
        return safety_smoke()

    if args.validation_preview:
        task = (
            input("TASK > ").strip()
        )
        if not task:
            print("Brak zadania.")
            return 1
        return validation_preview(task)

    if args.validate_current:
        return await validate_current(
            args.validate_current
        )

    print(
        "Użyj --validation-smoke, "
        "--validation-preview lub "
        "--validate-current \"...\"."
    )
    return 1


def main() -> None:
    try:
        code = asyncio.run(
            async_main()
        )
    except (
        ValidationError,
        RuntimeError,
        FileNotFoundError,
    ) as exc:
        print(
            f"\nBŁĄD / SAFETY STOP:\n{exc}"
        )
        code = 2
    except KeyboardInterrupt:
        print(
            "\nPrzerwano Stage 4."
        )
        code = 130

    raise SystemExit(code)


if __name__ == "__main__":
    main()
