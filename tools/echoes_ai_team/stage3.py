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
from context_escalation import (
    EscalatedBrief,
    EscalationError,
    build_escalated_brief,
    find_latest_blocked_run,
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
                        input_tokens=int(getattr(entry, "input_tokens", 0) or 0),
                        cached_tokens=int(
                            getattr(input_details, "cached_tokens", 0) or 0
                        ),
                        cache_write_tokens=int(
                            getattr(input_details, "cache_write_tokens", 0) or 0
                        ),
                        output_tokens=int(getattr(entry, "output_tokens", 0) or 0),
                        reasoning_tokens=int(
                            getattr(output_details, "reasoning_tokens", 0) or 0
                        ),
                    )
                )
            return

        requests = int(getattr(usage, "requests", 0) or 0)
        if requests == 1:
            input_details = getattr(usage, "input_tokens_details", None)
            output_details = getattr(usage, "output_tokens_details", None)
            self.records.append(
                RequestRecord(
                    model=model,
                    input_tokens=int(getattr(usage, "input_tokens", 0) or 0),
                    cached_tokens=int(
                        getattr(input_details, "cached_tokens", 0) or 0
                    ),
                    cache_write_tokens=int(
                        getattr(input_details, "cache_write_tokens", 0) or 0
                    ),
                    output_tokens=int(getattr(usage, "output_tokens", 0) or 0),
                    reasoning_tokens=int(
                        getattr(output_details, "reasoning_tokens", 0) or 0
                    ),
                )
            )

    def totals(self) -> dict:
        input_tokens = sum(x.input_tokens for x in self.records)
        cached_tokens = sum(x.cached_tokens for x in self.records)
        cache_write_tokens = sum(x.cache_write_tokens for x in self.records)
        output_tokens = sum(x.output_tokens for x in self.records)
        reasoning_tokens = sum(x.reasoning_tokens for x in self.records)
        costs = [x.estimated_cost_usd() for x in self.records]

        estimated = None
        if costs and all(cost is not None for cost in costs):
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
        "reasoning": {"effort": reasoning_effort},
        "verbosity": "low",
        "preserve_raw_usage": True,
    }


def _json_text(model: object) -> str:
    payload = model.model_dump() if hasattr(model, "model_dump") else model
    return json.dumps(payload, ensure_ascii=False, indent=2)


def _run_dir() -> Path:
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    path = REPO_ROOT / "output" / "ai-team" / f"WRITE-{stamp}"
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


def _developer_attempts() -> int:
    return max(1, int(os.getenv("EOP_MAX_DEVELOPER_ATTEMPTS", "2")))


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


def _print_escalation(escalated: EscalatedBrief) -> None:
    print("\n[Local context escalation]")
    print(f"Base brief:           {escalated.base_chars:,} znaków")
    print(f"Added context:        {escalated.added_chars:,} znaków")
    print(f"Escalated brief:      {escalated.chars:,} znaków")
    print("Expanded files:")
    for relative in escalated.expanded_files:
        print(f" - {relative}")


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


def escalation_preview_latest(task: str) -> int:
    brief = build_repo_brief(task)
    run_dir, blocked = find_latest_blocked_run(task)
    escalated = build_escalated_brief(task, brief, blocked)

    print("\n=== STAGE 3.1 — ZERO-COST ESCALATION PREVIEW ===")
    print(f"Source blocked run:    {run_dir}")
    print(f"Branch:                {brief.branch}")
    print(f"Base brief:            {brief.chars:,} znaków")
    print(f"Escalated brief:       {escalated.chars:,} znaków")
    print("Expanded files:")
    for relative in escalated.expanded_files:
        print(f" - {relative}")
    print("\nBlocked reason:")
    print(blocked.summary)
    if blocked.human_question:
        print("\nRequested context:")
        print(blocked.human_question)
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


async def _call_developer(
    *,
    task: str,
    pack_text: str,
    brief_text: str,
    attempt: int,
    prior_blocked: ChangeProposal | None,
    ledger: UsageLedger,
):
    from agents import Agent, RunConfig, Runner

    developer = Agent(
        name="Echoes Developer — Astra",
        model=DEVELOPER_MODEL,
        model_settings=_settings(DEVELOPER_REASONING),
        instructions=developer_write_instructions(pack_text, brief_text),
        output_type=ChangeProposal,
    )

    retry_context = ""
    if prior_blocked is not None:
        retry_context = (
            "\n\nPOPRZEDNIA PRÓBA BYŁA BLOCKED.\n"
            "Lokalny kontroler rozszerzył teraz kontekst dokładnie na podstawie "
            "Twojego poprzedniego blockera. Oceń nowy brief od początku.\n"
            f"Poprzedni blocker: {prior_blocked.summary}\n"
            f"Poprzednie pytanie: {prior_blocked.human_question}\n"
        )

    print(
        f"\n[Developer/Astra attempt {attempt}] "
        "preparing exact replacements..."
    )
    result = await Runner.run(
        developer,
        (
            f"TASK:\n{task}\n\n"
            "Zaproponuj najmniejszą bezpieczną zmianę."
            + retry_context
        ),
        max_turns=1,
        run_config=RunConfig(
            tracing_disabled=True,
            workflow_name=f"Echoes AI Team - Stage 3 developer attempt {attempt}",
        ),
    )
    ledger.add_result(DEVELOPER_MODEL, result)
    return result.final_output


