from __future__ import annotations

import subprocess
from dataclasses import dataclass
from pathlib import Path

from config import REPO_ROOT
from write_schemas import ChangeProposal


ROOT = REPO_ROOT.resolve()

EDITABLE_SUFFIXES = {
    ".gd",
    ".gdshader",
    ".gdshaderinc",
    ".tscn",
    ".tres",
}

DENIED_NAMES = {
    "project.godot",
    ".env",
    "export_credentials.cfg",
}

MAX_EDIT_FILES = 3
MAX_REPLACEMENTS_PER_FILE = 6
MAX_TOTAL_NEW_CHARS = 18_000
MAX_DIFF_CHARS = 32_000


class ControlledWriteError(RuntimeError):
    pass


@dataclass
class AppliedChange:
    originals: dict[Path, str]
    edited_paths: tuple[Path, ...]


def _read_exact(path: Path) -> str:
    with path.open("r", encoding="utf-8", newline="") as handle:
        return handle.read()


def _write_exact(path: Path, text: str) -> None:
    with path.open("w", encoding="utf-8", newline="") as handle:
        handle.write(text)


def _safe_existing_edit_path(relative_path: str) -> Path:
    raw = (relative_path or "").strip()
    if not raw:
        raise ControlledWriteError("Empty edit path.")

    candidate = Path(raw)
    if candidate.is_absolute():
        raise ControlledWriteError("Absolute edit paths are forbidden.")
    if ".." in candidate.parts:
        raise ControlledWriteError("Parent traversal is forbidden.")

    unresolved = ROOT / candidate
    if not unresolved.exists():
        raise ControlledWriteError(f"Edit target does not exist: {raw}")

    resolved = unresolved.resolve()
    try:
        relative = resolved.relative_to(ROOT)
    except ValueError as exc:
        raise ControlledWriteError("Edit target escapes repository root.") from exc

    rel_posix = relative.as_posix()
    if not rel_posix.startswith("godot/"):
        raise ControlledWriteError(
            f"Stage 3 may edit only existing Godot project files: {rel_posix}"
        )

    if resolved.name.casefold() in {x.casefold() for x in DENIED_NAMES}:
        raise ControlledWriteError(f"Denied edit target: {resolved.name}")

    if resolved.name.casefold().startswith(".env"):
        raise ControlledWriteError("Denied edit target: .env")

    if resolved.suffix.casefold() not in EDITABLE_SUFFIXES:
        raise ControlledWriteError(
            f"File type is not editable in Stage 3: {resolved.suffix}"
        )

    if resolved.is_symlink():
        raise ControlledWriteError("Symlink edit targets are forbidden.")

    if not resolved.is_file():
        raise ControlledWriteError("Edit target must be a regular file.")

    return resolved


def _replacement_variants(old_text: str, new_text: str):
    old_lf = old_text.replace("\r\n", "\n")
    new_lf = new_text.replace("\r\n", "\n")

    yield old_lf, new_lf

    if "\n" in old_lf:
        yield (
            old_lf.replace("\n", "\r\n"),
            new_lf.replace("\n", "\r\n"),
        )


def _apply_one_replacement(text: str, old_text: str, new_text: str) -> str:
    if not old_text:
        raise ControlledWriteError("old_text must not be empty.")

    attempted = set()

    for old_variant, new_variant in _replacement_variants(old_text, new_text):
        key = (old_variant, new_variant)
        if key in attempted:
            continue
        attempted.add(key)

        count = text.count(old_variant)
        if count == 1:
            return text.replace(old_variant, new_variant, 1)
        if count > 1:
            raise ControlledWriteError(
                "old_text is not unique in the target file."
            )

    raise ControlledWriteError(
        "old_text was not found exactly in the target file."
    )


