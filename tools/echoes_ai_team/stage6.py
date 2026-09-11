from __future__ import annotations

import argparse
import json
import os
import re
import shutil
import subprocess
import sys
import unicodedata
from dataclasses import asdict, dataclass
from datetime import datetime
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parents[2]
OUTPUT_ROOT = ROOT / "output" / "ai-team"
STAGE6_ROOT = OUTPUT_ROOT / "STAGE6"
TASK_STATE_PATH = STAGE6_ROOT / "task_state.json"

BASE_BRANCH = os.getenv("EOP_STAGE6_BASE_BRANCH", "ai/echoes-team")
REMOTE = os.getenv("EOP_STAGE6_REMOTE", "origin")

PROTECTED_BRANCHES = {
    "main",
    "master",
    "snapshot/pre-ai-team-2026-09-10",
}

TASK_BRANCH_RE = re.compile(r"^ai/task/(?P<task_id>EOP-[A-Za-z0-9._-]+)-(?P<slug>[a-z0-9][a-z0-9-]*)$")


class Stage6Error(RuntimeError):
    pass


@dataclass(frozen=True)
class TaskState:
    task_id: str
    task: str
    slug: str
    branch: str
    base_branch: str
    base_head: str
    created_at: str


@dataclass(frozen=True)
class CommitEvidence:
    receipt_path: str
    commit_sha: str
    release_gate_status: str


@dataclass(frozen=True)
class FinishReceipt:
    task_id: str
    task: str
    branch: str
    base_branch: str
    head: str
    stage5_receipt: str
    full_check: str
    push: str
    pull_request_url: str
    finished_at: str


def _run(
    command: list[str],
    *,
    cwd: Path = ROOT,
    check: bool = True,
    timeout: int = 180,
) -> subprocess.CompletedProcess[str]:
    cp = subprocess.run(
        command,
        cwd=cwd,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=timeout,
        check=False,
    )
    if check and cp.returncode != 0:
        raise Stage6Error(
            "$ " + " ".join(command) + "\n\n"
            + cp.stdout
            + ("\n" if cp.stdout and cp.stderr else "")
            + cp.stderr
        )
    return cp


def _git(args: Iterable[str], *, check: bool = True, timeout: int = 180) -> subprocess.CompletedProcess[str]:
    return _run(["git", *args], check=check, timeout=timeout)


def _git_text(args: Iterable[str]) -> str:
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
        raise Stage6Error(
            "Working tree is not clean. Commit or restore these changes first:\n"
            + status
        )


def _ensure_safe_branch(branch: str) -> None:
    if branch in PROTECTED_BRANCHES or branch.startswith("release/"):
        raise Stage6Error(f"Protected branch is active: {branch}")


def _fetch() -> None:
    _git(["fetch", REMOTE, "--prune"], timeout=300)


def _remote_ref(branch: str) -> str:
    return f"{REMOTE}/{branch}"


def _remote_branch_exists(branch: str) -> bool:
    cp = _git(["show-ref", "--verify", "--quiet", f"refs/remotes/{REMOTE}/{branch}"], check=False)
    return cp.returncode == 0


def _local_branch_exists(branch: str) -> bool:
    cp = _git(["show-ref", "--verify", "--quiet", f"refs/heads/{branch}"], check=False)
    return cp.returncode == 0


def _divergence(left: str, right: str) -> tuple[int, int]:
    raw = _git_text(["rev-list", "--left-right", "--count", f"{left}...{right}"])
    parts = raw.replace("\t", " ").split()
    if len(parts) != 2:
        raise Stage6Error(f"Could not parse git divergence: {raw!r}")
    return int(parts[0]), int(parts[1])


def _powershell() -> str | None:
    return (
        shutil.which("pwsh")
        or shutil.which("powershell")
        or shutil.which("powershell.exe")
    )


def _venv_python() -> Path:
    if os.name == "nt":
        return ROOT / ".venv" / "Scripts" / "python.exe"
    return ROOT / ".venv" / "bin" / "python"


def _check_import(module: str) -> tuple[bool, str]:
    python = _venv_python()
    if not python.exists():
        return False, f"missing {python}"
    cp = _run(
        [str(python), "-c", f"import {module}; print(getattr({module}, '__version__', 'OK'))"],
        check=False,
    )
    if cp.returncode == 0:
        return True, cp.stdout.strip() or "OK"
    return False, (cp.stderr.strip() or cp.stdout.strip() or "import failed")


def _gh() -> str | None:
    return shutil.which("gh") or shutil.which("gh.exe")


