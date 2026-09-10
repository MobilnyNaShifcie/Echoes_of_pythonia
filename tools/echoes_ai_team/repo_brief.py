from __future__ import annotations

import os
import subprocess
from dataclasses import dataclass
from pathlib import Path

from config import (
    REPO_BRIEF_MAX_CHARS,
    REPO_BRIEF_MAX_FILES,
    REPO_BRIEF_SNIPPETS_PER_FILE,
    REPO_ROOT,
)
from context_router import detect_domains, tokenize


ROOT = REPO_ROOT.resolve()

DENIED_DIRS = {
    ".git",
    ".venv",
    ".tools",
    ".godot",
    "output",
    "build",
    "dist",
    "__pycache__",
    ".pytest_cache",
    ".mypy_cache",
    ".ruff_cache",
}

ALLOWED_FILENAMES = {
    ".gitignore",
    ".gitattributes",
}

ALLOWED_SUFFIXES = {
    ".gd",
    ".gdshader",
    ".gdshaderinc",
    ".shader",
    ".tscn",
    ".tres",
    ".godot",
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
}

SECRET_NAMES = {
    ".env",
    "export_credentials.cfg",
    "id_rsa",
    "id_ed25519",
}

MAX_SCAN_FILE_BYTES = 750_000
MAX_SNIPPET_LINE_LENGTH = 320


@dataclass(frozen=True)
class Candidate:
    path: Path
    score: float
    match_lines: tuple[int, ...]


@dataclass(frozen=True)
class RepoBrief:
    text: str
    branch: str
    head: str
    status: str
    selected_files: tuple[str, ...]
    chars: int
    scanned_files: int


class BriefError(RuntimeError):
    pass


def _run_git(args: list[str]) -> str:
    result = subprocess.run(
        ["git", *args],
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=20,
        check=False,
    )
    if result.returncode != 0:
        raise BriefError(
            f"git {' '.join(args)} failed: {result.stderr.strip()}"
        )
    return result.stdout.strip()


def _preflight() -> tuple[str, str, str]:
    branch = _run_git(["branch", "--show-current"])
    head = _run_git(["rev-parse", "HEAD"])
    status = _run_git(["status", "--short"])

    if branch == "snapshot/pre-ai-team-2026-09-10":
        raise BriefError("Protected snapshot branch is active.")

    if branch in {"main", "master"} or branch.startswith("release/"):
        raise BriefError(f"Protected branch is active: {branch}")

    if status:
        raise BriefError(
            "Working tree is not clean. Stage 2.2 refuses paid model calls.\n"
            + status[:5000]
        )

    return branch, head, status


def _safe_text_file(path: Path) -> bool:
    try:
        relative = path.resolve().relative_to(ROOT)
    except (ValueError, OSError):
        return False

    if any(
        part.casefold() in {x.casefold() for x in DENIED_DIRS}
        for part in relative.parts
    ):
        return False

    name = path.name.casefold()
    if name in {x.casefold() for x in SECRET_NAMES}:
        return False
    if name.startswith(".env"):
        return False
    if path.suffix.casefold() in {".pem", ".key", ".pfx", ".p12"}:
        return False

    # Godot *.uid sidecars do not contain useful task context.
    if path.suffix.casefold() == ".uid":
        return False

    if name in ALLOWED_FILENAMES:
        return True

    return path.suffix.casefold() in ALLOWED_SUFFIXES


def _is_world_map_task(task: str) -> bool:
    t = task.casefold()
    map_terms = ("map", "mapa", "mapę", "mapie", "world map", "świata")
    region_terms = ("region", "hover", "podświet", "highlight")
    return any(x in t for x in map_terms) and any(x in t for x in region_terms)


def _expanded_terms(task: str) -> set[str]:
    terms = set(tokenize(task))
    t = task.casefold()

    # Small bilingual synonym expansion for common project tasks.
    if any(x in t for x in ("hover", "najech", "podświet", "podswiet")):
        terms.update(
            {
                "hover",
                "highlight",
                "mouse",
                "region_hover",
                "hover_strength",
            }
        )

    if any(x in t for x in ("mapa", "mapę", "mapie", "świata", "world map")):
        terms.update(
            {
                "map",
                "world_map",
                "world",
                "region",
                "world_region_map",
            }
        )

    if "region" in t:
        terms.update(
            {
                "region",
                "region_id",
                "region_selected",
                "region_hovered",
            }
        )

    if any(x in t for x in ("test", "sprawd", "walid", "validation")):
        terms.update({"test", "check", "validation"})

    return terms


