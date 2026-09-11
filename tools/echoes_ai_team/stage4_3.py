from __future__ import annotations

import argparse
import asyncio
import base64
import json
import os
import subprocess
from dataclasses import dataclass, field
from pathlib import Path

from config import REPO_ROOT, REVIEWER_MODEL, REVIEWER_REASONING
from context_loader import load_project_context
from validation_runner import inspect_current_diff
from visual_capture import (
    VisualCaptureError,
    capture_visual_set,
    latest_capture_set,
)
from visual_review_prompts import visual_reviewer_instructions
from visual_review_schemas import VisualReview


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
        write = min(self.cache_write_tokens, max(0, self.input_tokens - cached))
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


def _data_url(path: Path) -> str:
    return "data:image/png;base64," + base64.b64encode(path.read_bytes()).decode("ascii")


def _current_diff() -> str:
    working = inspect_current_diff()
    cp = subprocess.run(
        [
            "git", "--no-pager", "diff", "--no-ext-diff", "--unified=50",
            "--", *working.changed_paths,
        ],
        cwd=REPO_ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    if cp.returncode != 0 or not cp.stdout.strip():
        raise VisualCaptureError("Could not read current git diff.")
    return cp.stdout.strip()


def capture() -> int:
    print("\n=== STAGE 4.3 — LOCAL VISUAL CAPTURE ===")
    print("API calls: 0")
    print("Generating 6 real Godot screenshots...")
    capture_set = capture_visual_set()

    print("\nVISUAL CAPTURE: PASS ✅")
    print(f"Folder: {capture_set.directory}")
    for record in capture_set.records:
        print(
            f" - {record.label}: {record.width}x{record.height}, "
            f"{record.bytes / 1024:.0f} KiB"
        )
    print("\nNo model was called.")
    return 0


def preview_latest() -> int:
    capture_set = latest_capture_set()
    print("\n=== STAGE 4.3 — ZERO-COST VISUAL REVIEW PREVIEW ===")
    print(f"Folder: {capture_set.directory}")
    for record in capture_set.records:
        print(
            f" - {record.label}: {record.width}x{record.height} "
            f"hover={record.hover_region}"
        )
    print("\nPaid review:")
    print(f" - {REVIEWER_MODEL}: exactly 1 model call")
    print(" - 6 screenshot inputs")
    print("API calls now: 0")
    return 0


async def review_latest(task: str) -> int:
    if not os.getenv("OPENAI_API_KEY", "").strip():
        raise RuntimeError("Brak OPENAI_API_KEY.")

    from agents import Agent, Runner, RunConfig

    capture_set = latest_capture_set()
    pack = load_project_context(task)
    diff_text = _current_diff()
    manifest_text = capture_set.manifest_path.read_text(encoding="utf-8")

    agent = Agent(
        name="Echoes Visual Reviewer — Sol",
        model=REVIEWER_MODEL,
        model_settings=_settings(),
        instructions=visual_reviewer_instructions(
            project_context=pack.text,
            task=task,
            diff_text=diff_text,
            manifest_text=manifest_text,
        ),
        output_type=VisualReview,
    )

    content: list[dict] = [
        {
            "type": "input_text",
            "text": (
                "Oceń screenshoty jako finalny visual gate bieżącej poprawki hoveru. "
                "Każdy obraz jest podpisany bezpośrednio przed input_image."
            ),
        }
    ]

    for record in capture_set.records:
        content.append(
            {
                "type": "input_text",
                "text": (
                    f"SCREENSHOT: {record.label} | "
                    f"{record.width}x{record.height} | hover={record.hover_region}"
                ),
            }
        )
        content.append(
            {
                "type": "input_image",
                "image_url": _data_url(Path(record.path)),
                "detail": "high" if record.hover_region != "none" else "low",
            }
        )

    print("\n=== ECHOES AI TEAM — STAGE 4.3 / VISUAL GATE ===")
    print(f"Reviewer:      {REVIEWER_MODEL} ({REVIEWER_REASONING})")
    print("Model calls:   maximum 1")
    print(f"Screenshots:   {len(capture_set.records)}")
    print(f"Folder:        {capture_set.directory}")

    usage = Usage()
    result = await Runner.run(
        agent,
        [{"role": "user", "content": content}],
        max_turns=1,
        run_config=RunConfig(
            tracing_disabled=True,
            workflow_name="Echoes AI Team - Stage 4.3 visual gate",
        ),
    )
    usage.add(REVIEWER_MODEL, result)
    review = result.final_output

    review_path = capture_set.directory / "visual_review.json"
    review_path.write_text(
        json.dumps(review.model_dump(), ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print("\n[Reviewer/Sol]")
    print(json.dumps(review.model_dump(), ensure_ascii=False, indent=2))
    print("\n====================================")

    if review.verdict == "APPROVED":
        print("VISUAL GATE: APPROVED ✅")
        print("CURRENT CHANGE: ready for Stage 5 commit gate")
        print("RELEASE GATE: BLOCKED_BY_BASELINE_DEBT ⚠️")
    elif review.verdict == "CHANGES_REQUESTED":
        print("VISUAL GATE: CHANGES_REQUESTED ❌")
        print("Shader remains uncommitted.")
    else:
        print("VISUAL GATE: HUMAN_DECISION_REQUIRED ⚠️")
        print("Shader remains uncommitted.")

    usage.print()
    print(f"\nReview: {review_path}")
    return 0 if review.verdict == "APPROVED" else 6


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Echoes — Stage 4.3 visual gate.")
    parser.add_argument("--capture", action="store_true")
    parser.add_argument("--preview-latest", action="store_true")
    parser.add_argument("--review-latest", type=str, metavar="TASK")
    return parser.parse_args()


async def async_main() -> int:
    args = parse_args()
    if args.capture:
        return capture()
    if args.preview_latest:
        return preview_latest()
    if args.review_latest:
        return await review_latest(args.review_latest)

    print('Użyj --capture, --preview-latest lub --review-latest "TASK".')
    return 1


def main() -> None:
    try:
        code = asyncio.run(async_main())
    except (VisualCaptureError, RuntimeError, FileNotFoundError) as exc:
        print(f"\nBŁĄD / SAFETY STOP:\n{exc}")
        code = 2
    except KeyboardInterrupt:
        print("\nPrzerwano Stage 4.3.")
        code = 130
    raise SystemExit(code)


if __name__ == "__main__":
    main()
