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
    ".git", ".venv", ".tools", ".godot", "output", "build", "dist",
    "__pycache__", ".pytest_cache", ".mypy_cache", ".ruff_cache",
}
ALLOWED_FILENAMES = {".gitignore", ".gitattributes"}
ALLOWED_SUFFIXES = {
    ".gd", ".gdshader", ".gdshaderinc", ".shader", ".tscn", ".tres",
    ".godot", ".uid", ".md", ".txt", ".json", ".py", ".ps1", ".cfg",
    ".ini", ".toml", ".yml", ".yaml", ".csv",
}
SECRET_NAMES = {".env", "export_credentials.cfg", "id_rsa", "id_ed25519"}
MAX_SCAN_FILE_BYTES = 750_000
MAX_LINE = 320


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
    selected_files: tuple[str, ...]
    chars: int
    scanned_files: int


class BriefError(RuntimeError):
    pass


def _git(args: list[str]) -> str:
    result = subprocess.run(
        ["git", *args], cwd=ROOT, capture_output=True, text=True,
        encoding="utf-8", errors="replace", timeout=20, check=False,
    )
    if result.returncode != 0:
        raise BriefError(f"git {' '.join(args)} failed: {result.stderr.strip()}")
    return result.stdout.strip()


def _preflight() -> tuple[str, str]:
    branch = _git(["branch", "--show-current"])
    head = _git(["rev-parse", "HEAD"])
    status = _git(["status", "--short"])
    if branch == "snapshot/pre-ai-team-2026-09-10" or branch in {"main", "master"} or branch.startswith("release/"):
        raise BriefError(f"Protected branch is active: {branch}")
    if status:
        raise BriefError(
            "Working tree is not clean. Stage 2.1 refuses paid model calls.\n" + status[:5000]
        )
    return branch, head


def _safe_text_file(path: Path) -> bool:
    try:
        rel = path.resolve().relative_to(ROOT)
    except (ValueError, OSError):
        return False
    denied = {x.casefold() for x in DENIED_DIRS}
    if any(part.casefold() in denied for part in rel.parts):
        return False
    name = path.name.casefold()
    if name in {x.casefold() for x in SECRET_NAMES} or name.startswith(".env"):
        return False
    if path.suffix.casefold() in {".pem", ".key", ".pfx", ".p12"}:
        return False
    return name in ALLOWED_FILENAMES or path.suffix.casefold() in ALLOWED_SUFFIXES


def _domain_bonus(path_text: str, domains: set[str]) -> float:
    p = "/" + path_text.casefold()
    score = 0.0
    if "ui" in domains:
        score += 18 if "/ui/" in p else 0
        score += 6 if "/screens/" in p or "/components/" in p else 0
        score += 7 if "/tests/" in p else 0
    if "art" in domains:
        score += 16 if "/assets/" in p else 0
        score += 8 if "manifest" in p else 0
    if "save" in domains:
        score += 22 if "/save/" in p else 0
        score += 8 if "/tests/" in p else 0
    if "combat" in domains:
        score += 20 if "/combat/" in p else 0
        score += 8 if "/skills/" in p else 0
        score += 7 if "/tests/" in p else 0
    if "technical" in domains:
        score += 8 if "/tests/" in p or "/scripts/" in p else 0
        score += 6 if p.endswith("project.godot") else 0
    if "gameplay" in domains:
        score += 9 if "/core/" in p else 0
        score += 6 if "/tests/" in p else 0
    return score


def _content_score(lines: list[str], tokens: set[str]) -> tuple[float, tuple[int, ...]]:
    useful = {t for t in tokens if len(t) >= 4 and t not in {"gameplay", "visual", "world"}}
    matched = []
    weighted = 0
    for number, line in enumerate(lines, 1):
        folded = line.casefold()
        hits = sum(1 for token in useful if token in folded)
        if hits:
            matched.append(number)
            weighted += min(hits, 4)
        if len(matched) >= 80:
            break
    return min(weighted, 24) * 1.7, tuple(matched)


