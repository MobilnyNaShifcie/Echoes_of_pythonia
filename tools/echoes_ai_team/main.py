from __future__ import annotations

import argparse
import asyncio
import json
import os
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path

from config import (
    CONTEXT_MAX_CHARS, CONTEXT_MAX_SECTIONS,
    DEVELOPER_MODEL, DEVELOPER_REASONING, MAX_REVIEW_ROUNDS,
    REPO_ROOT, REVIEWER_MODEL, REVIEWER_REASONING,
)
from context_loader import ContextPack, load_project_context
from prompts import (
    developer_instructions,
    developer_repo_instructions,
    reviewer_instructions,
    reviewer_repo_instructions,
)
from schemas import DeveloperPlan, ReviewResult


@dataclass
class UsageTotals:
    requests: int = 0
    input_tokens: int = 0
    output_tokens: int = 0
    total_tokens: int = 0

    def add_result(self, result: object) -> None:
        wrapper = getattr(result, "context_wrapper", None)
        usage = getattr(wrapper, "usage", None)
        if usage is None:
            return
        self.requests += int(getattr(usage, "requests", 0) or 0)
        self.input_tokens += int(getattr(usage, "input_tokens", 0) or 0)
        self.output_tokens += int(getattr(usage, "output_tokens", 0) or 0)
        self.total_tokens += int(getattr(usage, "total_tokens", 0) or 0)


def _json_text(model: object) -> str:
    payload = model.model_dump() if hasattr(model, "model_dump") else model
    return json.dumps(payload, ensure_ascii=False, indent=2)


def _write_json(path: Path, model: object) -> None:
    path.write_text(_json_text(model) + "\n", encoding="utf-8")


def _make_run_dir(prefix: str) -> Path:
    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    path = REPO_ROOT / "output" / "ai-team" / f"{prefix}-{stamp}"
    path.mkdir(parents=True, exist_ok=True)
    return path


def _require_api_key() -> None:
    if not os.getenv("OPENAI_API_KEY", "").strip():
        raise RuntimeError("Brak OPENAI_API_KEY. Sprawdź tools\\echoes_ai_team\\.env.")


def _settings(reasoning_effort: str, verbosity: str = "low") -> dict:
    return {"reasoning": {"effort": reasoning_effort}, "verbosity": verbosity}


def _print_context_pack(pack: ContextPack) -> None:
    print("\n=== CONTEXT ROUTER ===")
    print(f"Pełne AI_CONTEXT:      {pack.source_chars:,} znaków")
    print(f"Wysłany context pack:  {pack.selected_chars:,} znaków")
    print(f"Redukcja:              {pack.reduction_percent:.1f}%")
    print(f"Wybrane sekcje:        {len(pack.selected_sections)}")
    print("\nSekcje:")
    for item in pack.selected_sections:
        print(f" - {item.section.document} :: {item.section.heading} [score={item.score:.2f}]")


async def smoke_test() -> int:
    _require_api_key()
    from agents import Agent, RunConfig, Runner

    totals = UsageTotals()
    cfg = RunConfig(tracing_disabled=True, workflow_name="Echoes AI Team - smoke test")
    tests = (
        ("Developer/Astra", DEVELOPER_MODEL, "Odpowiedz dokładnie jednym krótkim zdaniem: ASTRA_OK — połączenie działa."),
        ("Reviewer/Sol", REVIEWER_MODEL, "Odpowiedz dokładnie jednym krótkim zdaniem: REVIEWER_OK — połączenie działa."),
    )

    print("\n=== ECHOES AI TEAM — SMOKE TEST ===")
    for label, model, prompt in tests:
        print(f"[{label}] łączenie...")
        agent = Agent(
            name=label,
            model=model,
            model_settings=_settings("low"),
            instructions="Wykonaj wyłącznie krótki test połączenia.",
        )
        try:
            result = await Runner.run(agent, prompt, max_turns=2, run_config=cfg)
        except Exception as exc:
            print(f"\nBŁĄD podczas testu {label}:\n{type(exc).__name__}: {exc}")
            return 2
        totals.add_result(result)
        print(f"  {result.final_output}")

    print("\nSMOKE TEST: PASS")
    print(f"API usage: {totals.requests} requests, {totals.input_tokens} input, {totals.output_tokens} output, {totals.total_tokens} total tokens.")
    return 0


def repo_tools_smoke() -> int:
    from repo_tools import local_repo_tools_smoke

    print("\n=== STAGE 2 — LOCAL READ-ONLY TOOL SMOKE ===")
    result = local_repo_tools_smoke()
    print(result)

    if "FAIL" in result:
        print("\nREPO TOOL SMOKE: FAIL")
        return 2

    print("\nREPO TOOL SMOKE: PASS — API nie zostało wywołane.")
    return 0