def _domain_path_bonus(path_text: str, domains: set[str]) -> float:
    score = 0.0
    p = path_text.casefold()

    if "ui" in domains:
        if "/ui/" in p:
            score += 18.0
        if "/screens/" in p or "/components/" in p:
            score += 7.0
        if "/tests/" in p:
            score += 7.0

    if "art" in domains:
        if "/assets/" in p:
            score += 16.0
        if "manifest" in p:
            score += 8.0

    if "save" in domains:
        if "/save/" in p:
            score += 22.0
        if "/tests/" in p:
            score += 8.0

    if "combat" in domains:
        if "/combat/" in p:
            score += 20.0
        if "/skills/" in p:
            score += 8.0
        if "/tests/" in p:
            score += 7.0

    if "technical" in domains:
        if "/tests/" in p or "/scripts/" in p:
            score += 8.0
        if p.endswith("project.godot"):
            score += 6.0

    if "gameplay" in domains:
        if "/core/" in p:
            score += 9.0
        if "/tests/" in p:
            score += 6.0

    return score


def _world_map_bonus(relative: str, task: str) -> float:
    if not _is_world_map_task(task):
        return 0.0

    p = relative.casefold()
    score = 0.0

    # Strong preference for the current Godot world-map implementation.
    if p.startswith("godot/ui/screens/world_map/"):
        score += 42.0

    preferred_names = {
        "world_region_map.gd": 60.0,
        "world_map.gd": 55.0,
        "region_hover.gdshader": 52.0,
        "region_highlight.gdshaderinc": 50.0,
        "varenhold_valley.gdshader": 42.0,
        "test_world_map_interaction.gd": 58.0,
        "world_map.tscn": 38.0,
        "world_region_map.tscn": 38.0,
        "check.ps1": 14.0,
    }
    score += preferred_names.get(Path(p).name, 0.0)

    if p.startswith("godot/tests/") and "world_map" in p:
        score += 44.0

    # Legacy Python migration tests can contain many words like "region"
    # but are usually poor evidence for current Godot UI behavior.
    if p.startswith("tests/") and not p.startswith("godot/tests/"):
        score -= 55.0

    return score


def _path_token_score(path_text: str, terms: set[str]) -> float:
    normalized = path_text.casefold().replace("\\", "/")
    expanded_path = normalized.replace("/", " ").replace("_", " ")
    path_tokens = set(tokenize(expanded_path))
    score = 0.0

    for term in terms:
        folded = term.casefold()
        if folded in normalized:
            score += 13.0
        elif folded.replace("_", " ") in expanded_path:
            score += 9.0
        elif folded in path_tokens:
            score += 7.0

    return min(score, 72.0)


def _content_matches(
    lines: list[str],
    terms: set[str],
) -> tuple[float, tuple[int, ...]]:
    matched_lines: list[int] = []
    weighted_hits = 0.0

    useful = {
        token.casefold()
        for token in terms
        if len(token) >= 4 and token.casefold()
        not in {"gameplay", "visual", "world", "zmiana", "gry"}
    }

    for line_no, line in enumerate(lines, start=1):
        folded = line.casefold()
        hits = sum(1 for token in useful if token in folded)

        if hits:
            matched_lines.append(line_no)
            weighted_hits += min(hits, 4)

        if len(matched_lines) >= 80:
            break

    score = min(weighted_hits, 28.0) * 1.7
    return score, tuple(matched_lines)


def _iter_files():
    denied = {x.casefold() for x in DENIED_DIRS}

    for current_root, dirnames, filenames in os.walk(ROOT, followlinks=False):
        current_path = Path(current_root)

        dirnames[:] = [
            name for name in dirnames
            if name.casefold() not in denied
        ]

        for filename in filenames:
            path = current_path / filename
            if not _safe_text_file(path):
                continue
            try:
                if path.stat().st_size > MAX_SCAN_FILE_BYTES:
                    continue
            except OSError:
                continue
            yield path


def _rank_files(task: str) -> tuple[list[Candidate], int]:
    task_tokens = set(tokenize(task))
    terms = _expanded_terms(task)
    domains = detect_domains(task, task_tokens)

    candidates: list[Candidate] = []
    scanned = 0

    for path in _iter_files():
        scanned += 1
        relative = path.relative_to(ROOT).as_posix()

        score = _path_token_score(relative, terms)
        score += _domain_path_bonus("/" + relative, domains)
        score += _world_map_bonus(relative, task)

        try:
            text = path.read_text(encoding="utf-8")
        except (UnicodeDecodeError, OSError):
            continue

        lines = text.splitlines()
        content_score, matches = _content_matches(lines, terms)
        score += content_score

        rel_lower = relative.casefold()
        if "/tests/" in "/" + rel_lower:
            score += 2.5
        if rel_lower == "scripts/check.ps1":
            score += 3.0

        if score > 0:
            candidates.append(Candidate(path, score, matches))

    candidates.sort(
        key=lambda item: (
            -item.score,
            len(item.path.as_posix()),
            item.path.as_posix().casefold(),
        )
    )

    return candidates, scanned


