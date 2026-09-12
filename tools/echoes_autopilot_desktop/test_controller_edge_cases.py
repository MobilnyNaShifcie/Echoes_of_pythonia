import json
import sys
import threading
from pathlib import Path

import pytest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from echoes_autopilot_desktop.config import write_json
from echoes_autopilot_desktop.repo_agent_tools import exact_replace, source_snapshot
from echoes_autopilot_desktop.report import render_report
from echoes_autopilot_desktop.runner import ProcessRunner, Stopped


def test_atomic_json_retries_transient_onedrive_lock(tmp_path, monkeypatch):
    import echoes_autopilot_desktop.config as config
    path = tmp_path / 'state.json'
    write_json(path, {'state': 'old'})
    real_replace = config.os.replace
    attempts = []
    def transient(src, dst):
        attempts.append(1)
        if len(attempts) == 1:
            raise PermissionError('file is busy')
        real_replace(src, dst)
    monkeypatch.setattr(config.os, 'replace', transient)
    write_json(path, {'state': 'new'})
    assert len(attempts) == 2
    assert json.loads(path.read_text()) == {'state': 'new'}
    assert not list(tmp_path.glob('*.tmp'))


def test_mixed_line_endings_preserve_unrelated_bytes():
    text = 'untouched\r\nold\nline\nafter\r\n'
    assert exact_replace(text, 'old\nline', 'new\nvalue') == 'untouched\r\nnew\nvalue\nafter\r\n'
    assert exact_replace('a\r\nb\r\nc\n', 'a\nb', 'x\ny') == 'x\r\ny\r\nc\n'


def test_binary_asset_change_invalidates_review_snapshot(tmp_path):
    assets = tmp_path / 'godot/assets'
    assets.mkdir(parents=True)
    path = assets / 'character.png'
    path.write_bytes(b'old')
    old = source_snapshot(tmp_path)
    path.write_bytes(b'new')
    assert source_snapshot(tmp_path) != old


def test_cancel_terminates_running_process(tmp_path):
    stop = threading.Event()
    timer = threading.Timer(.5, stop.set)
    timer.start()
    try:
        with pytest.raises(Stopped):
            ProcessRunner(stop).run([sys.executable, '-c', 'import time; time.sleep(30)'],
                                    tmp_path, tmp_path / 'process.log', 60)
    finally:
        timer.cancel()


def test_report_escapes_model_and_task_text(tmp_path):
    report = render_report(tmp_path, {'task': '<script>alert(1)</script>', 'status': 'BLOCKED',
                                      'error': '<img src=x onerror=alert(1)>'})
    text = report.read_text(encoding='utf-8')
    assert '<script>' not in text
    assert '<img src=x' not in text
    assert '&lt;script&gt;' in text


def test_cumulative_diff_shows_final_revision_only(tmp_path):
    from echoes_autopilot_desktop.repo_agent_tools import apply_proposal, cumulative_diff
    directory = tmp_path / "run"
    target = tmp_path / "godot/core/a.gd"
    target.parent.mkdir(parents=True)
    target.write_bytes(b"extends Node\r\nvar speed = 1\r\n")
    for cycle, old, new in [(1, "1", "2"), (2, "2", "3")]:
        change = {"status": "READY_TO_APPLY", "edits": [{"path": "godot/core/a.gd",
                  "operation": "replace", "content": "", "replacements": [
                      {"old_text": "speed = " + old, "new_text": "speed = " + new}]}]}
        apply_proposal(tmp_path, change, source_snapshot(tmp_path), directory / f"cycle-{cycle}/backup")
    diff = cumulative_diff(tmp_path, directory)
    assert "-var speed = 1" in diff
    assert "+var speed = 3" in diff
    assert "speed = 2" not in diff
    assert "+extends Node" not in diff


def test_asset_validator_updates_allowed_but_main_gate_protected(tmp_path):
    from echoes_autopilot_desktop.repo_agent_tools import AutopilotError, safe_edit_path
    assert safe_edit_path(tmp_path, "scripts/check-city-assets.ps1").name == "check-city-assets.ps1"
    with pytest.raises(AutopilotError):
        safe_edit_path(tmp_path, "scripts/check.ps1")
    with pytest.raises(AutopilotError):
        safe_edit_path(tmp_path, "scripts/start-autopilot.ps1")
