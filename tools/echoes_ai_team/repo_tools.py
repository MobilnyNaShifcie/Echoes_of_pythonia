from __future__ import annotations

import os
import subprocess
from pathlib import Path

from agents.decorators import tool

from config import REPO_ROOT


ROOT = REPO_ROOT.resolve()

DENIED_PARTS = {
    ".git",
    ".venv",
    ".tools",
    "output",
    "build",
    "dist",
    "__pycache__",
    ".pytest_cache",
    ".mypy_cache",
    ".ruff_cache",
}

DENIED_FILENAMES = {
    ".env",
    "export_credentials.cfg",
    "id_rsa",
    "id_ed25519",
}

TEXT_SUFFIXES = {
    ".gd",
    ".gdshader",
    ".shader",
    ".tscn",
    ".tres",
    ".godot",
    ".uid",
    ".md",
    ".txt",
    ".json",
    ".py",
    ".ps1",
    ".cfg",
    ".ini",
    ".toml",
    ".yml",
    ".yaml",
    ".csv",
    ".gitattributes",
    ".gitignore",
}

MAX_READ_LINES = 240
MAX_TOOL_CHARS = 16000
MAX_SEARCH_RESULTS = 24
MAX_LIST_ENTRIES = 160
MAX_SEARCH_FILE_BYTES = 1_500_000


class RepoToolError(RuntimeError):
    pass


def _relative_display(path: Path) -> str:
    return path.relative_to(ROOT).as_posix() or "."


def _reject_secret_name(path: Path) -> None:
    lower_name = path.name.casefold()
    if lower_name in {name.casefold() for name in DENIED_FILENAMES}:
        raise RepoToolError(f"Access denied to secret/local file: {path.name}")

    if lower_name.startswith(".env"):
        raise RepoToolError("Access denied to .env files.")

    if path.suffix.casefold() in {".pem", ".key", ".pfx", ".p12"}:
        raise RepoToolError("Access denied to credential/key files.")


def _safe_path(relative_path: str, *, must_exist: bool = True) -> Path:
    raw = (relative_path or ".").strip()

    candidate_input = Path(raw)
    if candidate_input.is_absolute():
        raise RepoToolError("Only repository-relative paths are allowed.")

    if any(part in {"..", ""} for part in candidate_input.parts if part != "."):
        if ".." in candidate_input.parts:
            raise RepoToolError("Parent traversal is not allowed.")

    # Reject denied areas before resolve() so even junctions/symlinks cannot be
    # used as a path into local secrets/tooling.
    for part in candidate_input.parts:
        if part.casefold() in {x.casefold() for x in DENIED_PARTS}:
            raise RepoToolError(f"Access denied to local/generated area: {part}")

    unresolved = ROOT / candidate_input

    if must_exist and not unresolved.exists():
        raise RepoToolError(f"Path does not exist: {raw}")

    try:
        resolved = unresolved.resolve(strict=must_exist)
    except OSError as exc:
        raise RepoToolError(f"Could not resolve path: {raw}") from exc

    try:
        resolved.relative_to(ROOT)
    except ValueError as exc:
        raise RepoToolError("Resolved path escapes repository root.") from exc

    # A junction/symlink may resolve into an otherwise denied absolute target.
    relative = resolved.relative_to(ROOT)
    for part in relative.parts:
        if part.casefold() in {x.casefold() for x in DENIED_PARTS}:
            raise RepoToolError(f"Access denied to local/generated area: {part}")

    _reject_secret_name(resolved)
    return resolved


def _is_allowed_text_file(path: Path) -> bool:
    if not path.is_file():
        return False

    try:
        relative = path.relative_to(ROOT)
    except ValueError:
        return False

    if any(part.casefold() in {x.casefold() for x in DENIED_PARTS} for part in relative.parts):
        return False

    try:
        _reject_secret_name(path)
    except RepoToolError:
        return False

    name = path.name.casefold()
    suffix = path.suffix.casefold()

    if name in {".gitignore", ".gitattributes"}:
        return True

    return suffix in TEXT_SUFFIXES


def _truncate(text: str, limit: int = MAX_TOOL_CHARS) -> str:
    if len(text) <= limit:
        return text
    return text[:limit] + f"\n\n[TRUNCATED after {limit:,} characters]"


def _run_git(args: list[str]) -> str:
    completed = subprocess.run(
        ["git", *args],
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=20,
        check=False,
    )
    if completed.returncode != 0:
        stderr = completed.stderr.strip()
        raise RepoToolError(f"git {' '.join(args)} failed: {stderr}")
    return completed.stdout.strip()


