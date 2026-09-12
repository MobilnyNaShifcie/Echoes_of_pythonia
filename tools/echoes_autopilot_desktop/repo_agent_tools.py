"""Controller-owned exact edits, adapted from the supplied Autopilot v1.1.

Models inspect through Codex's read-only tools. They never apply their own edits.
No branch switch, git reset, commit, push or external publication happens here.
"""
from __future__ import annotations

import difflib
import hashlib
import json
import os
import re
import subprocess
from pathlib import Path, PurePosixPath

try:
    from .config import write_json
except ImportError:
    from config import write_json

EDIT_ROOTS = ("godot/core/", "godot/ui/", "godot/scenes/", "godot/assets/",
              "godot/tests/", "docs/", "tests/")
EDIT_FILES = {"AI_CONTEXT/ART_DIRECTION.md", "godot/project.godot", "scripts/check-city-assets.ps1",
              "scripts/check-item-assets.ps1", "scripts/check-skill-card-assets.ps1",
              "scripts/normalize-city-assets.ps1", "scripts/normalize-item-assets.ps1",
              "scripts/build_art_reference_board.py"}
SUFFIXES = {".gd", ".gdshader", ".gdshaderinc", ".tscn", ".tres", ".svg",
            ".md", ".txt", ".json", ".cfg", ".csv", ".py", ".godot", ".ps1"}


class AutopilotError(RuntimeError):
    pass


def safe_edit_path(root: Path, relative: str) -> Path:
    raw = relative.replace("\\", "/")
    parts = PurePosixPath(raw).parts
    if (not raw or raw != raw.strip() or raw.startswith("/") or ":" in raw
            or any(p in {".", ".."} or p.startswith(".") or p.endswith((".", " ")) for p in parts)
            or "//" in raw):
        raise AutopilotError(f"Niedozwolona ścieżka: {relative}")
    if raw not in EDIT_FILES and not raw.startswith(EDIT_ROOTS):
        raise AutopilotError(f"Plik poza zakresem automatycznych zmian: {relative}")
    if any(re.fullmatch(r"(?i)(con|prn|aux|nul|com[1-9]|lpt[1-9])(?:\..*)?", p) for p in parts):
        raise AutopilotError("Niedozwolona nazwa urządzenia Windows.")
    target = root.joinpath(*parts)
    for part in (target, *target.parents):
        if part == root:
            break
        if part.is_symlink() or (hasattr(part, "is_junction") and part.is_junction()):
            raise AutopilotError("Dowiązania nie mogą być celami zmian.")
    if not target.resolve().is_relative_to(root.resolve()):
        raise AutopilotError("Ścieżka wychodzi poza projekt.")
    if target.suffix.lower() not in SUFFIXES or target.name.lower().startswith(".env"):
        raise AutopilotError(f"Nieobsługiwany plik: {relative}")
    if target.exists() and (not target.is_file() or target.stat().st_size > 2_000_000):
        raise AutopilotError(f"Plik nie jest małym plikiem tekstowym: {relative}")
    return target


def file_hash(path: Path) -> str | None:
    if not path.is_file():
        return None
    with path.open('rb') as handle:
        return hashlib.file_digest(handle, 'sha256').hexdigest()


def source_snapshot(root: Path) -> dict[str, str]:
    """Include current uncommitted/new text sources, never assume a clean checkout."""
    result = {}
    candidates = set()
    for folder in EDIT_ROOTS:
        directory = root / folder
        if directory.exists():
            candidates.update(directory.rglob("*"))
    candidates.update(root / relative for relative in EDIT_FILES)
    for path in sorted(candidates):
        if not path.is_file():
            continue
        relative = path.relative_to(root).as_posix()
        if path.suffix.lower() in {'.png', '.jpg', '.jpeg', '.webp', '.wav', '.ogg', '.glb'}:
            if not path.is_symlink() and path.resolve().is_relative_to(root.resolve()):
                result[relative] = file_hash(path)
            continue
        if path.suffix.lower() not in SUFFIXES:
            continue
        try:
            safe_edit_path(root, relative)
            path.read_bytes().decode("utf-8")
            result[relative] = file_hash(path)
        except (AutopilotError, UnicodeDecodeError):
            continue
    return result


def exact_replace(text: str, old: str, new: str) -> str:
    if not old:
        raise AutopilotError("Pusta kotwica zamiany.")
    old = old.replace("\r\n", "\n")
    new = new.replace("\r\n", "\n")
    pattern = re.escape(old).replace(re.escape("\n"), r"\r?\n")
    matches = list(re.finditer(pattern, text))
    if len(matches) != 1:
        raise AutopilotError("Kotwica musi występować dokładnie raz w pliku.")
    match = matches[0]
    newline = "\r\n" if "\r\n" in match.group() or ("\n" not in old and "\r\n" in text) else "\n"
    return text[:match.start()] + new.replace("\n", newline) + text[match.end():]


