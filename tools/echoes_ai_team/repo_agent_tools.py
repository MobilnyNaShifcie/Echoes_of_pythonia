from __future__ import annotations

import json
import os
import re
import subprocess
from pathlib import Path
from typing import Any

from config import REPO_ROOT

ROOT = REPO_ROOT.resolve()

SAFE_SUFFIXES = {
    ".gd", ".gdshader", ".gdshaderinc", ".shader", ".tscn", ".tres",
    ".godot", ".md", ".txt", ".json", ".py", ".ps1", ".cfg", ".ini",
    ".toml", ".yml", ".yaml", ".csv",
}
DENIED_NAMES = {".env", "export_credentials.cfg", "id_rsa", "id_ed25519"}
MAX_FILE_BYTES = 900_000


class RepoToolError(RuntimeError):
    pass


def _git(args: list[str]) -> str:
    cp = subprocess.run(
        ["git", *args],
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
        timeout=30,
    )
    if cp.returncode != 0:
        raise RepoToolError(cp.stderr.strip() or cp.stdout.strip())
    return cp.stdout


def _tracked_files() -> tuple[str, ...]:
    items = []
    for raw in _git(["ls-files"]).splitlines():
        rel = raw.strip().replace("\\", "/")
        if not rel:
            continue
        path = ROOT / rel
        if _safe_text_path(rel, must_exist=True) is not None:
            items.append(rel)
    return tuple(items)


def _safe_text_path(relative: str, *, must_exist: bool) -> Path | None:
    raw = (relative or "").replace("\\", "/").strip().lstrip("/")
    if not raw or ".." in Path(raw).parts:
        return None
    path = (ROOT / raw).resolve()
    try:
        rel = path.relative_to(ROOT)
    except ValueError:
        return None

    name = path.name.casefold()
    if name in {x.casefold() for x in DENIED_NAMES} or name.startswith(".env"):
        return None
    if path.suffix.casefold() not in SAFE_SUFFIXES:
        return None
    if must_exist and (not path.exists() or not path.is_file()):
        return None
    if path.exists() and path.is_symlink():
        return None
    try:
        if path.exists() and path.stat().st_size > MAX_FILE_BYTES:
            return None
    except OSError:
        return None
    return path


def _parse_read_spec(spec: str) -> tuple[str, int | None, int | None]:
    raw = spec.strip().replace("\\", "/")
    match = re.fullmatch(r"(.+?)@(\d+):(\d+)", raw)
    if not match:
        return raw, None, None
    return match.group(1), int(match.group(2)), int(match.group(3))


class RepoInspector:
    def __init__(self, *, max_calls: int | None = None):
        self.max_calls = max_calls or int(os.getenv("EOP_REPO_TOOL_MAX_CALLS", "4"))
        self.max_output_chars = int(os.getenv("EOP_REPO_TOOL_MAX_OUTPUT_CHARS", "45000"))
        self.calls = 0
        self.read_paths: set[str] = set()
        self._tracked = _tracked_files()
        self._cache: dict[str, list[str]] = {}

    def _lines(self, rel: str) -> list[str]:
        if rel not in self._cache:
            path = _safe_text_path(rel, must_exist=True)
            if path is None:
                raise RepoToolError(f"Unsafe or unavailable tracked text file: {rel}")
            self._cache[rel] = path.read_text(
                encoding="utf-8", errors="replace"
            ).splitlines()
        return self._cache[rel]

    def _search(self, query: str, max_hits: int = 20) -> list[dict[str, Any]]:
        q = query.casefold().strip()
        if not q:
            return []
        hits: list[dict[str, Any]] = []
        for rel in self._tracked:
            try:
                lines = self._lines(rel)
            except Exception:
                continue
            for index, line in enumerate(lines, start=1):
                if q in line.casefold():
                    hits.append({
                        "path": rel,
                        "line": index,
                        "text": line[:320],
                    })
                    if len(hits) >= max_hits:
                        return hits
        return hits

    def _read(self, spec: str) -> dict[str, Any]:
        rel, start, end = _parse_read_spec(spec)
        rel = rel.replace("\\", "/")
        if rel not in self._tracked:
            raise RepoToolError(f"File is not a safe tracked text file: {rel}")
        lines = self._lines(rel)
        self.read_paths.add(rel)

        if start is None:
            if len(lines) <= 360:
                start, end = 1, len(lines)
            else:
                start, end = 1, min(240, len(lines))
        else:
            start = max(1, start)
            end = min(max(start, end or start), len(lines))

        rendered = "\n".join(
            f"{i:>5}: {lines[i - 1]}" for i in range(start, end + 1)
        )
        return {
            "path": rel,
            "start_line": start,
            "end_line": end,
            "total_lines": len(lines),
            "content": rendered,
            "note": (
                ""
                if end >= len(lines)
                else f"More content exists. Request {rel}@{end + 1}:{min(end + 300, len(lines))} if needed."
            ),
        }

    def _list(self, relative: str) -> dict[str, Any]:
        raw = (relative or ".").replace("\\", "/").strip().strip("/")
        prefix = "" if raw in {"", "."} else raw + "/"
        entries: set[str] = set()
        for rel in self._tracked:
            if not rel.startswith(prefix):
                continue
            remainder = rel[len(prefix):]
            first = remainder.split("/", 1)[0]
            entries.add(first)
        return {"path": raw or ".", "entries": sorted(entries)[:200]}

    def inspect(
        self,
        search_queries: list[str],
        read_paths: list[str],
        list_paths: list[str],
    ) -> str:
        self.calls += 1
        if self.calls > self.max_calls:
            return json.dumps({
                "error": "repo tool call budget exhausted",
                "max_calls": self.max_calls,
            })

        result: dict[str, Any] = {
            "call": self.calls,
            "max_calls": self.max_calls,
            "search": {},
            "reads": [],
            "listings": [],
        }

        for query in (search_queries or [])[:8]:
            result["search"][query] = self._search(query)

        for spec in (read_paths or [])[:8]:
            try:
                result["reads"].append(self._read(spec))
            except Exception as exc:
                result["reads"].append({"spec": spec, "error": str(exc)})

        for rel in (list_paths or [])[:4]:
            result["listings"].append(self._list(rel))

        text = json.dumps(result, ensure_ascii=False, indent=2)
        if len(text) > self.max_output_chars:
            text = text[: self.max_output_chars] + "\n...[repo tool output truncated]"
        return text


def build_repo_tool(inspector: RepoInspector):
    try:
        from agents.decorators import tool
    except ImportError:
        from agents import function_tool as tool

    @tool
    def inspect_repo(
        search_queries: list[str],
        read_paths: list[str],
        list_paths: list[str],
    ) -> str:
        """Search, read, and list safe tracked repository text files.

        Batch work aggressively. Use search_queries to discover symbols/terms,
        read_paths to read exact files or ranges (e.g. path/to/file.gd@500:800),
        and list_paths to inspect directories. You MUST explicitly read any file
        before proposing an edit to it.
        """
        return inspector.inspect(search_queries, read_paths, list_paths)

    return inspect_repo
