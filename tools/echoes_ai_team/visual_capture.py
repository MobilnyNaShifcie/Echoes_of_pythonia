from __future__ import annotations

import hashlib
import json
import os
import struct
import subprocess
import time
from dataclasses import asdict, dataclass
from datetime import datetime
from pathlib import Path

from config import REPO_ROOT
from validation_runner import (
    ensure_tests_did_not_change_tracked_files,
    inspect_current_diff,
)

ROOT = REPO_ROOT.resolve()
GODOT_DIR = ROOT / "godot"
GODOT_EXE = ROOT / ".tools" / "godot" / "Godot_v4.7.1-stable_win64_console.exe"
TEMP_SCRIPT = GODOT_DIR / "__echoes_ai_visual_capture_tmp.gd"
EXPECTED_CHANGE = "godot/ui/screens/world_map/region_highlight.gdshaderinc"
TIMEOUT = int(os.getenv("EOP_VISUAL_CAPTURE_TIMEOUT_SECONDS", "90"))

CAPTURES = (
    (1920, 1080, "none", "1920x1080_no_hover.png"),
    (1920, 1080, "ice_coast", "1920x1080_ice_coast_hover.png"),
    (1920, 1080, "black_forest", "1920x1080_black_forest_hover.png"),
    (1280, 720, "none", "1280x720_no_hover.png"),
    (1280, 720, "ice_coast", "1280x720_ice_coast_hover.png"),
    (1280, 720, "black_forest", "1280x720_black_forest_hover.png"),
)

class VisualCaptureError(RuntimeError):
    pass

@dataclass(frozen=True)
class CaptureRecord:
    label: str
    width: int
    height: int
    hover_region: str
    path: str
    bytes: int
    sha256: str

@dataclass(frozen=True)
class CaptureSet:
    directory: Path
    manifest_path: Path
    records: tuple[CaptureRecord, ...]

GDSCRIPT = r'''
extends SceneTree

const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const WORLD_MAP_SCENE := preload("res://ui/screens/world_map/world_map.tscn")

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    var args := OS.get_cmdline_user_args()
    if args.size() < 4:
        push_error("Expected width height hover output")
        quit(2)
        return

    var width := int(args[0])
    var height := int(args[1])
    var hover_region := str(args[2])
    var output_path := str(args[3])

    DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
    DisplayServer.window_set_size(Vector2i(width, height))
    await process_frame
    await process_frame

    var session = NewGameServiceClass.new().create_session("Visual QA", 1)
    var screen = WORLD_MAP_SCENE.instantiate()
    screen.configure(session)
    get_root().add_child(screen)

    await process_frame
    await process_frame
    await process_frame

    screen.region_map._set_hovered_region("" if hover_region == "none" else hover_region)

    await process_frame
    await process_frame
    await process_frame

    var image := get_root().get_texture().get_image()
    if image == null or image.is_empty():
        push_error("Viewport image is empty.")
        quit(3)
        return

    var err := image.save_png(output_path)
    if err != OK:
        push_error("save_png failed: %s" % error_string(err))
        quit(4)
        return

    print("ECHOES_VISUAL_CAPTURE_OK %dx%d hover=%s" % [image.get_width(), image.get_height(), hover_region])
    quit(0)
'''

def _png_size(path: Path) -> tuple[int, int]:
    data = path.read_bytes()
    if len(data) < 24 or data[:8] != b"\x89PNG\r\n\x1a\n":
        raise VisualCaptureError(f"Invalid PNG: {path}")
    return struct.unpack(">II", data[16:24])

def _sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()

def _preflight() -> tuple[str, ...]:
    working = inspect_current_diff()
    if working.changed_paths != (EXPECTED_CHANGE,):
        raise VisualCaptureError(
            "Stage 4.3 expects exactly the approved hover shader diff.\n"
            f"Found: {list(working.changed_paths)}"
        )
    return working.changed_paths