def _merge_windows(
    centers: tuple[int, ...],
    total_lines: int,
    max_windows: int,
) -> list[tuple[int, int]]:
    if not centers:
        return [(1, min(total_lines, 55))] if total_lines else []

    windows: list[tuple[int, int]] = []

    for center in centers:
        start = max(1, center - 13)
        end = min(total_lines, center + 18)

        if windows and start <= windows[-1][1] + 5:
            old_start, old_end = windows[-1]
            windows[-1] = (old_start, max(old_end, end))
        else:
            windows.append((start, end))

        if len(windows) >= max_windows:
            break

    return windows


def _render_file(candidate: Candidate, remaining_chars: int) -> str:
    path = candidate.path
    relative = path.relative_to(ROOT).as_posix()

    try:
        lines = path.read_text(encoding="utf-8").splitlines()
    except (UnicodeDecodeError, OSError):
        return ""

    windows = _merge_windows(
        candidate.match_lines,
        len(lines),
        REPO_BRIEF_SNIPPETS_PER_FILE,
    )

    parts = [
        f'\n<REPO_FILE path="{relative}" score="{candidate.score:.2f}">\n'
    ]

    # Include compact file header when matched areas start later.
    if windows and windows[0][0] > 12:
        header_end = min(24, len(lines))
        parts.append(f"[header lines 1-{header_end}]\n")
        for idx in range(1, header_end + 1):
            line = lines[idx - 1]
            if len(line) > MAX_SNIPPET_LINE_LENGTH:
                line = line[:MAX_SNIPPET_LINE_LENGTH] + "…"
            parts.append(f"{idx:>5}: {line}\n")

    for start, end in windows:
        parts.append(f"[lines {start}-{end}]\n")
        for idx in range(start, end + 1):
            line = lines[idx - 1]
            if len(line) > MAX_SNIPPET_LINE_LENGTH:
                line = line[:MAX_SNIPPET_LINE_LENGTH] + "…"
            parts.append(f"{idx:>5}: {line}\n")

    parts.append("</REPO_FILE>\n")
    block = "".join(parts)

    if len(block) <= remaining_chars:
        return block

    if remaining_chars < 1000:
        return ""

    trimmed = block[: max(0, remaining_chars - 80)]
    return trimmed + "\n[REPO_FILE TRUNCATED]\n</REPO_FILE>\n"


def _promote_required_world_map_candidates(
    candidates: list[Candidate],
    task: str,
) -> list[Candidate]:
    """Ensure current Godot map evidence is preferred over legacy region tests."""
    if not _is_world_map_task(task):
        return candidates

    preferred = [
        "godot/ui/screens/world_map/world_region_map.gd",
        "godot/ui/screens/world_map/world_map.gd",
        "godot/ui/screens/world_map/region_hover.gdshader",
        "godot/ui/screens/world_map/region_highlight.gdshaderinc",
        "godot/ui/screens/world_map/varenhold_valley.gdshader",
        "godot/tests/test_world_map_interaction.gd",
    ]

    by_path = {
        item.path.relative_to(ROOT).as_posix(): item
        for item in candidates
    }

    promoted: list[Candidate] = []
    seen: set[str] = set()

    for relative in preferred:
        item = by_path.get(relative)
        if item is not None:
            promoted.append(item)
            seen.add(relative)

    for item in candidates:
        relative = item.path.relative_to(ROOT).as_posix()
        if relative not in seen:
            promoted.append(item)
            seen.add(relative)

    return promoted


def build_repo_brief(task: str) -> RepoBrief:
    branch, head, status = _preflight()
    candidates, scanned = _rank_files(task)
    candidates = _promote_required_world_map_candidates(candidates, task)

    preamble = (
        "<REPO_BRIEF>\n"
        f"branch: {branch}\n"
        f"head: {head}\n"
        "working_tree: CLEAN\n"
        f"task: {task}\n"
        f"locally_scanned_text_files: {scanned}\n"
        "\n"
        "IMPORTANT: This brief was produced locally without model tool calls. "
        "It contains bounded excerpts from selected repository files, "
        "not a complete repository dump.\n"
    )

    parts = [preamble]
    chosen_paths: list[str] = []

    for candidate in candidates:
        if len(chosen_paths) >= REPO_BRIEF_MAX_FILES:
            break

        used = sum(len(part) for part in parts)
        remaining = (
            REPO_BRIEF_MAX_CHARS
            - used
            - len("\n</REPO_BRIEF>\n")
        )
        if remaining <= 900:
            break

        block = _render_file(candidate, remaining)
        if not block:
            continue

        parts.append(block)
        chosen_paths.append(
            candidate.path.relative_to(ROOT).as_posix()
        )

    parts.append("\n</REPO_BRIEF>\n")
    text = "".join(parts)

    return RepoBrief(
        text=text,
        branch=branch,
        head=head,
        status=status,
        selected_files=tuple(chosen_paths),
        chars=len(text),
        scanned_files=scanned,
    )
