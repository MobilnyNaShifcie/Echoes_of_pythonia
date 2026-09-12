"""Regression coverage for the controller's real failure boundaries; no model network calls."""
import base64
import copy
import json
import subprocess
import sys
import threading
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from echoes_autopilot_desktop.config import Settings
from echoes_autopilot_desktop.repo_agent_tools import (AutopilotError, apply_proposal, exact_replace,
                                              file_hash, safe_edit_path, source_snapshot)
from echoes_autopilot_desktop.runner import Autopilot, ProcessRunner, ProjectLock, Stopped, agent_command
from echoes_autopilot_desktop.schemas import PROPOSAL, REVIEW, validate, validate_review


@pytest.fixture
def repo(tmp_path, monkeypatch):
    # Orchestration fixture intentionally has no Git database or enemy assets.
    monkeypatch.setattr('echoes_autopilot_desktop.runner.changed_enemy_sources', lambda root: [])
    (tmp_path / 'godot/core').mkdir(parents=True)
    (tmp_path / 'godot/project.godot').write_text('config_version=5\n', encoding='utf-8')
    (tmp_path / 'godot/core/hero.gd').write_bytes(b'extends Node\r\nvar speed = 1\r\n')
    return tmp_path


def proposal(old='speed = 1', new='speed = 2'):
    return {'status': 'READY_TO_APPLY', 'summary': 'Zmiana prędkości', 'edits': [
        {'path': 'godot/core/hero.gd', 'operation': 'replace', 'content': '',
         'replacements': [{'old_text': old, 'new_text': new}]}]}


def review(verdict='PASS', images=()):
    return {'verdict': verdict, 'summary': 'Ocena', 'reviewed_images': [p.name for p in images],
            'findings': [], 'suggestions': []}


def test_exact_edits_preserve_dirty_content_newlines_and_backup(repo):
    target = repo / 'godot/core/hero.gd'
    target.write_bytes(target.read_bytes() + b'# existing user work\r\n')
    before = target.read_bytes()
    diff = apply_proposal(repo, proposal(), source_snapshot(repo), repo / 'backup')
    assert 'speed = 2' in diff
    assert target.read_bytes() == before.replace(b'speed = 1', b'speed = 2')
    assert (repo / 'backup/godot/core/hero.gd').read_bytes() == before
    assert json.loads((repo / 'backup/manifest.json').read_text())['godot/core/hero.gd']['existed']


@pytest.mark.parametrize('relative', ['../x', 'godot/core/../../x.gd', 'godot/core/x.gd:stream',
                                     'godot/core/.env', 'godot/core/CON.gd', 'godot/core/x.gd.',
                                     'godot/addons/x.gd', 'tools/echoes_autopilot_desktop/runner.py',
                                     'godot/core/link/../x.gd', 'godot/core//x.gd', '/godot/core/x.gd'])
def test_refuses_unsafe_and_controller_paths(repo, relative):
    with pytest.raises(AutopilotError):
        safe_edit_path(repo, relative)


def test_new_file_and_source_snapshot(repo):
    p = proposal()
    p['edits'] = [{'path': 'godot/core/new.gd', 'operation': 'create', 'content': 'extends Node\n',
                   'replacements': []}]
    apply_proposal(repo, p, source_snapshot(repo), repo / 'backup')
    assert 'godot/core/new.gd' in source_snapshot(repo)
    with pytest.raises(AutopilotError):
        apply_proposal(repo, p, source_snapshot(repo), repo / 'backup2')


def test_stale_proposal_keeps_concurrent_user_edits(repo):
    snapshot = source_snapshot(repo)
    target = repo / 'godot/core/hero.gd'
    target.write_text('user edited this', encoding='utf-8')
    with pytest.raises(AutopilotError, match='zmienił'):
        apply_proposal(repo, proposal(), snapshot, repo / 'backup')
    assert target.read_text() == 'user edited this'


def test_invalid_second_edit_applies_nothing(repo):
    p = proposal()
    p['edits'].append({'path': 'godot/core/missing.gd', 'operation': 'replace', 'content': '',
                      'replacements': [{'old_text': 'a', 'new_text': 'b'}]})
    snapshot = source_snapshot(repo)
    with pytest.raises(AutopilotError):
        apply_proposal(repo, p, snapshot, repo / 'backup')
    assert snapshot == source_snapshot(repo)


def test_duplicate_and_ambiguous_replacements(repo):
    p = proposal()
    p['edits'].append(copy.deepcopy(p['edits'][0]))
    with pytest.raises(AutopilotError, match='Powtórzony'):
        apply_proposal(repo, p, source_snapshot(repo), repo / 'backup')
    with pytest.raises(AutopilotError):
        exact_replace('x x', 'x', 'y')


def test_mid_write_failure_rolls_back_only_own_files(repo, monkeypatch):
    import echoes_autopilot_desktop.repo_agent_tools as module
    p = proposal()
    p['edits'].append({'path': 'godot/core/new.gd', 'operation': 'create',
                      'content': 'extends Node\n', 'replacements': []})
    snapshot = source_snapshot(repo)
    replace = module.os.replace
    def fail(src, dst):
        if Path(dst).name == 'new.gd':
            raise OSError('disk failure')
        return replace(src, dst)
    monkeypatch.setattr(module.os, 'replace', fail)
    with pytest.raises(OSError):
        apply_proposal(repo, p, snapshot, repo / 'backup')
    assert source_snapshot(repo) == snapshot
    assert not list((repo / 'godot').rglob('*.autopilot-tmp'))


