from __future__ import annotations

import argparse
import asyncio
import json
import os
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

from config import (
    DEVELOPER_MODEL,
    DEVELOPER_REASONING,
    REPO_ROOT,
    REVIEWER_MODEL,
    REVIEWER_REASONING,
)
from context_loader import load_project_context
from controlled_write import (
    ControlledWriteError,
    apply_proposal,
    rollback,
    safety_smoke,
    validate_diff,
)
from repo_brief import BriefError, build_repo_brief
from write_prompts import (
    developer_write_instructions,
    reviewer_diff_instructions,
)
from write_schemas import ChangeProposal, DiffReview


MODEL_PRICES = {
    "gpt-6-astra": {
        "input": 10.00,
        "cached": 1.00,
        "cache_write": 12.50,
        "output": 50.00,
    },
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

        entries = getattr(usage, "request_usage_entries", None) or []

        if entries:
            for entry in entries:
                input_details = getattr(entry, "input_tokens_details", None)
                output_details = getattr(entry, "output_tokens_details", None)

                self.records.append(
                    RequestRecord(
                        model=model,
                        input_tokens=int(
                            getattr(entry, "input_tokens", 0) or 0
                        ),
                        cached_tokens=int(
                            getattr(input_details, "cached_tokens", 0) or 0
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
                            getattr(entry, "output_tokens", 0) or 0
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

        # Fallback for SDK versions that return one aggregated request.
        requests = int(getattr(usage, "requests", 0) or 0)
        if requests == 1:
            input_details = getattr(usage, "input_tokens_details", None)
            output_details = getattr(usage, "output_tokens_details", None)

            self.records.append(
                RequestRecord(
                    model=model,
                    input_tokens=int(
                        getattr(usage, "input_tokens", 0) or 0
                    ),
                    cached_tokens=int(
                        getattr(input_details, "cached_tokens", 0) or 0
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
                        getattr(usage, "output_tokens", 0) or 0
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
        input_tokens = sum(x.input_tokens for x in self.records)
        cached_tokens = sum(x.cached_tokens for x in self.records)
        cache_write_tokens = sum(
            x.cache_write_tokens for x in self.records
        )
        output_tokens = sum(x.output_tokens for x in self.records)
        reasoning_tokens = sum(
            x.reasoning_tokens for x in self.records
        )

        costs = [x.estimated_cost_usd() for x in self.records]
        if costs and all(cost is not None for cost in costs):
            estimated = sum(costs)  # type: ignore[arg-type]
        else:
            estimated = None

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
        "reasoning": {"effort": reasoning_effort},
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


def _run_dir() -> Path:
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    path = (
        REPO_ROOT
        / "output"
        / "ai-team"
        / f"WRITE-{stamp}"
    )
    path.mkdir(parents=True, exist_ok=True)
    return path


def _write_json(path: Path, value: object) -> None:
    if hasattr(value, "model_dump"):
        value = value.model_dump()
    path.write_text(
        json.dumps(value, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def _require_api_key() -> None:
    if not os.getenv("OPENAI_API_KEY", "").strip():
        raise RuntimeError(
            "Brak OPENAI_API_KEY w tools\\echoes_ai_team\\.env."
        )


def _hard_call_fuse() -> int:
    return int(os.getenv("EOP_MAX_MODEL_CALLS_PER_TASK", "2"))


def _print_usage(ledger: UsageLedger) -> None:
    totals = ledger.totals()

    print("\n=== COST / USAGE REPORT ===")
    print(f"Model requests:       {totals['requests']}")
    print(f"Input tokens:         {totals['input_tokens']:,}")
    print(f"  cached input:       {totals['cached_tokens']:,}")
    print(f"  cache writes:       {totals['cache_write_tokens']:,}")
    print(f"Output tokens:        {totals['output_tokens']:,}")
    print(f"  reasoning tokens:   {totals['reasoning_tokens']:,}")
    print(f"Total tokens:         {totals['total_tokens']:,}")

    cost = totals["estimated_cost_usd"]
    if cost is None:
        print("Estimated API cost:   unavailable")
    else:
        print(f"Estimated API cost:   ${cost:.4f} USD")


def zero_cost_preview(task: str) -> int:
    pack = load_project_context(task)
    brief = build_repo_brief(task)

    print("\n=== STAGE 3 — ZERO-COST WRITE PREVIEW ===")
    print(f"Branch:               {brief.branch}")
    print("Working tree:          CLEAN")
    print(f"AI_CONTEXT pack:       {pack.selected_chars:,} znaków")
    print(f"REPO_BRIEF:            {brief.chars:,} znaków")
    print("Potential edit allowlist:")
    for path in brief.selected_files:
        print(f" - {path}")
    print("\nAPI calls: 0")
    print("No files were edited.")
    return 0


def local_write_smoke() -> int:
    print("\n=== STAGE 3 — LOCAL WRITE SAFETY SMOKE ===")
    results = safety_smoke()
    for item in results:
        print(item)

    if any("FAIL" in item for item in results):
        print("\nWRITE SAFETY SMOKE: FAIL")
        return 2

    print("\nWRITE SAFETY SMOKE: PASS — API nie zostało wywołane.")
    print("No files were edited.")
    return 0


async def apply_task(task: str) -> int:
    _require_api_key()

    fuse = _hard_call_fuse()
    if fuse < 2:
        raise RuntimeError(
            "EOP_MAX_MODEL_CALLS_PER_TASK musi wynosić co najmniej 2 "
            "dla Stage 3 (Developer + Reviewer)."
        )

    from agents import Agent, RunConfig, Runner

    pack = load_project_context(task)
    brief = build_repo_brief(task)

    run_dir = _run_dir()
    (run_dir / "task.txt").write_text(
        task + "\n",
        encoding="utf-8",
    )
    (run_dir / "context_pack.txt").write_text(
        pack.text,
        encoding="utf-8",
    )
    (run_dir / "repo_brief.txt").write_text(
        brief.text,
        encoding="utf-8",
    )

    print("\n=== ECHOES AI TEAM — STAGE 3 / CONTROLLED WRITE ===")
    print(f"Developer:            {DEVELOPER_MODEL} ({DEVELOPER_REASONING})")
    print(f"Reviewer:             {REVIEWER_MODEL} ({REVIEWER_REASONING})")
    print("Model calls this run: exactly 2 maximum")
    print(f"Configured hard fuse: {fuse}")
    print(f"Branch:               {brief.branch}")
    print(f"HEAD:                 {brief.head}")
    print("Working tree:         CLEAN")
    print(f"REPO_BRIEF files:     {len(brief.selected_files)}")
    print("\nTASK:")
    print(task)

    ledger = UsageLedger()

    developer = Agent(
        name="Echoes Developer — Astra",
        model=DEVELOPER_MODEL,
        model_settings=_settings(DEVELOPER_REASONING),
        instructions=developer_write_instructions(
            pack.text,
            brief.text,
        ),
        output_type=ChangeProposal,
    )

    print("\n[1/2 Developer/Astra] preparing exact replacements...")
    developer_result = await Runner.run(
        developer,
        f"TASK:\n{task}\n\nZaproponuj najmniejszą bezpieczną zmianę.",
        max_turns=1,
        run_config=RunConfig(
            tracing_disabled=True,
            workflow_name="Echoes AI Team - Stage 3 developer",
        ),
    )
    ledger.add_result(DEVELOPER_MODEL, developer_result)
    proposal = developer_result.final_output
    _write_json(run_dir / "developer_proposal.json", proposal)

    print("\n[Developer proposal]")
    print(_json_text(proposal))

    if proposal.status == "BLOCKED":
        print("\nSTAGE 3: BLOCKED — niczego nie zmieniono.")
        _print_usage(ledger)
        return 3

    if proposal.status == "HUMAN_DECISION_REQUIRED":
        print("\nSTAGE 3: HUMAN_DECISION_REQUIRED — niczego nie zmieniono.")
        if proposal.human_question:
            print(f"Pytanie: {proposal.human_question}")
        _print_usage(ledger)
        return 4

    allowed_paths = {
        Path(path).as_posix()
        for path in brief.selected_files
    }

    change = None

    try:
        change = apply_proposal(
            proposal,
            allowed_paths=allowed_paths,
        )
        diff_text = validate_diff(change)
    except Exception:
        if change is not None:
            rollback(change)
        raise

    (run_dir / "applied_diff.patch").write_text(
        diff_text + "\n",
        encoding="utf-8",
    )

    print("\n[Local controller]")
    print(
        f"Applied {len(change.edited_paths)} file(s) temporarily. "
        "git diff --check: PASS"
    )
    for path in change.edited_paths:
        print(f" - {path.relative_to(REPO_ROOT).as_posix()}")

    reviewer = Agent(
        name="Echoes Reviewer — Sol",
        model=REVIEWER_MODEL,
        model_settings=_settings(REVIEWER_REASONING),
        instructions=reviewer_diff_instructions(
            pack.text,
            brief.text,
            _json_text(proposal),
            diff_text,
        ),
        output_type=DiffReview,
    )

    print("\n[2/2 Reviewer/Sol] reviewing actual git diff...")

    try:
        reviewer_result = await Runner.run(
            reviewer,
            (
                f"TASK:\n{task}\n\n"
                "Zrecenzuj RZECZYWISTY diff przekazany w instrukcjach."
            ),
            max_turns=1,
            run_config=RunConfig(
                tracing_disabled=True,
                workflow_name="Echoes AI Team - Stage 3 reviewer",
            ),
        )
    except Exception:
        rollback(change)
        raise

    ledger.add_result(REVIEWER_MODEL, reviewer_result)
    review = reviewer_result.final_output
    _write_json(run_dir / "review.json", review)

    print("\n[Reviewer]")
    print(_json_text(review))

    if review.verdict != "APPROVED":
        rollback(change)
        (run_dir / "ROLLBACK.txt").write_text(
            "Reviewer did not approve. Original file contents were restored.\n",
            encoding="utf-8",
        )
        print("\n====================================")
        print(f"STAGE 3: {review.verdict}")
        print("ROLLBACK: PASS — oryginalne pliki zostały przywrócone.")
        _print_usage(ledger)
        print(f"Logi: {run_dir}")
        return 5 if review.verdict == "CHANGES_REQUESTED" else 4

    print("\n====================================")
    print("CONTROLLED WRITE: APPROVED ✅")
    print("Reviewer zaakceptował rzeczywisty git diff.")
    print("Zmiany pozostają NIEZACOMMITOWANE w working tree.")
    print("Nie wykonano testów projektu, commita ani push.")
    _print_usage(ledger)
    print(f"\nLogi: {run_dir}")
    print("\nNastępnie sprawdź:")
    print("  git status -sb")
    print("  git --no-pager diff")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Echoes of Pythonia — Stage 3 controlled write."
    )
    parser.add_argument("--write-smoke", action="store_true")
    parser.add_argument("--write-preview", action="store_true")
    parser.add_argument("--apply-task", type=str)
    parser.add_argument("--task", type=str)
    return parser.parse_args()


async def async_main() -> int:
    args = parse_args()

    if args.write_smoke:
        return local_write_smoke()

    task = args.apply_task or args.task

    if args.write_preview:
        if not task:
            task = input("TASK > ").strip()
        if not task:
            print("Brak zadania.")
            return 1
        return zero_cost_preview(task)

    if args.apply_task:
        return await apply_task(args.apply_task)

    print(
        "Użyj --write-smoke, --write-preview --task \"...\" "
        "lub --apply-task \"...\"."
    )
    return 1


def main() -> None:
    try:
        code = asyncio.run(async_main())
    except (
        BriefError,
        ControlledWriteError,
        RuntimeError,
        FileNotFoundError,
    ) as exc:
        print(f"\nBŁĄD / SAFETY STOP:\n{exc}")
        code = 2
    except KeyboardInterrupt:
        print("\nPrzerwano. Jeśli zmiana była w trakcie, kontroler próbuje ją cofnąć.")
        code = 130

    raise SystemExit(code)


if __name__ == "__main__":
    main()
