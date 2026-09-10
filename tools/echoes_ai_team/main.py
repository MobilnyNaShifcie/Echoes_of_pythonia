from __future__ import annotations

import argparse, asyncio, json, os
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

from config import (
    CONTEXT_MAX_CHARS, CONTEXT_MAX_SECTIONS, DEVELOPER_MODEL,
    DEVELOPER_REASONING, MAX_MODEL_CALLS_PER_TASK, MAX_REVIEW_ROUNDS,
    REPO_BRIEF_MAX_CHARS, REPO_BRIEF_MAX_FILES, REPO_ROOT,
    REVIEWER_MODEL, REVIEWER_REASONING,
)
from context_loader import ContextPack, load_project_context
from prompts import developer_single_shot_instructions, reviewer_single_shot_instructions
from repo_brief import BriefError, RepoBrief, build_repo_brief
from schemas import DeveloperPlan, ReviewResult

# Current Standard API text prices in USD per 1M tokens.
MODEL_PRICES = {
    "gpt-6-astra": {"input":10.0, "cached":1.0, "cache_write":12.5, "output":50.0},
    "gpt-5.6-sol": {"input":4.0, "cached":0.4, "cache_write":5.0, "output":20.0},
}

@dataclass
class RequestRecord:
    model: str
    input_tokens: int
    cached_tokens: int
    cache_write_tokens: int
    output_tokens: int
    reasoning_tokens: int

    def cost(self):
        p = MODEL_PRICES.get(self.model)
        if not p:
            return None
        cached = min(self.cached_tokens, self.input_tokens)
        writes = min(self.cache_write_tokens, max(0, self.input_tokens-cached))
        regular = max(0, self.input_tokens-cached-writes)
        return (regular*p["input"] + cached*p["cached"] + writes*p["cache_write"] + self.output_tokens*p["output"]) / 1_000_000

@dataclass
class UsageLedger:
    records: list[RequestRecord] = field(default_factory=list)
    @property
    def calls(self): return len(self.records)

    def add(self, model, result):
        usage = getattr(getattr(result, "context_wrapper", None), "usage", None)
        if usage is None:
            return
        entries = getattr(usage, "request_usage_entries", None) or []
        if not entries and int(getattr(usage, "requests", 0) or 0) == 1:
            entries = [usage]
        for e in entries:
            ind = getattr(e, "input_tokens_details", None)
            outd = getattr(e, "output_tokens_details", None)
            self.records.append(RequestRecord(
                model,
                int(getattr(e,"input_tokens",0) or 0),
                int(getattr(ind,"cached_tokens",0) or 0),
                int(getattr(ind,"cache_write_tokens",0) or 0),
                int(getattr(e,"output_tokens",0) or 0),
                int(getattr(outd,"reasoning_tokens",0) or 0),
            ))

    def totals(self):
        vals = {
            "requests": self.calls,
            "input_tokens": sum(x.input_tokens for x in self.records),
            "cached_tokens": sum(x.cached_tokens for x in self.records),
            "cache_write_tokens": sum(x.cache_write_tokens for x in self.records),
            "output_tokens": sum(x.output_tokens for x in self.records),
            "reasoning_tokens": sum(x.reasoning_tokens for x in self.records),
        }
        vals["total_tokens"] = vals["input_tokens"] + vals["output_tokens"]
        costs = [x.cost() for x in self.records]
        vals["estimated_cost_usd"] = sum(costs) if costs and all(x is not None for x in costs) else None
        return vals


def _json(obj):
    if hasattr(obj, "model_dump"): obj = obj.model_dump()
    return json.dumps(obj, ensure_ascii=False, indent=2)


def _run_dir(prefix):
    p = REPO_ROOT / "output" / "ai-team" / f"{prefix}-{datetime.now():%Y%m%d-%H%M%S}"
    p.mkdir(parents=True, exist_ok=True)
    return p


def _require_key():
    if not os.getenv("OPENAI_API_KEY", "").strip():
        raise RuntimeError("Brak OPENAI_API_KEY. Sprawdź tools\\echoes_ai_team\\.env.")


def _settings(effort):
    return {"reasoning":{"effort":effort}, "verbosity":"low", "preserve_raw_usage":True}


