from __future__ import annotations

import os
import shutil
import subprocess
import time
from dataclasses import dataclass
from pathlib import Path

from config import REPO_ROOT


ROOT = REPO_ROOT.resolve()

ALLOWED_CHANGED_SUFFIXES = {
    ".gd",
    ".gdshader",
    ".gdshaderinc",
    ".tscn",
    ".tres",
}

DENIED_CHANGED_NAMES = {
    "project.godot",
    ".env",
    "export_credentials.cfg",
}

MAX_CHANGED_FILES = 3
MAX_DIFF_CHARS = 36_000
MAX_VALIDATION_LOG_CHARS = 24_000
CHECK_TIMEOUT_SECONDS = int(
    os.getenv("EOP_VALIDATION_TIMEOUT_SECONDS", "900")
)


class ValidationError(RuntimeError):
    pass


@dataclass(frozen=True)
class WorkingDiff:
    branch: str
    head: str
    changed_paths: tuple[str, ...]
    diff_text: str


@dataclass(frozen=True)
class CommandResult:
    label: str
    command_display: str
    returncode: int
    duration_seconds: float
    stdout: str
    stderr: str

    @property
    def passed(self) -> bool:
        return self.returncode == 0

    def render(self) -> str:
        status = "PASS" if self.passed else "FAIL"
        parts = [
            f"=== {self.label} ===",
            f"status: {status}",
            f"command: {self.command_display}",
            f"returncode: {self.returncode}",
            f"duration_seconds: {self.duration_seconds:.2f}",
        ]

        if self.stdout.strip():
            parts.extend(
                [
                    "--- stdout ---",
                    self.stdout.strip(),
                ]
            )

        if self.stderr.strip():
            parts.extend(
                [
                    "--- stderr ---",
                    self.stderr.strip(),
                ]
            )

        return "\n".join(parts)


def _run_git(args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=60,
        check=False,
    )


def _git_text(args: list[str]) -> str:
    result = _run_git(args)
    if result.returncode != 0:
        raise ValidationError(
            f"git {' '.join(args)} failed:\n"
            f"{result.stdout}\n{result.stderr}"
        )
    return result.stdout.strip()


def _protected_branch(branch: str) -> bool:
    return (
        branch in {"main", "master"}
        or branch.startswith("release/")
        or branch == "snapshot/pre-ai-team-2026-09-10"
    )


def inspect_current_diff() -> WorkingDiff:
    branch = _git_text(["branch", "--show-current"])
    head = _git_text(["rev-parse", "HEAD"])

    if _protected_branch(branch):
        raise ValidationError(
            f"Protected branch is active: {branch}"
        )

    staged = _git_text(["diff", "--cached", "--name-only"])
    if staged:
        raise ValidationError(
            "Stage 4 refuses to validate while staged changes exist.\n"
            + staged
        )

    untracked = _git_text(
        ["ls-files", "--others", "--exclude-standard"]
    )
    if untracked:
        raise ValidationError(
            "Stage 4 refuses to validate with untracked files.\n"
            + untracked[:5000]
        )

    changed = _git_text(["diff", "--name-only"])
    changed_paths = tuple(
        line.strip().replace("\\", "/")
        for line in changed.splitlines()
        if line.strip()
    )

    if not changed_paths:
        raise ValidationError(
            "No uncommitted working-tree diff found. "
            "Stage 4 expects the approved Stage 3 change."
        )

    if len(changed_paths) > MAX_CHANGED_FILES:
        raise ValidationError(
            f"Too many changed files: {len(changed_paths)} > "
            f"{MAX_CHANGED_FILES}"
        )

    for relative in changed_paths:
        path = (ROOT / relative).resolve()

        try:
            path.relative_to(ROOT)
        except ValueError as exc:
            raise ValidationError(
                f"Changed path escapes repository: {relative}"
            ) from exc

        if not relative.startswith("godot/"):
            raise ValidationError(
                f"Stage 4 accepts only Godot project changes: {relative}"
            )

        if path.name.casefold() in {
            name.casefold() for name in DENIED_CHANGED_NAMES
        }:
            raise ValidationError(
                f"Denied changed file: {relative}"
            )

        if path.suffix.casefold() not in ALLOWED_CHANGED_SUFFIXES:
            raise ValidationError(
                f"Unexpected changed file type: {relative}"
            )

        if not path.exists() or not path.is_file():
            raise ValidationError(
                f"Changed file is missing/not regular: {relative}"
            )

    diff_check = _run_git(
        ["diff", "--check", "--", *changed_paths]
    )
    if diff_check.returncode != 0:
        raise ValidationError(
            "git diff --check failed before validation:\n"
            + diff_check.stdout
            + diff_check.stderr
        )

    diff = _git_text(
        [
            "--no-pager",
            "diff",
            "--no-ext-diff",
            "--unified=60",
            "--",
            *changed_paths,
        ]
    )

    if len(diff) > MAX_DIFF_CHARS:
        diff = (
            diff[:MAX_DIFF_CHARS]
            + f"\n\n[DIFF TRUNCATED after {MAX_DIFF_CHARS:,} chars]"
        )

    return WorkingDiff(
        branch=branch,
        head=head,
        changed_paths=changed_paths,
        diff_text=diff,
    )


