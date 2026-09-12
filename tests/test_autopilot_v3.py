import json
import sys
from pathlib import Path

import pytest
from PIL import Image

sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from echoes_autopilot_desktop.config import Settings, write_json
from echoes_autopilot_desktop.repo_agent_tools import AutopilotError, file_hash, source_snapshot
from echoes_autopilot_desktop.runner import Autopilot, Stopped
from echoes_autopilot_desktop.workflow import canonical_coverage, fingerprint, receipts_valid, update_issues
from echoes_autopilot_desktop.workspaces import apply_workspace, managed_path
from echoes_autopilot_desktop.art_studio import ArtStudio, png_quality


def finding():
    return {'title': 'Panel zasłania postać', 'category': 'visual', 'priority': 'P1',
            'must_fix': True, 'evidence': ['godot/ui/screen.gd:21'], 'recommendation': 'Przesuń panel.'}


def review(verdict='PASS', findings=None):
    return {'verdict': verdict, 'summary': 'fixture', 'findings': findings or [],
            'reviewed_images': [], 'suggestions': []}


def test_issue_can_return_and_partial_review_cannot_close_it(tmp_path):
    path = tmp_path / 'issues.json'
    first = update_issues(path, [review('CHANGES_REQUIRED', [finding()])], 'one', 1, True, 'same')
    number = first[0]['id']
    partial = update_issues(path, [review()], 'two', 1, False, 'same')
    assert partial[0]['status'] == 'unverified'
    assert update_issues(path, [review()], 'three', 1, True, 'same')[0]['status'] == 'fixed'
    returned = update_issues(path, [review('CHANGES_REQUIRED', [finding()])], 'four', 1, True, 'same')
    assert returned[0]['id'] == number and returned[0]['status'] == 'returned'
    assert len(returned[0]['history']) == 4


def test_different_visual_scope_cannot_close_an_issue(tmp_path):
    path = tmp_path / 'issues.json'
    update_issues(path, [review('CHANGES_REQUIRED', [finding()])], 'one', 1, True, 'combat')
    issues = update_issues(path, [review()], 'two', 1, True, 'city')
    assert issues[0]['status'] == 'open'


def test_checkpoint_tracks_logs_and_rejects_changed_evidence(tmp_path):
    runner = Autopilot(Settings(), root=tmp_path)
    runner.directory = tmp_path / 'run'
    runner.directory.mkdir()
    runner.state = {'checks': [], 'reviews': []}
    calls = []
    def operation():
        calls.append(1)
        (runner.directory / 'proof.log').write_text('PASS')
        runner.state['checks'].append({'name': 'test', 'status': 'PASS', 'log': 'proof.log'})
        return True
    assert runner.step('tests', operation)
    runner.state['checks'] = []
    assert runner.step('tests', operation)
    assert calls == [1] and len(runner.state['checks']) == 1
    (runner.directory / 'proof.log').write_text('changed')
    assert not receipts_valid(runner.directory, runner.state['checkpoints'])
    with pytest.raises(RuntimeError, match='Dowody'):
        runner.step('tests', operation)


def test_resume_fingerprint_includes_capture_fixture_and_settings(tmp_path):
    fixture = tmp_path / 'godot/tools/capture.gd'
    fixture.parent.mkdir(parents=True)
    fixture.write_text('one')
    settings = Settings()
    original = fingerprint(tmp_path, settings)
    fixture.write_text('two')
    assert fingerprint(tmp_path, settings) != original
    other = fingerprint(tmp_path, settings)
    settings.reviewer_model = 'another'
    assert fingerprint(tmp_path, settings) != other


class ResumePipeline(Autopilot):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.counts = {'develop': 0, 'checks': 0, 'code': 0, 'visual': 0}
        self.interrupt = True

    def develop(self, cycle, feedback):
        self.counts['develop'] += 1
        path = self.root / 'godot/core/a.gd'
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text('extends Node\n')

    def checks(self, label, focused=False):
        def operation():
            self.counts['checks'] += 1
            return True
        return self.step(label, operation)

    def capture(self, label):
        path = self.directory / label / 'city.png'
        path.parent.mkdir(parents=True, exist_ok=True)
        Image.new('RGB', (64, 64), 'blue').save(path)
        self.state['screenshots'] = [path.relative_to(self.directory).as_posix()]
        return [path]

    def review(self, cycle, diff, images, before):
        def code():
            self.counts['code'] += 1
            self.state['reviews'].append(review())
            return True
        self.step('sol-code', code)
        def visual():
            self.counts['visual'] += 1
            if self.interrupt:
                raise Stopped('interrupted visual review')
            self.state['reviews'].append(review())
            return True
        return self.step('sol-visual', visual)