def apply_proposal(root: Path, proposal: dict, snapshot: dict, backup: Path) -> str:
    if proposal.get("status") != "READY_TO_APPLY":
        raise AutopilotError(proposal.get("summary", "Developer nie przygotował zmian."))
    edits = proposal.get("edits")
    if not isinstance(edits, list) or not 1 <= len(edits) <= 16:
        raise AutopilotError("Propozycja musi zmieniać od 1 do 16 plików.")
    original, prepared, seen = {}, {}, set()
    for edit in edits:
        path = safe_edit_path(root, edit["path"])
        key = str(path).casefold()
        if key in seen:
            raise AutopilotError("Powtórzony plik w propozycji.")
        seen.add(key)
        relative = path.relative_to(root).as_posix()
        if file_hash(path) != snapshot.get(relative):
            raise AutopilotError(f"Plik zmienił się podczas pracy AI: {relative}")
        previous = path.read_bytes() if path.exists() else None
        original[path] = previous
        if edit["operation"] == "create":
            if previous is not None or edit.get("replacements"):
                raise AutopilotError("Utworzenie wymaga nieistniejącego pliku bez zamian.")
            updated = edit["content"]
        elif edit["operation"] == "replace":
            if previous is None or not 1 <= len(edit["replacements"]) <= 20 or edit["content"]:
                raise AutopilotError("Zamiana wymaga istniejącego pliku i kotwic.")
            updated = previous.decode("utf-8")
            for replacement in edit["replacements"]:
                updated = exact_replace(updated, replacement["old_text"], replacement["new_text"])
        else:
            raise AutopilotError("Nieznana operacja.")
        if not updated.strip() or "\x00" in updated:
            raise AutopilotError("Zmiana tworzy pusty lub binarny plik.")
        prepared[path] = updated.encode("utf-8")
    if sum(len(data) for data in prepared.values()) > 400_000:
        raise AutopilotError("Propozycja jest za duża; podziel zadanie.")
    diff = "".join("".join(difflib.unified_diff(
        (original[p] or b"").decode("utf-8").splitlines(keepends=True),
        content.decode("utf-8").splitlines(keepends=True),
        fromfile="a/" + p.relative_to(root).as_posix(),
        tofile="b/" + p.relative_to(root).as_posix())) for p, content in prepared.items())
    if not diff:
        raise AutopilotError("Propozycja nie zmienia zawartości plików.")
    backup.mkdir(parents=True, exist_ok=True)
    for path, content in original.items():
        if content is not None:
            copy = backup / path.relative_to(root)
            copy.parent.mkdir(parents=True, exist_ok=True)
            copy.write_bytes(content)
    write_json(backup / "manifest.json", {
        p.relative_to(root).as_posix(): {"existed": original[p] is not None,
            "before": snapshot.get(p.relative_to(root).as_posix()),
            "after": hashlib.sha256(prepared[p]).hexdigest()} for p in prepared})
    written = []
    try:
        for path, content in prepared.items():
            if file_hash(path) != snapshot.get(path.relative_to(root).as_posix()):
                raise AutopilotError("Równoległa edycja pliku. Zatrzymano zapis.")
            path.parent.mkdir(parents=True, exist_ok=True)
            temporary = path.with_name(path.name + ".autopilot-tmp")
            with temporary.open("xb") as handle:
                handle.write(content)
            try:
                os.replace(temporary, path)
            finally:
                temporary.unlink(missing_ok=True)
            written.append(path)
    except Exception:
        for path in written:
            # Never overwrite an external edit made after our own write.
            if path.read_bytes() == prepared[path]:
                if original[path] is None:
                    path.unlink()
                else:
                    path.write_bytes(original[path])
        raise
    (backup / "applied.diff").write_text(diff, encoding="utf-8")
    return diff


def git_context(root: Path) -> dict:
    result = {}
    for key, arguments in (("branch", ["branch", "--show-current"]),
                           ("head", ["rev-parse", "HEAD"]),
                           ("status", ["status", "--short"])):
        cp = subprocess.run(["git", "-C", str(root), *arguments], capture_output=True,
                            text=True, encoding="utf-8", errors="replace", timeout=15,
                            creationflags=subprocess.CREATE_NO_WINDOW if os.name == "nt" else 0)
        result[key] = cp.stdout.strip() if cp.returncode == 0 else "unavailable"
    return result


def cumulative_diff(root: Path, directory: Path) -> str:
    """Compare the first backup with the current files, including created files."""
    originals = {}
    for manifest in sorted(directory.glob("cycle-*/backup/manifest.json")):
        for relative, info in json.loads(manifest.read_text(encoding="utf-8")).items():
            path = safe_edit_path(root, relative)
            if path not in originals:
                originals[path] = ((manifest.parent / relative).read_bytes()
                                   if info["existed"] else b"")
    return "".join("".join(difflib.unified_diff(
        original.decode("utf-8").replace("\r\n", "\n").splitlines(keepends=True),
        path.read_text(encoding="utf-8").splitlines(keepends=True),
        fromfile="a/" + path.relative_to(root).as_posix(),
        tofile="b/" + path.relative_to(root).as_posix())) for path, original in originals.items())