def _capture_one(width: int, height: int, hover: str, output: Path) -> str:
    command = [
        str(GODOT_EXE),
        "--path", str(GODOT_DIR),
        "--rendering-method", "gl_compatibility",
        "--script", "res://__echoes_ai_visual_capture_tmp.gd",
        "--",
        str(width), str(height), hover, str(output.resolve()),
    ]
    started = time.monotonic()
    try:
        cp = subprocess.run(
            command,
            cwd=ROOT,
            capture_output=True,
            text=True,
            encoding="utf-8",
            errors="replace",
            timeout=TIMEOUT,
            check=False,
        )
    except subprocess.TimeoutExpired as exc:
        raise VisualCaptureError(f"Capture timeout: {width}x{height} / {hover}") from exc

    log = (
        f"capture={width}x{height}/{hover}\n"
        f"returncode={cp.returncode}\n"
        f"seconds={time.monotonic() - started:.2f}\n"
        f"stdout:\n{cp.stdout}\n"
        f"stderr:\n{cp.stderr}\n"
    )
    if cp.returncode != 0:
        raise VisualCaptureError(log)
    return log

def capture_visual_set() -> CaptureSet:
    changed = _preflight()
    if not GODOT_EXE.exists():
        raise VisualCaptureError(f"Missing Godot: {GODOT_EXE}")
    if TEMP_SCRIPT.exists():
        raise VisualCaptureError(f"Temporary script already exists: {TEMP_SCRIPT}")

    directory = ROOT / "output" / "ai-team" / f"VISUAL-{datetime.now():%Y%m%d-%H%M%S}"
    directory.mkdir(parents=True, exist_ok=True)
    manifest_path = directory / "manifest.json"

    records: list[CaptureRecord] = []
    logs: list[str] = []

    try:
        TEMP_SCRIPT.write_text(GDSCRIPT, encoding="utf-8", newline="\n")

        for width, height, hover, filename in CAPTURES:
            output = directory / filename
            logs.append(_capture_one(width, height, hover, output))

            if not output.exists():
                raise VisualCaptureError(f"Screenshot not created: {output}")

            actual = _png_size(output)
            if actual != (width, height):
                raise VisualCaptureError(
                    f"Wrong size for {filename}: {actual[0]}x{actual[1]}, expected {width}x{height}"
                )
            if output.stat().st_size < 50_000:
                raise VisualCaptureError(f"Suspiciously small screenshot: {filename}")

            records.append(
                CaptureRecord(
                    label=filename[:-4],
                    width=width,
                    height=height,
                    hover_region=hover,
                    path=str(output.resolve()),
                    bytes=output.stat().st_size,
                    sha256=_sha(output),
                )
            )

        by_label = {r.label: r for r in records}
        for baseline, hover in (
            ("1920x1080_no_hover", "1920x1080_ice_coast_hover"),
            ("1920x1080_no_hover", "1920x1080_black_forest_hover"),
            ("1280x720_no_hover", "1280x720_ice_coast_hover"),
            ("1280x720_no_hover", "1280x720_black_forest_hover"),
        ):
            if by_label[baseline].sha256 == by_label[hover].sha256:
                raise VisualCaptureError(f"Hover screenshot equals baseline: {hover}")

        manifest = {
            "schema": 1,
            "task_kind": "world_map_hover_visual_gate",
            "changed_paths": list(changed),
            "captures": [asdict(r) for r in records],
        }
        manifest_path.write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )
        (directory / "capture.log").write_text("\n\n".join(logs), encoding="utf-8")

    finally:
        if TEMP_SCRIPT.exists():
            TEMP_SCRIPT.unlink()

    ensure_tests_did_not_change_tracked_files(changed)

    cp = subprocess.run(
        ["git", "ls-files", "--others", "--exclude-standard", "godot"],
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        check=False,
    )
    if cp.returncode != 0 or cp.stdout.strip():
        raise VisualCaptureError(
            "Unexpected untracked files left under godot/:\n" + cp.stdout.strip()
        )

    return CaptureSet(directory, manifest_path, tuple(records))

def latest_capture_set() -> CaptureSet:
    root = ROOT / "output" / "ai-team"
    dirs = sorted(
        [p for p in root.glob("VISUAL-*") if (p / "manifest.json").exists()],
        reverse=True,
    )
    if not dirs:
        raise VisualCaptureError("No VISUAL-* capture set found.")

    directory = dirs[0]
    manifest_path = directory / "manifest.json"
    data = json.loads(manifest_path.read_text(encoding="utf-8"))

    records = tuple(CaptureRecord(**item) for item in data.get("captures", []))
    if len(records) != 6:
        raise VisualCaptureError(f"Expected 6 screenshots, found {len(records)}.")

    for record in records:
        if not Path(record.path).exists():
            raise VisualCaptureError(f"Missing screenshot: {record.path}")

    return CaptureSet(directory, manifest_path, records)