async def planning_dry_run(task: str) -> int:
    _require_api_key()
    from agents import Agent, RunConfig, Runner

    pack = load_project_context(task)
    project_context = pack.text
    developer = Agent(
        name="Echoes Developer — Astra",
        model=DEVELOPER_MODEL,
        model_settings=_settings(DEVELOPER_REASONING),
        instructions=developer_instructions(project_context),
        output_type=DeveloperPlan,
    )
    reviewer = Agent(
        name="Echoes Reviewer — Sol",
        model=REVIEWER_MODEL,
        model_settings=_settings(REVIEWER_REASONING),
        instructions=reviewer_instructions(project_context),
        output_type=ReviewResult,
    )
    return await _run_loop(task, pack, developer, reviewer, "DRYRUN", "Stage 1.2", False)


async def repository_dry_run(task: str) -> int:
    _require_api_key()
    from agents import Agent, RunConfig, Runner
    from repo_tools import READ_ONLY_REPO_TOOLS

    pack = load_project_context(task)
    project_context = pack.text

    developer = Agent(
        name="Echoes Developer — Astra",
        model=DEVELOPER_MODEL,
        model_settings=_settings(DEVELOPER_REASONING),
        instructions=developer_repo_instructions(project_context),
        output_type=DeveloperPlan,
        tools=READ_ONLY_REPO_TOOLS,
    )
    reviewer = Agent(
        name="Echoes Reviewer — Sol",
        model=REVIEWER_MODEL,
        model_settings=_settings(REVIEWER_REASONING),
        instructions=reviewer_repo_instructions(project_context),
        output_type=ReviewResult,
        tools=READ_ONLY_REPO_TOOLS,
    )

    return await _run_loop(task, pack, developer, reviewer, "REPO-DRYRUN", "Stage 2", True)