def test_interrupted_review_resumes_without_reapplying_edits_or_tests(tmp_path):
    settings = Settings(godot='fake', codex='fake', powershell='fake', gameplay_journeys=False)
    runner = ResumePipeline(settings, root=tmp_path)
    directory = runner.run('fixture')
    assert runner.state['status'] == 'STOPPED'
    runner.interrupt = False
    resumed = runner.run('fixture', resume=directory)
    assert resumed == directory
    assert runner.state['status'] == 'PASSED'
    assert runner.counts == {'develop': 1, 'checks': 1, 'code': 1, 'visual': 2}


def test_changed_source_starts_new_run_instead_of_reusing_review(tmp_path):
    settings = Settings(godot='fake', codex='fake', powershell='fake', gameplay_journeys=False)
    runner = ResumePipeline(settings, root=tmp_path)
    directory = runner.run('fixture')
    (tmp_path / 'godot/core/new.gd').write_text('extends Node\n')
    runner.interrupt = False
    assert runner.run('fixture', resume=directory) != directory
    assert runner.counts['checks'] == 2


def test_canonical_result_reuse_requires_explicit_complete_markers():
    assert canonical_coverage('Running GUT tests...\nAll tests passed')['gut'] is False
    assert canonical_coverage('AUTOPILOT_STAGE boot PASS\nAUTOPILOT_STAGE gut PASS') == {'boot': True, 'gut': True}
    assert canonical_coverage('AUTOPILOT_STAGE boot PASS\nAUTOPILOT_STAGE gut FAIL') == {'boot': True, 'gut': True}


def test_focused_receipt_cannot_replace_full_gate(tmp_path):
    runner = Autopilot(Settings(godot='fake', powershell='fake'), root=tmp_path)
    runner.directory = tmp_path / 'run'
    runner.directory.mkdir()
    runner.state = {'checks': [], 'reviews': []}
    commands = []
    def run(command, cwd, log, timeout, env):
        commands.append(command)
        log.write_text('focused' if '-Focused' in command else 'AUTOPILOT_STAGE boot PASS\nAUTOPILOT_STAGE gut PASS')
        return 0
    runner.process.run = run
    assert runner.checks('tests', focused=True)
    assert runner.checks('tests', focused=False)
    assert len(commands) == 2 and '-Focused' not in commands[1]


def test_completed_failed_gut_is_not_run_twice(tmp_path):
    runner = Autopilot(Settings(godot='fake', powershell='fake'), root=tmp_path)
    runner.directory = tmp_path / 'run'
    runner.directory.mkdir()
    runner.state = {'checks': [], 'reviews': []}
    calls = []
    def run(command, cwd, log, timeout, env):
        calls.append(command)
        log.write_text('AUTOPILOT_STAGE boot PASS\nAUTOPILOT_STAGE gut FAIL')
        return 1
    runner.process.run = run
    assert not runner.checks('tests')
    assert len(calls) == 1


def workspace_fixture(tmp_path):
    source = tmp_path / 'source'
    target = source / 'godot/core/a.gd'
    target.parent.mkdir(parents=True)
    target.write_text('extends Node\nvar value = 1\n')
    output = source / 'output/ai-team'
    working = output / 'workspaces/WORK-test'
    copy = working / 'godot/core/a.gd'
    copy.parent.mkdir(parents=True)
    copy.write_bytes(target.read_bytes())
    metadata = {'source_root': str(source), 'root': str(working), 'baseline': source_snapshot(working)}
    copy.write_text('extends Node\nvar value = 2\n')
    return target, output, metadata


def test_apply_workspace_preserves_original_and_only_applies_delta(tmp_path):
    target, output, metadata = workspace_fixture(tmp_path)
    result = apply_workspace(metadata, output)
    assert 'value = 2' in target.read_text()
    assert 'value = 1' in (Path(result['backup']) / 'godot/core/a.gd').read_text()


