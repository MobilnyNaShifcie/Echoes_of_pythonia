from __future__ import annotations

import argparse
import asyncio
import json
import os
import re
import shutil
import subprocess
import unicodedata
from dataclasses import asdict, dataclass, field
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
from repo_agent_tools import RepoInspector, build_repo_tool
from write_prompts import reviewer_diff_instructions
from write_schemas import ChangeProposal, DiffReview


ROOT = REPO_ROOT.resolve()
BASE_BRANCH = os.getenv("EOP_AUTOPILOT_BASE_BRANCH", "ai/echoes-team")
REMOTE = os.getenv("EOP_AUTOPILOT_REMOTE", "origin")
OUTPUT_ROOT = ROOT / "output" / "ai-team"

PROTECTED_BRANCHES = {
    "main",
    "master",
    "snapshot/pre-ai-team-2026-09-10",
}

EDIT_ROOTS = ("godot/", "AI_CONTEXT/", "tools/", "scripts/")
EDITABLE_SUFFIXES = {
    ".gd", ".gdshader", ".gdshaderinc", ".tscn", ".tres",
    ".md", ".txt", ".json", ".py", ".ps1", ".cfg", ".ini",
    ".toml", ".yml", ".yaml", ".csv",
}
DENIED_NAMES = {".env", "export_credentials.cfg", "project.godot"}
MAX_EDIT_FILES = int(os.getenv("EOP_AUTOPILOT_MAX_EDIT_FILES", "4"))
MAX_REPLACEMENTS_PER_FILE = int(os.getenv("EOP_AUTOPILOT_MAX_REPLACEMENTS_PER_FILE", "8"))
MAX_TOTAL_NEW_CHARS = int(os.getenv("EOP_AUTOPILOT_MAX_NEW_CHARS", "26000"))
MAX_DIFF_CHARS = int(os.getenv("EOP_AUTOPILOT_MAX_DIFF_CHARS", "42000"))
MAX_REVIEW_CYCLES = int(os.getenv("EOP_AUTOPILOT_MAX_REVIEW_CYCLES", "2"))
DEVELOPER_MAX_TURNS = int(os.getenv("EOP_AUTOPILOT_DEVELOPER_MAX_TURNS", "4"))
REVIEWER_MAX_TURNS = int(os.getenv("EOP_AUTOPILOT_REVIEWER_MAX_TURNS", "3"))


class AutopilotError(RuntimeError):
    pass


@dataclass
class AppliedChange:
    originals: dict[Path, str]
    edited_paths: tuple[Path, ...]


