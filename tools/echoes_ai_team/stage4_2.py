from __future__ import annotations

import argparse
import asyncio
import json
import os
import subprocess
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

from config import REPO_ROOT, REVIEWER_MODEL, REVIEWER_REASONING
from context_loader import load_project_context
from targeted_validation import (
    TargetedValidationError,
    run_targeted_validation,
)
from validation_runner import inspect_current_diff, ensure_tests_did_not_change_tracked_files
from baseline_review_prompts import reviewer_instructions
from baseline_review_schemas import BaselineAwareReview


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

    def cost(self) -> float | None:
        price = MODEL_PRICES.get(self.model)
        if price is None:
            return None
        cached = min(self.cached_tokens, self.input_tokens)
        write = min(
            self.cache_write_tokens,
            max(0, self.input_tokens - cached),
        )
        regular = max(0, self.input_tokens - cached - write)
        return (
            regular * price["input"]
            + cached * price["cached"]
            + write * price["cache_write"]
            + self.output_tokens * price["output"]
        ) / 1_000_000.0


@dataclass
class Usage:
    records: list[RequestRecord] = field(default_factory=list)

    def add(self, model: str, result: object) -> None:
        wrapper = getattr(result, "context_wrapper", None)
        usage = getattr(wrapper, "usage", None)
        if usage is None:
            return
        entries = getattr(usage, "request_usage_entries", None) or []
        for entry in entries:
            inp = getattr(entry, "input_tokens_details", None)
            out = getattr(entry, "output_tokens_details", None)
            self.records.append(
                RequestRecord(
                    model=model,
                    input_tokens=int(getattr(entry, "input_tokens", 0) or 0),
                    cached_tokens=int(getattr(inp, "cached_tokens", 0) or 0),
                    cache_write_tokens=int(getattr(inp, "cache_write_tokens", 0) or 0),
                    output_tokens=int(getattr(entry, "output_tokens", 0) or 0),
                    reasoning_tokens=int(getattr(out, "reasoning_tokens", 0) or 0),
                )
            )

        if not entries and int(getattr(usage, "requests", 0) or 0) == 1:
            inp = getattr(usage, "input_tokens_details", None)
            out = getattr(usage, "output_tokens_details", None)
            self.records.append(
                RequestRecord(
                    model=model,
                    input_tokens=int(getattr(usage, "input_tokens", 0) or 0),
                    cached_tokens=int(getattr(inp, "cached_tokens", 0) or 0),
                    cache_write_tokens=int(getattr(inp, "cache_write_tokens", 0) or 0),
                    output_tokens=int(getattr(usage, "output_tokens", 0) or 0),
                    reasoning_tokens=int(getattr(out, "reasoning_tokens", 0) or 0),
                )
            )

    def print(self) -> None:
        inp = sum(x.input_tokens for x in self.records)
        cached = sum(x.cached_tokens for x in self.records)
        write = sum(x.cache_write_tokens for x in self.records)
        out = sum(x.output_tokens for x in self.records)
        reasoning = sum(x.reasoning_tokens for x in self.records)
        costs = [x.cost() for x in self.records]
        cost = sum(x for x in costs if x is not None) if costs else 0.0

        print("\n=== COST / USAGE REPORT ===")
        print(f"Model requests:       {len(self.records)}")
        print(f"Input tokens:         {inp:,}")
        print(f"  cached input:       {cached:,}")
        print(f"  cache writes:       {write:,}")
        print(f"Output tokens:        {out:,}")
        print(f"  reasoning tokens:   {reasoning:,}")
        print(f"Total tokens:         {inp + out:,}")
        print(f"Estimated API cost:   ${cost:.4f} USD")


def _settings() -> dict:
    return {
        "reasoning": {"effort": REVIEWER_REASONING},
        "verbosity": "low",
        "preserve_raw_usage": True,
    }


def _run_dir() -> Path:
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    p = REPO_ROOT / "output" / "ai-team" / f"BASELINE-VALIDATE-{stamp}"
    p.mkdir(parents=True, exist_ok=True)
    return p


def _json_text(obj: object) -> str:
    if hasattr(obj, "model_dump"):
        obj = obj.model_dump()
    return json.dumps(obj, ensure_ascii=False, indent=2)


def preview(task: str) -> int:
    working = inspect_current_diff()
    print("\n=== STAGE 4.2 — ZERO-COST BASELINE-AWARE PREVIEW ===")
    print(f"Branch: {working.branch}")
    print("Changed files:")
    for path in working.changed_paths:
        print(f" - {path}")
    print("\nBlocking targeted gates:")
    print(" - git diff --check")
    if any(p.endswith(".gd") for p in working.changed_paths):
        print(" - gdformat --check [changed .gd only]")
        print(" - gdlint [changed .gd only]")
    print(" - Godot headless bootstrap")
    if any("/world_map/" in p.replace("\\", "/") for p in working.changed_paths):
        print(" - GUT: res://tests/test_world_map_interaction.gd")
    print("\nAdvisory/release-debt gate:")
    print(r" - .\scripts\check.ps1")
    print("\nAPI calls now: 0")
    print("Reviewer is called only if targeted gates PASS.")
    return 0