async def _run_loop(task, pack, developer, reviewer, prefix, stage_name, repo_aware):
    from agents import RunConfig, Runner

    run_dir = _make_run_dir(prefix)
    (run_dir / "task.txt").write_text(task + "\n", encoding="utf-8")
    (run_dir / "context_pack.txt").write_text(pack.text, encoding="utf-8")

    totals = UsageTotals()
    previous_plan = None
    previous_review = None

    print(f"\n=== ECHOES AI TEAM — {stage_name.upper()} ===")
    print(f"Developer: {DEVELOPER_MODEL} ({DEVELOPER_REASONING})")
    print(f"Reviewer:  {REVIEWER_MODEL} ({REVIEWER_REASONING})")
    print("Repository mode: READ-ONLY" if repo_aware else "Repository mode: no repo tools")
    _print_context_pack(pack)
    print(f"\nLogi: {run_dir}")
    print(f"\nTASK:\n{task}\n")

    dev_cfg = RunConfig(
        tracing_disabled=True,
        workflow_name=f"Echoes AI Team - {stage_name} developer",
    )
    rev_cfg = RunConfig(
        tracing_disabled=True,
        workflow_name=f"Echoes AI Team - {stage_name} review",
    )

    for round_no in range(1, MAX_REVIEW_ROUNDS + 1):
        print(f"\n========== RUNDA {round_no}/{MAX_REVIEW_ROUNDS} ==========")
        print("[Developer] analizuje...")

        if previous_plan is None:
            dev_input = (
                f"TASK:\n{task}\n\n"
                "Przygotuj plan. To DRY RUN: niczego nie edytuj i nie twierdź, że testy zostały uruchomione."
            )
        else:
            dev_input = (
                f"TASK:\n{task}\n\nPOPRZEDNI PLAN:\n{_json_text(previous_plan)}\n\n"
                f"REVIEW:\n{_json_text(previous_review)}\n\n"
                "Przygotuj poprawiony plan. Napraw BLOCKERY i istotne uwagi. To nadal DRY RUN."
            )

        try:
            dev_result = await Runner.run(
                developer,
                dev_input,
                max_turns=10 if repo_aware else 4,
                run_config=dev_cfg,
            )
        except Exception as exc:
            print(f"\nBŁĄD DEVELOPERA: {type(exc).__name__}: {exc}")
            return 2

        totals.add_result(dev_result)
        plan = dev_result.final_output
        _write_json(run_dir / f"developer_round_{round_no}.json", plan)

        print("\n[Developer plan]")
        print(_json_text(plan))

        if repo_aware and plan.status == "READY_FOR_REVIEW" and len(plan.repo_evidence) < 2:
            print("\nSTAGE 2 SAFETY GATE: Developer podał za mało rzeczywistego repo_evidence.")
            print("Pętla zatrzymana; nie uznajemy planu opartego głównie na zgadywaniu.")
            return 6

        if plan.status in {"BLOCKED", "HUMAN_DECISION_REQUIRED"}:
            print(f"\nDRY RUN: {plan.status}")
            if plan.human_question:
                print(f"Pytanie: {plan.human_question}")
            return 3 if plan.status == "BLOCKED" else 4

        print("\n[Reviewer] niezależnie weryfikuje...")

        rev_input = (
            f"ORYGINALNE ZADANIE:\n{task}\n\n"
            f"PLAN DEVELOPERA — RUNDA {round_no}:\n{_json_text(plan)}\n\n"
            "Oceń plan według AI_CONTEXT. To planning-only dry run: brak faktycznie uruchomionych testów nie jest blockerem."
        )

        try:
            rev_result = await Runner.run(
                reviewer,
                rev_input,
                max_turns=10 if repo_aware else 4,
                run_config=rev_cfg,
            )
        except Exception as exc:
            print(f"\nBŁĄD REVIEWERA: {type(exc).__name__}: {exc}")
            return 2

        totals.add_result(rev_result)
        review = rev_result.final_output
        _write_json(run_dir / f"review_round_{round_no}.json", review)

        print("\n[Reviewer]")
        print(_json_text(review))

        if repo_aware and len(review.evidence_checked) < 1:
            print("\nSTAGE 2 SAFETY GATE: Reviewer nie podał niezależnego evidence_checked.")
            return 6

        if review.verdict == "APPROVED":
            print("\n====================================")
            print("REPOSITORY DRY RUN: APPROVED ✅" if repo_aware else "DRY RUN: APPROVED ✅")
            print(f"Review rounds: {round_no}")
            print(f"API usage: {totals.requests} requests, {totals.input_tokens} input, {totals.output_tokens} output, {totals.total_tokens} total tokens.")
            print(f"Logi: {run_dir}")
            if repo_aware:
                print("\nStage 2 nadal NIE posiada narzędzi zapisu ani shell.")
            return 0

        if review.verdict == "HUMAN_DECISION_REQUIRED":
            print("\nDRY RUN: HUMAN_DECISION_REQUIRED")
            if review.human_question:
                print(f"Pytanie: {review.human_question}")
            return 4

        previous_plan = plan
        previous_review = review

    print("\nDRY RUN: MAX_REVIEW_ROUNDS_REACHED")
    return 5


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Echoes of Pythonia — AI team.")
    p.add_argument("--smoke", action="store_true")
    p.add_argument("--repo-smoke", action="store_true")
    p.add_argument("--task", type=str)
    p.add_argument("--repo-task", type=str)
    p.add_argument("--show-config", action="store_true")
    p.add_argument("--context-preview", action="store_true")
    return p.parse_args()


async def async_main() -> int:
    args = parse_args()

    if args.show_config:
        print(f"Repo root:             {REPO_ROOT}")
        print(f"Developer model:       {DEVELOPER_MODEL}")
        print(f"Reviewer model:        {REVIEWER_MODEL}")
        print(f"Max rounds:            {MAX_REVIEW_ROUNDS}")
        print(f"Context max chars:     {CONTEXT_MAX_CHARS}")
        print(f"Context max sections:  {CONTEXT_MAX_SECTIONS}")
        print("API key:               " + ("SET" if os.getenv("OPENAI_API_KEY", "").strip() else "MISSING"))
        if not any((args.smoke, args.repo_smoke, args.task, args.repo_task, args.context_preview)):
            return 0

    if args.repo_smoke:
        return repo_tools_smoke()

    if args.smoke:
        return await smoke_test()

    if args.context_preview:
        task = args.task or args.repo_task or input("TASK > ").strip()
        if not task:
            print("Brak zadania.")
            return 1
        pack = load_project_context(task)
        _print_context_pack(pack)
        print("\nCONTEXT PREVIEW: PASS — API nie zostało wywołane.")
        return 0

    if args.repo_task:
        return await repository_dry_run(args.repo_task)

    task = args.task or input("TASK > ").strip()
    if not task:
        print("Brak zadania.")
        return 1
    return await planning_dry_run(task)


def main() -> None:
    try:
        code = asyncio.run(async_main())
    except (FileNotFoundError, RuntimeError) as exc:
        print(f"\nBŁĄD:\n{exc}")
        code = 2
    except KeyboardInterrupt:
        print("\nPrzerwano przez użytkownika. Tryby Stage 1/2 nie edytują plików gry.")
        code = 130
    raise SystemExit(code)


if __name__ == "__main__":
    main()