@dataclass
class RequestRecord:
    model: str
    input_tokens: int
    cached_tokens: int
    cache_write_tokens: int
    output_tokens: int
    reasoning_tokens: int


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
                        cached_tokens=int(getattr(input_details, "cached_tokens", 0) or 0),
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

        if int(getattr(usage, "requests", 0) or 0) == 1:
            input_details = getattr(usage, "input_tokens_details", None)
            output_details = getattr(usage, "output_tokens_details", None)
            self.records.append(
                RequestRecord(
                    model=model,
                    input_tokens=int(getattr(usage, "input_tokens", 0) or 0),
                    cached_tokens=int(getattr(input_details, "cached_tokens", 0) or 0),
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
        return {
            "requests": len(self.records),
            "input_tokens": sum(x.input_tokens for x in self.records),
            "cached_tokens": sum(x.cached_tokens for x in self.records),
            "cache_write_tokens": sum(x.cache_write_tokens for x in self.records),
            "output_tokens": sum(x.output_tokens for x in self.records),
            "reasoning_tokens": sum(x.reasoning_tokens for x in self.records),
        }


def _run(
    command: list[str],
    *,
    check: bool = True,
    timeout: int = 180,
) -> subprocess.CompletedProcess[str]:
    cp = subprocess.run(
        command,
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
        timeout=timeout,
    )
    if check and cp.returncode != 0:
        raise AutopilotError(
            "$ " + " ".join(command) + "\n\n" + cp.stdout + "\n" + cp.stderr
        )
    return cp


def _git(args: list[str], *, check: bool = True, timeout: int = 180):
    return _run(["git", *args], check=check, timeout=timeout)


def _git_text(args: list[str]) -> str:
    return _git(args).stdout.strip()


def _branch() -> str:
    return _git_text(["branch", "--show-current"])


def _head() -> str:
    return _git_text(["rev-parse", "HEAD"])


def _status() -> str:
    return _git_text(["status", "--porcelain"])


def _ensure_clean() -> None:
    status = _status()
    if status:
        raise AutopilotError("Working tree is not clean:\n" + status)


def _ensure_safe_branch(branch: str) -> None:
    if branch in PROTECTED_BRANCHES or branch.startswith("release/"):
        raise AutopilotError(f"Protected branch is active: {branch}")


def _fetch() -> None:
    _git(["fetch", REMOTE, "--prune"], timeout=300)


def _divergence(left: str, right: str) -> tuple[int, int]:
    raw = _git_text(["rev-list", "--left-right", "--count", f"{left}...{right}"])
    parts = raw.replace("\t", " ").split()
    if len(parts) != 2:
        raise AutopilotError(f"Could not parse divergence: {raw}")
    return int(parts[0]), int(parts[1])


def _slugify(text: str, max_len: int = 44) -> str:
    normalized = unicodedata.normalize("NFKD", text)
    ascii_text = normalized.encode("ascii", "ignore").decode("ascii")
    slug = re.sub(r"[^A-Za-z0-9]+", "-", ascii_text).strip("-").lower()
    return (slug or "task")[:max_len].rstrip("-")


def _task_id() -> str:
    return "EOP-" + datetime.now().strftime("%Y%m%d-%H%M%S")


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
    path = OUTPUT_ROOT / f"AUTOPILOT-{datetime.now():%Y%m%d-%H%M%S}"
    path.mkdir(parents=True, exist_ok=True)
    return path


def _write_json(path: Path, value: object) -> None:
    if hasattr(value, "model_dump"):
        value = value.model_dump()
    path.write_text(
        json.dumps(value, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def _start_task_branch(task: str) -> tuple[str, str]:
    branch = _branch()
    _ensure_safe_branch(branch)
    if branch != BASE_BRANCH:
        raise AutopilotError(
            f"Start Autopilot from {BASE_BRANCH}. Current branch: {branch}"
        )
    _ensure_clean()
    _fetch()

    remote_base = f"{REMOTE}/{BASE_BRANCH}"
    behind, ahead = _divergence(remote_base, BASE_BRANCH)
    if behind or ahead:
        raise AutopilotError(
            f"Base must be synchronized with origin first. behind={behind}, ahead={ahead}"
        )

    task_branch = f"ai/task/{_task_id()}-{_slugify(task)}"
    _git(["switch", "-c", task_branch])
    return task_branch, _head()


def _safe_edit_path(relative: str) -> Path:
    raw = (relative or "").replace("\\", "/").strip()
    if not raw or raw.startswith("/") or ".." in Path(raw).parts:
        raise AutopilotError(f"Unsafe edit path: {relative}")
    if not raw.startswith(EDIT_ROOTS):
        raise AutopilotError(f"Edit root is not allowed: {raw}")

    path = (ROOT / raw).resolve()
    try:
        path.relative_to(ROOT)
    except ValueError as exc:
        raise AutopilotError(f"Edit target escapes repo: {raw}") from exc

    if not path.exists() or not path.is_file() or path.is_symlink():
        raise AutopilotError(f"Edit target must be an existing regular file: {raw}")
    if path.name.casefold() in {x.casefold() for x in DENIED_NAMES}:
        raise AutopilotError(f"Denied edit target: {raw}")
    if path.name.casefold().startswith(".env"):
        raise AutopilotError(f"Denied edit target: {raw}")
    if path.suffix.casefold() not in EDITABLE_SUFFIXES:
        raise AutopilotError(f"Unsupported edit file type: {raw}")
    return path


def _read_exact(path: Path) -> str:
    with path.open("r", encoding="utf-8", newline="") as handle:
        return handle.read()


def _write_exact(path: Path, text: str) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        handle.write(text)


def _apply_replacement(text: str, old_text: str, new_text: str) -> str:
    if not old_text:
        raise AutopilotError("old_text must not be empty")

    variants = [(old_text.replace("\r\n", "\n"), new_text.replace("\r\n", "\n"))]
    if "\n" in variants[0][0]:
        variants.append((
            variants[0][0].replace("\n", "\r\n"),
            variants[0][1].replace("\n", "\r\n"),
        ))

    for old, new in variants:
        count = text.count(old)
        if count == 1:
            return text.replace(old, new, 1)
        if count > 1:
            raise AutopilotError("old_text is not unique in target file")
    raise AutopilotError("old_text was not found exactly in target file")


def _apply_proposal(
    proposal: ChangeProposal,
    inspected_paths: set[str],
) -> AppliedChange:
    if proposal.status != "READY_TO_APPLY":
        raise AutopilotError(f"Proposal is not ready: {proposal.status}")
    if not proposal.edits:
        raise AutopilotError("Developer returned no edits")
    if len(proposal.edits) > MAX_EDIT_FILES:
        raise AutopilotError("Developer proposed too many edited files")

    originals: dict[Path, str] = {}
    working: dict[Path, str] = {}
    total_new_chars = 0

    try:
        for edit in proposal.edits:
            rel = Path(edit.path).as_posix()
            if rel not in inspected_paths:
                raise AutopilotError(
                    f"Developer tried to edit a file it did not explicitly read: {rel}"
                )
            path = _safe_edit_path(rel)
            if not edit.replacements:
                raise AutopilotError(f"No replacements for {rel}")
            if len(edit.replacements) > MAX_REPLACEMENTS_PER_FILE:
                raise AutopilotError(f"Too many replacements for {rel}")

            if path not in originals:
                originals[path] = _read_exact(path)
                working[path] = originals[path]

            current = working[path]
            for replacement in edit.replacements:
                total_new_chars += len(replacement.new_text)
                if total_new_chars > MAX_TOTAL_NEW_CHARS:
                    raise AutopilotError("Replacement payload is too large")
                current = _apply_replacement(
                    current,
                    replacement.old_text,
                    replacement.new_text,
                )
            if not current.strip():
                raise AutopilotError(f"Edit would empty file: {rel}")
            working[path] = current

        for path, text in working.items():
            _write_exact(path, text)

        return AppliedChange(
            originals=originals,
            edited_paths=tuple(working.keys()),
        )
    except Exception:
        for path, original in originals.items():
            try:
                _write_exact(path, original)
            except Exception:
                pass
        raise


def _rollback(change: AppliedChange) -> None:
    for path, original in change.originals.items():
        _write_exact(path, original)


def _diff(change: AppliedChange) -> str:
    paths = [p.relative_to(ROOT).as_posix() for p in change.edited_paths]
    check = _git(["diff", "--check", "--", *paths], check=False)
    if check.returncode != 0:
        raise AutopilotError("git diff --check failed:\n" + check.stdout + check.stderr)

    cp = _git([
        "--no-pager", "diff", "--no-ext-diff", "--unified=60", "--", *paths
    ])
    text = cp.stdout.strip()
    if not text:
        raise AutopilotError("Proposal produced no git diff")
    if len(text) > MAX_DIFF_CHARS:
        text = text[:MAX_DIFF_CHARS] + "\n...[diff truncated]"
    return text


def _developer_instructions(project_context: str) -> str:
    return f"""
Jesteś głównym DEVELOPEREM Echoes of Pythonia.

Nie dostajesz statycznego REPO_BRIEF. Masz bezpieczne read-only narzędzie
`inspect_repo` i sam odpowiadasz za znalezienie właściwego kontekstu w repo.

Zasady pracy:
- Najpierw odkryj właściwe źródła w repo. Batchuj wiele wyszukiwań i odczytów
  w jednym wywołaniu narzędzia.
- Zwykle wystarczą: 1 wywołanie discovery + 1 wywołanie odczytu plików.
- Możesz wykonać dodatkowe wywołanie, jeśli naprawdę go potrzebujesz.
- MUSISZ jawnie przeczytać każdy plik, który chcesz edytować.
- Nie zgaduj ścieżek ani implementacji. Szukaj symboli, dokumentów i referencji.
- Jeśli brakuje kontekstu repo, użyj narzędzia ponownie zamiast zwracać BLOCKED.
- BLOCKED dopiero gdy wykorzystałeś dostępny budżet narzędzi albo źródło
  faktycznie nie istnieje.
- HUMAN_DECISION_REQUIRED tylko gdy potrzebna jest decyzja właściciela projektu.
- Preferuj najmniejszy bezpieczny diff, ale poprawiaj prawdziwe źródło problemu.
- Nie dodawaj ani nie usuwaj plików w tym trybie.
- Nie zmieniaj mechanik, save ID ani kanonu poza zakresem zadania.
- old_text musi być dokładnym, unikalnym fragmentem odczytanego pliku.
- Odpowiadaj po polsku.
- Finalny wynik ma być zgodny ze schematem ChangeProposal.

AI_CONTEXT (wybrane reguły kanoniczne):
{project_context}
""".strip()


def _reviewer_instructions(
    project_context: str,
    proposal: ChangeProposal,
    diff_text: str,
) -> str:
    return f"""
Jesteś niezależnym REVIEWEREM Echoes of Pythonia.

Masz read-only narzędzie `inspect_repo`. Oceniaj RZECZYWISTY diff, nie zamiary.
Możesz samodzielnie wyszukać i przeczytać pliki, jeśli potrzebujesz potwierdzenia.

Wymagania:
- sprawdź zgodność z zadaniem i AI_CONTEXT;
- sprawdź, czy Developer zmienił właściwe źródło prawdy;
- sprawdź zakres, oczywiste błędy i ryzyko regresji;
- zweryfikuj, czy dokumentacyjna polityka faktycznie dociera do istniejącego
  workflow, jeśli taki workflow jest częścią zadania;
- APPROVED tylko dla minimalnej i bezpiecznej zmiany;
- CHANGES_REQUESTED gdy diff wymaga korekty;
- HUMAN_DECISION_REQUIRED tylko gdy naprawdę potrzebna jest decyzja właściciela;
- odpowiadaj po polsku zgodnie ze schematem DiffReview.

AI_CONTEXT:
{project_context}

PROPOZYCJA:
{_json_text(proposal)}

RZECZYWISTY GIT DIFF:
{diff_text}
""".strip()


async def _developer_run(
    task: str,
    project_context: str,
    inspector: RepoInspector,
    ledger: UsageLedger,
    *,
    revision_feedback: str = "",
) -> ChangeProposal:
    from agents import Agent, RunConfig, Runner

    tool = build_repo_tool(inspector)
    agent = Agent(
        name="Echoes Repo Developer — Astra",
        model=DEVELOPER_MODEL,
        model_settings=_settings(DEVELOPER_REASONING),
        instructions=_developer_instructions(project_context),
        tools=[tool],
        output_type=ChangeProposal,
    )

    prompt = (
        f"TASK:\n{task}\n\n"
        "Samodzielnie zbadaj repo i wykonaj zadanie. "
        "Nie kończ na braku statycznego kontekstu — używaj inspect_repo."
    )
    if revision_feedback:
        prompt += (
            "\n\nPOPRZEDNI REVIEWER POPROSIŁ O POPRAWKI:\n"
            + revision_feedback
            + "\nPrzeanalizuj repo ponownie i zaproponuj poprawiony diff."
        )

    result = await Runner.run(
        agent,
        prompt,
        max_turns=DEVELOPER_MAX_TURNS,
        run_config=RunConfig(
            tracing_disabled=True,
            workflow_name="Echoes Autopilot - repo-aware developer",
        ),
    )
    ledger.add_result(DEVELOPER_MODEL, result)
    return result.final_output


async def _review_run(
    task: str,
    project_context: str,
    proposal: ChangeProposal,
    diff_text: str,
    ledger: UsageLedger,
) -> DiffReview:
    from agents import Agent, RunConfig, Runner

    inspector = RepoInspector(max_calls=2)
    tool = build_repo_tool(inspector)
    agent = Agent(
        name="Echoes Independent Reviewer — Sol",
        model=REVIEWER_MODEL,
        model_settings=_settings(REVIEWER_REASONING),
        instructions=_reviewer_instructions(project_context, proposal, diff_text),
        tools=[tool],
        output_type=DiffReview,
    )

    result = await Runner.run(
        agent,
        f"TASK:\n{task}\n\nZrecenzuj rzeczywisty diff.",
        max_turns=REVIEWER_MAX_TURNS,
        run_config=RunConfig(
            tracing_disabled=True,
            workflow_name="Echoes Autopilot - independent reviewer",
        ),
    )
    ledger.add_result(REVIEWER_MODEL, result)
    return result.final_output


def _powershell() -> str:
    shell = shutil.which("pwsh") or shutil.which("powershell") or shutil.which("powershell.exe")
    if not shell:
        raise AutopilotError("PowerShell not found")
    return shell


def _run_full_check(run_dir: Path) -> Path:
    script = ROOT / "scripts" / "check.ps1"
    if not script.exists():
        raise AutopilotError("scripts/check.ps1 is missing")

    cp = _run(
        [
            _powershell(),
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(script),
        ],
        check=False,
        timeout=1800,
    )
    log = run_dir / "full-check.log"
    log.write_text(
        cp.stdout + ("\n" if cp.stdout and cp.stderr else "") + cp.stderr,
        encoding="utf-8",
    )
    if cp.returncode != 0:
        raise AutopilotError(
            f"Canonical check.ps1 failed. Log: {log}\n\n"
            + (cp.stdout + "\n" + cp.stderr)[-7000:]
        )
    return log


def _requires_visual(paths: tuple[Path, ...]) -> bool:
    for path in paths:
        rel = path.relative_to(ROOT).as_posix().casefold()
        if rel.startswith("godot/ui/"):
            return True
        if path.suffix.casefold() in {".gdshader", ".gdshaderinc", ".tscn"}:
            return True
    return False


def _commit_message(task: str, paths: tuple[Path, ...]) -> str:
    rels = [p.relative_to(ROOT).as_posix() for p in paths]
    if all(r.startswith(("AI_CONTEXT/", "tools/", "scripts/")) for r in rels):
        prefix = "chore(ai): "
    elif any(word in task.casefold() for word in ("napraw", "fix", "bug", "błąd")):
        prefix = "fix: "
    else:
        prefix = "feat: "

    subject = re.sub(r"\s+", " ", task.strip()).rstrip(".")
    if len(subject) > 62:
        subject = subject[:59].rstrip() + "..."
    return prefix + subject


def _commit(paths: tuple[Path, ...], message: str) -> str:
    rels = [p.relative_to(ROOT).as_posix() for p in paths]
    _git(["add", "--", *rels])
    check = _git(["diff", "--cached", "--check", "--", *rels], check=False)
    if check.returncode != 0:
        _git(["restore", "--staged", "--", *rels], check=False)
        raise AutopilotError("staged diff check failed:\n" + check.stdout + check.stderr)
    _git(["commit", "-m", message])
    return _head()


def _gh() -> str:
    gh = shutil.which("gh") or shutil.which("gh.exe")
    if not gh:
        raise AutopilotError("GitHub CLI (gh) not found")
    cp = _run([gh, "auth", "status"], check=False)
    if cp.returncode != 0:
        raise AutopilotError("GitHub CLI is not authenticated")
    return gh


def _push_and_pr(
    task: str,
    branch: str,
    commit_sha: str,
    run_dir: Path,
) -> str:
    _git(["push", "-u", REMOTE, branch], timeout=600)

    gh = _gh()
    title = re.sub(r"\s+", " ", task.strip())
    if len(title) > 100:
        title = title[:97].rstrip() + "..."

    body = run_dir / "pr-body.md"
    body.write_text(
        f"""## Task

{task}

## Automated validation

- Astra repo-aware Developer: completed
- Sol independent Reviewer: APPROVED
- Canonical `scripts/check.ps1`: PASS
- Commit: `{commit_sha}`
- Force push: not used
- Automatic merge: not performed
""",
        encoding="utf-8",
    )

    cp = _run(
        [
            gh, "pr", "create",
            "--base", BASE_BRANCH,
            "--head", branch,
            "--title", title,
            "--body-file", str(body),
        ],
        check=False,
        timeout=180,
    )
    if cp.returncode != 0:
        raise AutopilotError(
            "Branch was pushed, but PR creation failed:\n"
            + cp.stdout + "\n" + cp.stderr
        )
    return cp.stdout.strip().splitlines()[-1].strip()


def _print_usage(ledger: UsageLedger) -> None:
    t = ledger.totals()
    print("\n=== MODEL USAGE ===")
    print(f"Requests:          {t['requests']}")
    print(f"Input tokens:      {t['input_tokens']:,}")
    print(f"Cached input:      {t['cached_tokens']:,}")
    print(f"Cache writes:      {t['cache_write_tokens']:,}")
    print(f"Output tokens:     {t['output_tokens']:,}")
    print(f"Reasoning tokens:  {t['reasoning_tokens']:,}")


async def run_task(task: str, *, publish: bool) -> int:
    if not task.strip():
        raise AutopilotError("Task is empty")
    if not os.getenv("OPENAI_API_KEY", "").strip():
        raise AutopilotError("OPENAI_API_KEY is missing from local .env")

    task_branch, base_head = _start_task_branch(task)
    run_dir = _run_dir()
    (run_dir / "task.txt").write_text(task + "\n", encoding="utf-8")
    _write_json(
        run_dir / "run.json",
        {
            "task": task,
            "branch": task_branch,
            "base_branch": BASE_BRANCH,
            "base_head": base_head,
            "started_at": datetime.now().isoformat(timespec="seconds"),
        },
    )

    print("\n=== ECHOES AUTOPILOT ===")
    print(f"Task branch: {task_branch}")
    print(f"Developer:   {DEVELOPER_MODEL}")
    print(f"Reviewer:    {REVIEWER_MODEL}")
    print("Repo routing: dynamic read-only tools (no static file router)")
    print(f"Logs:        {run_dir}")

    pack = load_project_context(task)
    ledger = UsageLedger()
    revision_feedback = ""

    for cycle in range(1, MAX_REVIEW_CYCLES + 1):
        inspector = RepoInspector()

        print(f"\n=== CYCLE {cycle}/{MAX_REVIEW_CYCLES} — DEVELOPER ===")
        proposal = await _developer_run(
            task,
            pack.text,
            inspector,
            ledger,
            revision_feedback=revision_feedback,
        )
        _write_json(run_dir / f"developer-cycle-{cycle}.json", proposal)
        print(_json_text(proposal))

        if proposal.status == "BLOCKED":
            raise AutopilotError(
                "Developer exhausted repository inspection and is still BLOCKED:\n"
                + proposal.summary
            )
        if proposal.status == "HUMAN_DECISION_REQUIRED":
            print("\nHUMAN_DECISION_REQUIRED")
            print(proposal.human_question or proposal.summary)
            _print_usage(ledger)
            return 4

        change = _apply_proposal(proposal, inspector.read_paths)
        diff_text = _diff(change)
        (run_dir / f"diff-cycle-{cycle}.patch").write_text(
            diff_text + "\n",
            encoding="utf-8",
        )

        print("\n=== REVIEWER ===")
        review = await _review_run(task, pack.text, proposal, diff_text, ledger)
        _write_json(run_dir / f"review-cycle-{cycle}.json", review)
        print(_json_text(review))

        if review.verdict == "APPROVED":
            if _requires_visual(change.edited_paths):
                _rollback(change)
                print("\nAUTOPILOT SAFETY STOP: VISUAL_GATE_REQUIRED")
                print(
                    "Reviewer approved the code diff, but the changed files are visual/UI. "
                    "Generic visual scenario automation is not installed yet, so the diff "
                    "was rolled back rather than committed without screenshots."
                )
                _print_usage(ledger)
                return 7

            print("\nRunning canonical check.ps1...")
            try:
                check_log = _run_full_check(run_dir)
            except Exception:
                _rollback(change)
                raise

            message = _commit_message(task, change.edited_paths)
            commit_sha = _commit(change.edited_paths, message)

            pr_url = ""
            if publish:
                pr_url = _push_and_pr(task, task_branch, commit_sha, run_dir)

            receipt = {
                "task": task,
                "branch": task_branch,
                "base_branch": BASE_BRANCH,
                "commit_sha": commit_sha,
                "check_log": str(check_log),
                "pull_request_url": pr_url,
                "finished_at": datetime.now().isoformat(timespec="seconds"),
            }
            _write_json(run_dir / "receipt.json", receipt)

            print("\n====================================")
            print("ECHOES AUTOPILOT: PASS ✅")
            print(f"Commit: {commit_sha}")
            print(f"Check:  PASS ✅")
            print(f"Push:   {'PASS ✅' if publish else 'NOT REQUESTED'}")
            if pr_url:
                print(f"PR:     {pr_url}")
            print("Merge:  NOT PERFORMED")
            _print_usage(ledger)
            return 0

        _rollback(change)

        if review.verdict == "HUMAN_DECISION_REQUIRED":
            print("\nHUMAN_DECISION_REQUIRED")
            print(review.human_question or review.summary)
            _print_usage(ledger)
            return 4

        revision_feedback = _json_text(review)
        print("\nReviewer requested changes. Diff rolled back; Developer will retry automatically.")

    raise AutopilotError("Maximum autonomous review cycles exhausted")


def doctor() -> int:
    print("\n=== ECHOES AUTOPILOT DOCTOR ===")
    branch = _branch()
    print(f"Branch: {branch}")
    print(f"Clean:  {'YES' if not _status() else 'NO'}")
    print(f"Base:   {BASE_BRANCH}")
    print(f"gh:     {'FOUND' if (shutil.which('gh') or shutil.which('gh.exe')) else 'MISSING'}")
    print(f"OpenAI key: {'SET' if os.getenv('OPENAI_API_KEY', '').strip() else 'MISSING'}")
    print("Developer repo tools: dynamic/batched read-only")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Echoes of Pythonia autonomous repo-aware task runner.")
    parser.add_argument("task", nargs="?", default="")
    parser.add_argument("--no-publish", action="store_true")
    parser.add_argument("--doctor", action="store_true")
    return parser.parse_args()


async def async_main() -> int:
    args = parse_args()
    if args.doctor:
        return doctor()
    if not args.task:
        print('Użyj: python tools\\echoes_ai_team\\autopilot.py "opis zadania"')
        return 1
    return await run_task(args.task, publish=not args.no_publish)


def main() -> None:
    try:
        code = asyncio.run(async_main())
    except (AutopilotError, FileNotFoundError, RuntimeError) as exc:
        print(f"\nAUTOPILOT SAFETY STOP ❌\n{exc}")
        code = 2
    except KeyboardInterrupt:
        print("\nPrzerwano. Autopilot nigdy nie wykonuje automatycznego merge.")
        code = 130
    raise SystemExit(code)


if __name__ == "__main__":
    main()
