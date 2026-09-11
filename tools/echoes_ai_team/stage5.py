from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
from dataclasses import asdict, dataclass
from datetime import datetime
from pathlib import Path

from config import REPO_ROOT
from targeted_validation import run_targeted_validation
from validation_runner import inspect_current_diff


ROOT = REPO_ROOT.resolve()
OUTPUT_ROOT = ROOT / "output" / "ai-team"

PROTECTED_BRANCHES = {
    "main",
    "master",
    "snapshot/pre-ai-team-2026-09-10",
}

ALLOWED_SUFFIXES = {
    ".gd",
    ".gdshader",
    ".gdshaderinc",
    ".tscn",
    ".tres",
}

MAX_CHANGED_FILES = 3


class CommitGateError(RuntimeError):
    pass


@dataclass(frozen=True)
class ValidationEvidence:
    directory: str
    classification: str
    diff_match: bool


@dataclass(frozen=True)
class VisualEvidence:
    directory: str
    verdict: str
    diff_match: bool
    current_file_sha_match: bool


@dataclass(frozen=True)
class CommitReceipt:
    timestamp: str
    branch: str
    parent_head: str
    commit_sha: str
    commit_message: str
    changed_paths: list[str]
    validation_evidence: ValidationEvidence
    visual_evidence: VisualEvidence | None
    release_gate_status: str


def _run_git(args: list[str], *, check: bool = True) -> subprocess.CompletedProcess[str]:
    result = subprocess.run(
        ["git", *args],
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=120,
        check=False,
    )
    if check and result.returncode != 0:
        raise CommitGateError(
            f"git {' '.join(args)} failed:\n{result.stdout}\n{result.stderr}"
        )
    return result


def _git_text(args: list[str]) -> str:
    return _run_git(args).stdout.strip()