async def validate(task: str) -> int:
    if not os.getenv("OPENAI_API_KEY", "").strip():
        raise RuntimeError("Brak OPENAI_API_KEY.")

    from agents import Agent, Runner, RunConfig

    working = inspect_current_diff()
    pack = load_project_context(task)
    run_dir = _run_dir()

    print("\n=== ECHOES AI TEAM — STAGE 4.2 / BASELINE-AWARE VALIDATION ===")
    print(f"Reviewer:      {REVIEWER_MODEL} ({REVIEWER_REASONING})")
    print("Model calls:   maximum 1")
    print(f"Branch:        {working.branch}")
    print("Changed files:")
    for path in working.changed_paths:
        print(f" - {path}")

    bundle = run_targeted_validation(working.changed_paths, run_full_check_advisory=True)

    # Validation subprocesses may write ignored caches, but tracked working-tree
    # files must remain the same set.
    ensure_tests_did_not_change_tracked_files(working.changed_paths)

    validation_text = bundle.render()
    print("\n" + validation_text)
    (run_dir / "validation.log").write_text(validation_text + "\n", encoding="utf-8")
    (run_dir / "diff.patch").write_text(working.diff_text + "\n", encoding="utf-8")

    if not bundle.targeted_passed:
        print("\n====================================")
        print("TARGETED VALIDATION: FAIL ❌")
        print("Reviewer API call skipped.")
        print(f"Logi: {run_dir}")
        return 5

    if bundle.full_check_blocks_current_change:
        print("\n====================================")
        print("TARGETED VALIDATION: PASS ✅")
        print("FULL CHECK: failure cannot be proven unrelated ❌")
        print("Reviewer API call skipped for safety.")
        print(f"Logi: {run_dir}")
        return 6

    print("\n[Local validator] Targeted gates PASS ✅")
    if bundle.full_check_classification == "PREEXISTING_UNRELATED_FORMAT_DEBT":
        print("Canonical full check still FAILS on unrelated formatting debt ⚠️")
        print("This keeps the RELEASE gate blocked, but does not automatically blame this diff.")

    reviewer = Agent(
        name="Echoes Reviewer — Sol",
        model=REVIEWER_MODEL,
        model_settings=_settings(),
        instructions=reviewer_instructions(
            project_context=pack.text,
            task=task,
            diff_text=working.diff_text,
            validation_text=validation_text,
            full_check_classification=bundle.full_check_classification,
        ),
        output_type=BaselineAwareReview,
    )

    usage = Usage()
    result = await Runner.run(
        reviewer,
        "Oceń bieżący diff po targeted validation i sklasyfikowanym full check.",
        max_turns=1,
        run_config=RunConfig(
            tracing_disabled=True,
            workflow_name="Echoes AI Team - Stage 4.2 baseline aware review",
        ),
    )
    usage.add(REVIEWER_MODEL, result)
    review = result.final_output

    (run_dir / "review.json").write_text(_json_text(review) + "\n", encoding="utf-8")

    print("\n[Reviewer/Sol]")
    print(_json_text(review))

    print("\n====================================")
    if review.verdict == "APPROVED":
        print("CURRENT CHANGE VALIDATION: APPROVED ✅")
        print(f"RELEASE GATE: {review.release_gate_status}")
        if review.visual_review_required:
            print("VISUAL GATE: PENDING ⚠️")
        else:
            print("VISUAL GATE: NOT REQUIRED")
    else:
        print(f"CURRENT CHANGE VALIDATION: {review.verdict}")

    print("Zmiany pozostają NIEZACOMMITOWANE.")
    usage.print()
    print(f"\nLogi: {run_dir}")

    if review.verdict != "APPROVED":
        return 7
    if review.visual_review_required:
        return 8
    return 0


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser()
    p.add_argument("--preview", action="store_true")
    p.add_argument("--validate-current", type=str)
    return p.parse_args()


async def async_main() -> int:
    args = parse_args()
    if args.preview:
        task = input("TASK > ").strip()
        if not task:
            print("Brak zadania.")
            return 1
        return preview(task)

    if args.validate_current:
        return await validate(args.validate_current)

    print("Użyj --preview lub --validate-current \"...\".")
    return 1


def main() -> None:
    try:
        code = asyncio.run(async_main())
    except (TargetedValidationError, RuntimeError, FileNotFoundError) as exc:
        print(f"\nBŁĄD / SAFETY STOP:\n{exc}")
        code = 2
    except KeyboardInterrupt:
        print("\nPrzerwano Stage 4.2.")
        code = 130
    raise SystemExit(code)


if __name__ == "__main__":
    main()
