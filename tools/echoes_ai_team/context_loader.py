from __future__ import annotations

from dataclasses import dataclass

from config import CONTEXT_FILES, CONTEXT_MAX_CHARS, CONTEXT_MAX_SECTIONS, REPO_ROOT
from context_router import SelectedSection, select_sections

@dataclass(frozen=True)
class ContextPack:
    text: str
    source_chars: int
    selected_chars: int
    selected_sections: tuple[SelectedSection, ...]
    @property
    def reduction_percent(self) -> float:
        if self.source_chars <= 0:
            return 0.0
        return 100.0 * (1.0 - self.selected_chars / self.source_chars)

def _load_documents() -> dict[str, str]:
    context_dir = REPO_ROOT / "AI_CONTEXT"
    missing = [name for name in CONTEXT_FILES if not (context_dir / name).is_file()]
    if missing:
        formatted = "\n".join(f" - {name}" for name in missing)
        raise FileNotFoundError(
            "Brakuje wymaganych plików AI_CONTEXT:\n"
            f"{formatted}\nOczekiwany katalog: {context_dir}"
        )
    return {name: (context_dir / name).read_text(encoding="utf-8") for name in CONTEXT_FILES}

def load_project_context(task: str) -> ContextPack:
    documents = _load_documents()
    text, selected, source_chars = select_sections(
        task, documents, CONTEXT_MAX_CHARS, CONTEXT_MAX_SECTIONS
    )
    return ContextPack(text, source_chars, len(text), tuple(selected))
