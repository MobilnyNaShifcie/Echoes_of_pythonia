from __future__ import annotations

import os
from pathlib import Path

THIS_DIR = Path(__file__).resolve().parent
REPO_ROOT = THIS_DIR.parent.parent
ENV_FILE = THIS_DIR / ".env"

CONTEXT_FILES = (
    "PROJECT_BIBLE.md",
    "GAME_DESIGN.md",
    "TECHNICAL_RULES.md",
    "UI_RULES.md",
    "ART_DIRECTION.md",
    "AI_WORKFLOW.md",
)


def _unquote(value: str) -> str:
    value = value.strip()
    if len(value) >= 2 and value[0] == value[-1] and value[0] in {"'", '"'}:
        return value[1:-1]
    return value


def load_local_env() -> None:
    if not ENV_FILE.exists():
        return
    for raw_line in ENV_FILE.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        if key:
            os.environ.setdefault(key, _unquote(value))


load_local_env()

DEVELOPER_MODEL = os.getenv("EOP_DEVELOPER_MODEL", "gpt-6-astra").strip()
REVIEWER_MODEL = os.getenv("EOP_REVIEWER_MODEL", "gpt-5.6-sol").strip()
DEVELOPER_REASONING = os.getenv("EOP_DEVELOPER_REASONING", "medium").strip()
REVIEWER_REASONING = os.getenv("EOP_REVIEWER_REASONING", "medium").strip()
MAX_REVIEW_ROUNDS = int(os.getenv("EOP_MAX_REVIEW_ROUNDS", "4"))
CONTEXT_MAX_CHARS = int(os.getenv("EOP_CONTEXT_MAX_CHARS", "22000"))
CONTEXT_MAX_SECTIONS = int(os.getenv("EOP_CONTEXT_MAX_SECTIONS", "18"))
REPO_BRIEF_MAX_CHARS = int(os.getenv("EOP_REPO_BRIEF_MAX_CHARS", "26000"))
REPO_BRIEF_MAX_FILES = int(os.getenv("EOP_REPO_BRIEF_MAX_FILES", "8"))
REPO_BRIEF_SNIPPETS_PER_FILE = int(os.getenv("EOP_REPO_BRIEF_SNIPPETS_PER_FILE", "2"))
MAX_MODEL_CALLS_PER_TASK = int(os.getenv("EOP_MAX_MODEL_CALLS_PER_TASK", "4"))