def apply_proposal(
    proposal: ChangeProposal,
    allowed_paths: set[str],
) -> AppliedChange:
    if proposal.status != "READY_TO_APPLY":
        raise ControlledWriteError(
            f"Proposal status is not READY_TO_APPLY: {proposal.status}"
        )

    if not proposal.edits:
        raise ControlledWriteError("Developer returned no edits.")

    if len(proposal.edits) > MAX_EDIT_FILES:
        raise ControlledWriteError(
            f"Too many edited files: {len(proposal.edits)} > {MAX_EDIT_FILES}"
        )

    total_new_chars = 0
    originals: dict[Path, str] = {}
    working: dict[Path, str] = {}

    try:
        for file_edit in proposal.edits:
            rel = Path(file_edit.path).as_posix()

            if rel not in allowed_paths:
                raise ControlledWriteError(
                    f"Edit target was not included in REPO_BRIEF: {rel}"
                )

            path = _safe_existing_edit_path(rel)

            if len(file_edit.replacements) == 0:
                raise ControlledWriteError(f"No replacements for {rel}")

            if len(file_edit.replacements) > MAX_REPLACEMENTS_PER_FILE:
                raise ControlledWriteError(
                    f"Too many replacements in {rel}: "
                    f"{len(file_edit.replacements)} > "
                    f"{MAX_REPLACEMENTS_PER_FILE}"
                )

            if path not in originals:
                originals[path] = _read_exact(path)
                working[path] = originals[path]

            current = working[path]

            for replacement in file_edit.replacements:
                total_new_chars += len(replacement.new_text)
                if total_new_chars > MAX_TOTAL_NEW_CHARS:
                    raise ControlledWriteError(
                        "Proposed replacement payload is too large."
                    )

                current = _apply_one_replacement(
                    current,
                    replacement.old_text,
                    replacement.new_text,
                )

            if not current.strip():
                raise ControlledWriteError(
                    f"Result would empty the file: {rel}"
                )

            working[path] = current

        # Write only after every proposed edit validates.
        for path, text in working.items():
            _write_exact(path, text)

        return AppliedChange(
            originals=originals,
            edited_paths=tuple(working.keys()),
        )

    except Exception:
        # Atomic rollback if anything failed after a partial write.
        for path, original in originals.items():
            try:
                _write_exact(path, original)
            except Exception:
                pass
        raise


def rollback(change: AppliedChange) -> None:
    for path, original in change.originals.items():
        _write_exact(path, original)


def _run_git(args: list[str]) -> subprocess.CompletedProcess[str]:
    return subprocess.run(
        ["git", *args],
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=30,
        check=False,
    )


def validate_diff(change: AppliedChange) -> str:
    relative_paths = [
        path.relative_to(ROOT).as_posix()
        for path in change.edited_paths
    ]

    check = _run_git(["diff", "--check", "--", *relative_paths])
    if check.returncode != 0:
        raise ControlledWriteError(
            "git diff --check failed:\n" + check.stdout + check.stderr
        )

    diff = _run_git(
        [
            "--no-pager",
            "diff",
            "--no-ext-diff",
            "--unified=50",
            "--",
            *relative_paths,
        ]
    )
    if diff.returncode != 0:
        raise ControlledWriteError(
            "Could not read git diff:\n" + diff.stderr
        )

    text = diff.stdout.strip()
    if not text:
        raise ControlledWriteError(
            "Proposal produced no actual git diff."
        )

    if len(text) > MAX_DIFF_CHARS:
        text = (
            text[:MAX_DIFF_CHARS]
            + f"\n\n[DIFF TRUNCATED after {MAX_DIFF_CHARS:,} chars]"
        )

    return text


def safety_smoke() -> list[str]:
    results: list[str] = []

    # A known source file should be accepted when present.
    known = ROOT / "godot" / "ui" / "screens" / "world_map" / "world_region_map.gd"
    if known.exists():
        try:
            _safe_existing_edit_path(
                "godot/ui/screens/world_map/world_region_map.gd"
            )
            results.append("godot_source_guard=PASS")
        except ControlledWriteError:
            results.append("godot_source_guard=FAIL")
    else:
        results.append("godot_source_guard=SKIP")

    blocked = 0
    for bad in (
        "tools/echoes_ai_team/.env",
        "../outside.txt",
        "godot/project.godot",
    ):
        try:
            _safe_existing_edit_path(bad)
        except ControlledWriteError:
            blocked += 1

    results.append(
        "denied_path_guard=PASS" if blocked == 3 else "denied_path_guard=FAIL"
    )

    return results