def _files():
    denied = {x.casefold() for x in DENIED_DIRS}
    for current_root, dirnames, filenames in os.walk(ROOT, followlinks=False):
        dirnames[:] = [d for d in dirnames if d.casefold() not in denied]
        base = Path(current_root)
        for filename in filenames:
            path = base / filename
            if not _safe_text_file(path):
                continue
            try:
                if path.stat().st_size > MAX_SCAN_FILE_BYTES:
                    continue
            except OSError:
                continue
            yield path


def _rank(task: str) -> tuple[list[Candidate], int]:
    task_tokens = tokenize(task)
    domains = detect_domains(task, task_tokens)
    candidates = []
    scanned = 0
    for path in _files():
        scanned += 1
        rel = path.relative_to(ROOT).as_posix()
        path_tokens = tokenize(rel.replace("/", " ").replace("_", " "))
        score = len(task_tokens & path_tokens) * 15.0 + _domain_bonus(rel, domains)
        try:
            lines = path.read_text(encoding="utf-8").splitlines()
        except (UnicodeDecodeError, OSError):
            continue
        content_score, matches = _content_score(lines, task_tokens)
        score += content_score
        if "/tests/" in "/" + rel.casefold():
            score += 2.5
        if rel.casefold() == "scripts/check.ps1":
            score += 3.0
        if score > 0:
            candidates.append(Candidate(path, score, matches))
    candidates.sort(key=lambda c: (-c.score, len(c.path.as_posix()), c.path.as_posix().casefold()))
    return candidates, scanned


def _windows(centers: tuple[int, ...], total: int) -> list[tuple[int, int]]:
    if not centers:
        return [(1, min(total, 55))] if total else []
    result = []
    for center in centers:
        start, end = max(1, center - 13), min(total, center + 18)
        if result and start <= result[-1][1] + 5:
            result[-1] = (result[-1][0], max(result[-1][1], end))
        else:
            result.append((start, end))
        if len(result) >= REPO_BRIEF_SNIPPETS_PER_FILE:
            break
    return result


def _render(candidate: Candidate, remaining: int) -> str:
    rel = candidate.path.relative_to(ROOT).as_posix()
    try:
        lines = candidate.path.read_text(encoding="utf-8").splitlines()
    except (UnicodeDecodeError, OSError):
        return ""
    windows = _windows(candidate.match_lines, len(lines))
    parts = [f'\n<REPO_FILE path="{rel}" score="{candidate.score:.2f}">\n']
    if windows and windows[0][0] > 12:
        end = min(24, len(lines))
        parts.append(f"[header lines 1-{end}]\n")
        for idx in range(1, end + 1):
            line = lines[idx-1]
            parts.append(f"{idx:>5}: {line[:MAX_LINE]}{'…' if len(line) > MAX_LINE else ''}\n")
    for start, end in windows:
        parts.append(f"[lines {start}-{end}]\n")
        for idx in range(start, end + 1):
            line = lines[idx-1]
            parts.append(f"{idx:>5}: {line[:MAX_LINE]}{'…' if len(line) > MAX_LINE else ''}\n")
    parts.append("</REPO_FILE>\n")
    block = "".join(parts)
    if len(block) <= remaining:
        return block
    if remaining < 1000:
        return ""
    return block[:remaining-80] + "\n[REPO_FILE TRUNCATED]\n</REPO_FILE>\n"


def build_repo_brief(task: str) -> RepoBrief:
    branch, head = _preflight()
    candidates, scanned = _rank(task)
    parts = [
        "<REPO_BRIEF>\n",
        f"branch: {branch}\nhead: {head}\nworking_tree: CLEAN\n",
        f"task: {task}\nlocally_scanned_text_files: {scanned}\n",
        "This brief was produced locally with zero model tool calls.\n",
    ]
    chosen = []
    for candidate in candidates:
        if len(chosen) >= REPO_BRIEF_MAX_FILES:
            break
        used = sum(len(part) for part in parts)
        remaining = REPO_BRIEF_MAX_CHARS - used - 20
        block = _render(candidate, remaining)
        if block:
            parts.append(block)
            chosen.append(candidate.path.relative_to(ROOT).as_posix())
    parts.append("\n</REPO_BRIEF>\n")
    text = "".join(parts)
    return RepoBrief(text, branch, head, tuple(chosen), len(text), scanned)
