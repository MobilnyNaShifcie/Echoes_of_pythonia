from __future__ import annotations

import os
import re
import shutil
import subprocess
import time
from dataclasses import dataclass
from pathlib import Path

from config import REPO_ROOT


ROOT = REPO_ROOT.resolve()

GODOT_CONSOLE = ROOT / ".tools" / "godot" / "Godot_v4.7.1-stable_win64_console.exe"
GDFORMAT = ROOT / ".venv" / "Scripts" / "gdformat.exe"
GDLINT = ROOT / ".venv" / "Scripts" / "gdlint.exe"

MAX_LOG_CHARS = 22000
TARGETED_TIMEOUT = int(os.getenv("EOP_TARGETED_VALIDATION_TIMEOUT_SECONDS", "300"))
FULL_CHECK_TIMEOUT = int(os.getenv("EOP_VALIDATION_TIMEOUT_SECONDS", "900"))


class TargetedValidationError(RuntimeError):
    pass


@dataclass(frozen=True)
class CommandResult:
    label: str
    command_display: str
    returncode: int
    seconds: float
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
            f"duration_seconds: {self.seconds:.2f}",
        ]
        if self.stdout.strip():
            parts.extend(["--- stdout ---", self.stdout.strip()])
        if self.stderr.strip():
            parts.extend(["--- stderr ---", self.stderr.strip()])
        return "\n".join(parts)


@dataclass(frozen=True)
class ValidationBundle:
    targeted_results: tuple[CommandResult, ...]
    targeted_passed: bool
    full_check_result: CommandResult | None
    full_check_classification: str
    full_check_blocks_current_change: bool
    mapped_test: str | None

    def render(self) -> str:
        chunks = ["\n\n".join(r.render() for r in self.targeted_results)]
        chunks.append(
            "\n".join(
                [
                    "=== Targeted gate summary ===",
                    f"status: {'PASS' if self.targeted_passed else 'FAIL'}",
                    f"mapped_test: {self.mapped_test or '(none)'}",
                ]
            )
        )

        if self.full_check_result is not None:
            chunks.append(self.full_check_result.render())
            chunks.append(
                "\n".join(
                    [
                        "=== Full-suite classification ===",
                        f"classification: {self.full_check_classification}",
                        f"blocks_current_change: {self.full_check_blocks_current_change}",
                        (
                            "note: A failing canonical full check is NEVER treated as a "
                            "clean release gate. Stage 4.2 may only distinguish whether "
                            "the first observed failure is unrelated to the current diff."
                        ),
                    ]
                )
            )

        return "\n\n".join(chunks)


def _truncate(text: str) -> str:
    if len(text) <= MAX_LOG_CHARS:
        return text
    half = (MAX_LOG_CHARS - 100) // 2
    return text[:half] + "\n\n[... LOG TRUNCATED ...]\n\n" + text[-half:]


def _run(
    label: str,
    command: list[str],
    display: str,
    timeout: int,
) -> CommandResult:
    started = time.monotonic()
    try:
        cp = subprocess.run(
            command,
            cwd=ROOT,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=timeout,
            check=False,
        )
        return CommandResult(
            label=label,
            command_display=display,
            returncode=cp.returncode,
            seconds=time.monotonic() - started,
            stdout=_truncate(cp.stdout),
            stderr=_truncate(cp.stderr),
        )
    except subprocess.TimeoutExpired as exc:
        stdout = exc.stdout or ""
        stderr = exc.stderr or ""
        if isinstance(stdout, bytes):
            stdout = stdout.decode("utf-8", errors="replace")
        if isinstance(stderr, bytes):
            stderr = stderr.decode("utf-8", errors="replace")
        return CommandResult(
            label=label,
            command_display=display,
            returncode=124,
            seconds=time.monotonic() - started,
            stdout=_truncate(stdout),
            stderr=_truncate(stderr + f"\nTIMEOUT after {timeout}s"),
        )


def _require_tools() -> None:
    missing = []
    for path in (GODOT_CONSOLE, GDFORMAT, GDLINT):
        if not path.exists():
            missing.append(str(path))
    if missing:
        raise TargetedValidationError(
            "Missing required local tools:\n" + "\n".join(missing)
        )


def _changed_gd_files(changed_paths: tuple[str, ...]) -> list[str]:
    return [p for p in changed_paths if p.casefold().endswith(".gd")]


def _needs_godot(changed_paths: tuple[str, ...]) -> bool:
    godot_exts = (".gd", ".gdshader", ".gdshaderinc", ".tscn", ".tres")
    return any(p.casefold().endswith(godot_exts) for p in changed_paths)


def _map_test(changed_paths: tuple[str, ...]) -> str | None:
    folded = [p.casefold().replace("\\", "/") for p in changed_paths]

    if any("/ui/screens/world_map/" in p for p in folded):
        candidate = ROOT / "godot" / "tests" / "test_world_map_interaction.gd"
        if candidate.exists():
            return "res://tests/test_world_map_interaction.gd"

    if any("/ui/screens/class_selection/" in p for p in folded):
        candidate = ROOT / "godot" / "tests" / "test_class_selection.gd"
        if candidate.exists():
            return "res://tests/test_class_selection.gd"

    return None