async def _review_and_leave_diff(
    *,
    task: str,
    pack_text: str,
    brief_text: str,
    selected_files: tuple[str, ...],
    proposal: ChangeProposal,
    run_dir: Path,
    ledger: UsageLedger,
) -> int:
    from agents import Agent, RunConfig, Runner

    allowed_paths = {Path(path).as_posix() for path in selected_files}

    change = None
    try:
        change = apply_proposal(proposal, allowed_paths=allowed_paths)
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
            pack_text,
            brief_text,
            _json_text(proposal),
            diff_text,
        ),
        output_type=DiffReview,
    )

    print("\n[Reviewer/Sol] reviewing actual git diff...")

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


async def apply_task(task: str) -> int:
    _require_api_key()

    fuse = _hard_call_fuse()
    if fuse < 2:
        raise RuntimeError(
            "EOP_MAX_MODEL_CALLS_PER_TASK musi wynosić co najmniej 2."
        )

    pack = load_project_context(task)
    brief = build_repo_brief(task)

    run_dir = _run_dir()
    (run_dir / "task.txt").write_text(task + "\n", encoding="utf-8")
    (run_dir / "context_pack.txt").write_text(pack.text, encoding="utf-8")
    (run_dir / "repo_brief.txt").write_text(brief.text, encoding="utf-8")

    print("\n=== ECHOES AI TEAM — STAGE 3.1 / CONTROLLED WRITE ===")
    print(f"Developer:            {DEVELOPER_MODEL} ({DEVELOPER_REASONING})")
    print(f"Reviewer:             {REVIEWER_MODEL} ({REVIEWER_REASONING})")
    print(f"Configured hard fuse: {fuse}")
    print(f"Developer attempts:   {_developer_attempts()}")
    print(f"Branch:               {brief.branch}")
    print(f"HEAD:                 {brief.head}")
    print("Working tree:         CLEAN")
    print(f"REPO_BRIEF files:     {len(brief.selected_files)}")
    print("\nTASK:")
    print(task)

    ledger = UsageLedger()

    proposal = await _call_developer(
        task=task,
        pack_text=pack.text,
        brief_text=brief.text,
        attempt=1,
        prior_blocked=None,
        ledger=ledger,
    )
    _write_json(run_dir / "developer_proposal_attempt_1.json", proposal)
    _write_json(run_dir / "developer_proposal.json", proposal)

    print("\n[Developer proposal]")
    print(_json_text(proposal))

    effective_brief_text = brief.text
    effective_files = brief.selected_files

    if proposal.status == "BLOCKED":
        escalated = build_escalated_brief(task, brief, proposal)
        (run_dir / "repo_brief_escalated.txt").write_text(
            escalated.text,
            encoding="utf-8",
        )
        _write_json(
            run_dir / "escalation_manifest.json",
            {
                "expanded_files": list(escalated.expanded_files),
                "base_chars": escalated.base_chars,
                "added_chars": escalated.added_chars,
                "chars": escalated.chars,
            },
        )
        _print_escalation(escalated)

        can_retry = _developer_attempts() >= 2 and fuse >= 3
        if not can_retry:
            print("\nSTAGE 3.1: CONTEXT ESCALATION READY ⚠️")
            print("Nie wykonano drugiego płatnego wywołania Developera.")
            if fuse < 3:
                print(
                    "Hard fuse ma wartość 2. Użyj --resume-blocked-latest "
                    "dla retry+review albo ustaw "
                    "EOP_MAX_MODEL_CALLS_PER_TASK=3 dla pełnej automatyzacji."
                )
            _print_usage(ledger)
            print(f"Logi: {run_dir}")
            return 6

        proposal = await _call_developer(
            task=task,
            pack_text=pack.text,
            brief_text=escalated.text,
            attempt=2,
            prior_blocked=proposal,
            ledger=ledger,
        )
        _write_json(run_dir / "developer_proposal_attempt_2.json", proposal)
        _write_json(run_dir / "developer_proposal.json", proposal)
        effective_brief_text = escalated.text
        effective_files = escalated.selected_files

        print("\n[Developer proposal after escalation]")
        print(_json_text(proposal))

    if proposal.status == "BLOCKED":
        print("\nSTAGE 3.1: BLOCKED after context escalation — niczego nie zmieniono.")
        _print_usage(ledger)
        print(f"Logi: {run_dir}")
        return 3

    if proposal.status == "HUMAN_DECISION_REQUIRED":
        print("\nSTAGE 3.1: HUMAN_DECISION_REQUIRED — niczego nie zmieniono.")
        if proposal.human_question:
            print(f"Pytanie: {proposal.human_question}")
        _print_usage(ledger)
        return 4

    if len(ledger.records) >= fuse:
        raise RuntimeError(
            "Hard model-call fuse would be exceeded before Reviewer."
        )

    return await _review_and_leave_diff(
        task=task,
        pack_text=pack.text,
        brief_text=effective_brief_text,
        selected_files=effective_files,
        proposal=proposal,
        run_dir=run_dir,
        ledger=ledger,
    )