def test_apply_workspace_refuses_concurrent_user_changes(tmp_path):
    target, output, metadata = workspace_fixture(tmp_path)
    target.write_text('user changes')
    with pytest.raises(AutopilotError, match='poza zadaniem'):
        apply_workspace(metadata, output)
    assert target.read_text() == 'user changes'


def test_apply_workspace_refuses_edits_after_validation(tmp_path):
    target, output, metadata = workspace_fixture(tmp_path)
    working = Path(metadata['root'])
    validated = source_snapshot(working)
    (working / 'godot/core/a.gd').write_text('untested change')
    with pytest.raises(AutopilotError, match='po testach'):
        apply_workspace(metadata, output, validated)
    assert 'value = 1' in target.read_text()


def art_fixture(tmp_path):
    original = tmp_path / 'godot/assets/wolf.png'
    original.parent.mkdir(parents=True)
    Image.new('RGBA', (64, 64), 'red').save(original)
    output = tmp_path / 'output/ai-team'
    directory = output / 'art-studio/ART-test'
    directory.mkdir(parents=True)
    (directory / 'original.png').write_bytes(original.read_bytes())
    candidate = directory / 'variant.png'
    Image.new('RGBA', (64, 64), 'blue').save(candidate)
    data = {'target': 'godot/assets/wolf.png', 'source_hash': file_hash(original), 'references': [],
            'variants': [{'path': candidate.name, 'hash': file_hash(candidate), 'quality': png_quality(candidate),
                          'status': 'REVIEWED', 'review': review(), 'source_snapshot': source_snapshot(tmp_path),
                          'reviewed_hashes': {str(candidate): file_hash(candidate)}}]}
    write_json(directory / 'request.json', data)
    return ArtStudio(tmp_path, output, Settings()), directory, original, candidate


def test_png_install_preserves_original(tmp_path):
    studio, directory, target, candidate = art_fixture(tmp_path)
    previous = target.read_bytes()
    studio.install(directory, 0)
    assert target.read_bytes() == candidate.read_bytes()
    assert (directory / 'backup-before-install.png').read_bytes() == previous
    assert studio.read(directory)['variants'][0]['status'] == 'APPLIED'


@pytest.mark.parametrize('change', ['review', 'source', 'evidence'])
def test_png_install_refuses_failed_or_stale_review(tmp_path, change):
    studio, directory, target, candidate = art_fixture(tmp_path)
    previous = target.read_bytes()
    if change == 'review':
        data = studio.read(directory)
        data['variants'][0]['review']['verdict'] = 'CHANGES_REQUIRED'
        write_json(directory / 'request.json', data)
    elif change == 'source':
        source = tmp_path / 'godot/core/new.gd'
        source.parent.mkdir(parents=True)
        source.write_text('extends Node')
    else:
        Image.new('RGBA', (64, 64), 'green').save(candidate)
    with pytest.raises(AutopilotError):
        studio.install(directory, 0)
    assert target.read_bytes() == previous


def test_changed_art_reference_requires_new_approval(tmp_path):
    studio, directory, target, candidate = art_fixture(tmp_path)
    data = studio.read(directory)
    data['references'] = [{'path': 'godot/assets/wolf.png', 'approved_hash': file_hash(target)}]
    Image.new('RGBA', (64, 64), 'green').save(target)
    with pytest.raises(AutopilotError, match='wzorzec'):
        studio.request_images(directory, data)


def test_workspace_cannot_escape_managed_directory(tmp_path):
    with pytest.raises(AutopilotError):
        managed_path(tmp_path, tmp_path / '../outside')


def test_candidate_alpha_gate_rejects_empty_and_clipped_images(tmp_path):
    path = tmp_path / 'candidate.png'
    Image.new('RGBA', (64, 64), (0, 0, 0, 0)).save(path)
    assert png_quality(path, True)['ok'] is False
    Image.new('RGBA', (64, 64), (255, 0, 0, 255)).save(path)
    assert png_quality(path, True)['ok'] is False
    image = Image.new('RGBA', (64, 64))
    image.paste((255, 0, 0, 255), (5, 5, 59, 59))
    image.save(path)
    assert png_quality(path, True)['ok'] is True