def _powershell_executable() -> str:
    for candidate in ("pwsh", "powershell"):
        resolved = shutil.which(candidate)
        if resolved:
            return resolved
    raise ValidationError(
        "Neither pwsh nor powershell was found on PATH."
    )


def _truncate_log(text: str) -> str:
    if len(text) <= MAX_VALIDATION_LOG_CHARS:
        return text

    # Keep both beginning and end: setup context + final failure/pass summary.
    half = (MAX_VALIDATION_LOG_CHARS - 120) // 2
    return (
        text[:half]
        + "\n\n[... VALIDATION LOG TRUNCATED ...]\n\n"
        + text[-half:]
    )


def _run_command(
    label: str,
    command: list[str],
    command_display: str,
    timeout_seconds: int,
) -> CommandResult:
    started = time.monotonic()

    try:
        completed = subprocess.run(
            command,
            cwd=ROOT,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=timeout_seconds,
            check=False,
        )
        duration = time.monotonic() - started
        return CommandResult(
            label=label,
            command_display=command_display,
            returncode=completed.returncode,
            duration_seconds=duration,
            stdout=_truncate_log(completed.stdout),
            stderr=_truncate_log(completed.stderr),
        )
    except subprocess.TimeoutExpired as exc:
        duration = time.monotonic() - started

        stdout = exc.stdout or ""
        stderr = exc.stderr or ""

        if isinstance(stdout, bytes):
            stdout = stdout.decode("utf-8", errors="replace")
        if isinstance(stderr, bytes):
            stderr = stderr.decode("utf-8", errors="replace")

        return CommandResult(
            label=label,
            command_display=command_display,
            returncode=124,
            duration_seconds=duration,
            stdout=_truncate_log(stdout),
            stderr=_truncate_log(
                stderr
                + f"\nTIMEOUT after {timeout_seconds} seconds."
            ),
        )


def run_canonical_validation(
    working_diff: WorkingDiff,
) -> tuple[list[CommandResult], str]:
    script = ROOT / "scripts" / "check.ps1"
    if not script.exists():
        raise ValidationError(
            "Canonical validation script is missing: scripts/check.ps1"
        )

    results: list[CommandResult] = []

    # Local structural validation first.
    diff_result = _run_command(
        label="Git diff check",
        command=[
            "git",
            "diff",
            "--check",
            "--",
            *working_diff.changed_paths,
        ],
        command_display=(
            "git diff --check -- "
            + " ".join(working_diff.changed_paths)
        ),
        timeout_seconds=60,
    )
    results.append(diff_result)

    if not diff_result.passed:
        rendered = "\n\n".join(
            result.render() for result in results
        )
        return results, rendered

    shell = _powershell_executable()

    check_result = _run_command(
        label="Canonical repository validation",
        command=[
            shell,
            "-NoProfile",
            "-ExecutionPolicy",
            "Bypass",
            "-File",
            str(script),
        ],
        command_display=r".\scripts\check.ps1",
        timeout_seconds=CHECK_TIMEOUT_SECONDS,
    )
    results.append(check_result)

    rendered = "\n\n".join(
        result.render() for result in results
    )

    return results, rendered


def validation_passed(results: list[CommandResult]) -> bool:
    return bool(results) and all(result.passed for result in results)


def ensure_tests_did_not_change_tracked_files(
    expected_paths: tuple[str, ...],
) -> None:
    after = _git_text(["diff", "--name-only"])
    after_paths = tuple(
        line.strip().replace("\\", "/")
        for line in after.splitlines()
        if line.strip()
    )

    if after_paths != expected_paths:
        raise ValidationError(
            "Validation changed the tracked working tree unexpectedly.\n"
            f"Before: {list(expected_paths)}\n"
            f"After:  {list(after_paths)}\n"
            "Stage 4 will not guess which new changes are disposable."
        )


def zero_cost_smoke() -> list[str]:
    results: list[str] = []

    script = ROOT / "scripts" / "check.ps1"
    results.append(
        "canonical_check_present=PASS"
        if script.exists()
        else "canonical_check_present=FAIL"
    )

    try:
        shell = _powershell_executable()
        results.append(
            "powershell_available=PASS"
            if shell
            else "powershell_available=FAIL"
        )
    except ValidationError:
        results.append("powershell_available=FAIL")

    branch = _git_text(["branch", "--show-current"])
    results.append(
        "protected_branch_guard=PASS"
        if not _protected_branch(branch)
        else "protected_branch_guard=FAIL"
    )

    return results