def test_strict_contract_and_missing_visual_evidence():
    validate(proposal(), PROPOSAL)
    broken = review()
    with pytest.raises(ValueError, match='wszystkich'):
        validate_review(broken, [Path('city.png')])
    broken['findings'] = [{'title': 'Bug', 'priority': 'P1', 'category': 'visual', 'must_fix': True,
                           'evidence': ['city.png: bottom'], 'recommendation': 'Fix clipping'}]
    with pytest.raises(ValueError, match='Sprzeczna'):
        validate_review(broken, [])
    broken['extra'] = True
    with pytest.raises(ValueError):
        validate(broken, REVIEW)


def test_process_timeout_and_stop(tmp_path):
    p = ProcessRunner()
    with pytest.raises(AutopilotError, match='limit'):
        p.run([sys.executable, '-c', 'import time; time.sleep(10)'], tmp_path, tmp_path / 'timeout.log', .3)
    stop = threading.Event()
    stop.set()
    with pytest.raises(Stopped):
        ProcessRunner(stop).run([sys.executable, '-c', 'print(1)'], tmp_path, tmp_path / 'stop.log', 10)


def test_single_project_lock(tmp_path):
    with ProjectLock(tmp_path / 'run.lock'):
        with pytest.raises(AutopilotError, match='aktywny'):
            with ProjectLock(tmp_path / 'run.lock'):
                pass
    with ProjectLock(tmp_path / 'run.lock'):
        pass


def test_agent_command_never_exposes_write_or_shell_prompt(tmp_path):
    args = agent_command(Settings(codex='codex'), tmp_path, 'gpt-5.6-sol', tmp_path / 'schema',
                         tmp_path / 'answer', [tmp_path / 'a b.png'])
    assert args[args.index('--sandbox') + 1] == 'read-only'
    assert '--dangerously-bypass-approvals-and-sandbox' not in args
    assert args[args.index('--model') + 1] == 'gpt-5.6-sol'
    assert args[-1] == '-'


class FakePipeline(Autopilot):
    """Exercise orchestration and real file writes with explicit simulated model results."""
    technical_ok = True
    def checks(self, label, focused=False):
        self.save('TESTING')
        path = self.directory / label / 'check.log'
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text('fixture check', encoding='utf-8')
        self.state['checks'].append({'name': 'fixture', 'status': 'PASS' if self.technical_ok else 'FAIL',
                                    'log': path.relative_to(self.directory).as_posix()})
        return self.technical_ok

    def journeys(self, label):
        return self.technical_ok

    def capture(self, label):
        self.save('CAPTURING')
        path = self.directory / label / 'city_1x1.png'
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(base64.b64decode('iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+jRZkAAAAASUVORK5CYII='))
        self.state['screenshots'] = [path.relative_to(self.directory).as_posix()]
        return [path]

    def agent(self, label, model, prompt, schema, images=()):
        cycle = self.state['cycle']
        if label.endswith('/astra'):
            if cycle == 1:
                return proposal()
            assert 'CHANGES_REQUIRED' in prompt
            return proposal('speed = 2', 'speed = 3')
        return review('CHANGES_REQUIRED' if cycle == 1 else 'PASS', images)


def test_full_develop_review_repair_cycle_uses_actual_diff(repo):
    runner = FakePipeline(Settings(godot='fake', codex='fake', powershell='fake'), root=repo)
    directory = runner.run('Change hero speed')
    assert runner.state['status'] == 'PASSED'
    assert runner.state['cycle'] == 2
    assert b'speed = 3' in (repo / 'godot/core/hero.gd').read_bytes()
    assert (directory / 'cycle-1/backup/applied.diff').exists()
    assert (directory / 'cycle-2/backup/applied.diff').exists()
    assert (directory / 'report.html').exists()


def test_model_pass_cannot_override_failed_technical_gate(repo):
    class FailedTests(FakePipeline):
        technical_ok = False
    runner = FailedTests(Settings(godot='fake', codex='fake', powershell='fake'), root=repo)
    runner.run('Task')
    assert runner.state['status'] == 'NEEDS_CHANGES'
    assert all(r['verdict'] == 'PASS' for r in runner.state['reviews'])


def test_missing_capture_manifest_blocks_approval(repo):
    runner = Autopilot(Settings(godot=sys.executable, codex='fake', powershell='fake'), root=repo)
    class NoImages:
        def run(self, command, cwd, log, *args, **kwargs):
            log.write_text('exit 0, no actual frames', encoding='utf-8')
            return 0
    runner.process = NoImages()
    runner.run('Images', 'capture')
    assert runner.state['status'] == 'BLOCKED'
    assert 'potwierdzenia' in runner.state['error']


def test_resume_rejects_external_modifications(repo):
    runner = FakePipeline(Settings(godot='fake', codex='fake', powershell='fake', max_cycles=1), root=repo)
    previous = runner.run('Task')
    (repo / 'godot/core/hero.gd').write_text('new user changes', encoding='utf-8')
    directory = runner.run('Task', resume=previous)
    assert runner.state['resume_source_changed'] is True
    assert runner.state['status'] == 'BLOCKED'  # stale model anchors still cannot apply
    assert (repo / 'godot/core/hero.gd').read_text() == 'new user changes'
    assert not (directory / 'cycle-1/backup').exists()