def _sha256_file(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while True:
            chunk = handle.read(1024 * 1024)
            if not chunk:
                break
            digest.update(chunk)
    return digest.hexdigest()


def _current_diff_text(changed_paths: tuple[str, ...]) -> str:
    result = _run_git(
        [
            "--no-pager",
            "diff",
            "--no-ext-diff",
            "--unified=50",
            "--",
            *changed_paths,
        ]
    )
    text = result.stdout.strip()
    if not text:
        raise CommitGateError("Current working-tree diff is empty.")
    return text


def _normalize_patch(text: str) -> str:
    # Normalize only line endings/trailing final newline.
    return text.replace("\r\n", "\n").rstrip() + "\n"


def _preflight() -> tuple[str, str, tuple[str, ...], str]:
    working = inspect_current_diff()
    branch = working.branch
    head = working.head
    changed_paths = working.changed_paths

    if branch in PROTECTED_BRANCHES or branch.startswith("release/"):
        raise CommitGateError(f"Protected branch is active: {branch}")

    if not branch.startswith("ai/"):
        raise CommitGateError(
            f"Stage 5 commits only on ai/* branches. Current branch: {branch}"
        )

    if len(changed_paths) == 0:
        raise CommitGateError("No current change to commit.")

    if len(changed_paths) > MAX_CHANGED_FILES:
        raise CommitGateError(
            f"Too many changed files: {len(changed_paths)} > {MAX_CHANGED_FILES}"
        )

    for relative in changed_paths:
        path = ROOT / relative
        if not relative.startswith("godot/"):
            raise CommitGateError(f"Non-Godot change is not allowed: {relative}")
        if path.suffix.casefold() not in ALLOWED_SUFFIXES:
            raise CommitGateError(f"Unexpected file type: {relative}")
        if not path.exists() or not path.is_file():
            raise CommitGateError(f"Changed path is missing/not a file: {relative}")

    staged = _git_text(["diff", "--cached", "--name-only"])
    if staged:
        raise CommitGateError(
            "Stage 5 refuses to start with staged files:\n" + staged
        )

    untracked = _git_text(["ls-files", "--others", "--exclude-standard"])
    if untracked:
        raise CommitGateError(
            "Stage 5 refuses to start with untracked files:\n" + untracked[:5000]
        )

    diff_text = _current_diff_text(changed_paths)

    diff_check = _run_git(["diff", "--check", "--", *changed_paths], check=False)
    if diff_check.returncode != 0:
        raise CommitGateError(
            "git diff --check failed:\n" + diff_check.stdout + diff_check.stderr
        )

    return branch, head, changed_paths, diff_text


def _find_matching_validation_evidence(
    current_diff: str,
) -> ValidationEvidence:
    wanted = _normalize_patch(current_diff)

    candidates = sorted(
        [
            p for p in OUTPUT_ROOT.glob("BASELINE-VALIDATE-*")
            if (p / "diff.patch").exists() and (p / "validation.log").exists()
        ],
        reverse=True,
    )

    for directory in candidates:
        patch = _normalize_patch(
            (directory / "diff.patch").read_text(encoding="utf-8", errors="replace")
        )
        if patch != wanted:
            continue

        log = (directory / "validation.log").read_text(
            encoding="utf-8",
            errors="replace",
        )

        if "=== Targeted gate summary ===" not in log or "status: PASS" not in log:
            continue

        classification = "UNKNOWN"
        marker = "classification:"
        for line in log.splitlines():
            if line.strip().startswith(marker):
                classification = line.split(":", 1)[1].strip()
                break

        if classification not in {
            "FULL_CHECK_PASS",
            "PREEXISTING_UNRELATED_FORMAT_DEBT",
        }:
            raise CommitGateError(
                "Matching Stage 4.2 evidence exists, but its full-check "
                f"classification is not commit-safe: {classification}"
            )

        return ValidationEvidence(
            directory=str(directory),
            classification=classification,
            diff_match=True,
        )

    raise CommitGateError(
        "No matching Stage 4.2 targeted-validation evidence was found for "
        "the exact current diff."
    )


def _find_matching_visual_evidence(
    changed_paths: tuple[str, ...],
) -> VisualEvidence | None:
    candidates = sorted(
        [
            p for p in OUTPUT_ROOT.glob("VISUAL-BASELINE-*")
            if (p / "manifest.json").exists()
            and (p / "visual_review.json").exists()
        ],
        reverse=True,
    )

    for directory in candidates:
        manifest = json.loads(
            (directory / "manifest.json").read_text(encoding="utf-8")
        )
        review = json.loads(
            (directory / "visual_review.json").read_text(encoding="utf-8")
        )

        if tuple(manifest.get("changed_paths", [])) != changed_paths:
            continue

        if review.get("verdict") != "APPROVED":
            continue

        current_sha = manifest.get("current_shader_sha256", "")
        sha_match = False

        if len(changed_paths) == 1 and current_sha:
            current_path = ROOT / changed_paths[0]
            sha_match = _sha256_file(current_path) == current_sha

        if not sha_match:
            continue

        return VisualEvidence(
            directory=str(directory),
            verdict="APPROVED",
            diff_match=True,
            current_file_sha_match=True,
        )

    return None


def _visual_required(changed_paths: tuple[str, ...]) -> bool:
    visual_suffixes = {".gdshader", ".gdshaderinc", ".tscn", ".tres"}
    if any((ROOT / path).suffix.casefold() in visual_suffixes for path in changed_paths):
        return True

    return any("/ui/" in path.replace("\\", "/").casefold() for path in changed_paths)


def _rerun_targeted_gate(changed_paths: tuple[str, ...]) -> str:
    bundle = run_targeted_validation(
        changed_paths,
        run_full_check_advisory=False,
    )

    rendered = bundle.render()

    if not bundle.targeted_passed:
        raise CommitGateError(
            "Fresh Stage 5 targeted validation failed.\n\n" + rendered
        )

    return rendered


def preview() -> int:
    branch, head, changed_paths, diff_text = _preflight()
    validation = _find_matching_validation_evidence(diff_text)
    visual = _find_matching_visual_evidence(changed_paths)
    needs_visual = _visual_required(changed_paths)

    print("\n=== STAGE 5 — ZERO-COST COMMIT GATE PREVIEW ===")
    print(f"Branch:            {branch}")
    print(f"HEAD:              {head}")
    print("Changed files:")
    for path in changed_paths:
        print(f" - {path}")

    print("\nEvidence:")
    print(f" - targeted validation: MATCH / PASS")
    print(f"   {validation.directory}")
    print(f" - full-check classification: {validation.classification}")

    if needs_visual:
        if visual is None:
            print(" - visual review: MISSING ❌")
        else:
            print(" - visual review: MATCH / APPROVED ✅")
            print(f"   {visual.directory}")
    else:
        print(" - visual review: not required")

    print("\nOn commit, Stage 5 will:")
    print(" 1. re-run targeted validation locally (0 API calls)")
    print(" 2. stage only the verified changed files")
    print(" 3. run git diff --cached --check")
    print(" 4. create one local commit")
    print(" 5. NOT push anything")
    print("\nAPI calls: 0")

    if needs_visual and visual is None:
        return 4

    return 0


def commit_current(message: str) -> int:
    if not message.strip():
        raise CommitGateError("Commit message must not be empty.")

    branch, head, changed_paths, diff_text = _preflight()

    validation = _find_matching_validation_evidence(diff_text)
    visual = _find_matching_visual_evidence(changed_paths)
    needs_visual = _visual_required(changed_paths)

    if needs_visual and visual is None:
        raise CommitGateError(
            "Visual evidence is required, but no APPROVED visual review matches "
            "the exact current file SHA."
        )

    print("\n=== ECHOES AI TEAM — STAGE 5 / CONTROLLED COMMIT ===")
    print(f"Branch:            {branch}")
    print(f"Parent HEAD:       {head}")
    print(f"Commit message:    {message}")
    print("Changed files:")
    for path in changed_paths:
        print(f" - {path}")

    print("\n[1/4] Re-running fresh targeted validation...")
    fresh_log = _rerun_targeted_gate(changed_paths)
    print("Fresh targeted validation: PASS ✅")

    receipt_dir = OUTPUT_ROOT / f"COMMIT-{datetime.now():%Y%m%d-%H%M%S}"
    receipt_dir.mkdir(parents=True, exist_ok=True)
    (receipt_dir / "fresh_targeted_validation.log").write_text(
        fresh_log + "\n",
        encoding="utf-8",
    )
    (receipt_dir / "precommit_diff.patch").write_text(
        diff_text + "\n",
        encoding="utf-8",
    )

    print("\n[2/4] Staging verified files only...")
    _run_git(["add", "--", *changed_paths])

    staged_paths_text = _git_text(["diff", "--cached", "--name-only"])
    staged_paths = tuple(
        line.strip().replace("\\", "/")
        for line in staged_paths_text.splitlines()
        if line.strip()
    )

    if staged_paths != changed_paths:
        _run_git(["restore", "--staged", "--", *staged_paths], check=False)
        raise CommitGateError(
            "Staged file set does not exactly match the verified diff.\n"
            f"Expected: {list(changed_paths)}\n"
            f"Actual:   {list(staged_paths)}"
        )

    cached_check = _run_git(
        ["diff", "--cached", "--check", "--", *changed_paths],
        check=False,
    )
    if cached_check.returncode != 0:
        _run_git(["restore", "--staged", "--", *changed_paths], check=False)
        raise CommitGateError(
            "git diff --cached --check failed:\n"
            + cached_check.stdout
            + cached_check.stderr
        )

    staged_diff = _git_text(
        [
            "--no-pager",
            "diff",
            "--cached",
            "--no-ext-diff",
            "--unified=50",
            "--",
            *changed_paths,
        ]
    )

    if _normalize_patch(staged_diff) != _normalize_patch(diff_text):
        _run_git(["restore", "--staged", "--", *changed_paths], check=False)
        raise CommitGateError(
            "Staged diff differs from the reviewed current diff. Commit aborted."
        )

    print("Staged diff integrity: PASS ✅")

    print("\n[3/4] Creating local commit...")
    commit = _run_git(["commit", "-m", message], check=False)
    if commit.returncode != 0:
        _run_git(["restore", "--staged", "--", *changed_paths], check=False)
        raise CommitGateError(
            "git commit failed:\n" + commit.stdout + commit.stderr
        )

    new_sha = _git_text(["rev-parse", "HEAD"])

    print("\n[4/4] Verifying post-commit state...")
    if new_sha == head:
        raise CommitGateError("HEAD did not advance after commit.")

    status = _git_text(["status", "--short"])
    if status:
        raise CommitGateError(
            "Commit was created, but working tree is not clean afterward:\n"
            + status[:5000]
        )

    release_gate = (
        "CLEAR"
        if validation.classification == "FULL_CHECK_PASS"
        else "BLOCKED_BY_BASELINE_DEBT"
    )

    receipt = CommitReceipt(
        timestamp=datetime.now().isoformat(timespec="seconds"),
        branch=branch,
        parent_head=head,
        commit_sha=new_sha,
        commit_message=message,
        changed_paths=list(changed_paths),
        validation_evidence=validation,
        visual_evidence=visual,
        release_gate_status=release_gate,
    )

    (receipt_dir / "commit_receipt.json").write_text(
        json.dumps(asdict(receipt), ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )

    print("\n====================================")
    print("CONTROLLED COMMIT: PASS ✅")
    print(f"Commit:       {new_sha}")
    print(f"Branch:       {branch}")
    print(f"Release gate: {release_gate}")
    print("Push:         NOT PERFORMED")
    print("API calls:    0")
    print(f"Receipt:      {receipt_dir / 'commit_receipt.json'}")

    return 0


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Echoes of Pythonia — Stage 5 controlled local commit."
    )
    parser.add_argument("--preview", action="store_true")
    parser.add_argument("--commit-current", action="store_true")
    parser.add_argument("--message", type=str, default="")
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    try:
        if args.preview:
            code = preview()
        elif args.commit_current:
            code = commit_current(args.message)
        else:
            print('Użyj --preview lub --commit-current --message "..."')
            code = 1
    except CommitGateError as exc:
        print(f"\nBŁĄD / SAFETY STOP:\n{exc}")
        code = 2
    except KeyboardInterrupt:
        print("\nPrzerwano Stage 5. Push nigdy nie jest wykonywany.")
        code = 130

    raise SystemExit(code)


if __name__ == "__main__":
    main()