def _show_pack(pack: ContextPack):
    print("\n=== CONTEXT PACK ===")
    print(f"Pełne AI_CONTEXT:     {pack.source_chars:,} znaków")
    print(f"Wysłane fragmenty:    {pack.selected_chars:,} znaków")
    print(f"Redukcja:             {pack.reduction_percent:.1f}%")


def _show_brief(brief: RepoBrief):
    print("\n=== LOCAL REPO BRIEF ===")
    print(f"Branch:               {brief.branch}")
    print(f"HEAD:                 {brief.head}")
    print("Working tree:         CLEAN")
    print(f"Przeskanowane pliki:  {brief.scanned_files}")
    print(f"Brief:                {brief.chars:,} znaków")
    print(f"Wybrane pliki:        {len(brief.selected_files)}")
    for path in brief.selected_files: print(" -", path)


def _show_cost(ledger: UsageLedger):
    t = ledger.totals()
    print("\n=== COST / USAGE REPORT ===")
    print(f"Model requests:       {t['requests']}")
    print(f"Input tokens:         {t['input_tokens']:,}")
    print(f"  cached input:       {t['cached_tokens']:,}")
    print(f"  cache writes:       {t['cache_write_tokens']:,}")
    print(f"Output tokens:        {t['output_tokens']:,}")
    print(f"  reasoning tokens:   {t['reasoning_tokens']:,}")
    print(f"Total tokens:         {t['total_tokens']:,}")
    cost = t["estimated_cost_usd"]
    print("Estimated API cost:   " + (f"${cost:.4f} USD" if cost is not None else "n/a"))
    for i,r in enumerate(ledger.records,1):
        c = r.cost()
        print(f" {i}. {r.model}: {r.input_tokens:,} in ({r.cached_tokens:,} cached, {r.cache_write_tokens:,} write), {r.output_tokens:,} out ≈ " + (f"${c:.4f}" if c is not None else "n/a"))


def brief_preview(task):
    pack = load_project_context(task)
    brief = build_repo_brief(task)
    print("\n=== STAGE 2.1 — ZERO-COST PREVIEW ===")
    _show_pack(pack); _show_brief(brief)
    print(f"\nŁączny lokalny materiał: {pack.selected_chars + brief.chars:,} znaków")
    print("API calls:             0")
    print("\nBRIEF PREVIEW: PASS — API nie zostało wywołane.")
    return 0