def _git_info_impl() -> str:
    branch = _run_git(["branch", "--show-current"])
    head = _run_git(["rev-parse", "HEAD"])
    status = _run_git(["status", "--short"])
    status_text = status if status else "(clean)"
    return _truncate(
        f"READ-ONLY GIT INFO\n"
        f"branch: {branch}\n"
        f"head: {head}\n"
        f"status:\n{status_text}"
    )


def _list_impl(relative_path: str = ".") -> str:
    path = _safe_path(relative_path)
    if not path.is_dir():
        raise RepoToolError(f"Not a directory: {relative_path}")

    entries = []
    for child in sorted(path.iterdir(), key=lambda p: (not p.is_dir(), p.name.casefold())):
        try:
            relative = child.relative_to(ROOT)
        except ValueError:
            continue

        if any(part.casefold() in {x.casefold() for x in DENIED_PARTS} for part in relative.parts):
            continue
        try:
            _reject_secret_name(child)
        except RepoToolError:
            continue

        kind = "DIR " if child.is_dir() else "FILE"
        size = ""
        if child.is_file():
            try:
                size = f" {child.stat().st_size}B"
            except OSError:
                size = ""
        entries.append(f"{kind} {_relative_display(child)}{size}")

        if len(entries) >= MAX_LIST_ENTRIES:
            entries.append(f"[TRUNCATED at {MAX_LIST_ENTRIES} entries]")
            break

    return _truncate(
        f"READ-ONLY LIST: {_relative_display(path)}\n" + "\n".join(entries)
    )


def _find_impl(name_contains: str, relative_path: str = ".") -> str:
    needle = name_contains.strip().casefold()
    if not needle:
        raise RepoToolError("name_contains must not be empty.")

    root = _safe_path(relative_path)
    if not root.is_dir():
        raise RepoToolError(f"Not a directory: {relative_path}")

    results: list[str] = []
    for current_root, dirnames, filenames in os.walk(root, followlinks=False):
        current_path = Path(current_root)

        dirnames[:] = [
            d for d in dirnames
            if d.casefold() not in {x.casefold() for x in DENIED_PARTS}
        ]

        for name in sorted(dirnames + filenames, key=str.casefold):
            if needle not in name.casefold():
                continue
            candidate = current_path / name
            try:
                resolved = _safe_path(str(candidate.relative_to(ROOT)))
            except (RepoToolError, ValueError):
                continue

            results.append(
                ("DIR " if resolved.is_dir() else "FILE")
                + " "
                + _relative_display(resolved)
            )
            if len(results) >= MAX_SEARCH_RESULTS:
                results.append(f"[TRUNCATED at {MAX_SEARCH_RESULTS} results]")
                return _truncate(
                    f"READ-ONLY FIND name~{name_contains!r} under {_relative_display(root)}\n"
                    + "\n".join(results)
                )

    if not results:
        return (
            f"READ-ONLY FIND name~{name_contains!r} under {_relative_display(root)}\n"
            "(no matches)"
        )

    return _truncate(
        f"READ-ONLY FIND name~{name_contains!r} under {_relative_display(root)}\n"
        + "\n".join(results)
    )


def _read_impl(relative_path: str, start_line: int = 1, end_line: int = 220) -> str:
    path = _safe_path(relative_path)
    if not _is_allowed_text_file(path):
        raise RepoToolError("Only approved text/source files may be read.")

    start_line = max(1, int(start_line))
    end_line = max(start_line, int(end_line))
    end_line = min(end_line, start_line + MAX_READ_LINES - 1)

    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError as exc:
        raise RepoToolError("File is not valid UTF-8 text.") from exc

    lines = text.splitlines()
    if start_line > len(lines) and lines:
        return (
            f"READ-ONLY FILE: {_relative_display(path)}\n"
            f"Requested start line {start_line}, file has {len(lines)} lines."
        )

    selected = lines[start_line - 1 : end_line]
    numbered = "\n".join(
        f"{line_no:>5}: {line}"
        for line_no, line in enumerate(selected, start=start_line)
    )

    header = (
        f"READ-ONLY FILE: {_relative_display(path)}\n"
        f"lines: {start_line}-{start_line + max(0, len(selected)-1)} "
        f"of {len(lines)}\n"
    )
    return _truncate(header + numbered)


