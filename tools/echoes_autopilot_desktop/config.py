from __future__ import annotations

import json
import os
import shutil
from dataclasses import asdict, dataclass, field
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
OUTPUT_ROOT = REPO_ROOT / "output" / "ai-team"
CONFIG_PATH = OUTPUT_ROOT / "settings.json"
SCENARIOS = (
    "main_menu", "class_selection", "city", "inn", "merchant", "equipment",
    "world_map", "combat_wolf", "combat_ice_crab", "guild", "black_market",
)


def find_program(name: str, candidates=()) -> str:
    found = shutil.which(name)
    if found:
        return found
    return next((str(p) for p in candidates if p.is_file()), "")


@dataclass
class Settings:
    developer_model: str = "gpt-6-astra"
    reviewer_model: str = "gpt-5.6-sol"
    reasoning: str = "high"
    codex: str = ""
    godot: str = ""
    powershell: str = ""
    max_cycles: int = 2
    agent_timeout: int = 900
    check_timeout: int = 1800
    capture_timeout: int = 240
    image_batch_size: int = 4
    isolated_workspace: bool = False
    branch: str = ''
    include_local_changes: bool = True
    gameplay_journeys: bool = True
    focused_iterations: bool = True
    scenarios: list[str] = field(default_factory=lambda: list(SCENARIOS))
    resolutions: list[list[int]] = field(default_factory=lambda: [[1280, 720], [1920, 1080]])

    def resolve_tools(self, root: Path = REPO_ROOT) -> None:
        profile = Path(os.environ.get("USERPROFILE", str(Path.home())))
        self.codex = self.codex or find_program("codex", sorted(
            (profile / "AppData/Local/OpenAI/Codex/bin").glob("*/codex.exe"),
            key=lambda p: p.stat().st_mtime, reverse=True))
        self.godot = self.godot or find_program("godot", sorted(
            (root / ".tools/godot").glob("*console.exe"), reverse=True))
        self.powershell = self.powershell or find_program("pwsh", [
            profile / ".cache/codex-runtimes/codex-primary-runtime/dependencies/native/powershell/pwsh.exe",
            Path("C:/Program Files/PowerShell/7/pwsh.exe"),
        ])

    def validate(self) -> None:
        if not isinstance(self.branch, str) or self.branch.startswith('-') or any(c in self.branch for c in '\r\n\0'):
            raise ValueError('Nieprawidłowy branch.')
        for name in ('isolated_workspace', 'include_local_changes', 'gameplay_journeys', 'focused_iterations'):
            if type(getattr(self, name)) is not bool:
                raise ValueError('Ustawienie musi być logiczne: ' + name)
        if not 1 <= self.max_cycles <= 5:
            raise ValueError("Liczba cykli musi wynosić 1–5.")
        if not 1 <= self.image_batch_size <= 4:
            raise ValueError("Paczka może obejmować 1–4 sceny (do 8 obrazów przed/po).")
        if not self.scenarios or len(set(self.scenarios)) != len(self.scenarios):
            raise ValueError("Wybierz co najmniej jeden scenariusz, bez powtórzeń.")
        if set(self.scenarios) - set(SCENARIOS):
            raise ValueError("Nieznany scenariusz.")
        if not self.resolutions or len(self.resolutions) > 4:
            raise ValueError("Wybierz od 1 do 4 rozdzielczości.")
        if any(len(r) != 2 or any(type(v) is not int or not 320 <= v <= 3840 for v in r)
               for r in self.resolutions):
            raise ValueError("Nieprawidłowa rozdzielczość.")
        if len({tuple(r) for r in self.resolutions}) != len(self.resolutions):
            raise ValueError("Rozdzielczości nie mogą się powtarzać.")
        if any(type(v) is not int or not 10 <= v <= 7200 for v in
               (self.agent_timeout, self.check_timeout, self.capture_timeout)):
            raise ValueError("Limit etapu musi wynosić 10–7200 sekund.")
        if not self.developer_model.strip() or not self.reviewer_model.strip():
            raise ValueError("Uzupełnij nazwy modeli.")


def write_json(path: Path, value) -> None:
    import tempfile
    import time
    path.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.NamedTemporaryFile(mode="w", encoding="utf-8", dir=path.parent,
                                     prefix=path.name + ".", suffix=".tmp", delete=False) as handle:
        temporary = Path(handle.name)
        json.dump(value, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())
    try:
        for attempt in range(10):
            try:
                os.replace(temporary, path)
                break
            except PermissionError:
                if attempt == 9:
                    raise
                # OneDrive, antivirus and report readers may briefly hold a Windows handle.
                time.sleep(0.1 * (attempt + 1))
    finally:
        temporary.unlink(missing_ok=True)


def load_settings(path: Path = CONFIG_PATH, root: Path = REPO_ROOT) -> Settings:
    data = json.loads(path.read_text(encoding="utf-8")) if path.exists() else {}
    unknown = set(data) - set(Settings.__dataclass_fields__)
    if unknown:
        raise ValueError(f"Nieznane ustawienia: {sorted(unknown)}")
    settings = Settings(**data)
    settings.resolve_tools(root)
    settings.validate()
    return settings


def save_settings(settings: Settings) -> None:
    settings.validate()
    write_json(CONFIG_PATH, asdict(settings))