async def run_task(task):
    _require_key()
    from agents import Agent, RunConfig, Runner

    pack = load_project_context(task)
    brief = build_repo_brief(task)
    log = _run_dir("SINGLESHOT")
    (log/"task.txt").write_text(task+"\n", encoding="utf-8")
    (log/"context_pack.txt").write_text(pack.text, encoding="utf-8")
    (log/"repo_brief.txt").write_text(brief.text, encoding="utf-8")

    print("\n=== ECHOES AI TEAM — STAGE 2.1 / SINGLE-SHOT ===")
    print(f"Developer:            {DEVELOPER_MODEL} ({DEVELOPER_REASONING})")
    print(f"Reviewer:             {REVIEWER_MODEL} ({REVIEWER_REASONING})")
    print(f"Hard model-call fuse: {MAX_MODEL_CALLS_PER_TASK}")
    _show_pack(pack); _show_brief(brief)
    print("\nTASK:\n" + task)

    developer = Agent(name="Echoes Developer — Astra", model=DEVELOPER_MODEL,
        model_settings=_settings(DEVELOPER_REASONING),
        instructions=developer_single_shot_instructions(pack.text, brief.text),
        output_type=DeveloperPlan)
    reviewer = Agent(name="Echoes Reviewer — Sol", model=REVIEWER_MODEL,
        model_settings=_settings(REVIEWER_REASONING),
        instructions=reviewer_single_shot_instructions(pack.text, brief.text),
        output_type=ReviewResult)
    devcfg = RunConfig(tracing_disabled=True, workflow_name="Echoes Stage 2.1 Developer")
    revcfg = RunConfig(tracing_disabled=True, workflow_name="Echoes Stage 2.1 Reviewer")

    ledger = UsageLedger(); prev_plan = prev_review = None
    rounds = min(MAX_REVIEW_ROUNDS, max(1, MAX_MODEL_CALLS_PER_TASK//2))

    for round_no in range(1, rounds+1):
        print(f"\n========== RUNDA {round_no}/{rounds} ==========")
        if ledger.calls >= MAX_MODEL_CALLS_PER_TASK: break
        prompt = f"TASK:\n{task}\n\nPrzygotuj plan. Nic nie edytuj." if prev_plan is None else f"TASK:\n{task}\n\nPOPRZEDNI PLAN:\n{_json(prev_plan)}\n\nREVIEW:\n{_json(prev_review)}\n\nPopraw plan bez rozszerzania scope."
        print("[Developer/Astra] model call...")
        result = await Runner.run(developer, prompt, max_turns=1, run_config=devcfg)
        ledger.add(DEVELOPER_MODEL, result)
        plan = result.final_output
        (log/f"developer_round_{round_no}.json").write_text(_json(plan)+"\n", encoding="utf-8")
        print(_json(plan))
        if plan.status != "READY_FOR_REVIEW":
            _show_cost(ledger); return 3 if plan.status == "BLOCKED" else 4
        if not plan.repo_evidence:
            print("SAFETY STOP: brak repo_evidence."); _show_cost(ledger); return 6
        if ledger.calls >= MAX_MODEL_CALLS_PER_TASK:
            print("HARD COST FUSE przed Reviewerem."); _show_cost(ledger); return 7

        print("\n[Reviewer/Sol] model call...")
        rprompt = f"ORYGINALNE ZADANIE:\n{task}\n\nPLAN DEVELOPERA:\n{_json(plan)}\n\nZweryfikuj plan względem AI_CONTEXT i REPO_BRIEF."
        rresult = await Runner.run(reviewer, rprompt, max_turns=1, run_config=revcfg)
        ledger.add(REVIEWER_MODEL, rresult)
        review = rresult.final_output
        (log/f"review_round_{round_no}.json").write_text(_json(review)+"\n", encoding="utf-8")
        print(_json(review))
        if not review.evidence_checked:
            print("SAFETY STOP: Reviewer nie podał evidence_checked."); _show_cost(ledger); return 6
        if review.verdict == "APPROVED":
            print("\n====================================\nSINGLE-SHOT REPO DRY RUN: APPROVED ✅")
            print(f"Review rounds: {round_no}"); _show_cost(ledger)
            print(f"\nLogi: {log}\nStage 2.1 nadal NIE edytuje plików i NIE posiada shella.")
            return 0
        if review.verdict == "HUMAN_DECISION_REQUIRED":
            _show_cost(ledger); return 4
        prev_plan, prev_review = plan, review

    print("\nAUTOMATIC REVISION LIMIT reached."); _show_cost(ledger); return 5


def parse_args():
    p=argparse.ArgumentParser(description="Echoes AI Team Stage 2.1")
    p.add_argument("--show-config", action="store_true")
    p.add_argument("--brief-preview", action="store_true")
    p.add_argument("--task", type=str)
    p.add_argument("--repo-task", type=str)
    return p.parse_args()


async def async_main():
    a=parse_args()
    if a.show_config:
        print(f"Repo root:               {REPO_ROOT}")
        print(f"Developer model:         {DEVELOPER_MODEL}")
        print(f"Reviewer model:          {REVIEWER_MODEL}")
        print(f"Developer reasoning:     {DEVELOPER_REASONING}")
        print(f"Reviewer reasoning:      {REVIEWER_REASONING}")
        print(f"Repo brief max chars:    {REPO_BRIEF_MAX_CHARS}")
        print(f"Repo brief max files:    {REPO_BRIEF_MAX_FILES}")
        print(f"Hard model-call fuse:    {MAX_MODEL_CALLS_PER_TASK}")
        print("API key:                 " + ("SET" if os.getenv("OPENAI_API_KEY","").strip() else "MISSING"))
        if not a.brief_preview and not a.task and not a.repo_task: return 0
    task=a.repo_task or a.task
    if a.brief_preview:
        task=task or input("TASK > ").strip()
        return brief_preview(task) if task else 1
    task=task or input("TASK > ").strip()
    return await run_task(task) if task else 1


def main():
    try: code=asyncio.run(async_main())
    except (FileNotFoundError, RuntimeError, BriefError) as exc:
        print(f"\nBŁĄD / SAFETY STOP:\n{exc}"); code=2
    except KeyboardInterrupt:
        print("\nPrzerwano. Stage 2.1 nie edytuje plików gry."); code=130
    raise SystemExit(code)


if __name__ == "__main__": main()