def _gh_auth_ok() -> tuple[bool, str]:
    gh = _gh()
    if not gh:
        return False, "GitHub CLI (gh) not found"
    cp = _run([gh, "auth", "status"], check=False)
    output = (cp.stdout + "\n" + cp.stderr).strip()
    return cp.returncode == 0, output


def _slugify(text: str, max_len: int = 42) -> str:
    normalized = unicodedata.normalize("NFKD", text)
    ascii_text = normalized.encode("ascii", "ignore").decode("ascii")
    slug = re.sub(r"[^a-zA-Z0-9]+", "-", ascii_text).strip("-").lower()
    slug = re.sub(r"-+", "-", slug)
    if not slug:
        slug = "task"
    return slug[:max_len].rstrip("-")


def _new_task_id() -> str:
    return "EOP-" + datetime.now().strftime("%Y%m%d-%H%M%S")


def _save_task_state(state: TaskState) -> None:
    STAGE6_ROOT.mkdir(parents=True, exist_ok=True)
    TASK_STATE_PATH.write_text(
        json.dumps(asdict(state), ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def _load_task_state(required: bool = True) -> TaskState | None:
    if not TASK_STATE_PATH.exists():
        if required:
            raise Stage6Error(f"Task state not found: {TASK_STATE_PATH}")
        return None
    data = json.loads(TASK_STATE_PATH.read_text(encoding="utf-8"))
    return TaskState(**data)


def _find_stage5_receipt(head: str) -> CommitEvidence:
    candidates = sorted(
        OUTPUT_ROOT.glob("COMMIT-*/commit_receipt.json"),
        key=lambda p: p.stat().st_mtime,
        reverse=True,
    )
    for path in candidates:
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            continue
        if data.get("commit_sha") != head:
            continue
        return CommitEvidence(
            receipt_path=str(path),
            commit_sha=str(data.get("commit_sha", "")),
            release_gate_status=str(data.get("release_gate_status", "")),
        )
    raise Stage6Error(
        "No Stage 5 commit receipt matches current HEAD. "
        "Finish the task through Stage 5 before publishing it."
    )


def _run_full_check() -> Path:
    check_script = ROOT / "scripts" / "check.ps1"
    if not check_script.exists():
        raise Stage6Error(f"Missing canonical validation script: {check_script}")

    shell = _powershell()
    if not shell:
        raise Stage6Error("PowerShell was not found.")

    stamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    log_path = STAGE6_ROOT / f"full-check-{stamp}.log"
    STAGE6_ROOT.mkdir(parents=True, exist_ok=True)

    cp = _run(
        [
            shell,
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(check_script),
        ],
        check=False,
        timeout=1800,
    )
    log_path.write_text(
        cp.stdout + ("\n" if cp.stdout and cp.stderr else "") + cp.stderr,
        encoding="utf-8",
    )
    if cp.returncode != 0:
        raise Stage6Error(
            "Canonical check.ps1 failed. Nothing was pushed.\n"
            f"Log: {log_path}\n\n"
            + (cp.stdout + "\n" + cp.stderr)[-7000:]
        )

    _ensure_clean()
    return log_path


def doctor() -> int:
    print("\n=== ECHOES AI TEAM — STAGE 6 DOCTOR ===")
    print("OpenAI API calls: 0")

    failures: list[str] = []
    warnings: list[str] = []

    try:
        branch = _branch()
        head = _head()
        print(f"Branch: {branch}")
        print(f"HEAD:   {head}")
        _ensure_safe_branch(branch)
    except Exception as exc:
        failures.append(f"git branch/HEAD: {exc}")
        branch = ""
        head = ""

    status = _status()
    if status:
        failures.append("working tree is not clean")
        print("\nWorking tree:")
        print(status)
    else:
        print("Working tree: CLEAN ✅")

    try:
        remote_url = _git_text(["remote", "get-url", REMOTE])
        print(f"Remote {REMOTE}: {remote_url}")
    except Exception as exc:
        failures.append(f"remote {REMOTE}: {exc}")

    try:
        _fetch()
        if not _remote_branch_exists(BASE_BRANCH):
            failures.append(f"remote base branch missing: {_remote_ref(BASE_BRANCH)}")
        else:
            print(f"Remote base: {_remote_ref(BASE_BRANCH)} ✅")
            if branch == BASE_BRANCH:
                behind, ahead = _divergence(_remote_ref(BASE_BRANCH), BASE_BRANCH)
                print(f"Base divergence: behind={behind}, ahead={ahead}")
                if behind:
                    failures.append("local base is behind origin; update it before Stage 6")
                if ahead:
                    warnings.append(
                        "local base has unpushed commits; run --publish-base after doctor"
                    )
    except Exception as exc:
        failures.append(f"git fetch/base check: {exc}")

    for module in ("pytest", "numpy"):
        ok, detail = _check_import(module)
        print(f"{module}: {'OK ✅' if ok else 'MISSING ❌'} {detail}")
        if not ok:
            failures.append(f"Python dependency missing: {module}")

    godot_console = ROOT / ".tools" / "godot" / "Godot_v4.7.1-stable_win64_console.exe"
    if godot_console.exists():
        print(f"Godot 4.7.1 console: OK ✅")
    else:
        failures.append(f"Godot console missing: {godot_console}")

    gh_ok, gh_detail = _gh_auth_ok()
    if gh_ok:
        print("GitHub CLI auth: OK ✅")
    else:
        failures.append("GitHub CLI/auth is not ready")
        print("GitHub CLI auth: NOT READY ❌")
        if gh_detail:
            print(gh_detail)

    if warnings:
        print("\nWarnings:")
        for item in warnings:
            print(f" - {item}")

    if failures:
        print("\nSTAGE 6 DOCTOR: FAIL ❌")
        for item in failures:
            print(f" - {item}")
        return 2

    print("\nSTAGE 6 DOCTOR: PASS ✅")
    return 0


def publish_base() -> int:
    branch = _branch()
    _ensure_safe_branch(branch)
    if branch != BASE_BRANCH:
        raise Stage6Error(
            f"--publish-base must run on {BASE_BRANCH}, current branch is {branch}"
        )
    _ensure_clean()
    _fetch()

    if not _remote_branch_exists(BASE_BRANCH):
        raise Stage6Error(f"Remote base branch does not exist: {_remote_ref(BASE_BRANCH)}")

    behind, ahead = _divergence(_remote_ref(BASE_BRANCH), BASE_BRANCH)
    if behind:
        raise Stage6Error(
            f"Local base is behind origin by {behind} commit(s). "
            "Stage 6 will not auto-merge or auto-rebase."
        )

    print("\n=== STAGE 6 — PUBLISH BASE ===")
    print(f"Branch: {BASE_BRANCH}")
    print(f"Ahead:  {ahead}")
    print("OpenAI API calls: 0")

    print("\nRunning canonical check.ps1 before any push...")
    log = _run_full_check()
    print(f"check.ps1: PASS ✅ ({log})")

    if ahead == 0:
        print("Base is already synchronized with origin. Nothing to push.")
        return 0

    _git(["push", REMOTE, f"{BASE_BRANCH}:{BASE_BRANCH}"], timeout=600)
    _fetch()
    behind2, ahead2 = _divergence(_remote_ref(BASE_BRANCH), BASE_BRANCH)
    if behind2 != 0 or ahead2 != 0:
        raise Stage6Error(
            f"Post-push base divergence is not zero: behind={behind2}, ahead={ahead2}"
        )

    print("BASE PUBLISH: PASS ✅")
    print(f"{BASE_BRANCH} is synchronized with {REMOTE}.")
    return 0


def start_task(task: str, task_id: str | None, slug: str | None) -> int:
    if not task.strip():
        raise Stage6Error("--task must not be empty")

    branch = _branch()
    _ensure_safe_branch(branch)
    if branch != BASE_BRANCH:
        raise Stage6Error(
            f"Start tasks only from {BASE_BRANCH}. Current branch: {branch}"
        )
    _ensure_clean()
    _fetch()

    if not _remote_branch_exists(BASE_BRANCH):
        raise Stage6Error(f"Remote base branch missing: {_remote_ref(BASE_BRANCH)}")

    behind, ahead = _divergence(_remote_ref(BASE_BRANCH), BASE_BRANCH)
    if behind or ahead:
        raise Stage6Error(
            f"Base must be exactly synchronized before starting a task. "
            f"behind={behind}, ahead={ahead}. Run --publish-base when appropriate."
        )

    task_id = (task_id or _new_task_id()).strip()
    if not re.fullmatch(r"EOP-[A-Za-z0-9._-]+", task_id):
        raise Stage6Error(
            "Task id must match EOP-..., e.g. EOP-101 or EOP-20260911-190500"
        )

    slug = _slugify(slug or task)
    task_branch = f"ai/task/{task_id}-{slug}"

    if _local_branch_exists(task_branch):
        raise Stage6Error(f"Local branch already exists: {task_branch}")
    if _remote_branch_exists(task_branch):
        raise Stage6Error(f"Remote branch already exists: {task_branch}")

    base_head = _head()
    _git(["switch", "-c", task_branch])

    state = TaskState(
        task_id=task_id,
        task=task.strip(),
        slug=slug,
        branch=task_branch,
        base_branch=BASE_BRANCH,
        base_head=base_head,
        created_at=datetime.now().isoformat(timespec="seconds"),
    )
    _save_task_state(state)

    print("\n=== STAGE 6 — TASK STARTED ===")
    print(f"Task ID: {task_id}")
    print(f"Branch:  {task_branch}")
    print(f"Base:    {BASE_BRANCH}@{base_head}")
    print(f"Task:    {task.strip()}")
    print("Push:    NOT PERFORMED")
    print("OpenAI API calls: 0")
    print(f"State:   {TASK_STATE_PATH}")
    return 0


def _task_branch_info() -> tuple[str, re.Match[str]]:
    branch = _branch()
    match = TASK_BRANCH_RE.fullmatch(branch)
    if not match:
        raise Stage6Error(
            "Current branch is not a Stage 6 task branch. "
            "Expected ai/task/EOP-...-slug"
        )
    return branch, match


def preview_finish() -> int:
    branch, match = _task_branch_info()
    _ensure_clean()
    _fetch()

    state = _load_task_state(required=False)
    head = _head()

    behind, ahead = _divergence(_remote_ref(BASE_BRANCH), "HEAD")
    evidence = _find_stage5_receipt(head)
    gh_ok, _ = _gh_auth_ok()

    print("\n=== STAGE 6 — FINISH PREVIEW ===")
    print(f"Branch:          {branch}")
    print(f"Task ID:         {match.group('task_id')}")
    print(f"HEAD:            {head}")
    print(f"vs origin/base:  behind={behind}, ahead={ahead}")
    print(f"Stage 5 receipt: {evidence.receipt_path}")
    print(f"Release gate:    {evidence.release_gate_status}")
    print(f"GitHub CLI auth: {'READY ✅' if gh_ok else 'NOT READY ❌'}")
    if state:
        print(f"Task:            {state.task}")
    print("OpenAI API calls: 0")

    blocked = False
    if behind:
        print("\nBLOCKED: base advanced after this task started.")
        blocked = True
    if ahead < 1:
        print("\nBLOCKED: task branch has no commits beyond origin/base.")
        blocked = True
    if evidence.release_gate_status != "CLEAR":
        print("\nBLOCKED: Stage 5 release gate is not CLEAR.")
        blocked = True
    if not gh_ok:
        print("\nBLOCKED: GitHub CLI is not authenticated.")
        blocked = True

    if blocked:
        return 3

    print("\nREADY FOR --finish-task ✅")
    print("The final command will rerun full check.ps1, push the task branch,")
    print("and create/reuse a PR into ai/echoes-team. It will NOT merge the PR.")
    return 0


def _existing_pr_url(gh: str, branch: str) -> str | None:
    cp = _run(
        [gh, "pr", "view", branch, "--json", "url", "--jq", ".url"],
        check=False,
        timeout=120,
    )
    if cp.returncode == 0:
        url = cp.stdout.strip()
        return url or None
    return None


def finish_task(title: str | None) -> int:
    branch, match = _task_branch_info()
    _ensure_clean()
    _fetch()

    head = _head()
    state = _load_task_state(required=False)
    evidence = _find_stage5_receipt(head)

    if evidence.release_gate_status != "CLEAR":
        raise Stage6Error(
            f"Stage 5 release gate must be CLEAR, got: {evidence.release_gate_status}"
        )

    behind, ahead = _divergence(_remote_ref(BASE_BRANCH), "HEAD")
    if behind:
        raise Stage6Error(
            f"Task branch is behind origin/{BASE_BRANCH} by {behind} commit(s). "
            "Stage 6 will not auto-rebase."
        )
    if ahead < 1:
        raise Stage6Error("Task branch has no commits to publish.")

    gh = _gh()
    if not gh:
        raise Stage6Error("GitHub CLI (gh) is not installed.")
    gh_ok, gh_detail = _gh_auth_ok()
    if not gh_ok:
        raise Stage6Error("GitHub CLI is not authenticated:\n" + gh_detail)

    print("\n=== STAGE 6 — FINISH TASK ===")
    print(f"Branch:   {branch}")
    print(f"HEAD:     {head}")
    print(f"Base:     {BASE_BRANCH}")
    print("OpenAI API calls: 0")

    print("\n[1/4] Running canonical check.ps1...")
    check_log = _run_full_check()
    print("Canonical validation: PASS ✅")

    print("\n[2/4] Pushing task branch (no force)...")
    _git(["push", "-u", REMOTE, branch], timeout=600)
    print("Push: PASS ✅")

    print("\n[3/4] Creating or reusing GitHub PR...")
    pr_url = _existing_pr_url(gh, branch)

    task_text = state.task if state else match.group("slug").replace("-", " ")
    pr_title = (title or task_text).strip()
    if len(pr_title) > 100:
        pr_title = pr_title[:97].rstrip() + "..."

    if not pr_url:
        STAGE6_ROOT.mkdir(parents=True, exist_ok=True)
        body_path = STAGE6_ROOT / f"pr-body-{match.group('task_id')}.md"
        body = (
            f"## Task\n\n{task_text}\n\n"
            f"## Validation\n\n"
            f"- Stage 5 controlled commit: `{head}`\n"
            f"- Stage 5 release gate: `CLEAR`\n"
            f"- Canonical `scripts/check.ps1`: PASS\n"
            f"- Base branch: `{BASE_BRANCH}`\n\n"
            "## Automation safety\n\n"
            "- No force push\n"
            "- No automatic merge\n"
            "- PR created only after clean working tree and full validation\n"
        )
        body_path.write_text(body, encoding="utf-8")

        cp = _run(
            [
                gh,
                "pr",
                "create",
                "--base",
                BASE_BRANCH,
                "--head",
                branch,
                "--title",
                pr_title,
                "--body-file",
                str(body_path),
            ],
            check=False,
            timeout=180,
        )
        if cp.returncode != 0:
            raise Stage6Error(
                "Branch was pushed, but PR creation failed. "
                "No merge was attempted.\n\n"
                + cp.stdout
                + "\n"
                + cp.stderr
            )
        pr_url = cp.stdout.strip().splitlines()[-1].strip()

    print(f"PR: {pr_url}")

    print("\n[4/4] Writing Stage 6 receipt...")
    task_id = match.group("task_id")
    receipt = FinishReceipt(
        task_id=task_id,
        task=task_text,
        branch=branch,
        base_branch=BASE_BRANCH,
        head=head,
        stage5_receipt=evidence.receipt_path,
        full_check=str(check_log),
        push="PASS",
        pull_request_url=pr_url,
        finished_at=datetime.now().isoformat(timespec="seconds"),
    )
    receipt_path = STAGE6_ROOT / f"finish-{task_id}-{datetime.now():%Y%m%d-%H%M%S}.json"
    receipt_path.write_text(
        json.dumps(asdict(receipt), ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print("\n====================================")
    print("STAGE 6 TASK PUBLISH: PASS ✅")
    print(f"PR:           {pr_url}")
    print("Auto-merge:   NOT PERFORMED")
    print("Force push:   NOT PERFORMED")
    print("OpenAI calls: 0")
    print(f"Receipt:      {receipt_path}")
    return 0


def status_cmd() -> int:
    branch = _branch()
    print("\n=== STAGE 6 STATUS ===")
    print(f"Branch: {branch}")
    print(f"HEAD:   {_head()}")
    print(f"Clean:  {'YES' if not _status() else 'NO'}")
    state = _load_task_state(required=False)
    if state:
        print(f"Task:   {state.task_id} — {state.task}")
        print(f"Task branch: {state.branch}")
    else:
        print("Task:   none")
    print("OpenAI API calls: 0")
    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Echoes of Pythonia — Stage 6 task branches, push and PR gate."
    )

    action = parser.add_mutually_exclusive_group(required=True)
    action.add_argument("--doctor", action="store_true")
    action.add_argument("--publish-base", action="store_true")
    action.add_argument("--start-task", action="store_true")
    action.add_argument("--preview-finish", action="store_true")
    action.add_argument("--finish-task", action="store_true")
    action.add_argument("--status", action="store_true")

    parser.add_argument("--task", type=str, default="")
    parser.add_argument("--task-id", type=str, default=None)
    parser.add_argument("--slug", type=str, default=None)
    parser.add_argument("--title", type=str, default=None)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    try:
        if args.doctor:
            code = doctor()
        elif args.publish_base:
            code = publish_base()
        elif args.start_task:
            code = start_task(args.task, args.task_id, args.slug)
        elif args.preview_finish:
            code = preview_finish()
        elif args.finish_task:
            code = finish_task(args.title)
        elif args.status:
            code = status_cmd()
        else:
            code = 1
    except Stage6Error as exc:
        print(f"\nSTAGE 6 SAFETY STOP ❌\n{exc}")
        code = 2
    except KeyboardInterrupt:
        print("\nStage 6 interrupted. No automatic merge is ever performed.")
        code = 130

    raise SystemExit(code)


if __name__ == "__main__":
    main()
