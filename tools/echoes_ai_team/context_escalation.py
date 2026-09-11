from __future__ import annotations

import json
import os
import re
from dataclasses import dataclass
from pathlib import Path

from config import REPO_ROOT
from repo_brief import RepoBrief
from write_schemas import ChangeProposal


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
}

SAFE_SUFFIXES = {
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

PATH_RE = re.compile(
    r"""(?P<path>(?:[A-Za-z0-9_.-]+/)+[A-Za-z0-9_.-]+\.
    (?:gd|gdshader|gdshaderinc|shader|tscn|tres|godot|md|txt|json|py|ps1|cfg|ini|toml|yml|yaml|csv))""",
    re.VERBOSE | re.IGNORECASE,
)

BASENAME_RE = re.compile(
    r"\b[A-Za-z0-9_.-]+\.(?:gd|gdshader|gdshaderinc|shader|tscn|tres|py|ps1)\b",
    re.IGNORECASE,
)


class EscalationError(RuntimeError):
    pass


@dataclass(frozen=True)
class EscalatedBrief:
    text: str
    selected_files: tuple[str, ...]
    expanded_files: tuple[str, ...]
    base_chars: int
    added_chars: int
    chars: int


def _max_chars() -> int:
    return int(os.getenv("EOP_ESCALATED_BRIEF_MAX_CHARS", "45000"))


def _max_files() -> int:
    return int(os.getenv("EOP_ESCALATED_MAX_FILES", "2"))


def _safe_path(relative: str) -> Path | None:
    normalized = relative.replace("\\", "/").lstrip("/")
    candidate = (ROOT / normalized).resolve()
    try:
        rel = candidate.relative_to(ROOT)
    except ValueError:
        return None

    if any(part.casefold() in DENIED_DIRS for part in rel.parts):
        return None
    if candidate.suffix.casefold() not in SAFE_SUFFIXES:
        return None
    if not candidate.exists() or not candidate.is_file():
        return None
    return candidate


def _proposal_text(proposal: ChangeProposal) -> str:
    parts = [proposal.summary, proposal.human_question]
    for evidence in proposal.repo_evidence:
        parts.append(evidence.path)
        parts.append(evidence.finding)
    parts.extend(proposal.risks)
    return "\n".join(x for x in parts if x)


def _requested_paths(
    base_brief: RepoBrief,
    proposal: ChangeProposal,
) -> list[str]:
    text = _proposal_text(proposal)
    selected = list(base_brief.selected_files)
    selected_set = set(selected)
    ordered: list[str] = []

    def add(relative: str) -> None:
        relative = relative.replace("\\", "/").strip()
        if not relative or relative in ordered:
            return
        if _safe_path(relative) is None:
            return
        ordered.append(relative)

    # Najpierw respektuj dok?adne pliki, o kt?re Developer poprosi?
    # w blockerze / human_question. To jest najsilniejszy sygna?,
    # jaki dodatkowy kontekst faktycznie odblokuje retry.
    for match in PATH_RE.finditer(text):
        add(match.group("path"))

    # Dopiero potem dodawaj og?lne repo_evidence z pierwszej pr?by.
    for evidence in proposal.repo_evidence:
        add(evidence.path)

    basenames = {
        match.group(0).casefold()
        for match in BASENAME_RE.finditer(text)
    }
    if basenames:
        for relative in selected:
            if Path(relative).name.casefold() in basenames:
                add(relative)

    if not ordered:
        for relative in selected[: _max_files()]:
            add(relative)

    ranked = [p for p in ordered if p in selected_set]
    ranked.extend(p for p in ordered if p not in selected_set)
    return ranked[: _max_files()]


def _needles(task: str, proposal: ChangeProposal) -> list[str]:
    raw = "\n".join([task, _proposal_text(proposal)])
    tokens = re.findall(r"[A-Za-z_][A-Za-z0-9_]{3,}", raw)
    stop = {
        "godot", "world", "mapie", "mapa", "task", "brief", "repo",
        "file", "path", "without", "zmiany", "zmiana", "mechanik",
        "regionu", "region", "oraz", "jego", "przy", "przez",
    }
    result: list[str] = []
    for token in tokens:
        folded = token.casefold()
        if folded in stop:
            continue
        if folded not in result:
            result.append(folded)
        if len(result) >= 36:
            break
    return result


def _focused_excerpt(
    relative: str,
    path: Path,
    task: str,
    proposal: ChangeProposal,
    budget: int,
) -> str:
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    needles = _needles(task, proposal)

    centers: list[int] = []
    for idx, line in enumerate(lines):
        folded = line.casefold()
        if any(needle in folded for needle in needles):
            centers.append(idx)
        if len(centers) >= 10:
            break

    if not centers:
        centers = [0]

    windows: list[tuple[int, int]] = []
    for center in centers:
        start = max(0, center - 18)
        end = min(len(lines), center + 28)
        if windows and start <= windows[-1][1] + 5:
            old_start, old_end = windows[-1]
            windows[-1] = (old_start, max(old_end, end))
        else:
            windows.append((start, end))
        if len(windows) >= 4:
            break

    parts = [f'\n<ESCALATED_REPO_FILE path="{relative}" mode="focused">\n']
    for start, end in windows:
        parts.append(f"[lines {start + 1}-{end}]\n")
        for idx in range(start, end):
            parts.append(f"{idx + 1:>5}: {lines[idx]}\n")
    parts.append("</ESCALATED_REPO_FILE>\n")
    block = "".join(parts)

    if len(block) <= budget:
        return block
    if budget < 900:
        return ""
    return block[: budget - 80] + "\n[ESCALATED FILE TRUNCATED]\n</ESCALATED_REPO_FILE>\n"


def _render_expansion(
    relative: str,
    task: str,
    proposal: ChangeProposal,
    budget: int,
) -> str:
    path = _safe_path(relative)
    if path is None:
        return ""

    content = path.read_text(encoding="utf-8", errors="replace")
    full = (
        f'\n<ESCALATED_REPO_FILE path="{relative}" mode="full">\n'
        + content
        + ("\n" if not content.endswith("\n") else "")
        + "</ESCALATED_REPO_FILE>\n"
    )
    if len(full) <= budget:
        return full
    return _focused_excerpt(relative, path, task, proposal, budget)


def build_escalated_brief(
    task: str,
    base_brief: RepoBrief,
    proposal: ChangeProposal,
) -> EscalatedBrief:
    if proposal.status != "BLOCKED":
        raise EscalationError("Escalation requires a BLOCKED developer proposal.")

    max_chars = _max_chars()
    if max_chars < base_brief.chars + 1500:
        raise EscalationError(
            "EOP_ESCALATED_BRIEF_MAX_CHARS is too small for useful escalation."
        )

    requested = _requested_paths(base_brief, proposal)
    if not requested:
        raise EscalationError(
            "The blocked proposal did not identify any safe file to expand."
        )

    header = (
        "\n\n<CONTEXT_ESCALATION>\n"
        "The first Developer attempt returned BLOCKED because context was insufficient.\n"
        "The local controller expanded only safe existing repository files named by the blocker.\n"
        "Use this added evidence together with the original REPO_BRIEF.\n"
        f"blocked_summary: {proposal.summary}\n"
        f"blocked_question: {proposal.human_question}\n"
    )

    parts = [base_brief.text, header]
    expanded: list[str] = []

    for relative in requested:
        used = sum(len(part) for part in parts)
        remaining = max_chars - used - len("\n</CONTEXT_ESCALATION>\n")
        if remaining <= 900:
            break
        block = _render_expansion(relative, task, proposal, remaining)
        if not block:
            continue
        parts.append(block)
        expanded.append(relative)

    parts.append("\n</CONTEXT_ESCALATION>\n")
    text = "".join(parts)

    if not expanded:
        raise EscalationError("No safe file could be expanded within the context budget.")

    selected = list(base_brief.selected_files)
    for relative in expanded:
        if relative not in selected:
            selected.append(relative)

    return EscalatedBrief(
        text=text,
        selected_files=tuple(selected),
        expanded_files=tuple(expanded),
        base_chars=base_brief.chars,
        added_chars=max(0, len(text) - base_brief.chars),
        chars=len(text),
    )


def find_latest_blocked_run(task: str | None = None) -> tuple[Path, ChangeProposal]:
    root = ROOT / "output" / "ai-team"
    candidates = sorted(
        [p for p in root.glob("WRITE-*") if p.is_dir()],
        key=lambda p: p.stat().st_mtime,
        reverse=True,
    )

    for run_dir in candidates:
        proposal_path = run_dir / "developer_proposal.json"
        task_path = run_dir / "task.txt"
        if not proposal_path.exists() or not task_path.exists():
            continue

        if task is not None:
            stored_task = task_path.read_text(encoding="utf-8").strip()
            if stored_task != task.strip():
                continue

        try:
            data = json.loads(proposal_path.read_text(encoding="utf-8"))
            proposal = ChangeProposal.model_validate(data)
        except Exception:
            continue

        if proposal.status == "BLOCKED":
            return run_dir, proposal

    raise EscalationError(
        "No matching BLOCKED Stage 3 run was found in output/ai-team/WRITE-*."
    )