def _search_impl(query: str, relative_path: str = "godot") -> str:
    needle = query.strip()
    if not needle:
        raise RepoToolError("query must not be empty.")

    root = _safe_path(relative_path)
    if not root.is_dir():
        raise RepoToolError(f"Not a directory: {relative_path}")

    needle_fold = needle.casefold()
    results: list[str] = []
    files_scanned = 0

    for current_root, dirnames, filenames in os.walk(root, followlinks=False):
        current_path = Path(current_root)
        dirnames[:] = [
            d for d in dirnames
            if d.casefold() not in {x.casefold() for x in DENIED_PARTS}
        ]

        for filename in filenames:
            path = current_path / filename
            if not _is_allowed_text_file(path):
                continue
            try:
                if path.stat().st_size > MAX_SEARCH_FILE_BYTES:
                    continue
            except OSError:
                continue

            files_scanned += 1
            try:
                lines = path.read_text(encoding="utf-8").splitlines()
            except (UnicodeDecodeError, OSError):
                continue

            for line_no, line in enumerate(lines, start=1):
                if needle_fold not in line.casefold():
                    continue

                snippet = line.strip()
                if len(snippet) > 260:
                    snippet = snippet[:260] + "…"
                results.append(
                    f"{_relative_display(path)}:{line_no}: {snippet}"
                )
                if len(results) >= MAX_SEARCH_RESULTS:
                    return _truncate(
                        f"READ-ONLY SEARCH {needle!r} under {_relative_display(root)} "
                        f"(scanned {files_scanned} files)\n"
                        + "\n".join(results)
                        + f"\n[TRUNCATED at {MAX_SEARCH_RESULTS} matches]"
                    )

    if not results:
        return (
            f"READ-ONLY SEARCH {needle!r} under {_relative_display(root)} "
            f"(scanned {files_scanned} files)\n(no matches)"
        )

    return _truncate(
        f"READ-ONLY SEARCH {needle!r} under {_relative_display(root)} "
        f"(scanned {files_scanned} files)\n"
        + "\n".join(results)
    )


@tool
def repo_git_info() -> str:
    """Return current branch, HEAD commit and short Git status. Read-only."""
    return _git_info_impl()


@tool
def repo_list(relative_path: str = ".") -> str:
    """List one repository directory without exposing ignored/local secret areas.

    Args:
        relative_path: Repository-relative directory, for example godot/ui/screens.
    """
    return _list_impl(relative_path)


@tool
def repo_find(name_contains: str, relative_path: str = ".") -> str:
    """Find files/directories by partial filename inside the repository. Read-only.

    Args:
        name_contains: Partial file or directory name, for example world_map.
        relative_path: Repository-relative directory to search under.
    """
    return _find_impl(name_contains, relative_path)


@tool
def repo_read(relative_path: str, start_line: int = 1, end_line: int = 220) -> str:
    """Read a bounded line range from an approved UTF-8 source/text file. Read-only.

    Args:
        relative_path: Repository-relative file path.
        start_line: First 1-based line number.
        end_line: Last 1-based line number. The tool enforces a maximum range.
    """
    return _read_impl(relative_path, start_line, end_line)


@tool
def repo_search(query: str, relative_path: str = "godot") -> str:
    """Literal case-insensitive text search across approved source files. Read-only.

    Args:
        query: Text to find, such as WorldRegionMap or region_hovered.
        relative_path: Repository-relative directory to search under.
    """
    return _search_impl(query, relative_path)


READ_ONLY_REPO_TOOLS = [
    repo_git_info,
    repo_list,
    repo_find,
    repo_read,
    repo_search,
]


def local_repo_tools_smoke() -> str:
    """Zero-API local smoke test used by --repo-smoke."""
    checks = []

    git_info = _git_info_impl()
    checks.append("git_info=PASS" if "branch:" in git_info else "git_info=FAIL")

    project = _read_impl("godot/project.godot", 1, 35)
    checks.append(
        "project_read=PASS"
        if 'config/name="Echoes of Pythonia"' in project
        else "project_read=FAIL"
    )

    found = _find_impl("world_map", "godot/ui")
    checks.append(
        "find_world_map=PASS"
        if "world_map" in found.casefold()
        else "find_world_map=FAIL"
    )

    secret_blocked = False
    try:
        _read_impl("tools/echoes_ai_team/.env", 1, 5)
    except RepoToolError:
        secret_blocked = True
    checks.append("secret_guard=PASS" if secret_blocked else "secret_guard=FAIL")

    return "\n".join(checks)