def _changed_path_mentioned_in_failure(
    changed_paths: tuple[str, ...],
    result: CommandResult,
) -> bool:
    haystack = (result.stdout + "\n" + result.stderr).casefold().replace("\\", "/")
    for path in changed_paths:
        normalized = path.casefold().replace("\\", "/")
        if normalized in haystack or Path(normalized).name in haystack:
            return True
    return False


def _looks_like_preexisting_format_debt(
    changed_paths: tuple[str, ...],
    result: CommandResult,
) -> bool:
    if result.passed:
        return False

    text = (result.stdout + "\n" + result.stderr).casefold()

    # gdformat's --check output:
    if "would reformat" not in text:
        return False

    # If one of the changed files itself is listed, this is not unrelated debt.
    return not _changed_path_mentioned_in_failure(changed_paths, result)


def run_targeted_validation(
    changed_paths: tuple[str, ...],
    *,
    run_full_check_advisory: bool = True,
) -> ValidationBundle:
    _require_tools()

    results: list[CommandResult] = []

    # 1) Whitespace / patch structure.
    diff_check = _run(
        "Git diff check",
        ["git", "diff", "--check", "--", *changed_paths],
        "git diff --check -- " + " ".join(changed_paths),
        60,
    )
    results.append(diff_check)

    if not diff_check.passed:
        return ValidationBundle(
            targeted_results=tuple(results),
            targeted_passed=False,
            full_check_result=None,
            full_check_classification="SKIPPED_TARGETED_FAILURE",
            full_check_blocks_current_change=True,
            mapped_test=None,
        )

    # 2) Only format/lint changed GDScript files. Existing unrelated formatting
    # debt must not block a shader-only or unrelated small change.
    changed_gd = _changed_gd_files(changed_paths)

    if changed_gd:
        fmt = _run(
            "Changed-file GDScript format check",
            [str(GDFORMAT), "--check", *changed_gd],
            "gdformat --check " + " ".join(changed_gd),
            TARGETED_TIMEOUT,
        )
        results.append(fmt)

        if fmt.passed:
            lint = _run(
                "Changed-file GDScript lint",
                [str(GDLINT), *changed_gd],
                "gdlint " + " ".join(changed_gd),
                TARGETED_TIMEOUT,
            )
            results.append(lint)

    # 3) Godot bootstrap for project-owned code/resources.
    if _needs_godot(changed_paths) and all(r.passed for r in results):
        bootstrap = _run(
            "Godot headless bootstrap",
            [
                str(GODOT_CONSOLE),
                "--headless",
                "--audio-driver",
                "Dummy",
                "--rendering-method",
                "gl_compatibility",
                "--path",
                str(ROOT / "godot"),
                "--quit-after",
                "3",
            ],
            "Godot --headless --path godot --quit-after 3",
            TARGETED_TIMEOUT,
        )
        results.append(bootstrap)

    # 4) Targeted GUT when a deterministic mapping exists.
    mapped_test = _map_test(changed_paths)
    if (
        mapped_test is not None
        and all(r.passed for r in results)
    ):
        gut = _run(
            "Targeted GUT",
            [
                str(GODOT_CONSOLE),
                "--headless",
                "--audio-driver",
                "Dummy",
                "--rendering-method",
                "gl_compatibility",
                "--path",
                str(ROOT / "godot"),
                "-s",
                "res://addons/gut/gut_cmdln.gd",
                f"-gtest={mapped_test}",
                "-gexit",
            ],
            f"GUT -gtest={mapped_test}",
            TARGETED_TIMEOUT,
        )
        results.append(gut)

    targeted_passed = bool(results) and all(r.passed for r in results)

    # 5) Canonical full check remains visible as debt/release information,
    # but does not automatically block a small change when its first observed
    # failure is clearly unrelated formatting debt.
    full_result: CommandResult | None = None
    classification = "NOT_RUN"
    blocks_current = False

    if run_full_check_advisory and targeted_passed:
        ps = shutil.which("pwsh") or shutil.which("powershell")
        if not ps:
            raise TargetedValidationError("PowerShell was not found.")

        full_result = _run(
            "Canonical full repository check (advisory in Stage 4.2)",
            [
                ps,
                "-NoProfile",
                "-ExecutionPolicy",
                "Bypass",
                "-File",
                str(ROOT / "scripts" / "check.ps1"),
            ],
            r".\scripts\check.ps1",
            FULL_CHECK_TIMEOUT,
        )

        if full_result.passed:
            classification = "FULL_CHECK_PASS"
            blocks_current = False
        elif _looks_like_preexisting_format_debt(changed_paths, full_result):
            classification = "PREEXISTING_UNRELATED_FORMAT_DEBT"
            blocks_current = False
        else:
            classification = "FULL_CHECK_FAILURE_NOT_PROVEN_UNRELATED"
            blocks_current = True

    return ValidationBundle(
        targeted_results=tuple(results),
        targeted_passed=targeted_passed,
        full_check_result=full_result,
        full_check_classification=classification,
        full_check_blocks_current_change=blocks_current,
        mapped_test=mapped_test,
    )