async def resume_blocked_latest(task: str) -> int:
    _require_api_key()

    fuse = _hard_call_fuse()
    if fuse < 2:
        raise RuntimeError(
            "Resume requires two calls maximum: Developer retry + Reviewer."
        )

    source_run, blocked = find_latest_blocked_run(task)
    pack = load_project_context(task)
    brief = build_repo_brief(task)
    escalated = build_escalated_brief(task, brief, blocked)

    run_dir = _run_dir()
    (run_dir / "task.txt").write_text(task + "\n", encoding="utf-8")
    (run_dir / "context_pack.txt").write_text(pack.text, encoding="utf-8")
    (run_dir / "repo_brief.txt").write_text(brief.text, encoding="utf-8")
    (run_dir / "repo_brief_escalated.txt").write_text(
        escalated.text,
        encoding="utf-8",
    )
    _write_json(run_dir / "source_blocked_proposal.json", blocked)

    print("\n=== STAGE 3.1 — RESUME BLOCKED TASK ===")
    print(f"Source run:            {source_run}")
    print(f"Developer:             {DEVELOPER_MODEL} ({DEVELOPER_REASONING})")
    print(f"Reviewer:              {REVIEWER_MODEL} ({REVIEWER_REASONING})")
    print(f"Hard fuse this run:    {fuse}")
    print("Model calls this run:  max 2 (retry + reviewer)")
    print(f"Branch:                {brief.branch}")
    _print_escalation(escalated)

    ledger = UsageLedger()
    proposal = await _call_developer(
        task=task,
        pack_text=pack.text,
        brief_text=escalated.text,
        attempt=2,
        prior_blocked=blocked,
        ledger=ledger,
    )
    _write_json(run_dir / "developer_proposal_attempt_2.json", proposal)
    _write_json(run_dir / "developer_proposal.json", proposal)

    print("\n[Developer proposal after escalation]")
    print(_json_text(proposal))

    if proposal.status == "BLOCKED":
        print("\nSTAGE 3.1: STILL BLOCKED — niczego nie zmieniono.")
        _print_usage(ledger)
        print(f"Logi: {run_dir}")
        return 3

    if proposal.status == "HUMAN_DECISION_REQUIRED":
        print("\nSTAGE 3.1: HUMAN_DECISION_REQUIRED — niczego nie zmieniono.")
        if proposal.human_question:
            print(f"Pytanie: {proposal.human_question}")
        _print_usage(ledger)
        return 4

    if len(ledger.records) >= fuse:
        raise RuntimeError(
            "Hard model-call fuse would be exceeded before Reviewer."
        )

    return await _review_and_leave_diff(
        task=task,
        pack_text=pack.text,
        brief_text=escalated.text,
        selected_files=escalated.selected_files,
        proposal=proposal,
        run_dir=run_dir,
        ledger=ledger,
    )


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Echoes of Pythonia — Stage 3.1 controlled write."
    )
    parser.add_argument("--write-smoke", action="store_true")
    parser.add_argument("--write-preview", action="store_true")
    parser.add_argument("--escalation-preview-latest", action="store_true")
    parser.add_argument("--resume-blocked-latest", action="store_true")
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

    if args.escalation_preview_latest:
        if not task:
            print("--escalation-preview-latest wymaga --task.")
            return 1
        return escalation_preview_latest(task)

    if args.resume_blocked_latest:
        if not task:
            print("--resume-blocked-latest wymaga --task.")
            return 1
        return await resume_blocked_latest(task)

    if args.apply_task:
        return await apply_task(args.apply_task)

    print(
        'Użyj --write-smoke, --write-preview --task "...", '
        '--escalation-preview-latest --task "...", '
        '--resume-blocked-latest --task "..." '
        'lub --apply-task "...".'
    )
    return 1


def main() -> None:
    try:
        code = asyncio.run(async_main())
    except (
        BriefError,
        ControlledWriteError,
        EscalationError,
        RuntimeError,
        FileNotFoundError,
    ) as exc:
        print(f"\nBŁĄD / SAFETY STOP:\n{exc}")
        code = 2
    except KeyboardInterrupt:
        print(
            "\nPrzerwano. Jeśli zmiana była w trakcie, "
            "kontroler próbuje ją cofnąć."
        )
        code = 130

    raise SystemExit(code)


if __name__ == "__main__":
    main()
