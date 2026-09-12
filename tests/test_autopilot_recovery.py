import copy
import json
import sys
from pathlib import Path

import pytest

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from echoes_autopilot_desktop.art_policy import POLICY_DOCUMENT, load_art_policy, review_context
from echoes_autopilot_desktop.panel import Panel, job_details
from echoes_autopilot_desktop.config import Settings
from echoes_autopilot_desktop.repo_agent_tools import safe_edit_path
from echoes_autopilot_desktop.runner import Autopilot


@pytest.fixture
def policy_repo(tmp_path):
    policy = load_art_policy(ROOT)
    for relative in policy['class_references'] + policy['world_references'] + [
        p for paths in policy['region_references'].values() for p in paths
    ] + list(policy['scenario_enemies'].values()):
        path = tmp_path / relative
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(b'fixture image; not rendered')
    def save(data):
        path = tmp_path / POLICY_DOCUMENT
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text('```autopilot-art-policy\n' + json.dumps(data) + '\n```\n', encoding='utf-8')
    save(policy)
    return tmp_path, policy, save


def test_current_combat_scenarios_use_matching_regions_and_approved_classes(policy_repo):
    root, policy, _ = policy_repo
    for shot, region in [('combat_wolf_1280x720.png', 'twilight_plains'),
                         ('combat_ice_crab_1920x1080.png', 'ice_coast')]:
        context, references = review_context(root, load_art_policy(root), [Path(shot)])
        names = [p.name for p, _ in references]
        assert names == ['hunter_male.png', 'mage_female.png', 'pythonia_world_map_integrated.png', region + '_day.png', 'wolf.png' if region == 'twilight_plains' else 'ice_crab.png']
        assert 'Zbyt realistyczna' in context
        assert 'city' not in ' '.join(names)


def test_policy_changes_are_loaded_without_restarting(policy_repo):
    root, policy, save = policy_repo
    policy['review_rules'] = ['New review criterion']
    save(policy)
    context, _ = review_context(root, load_art_policy(root), [])
    assert 'New review criterion' in context


def test_no_silent_substitution_for_unknown_combat_or_missing_reference(policy_repo):
    root, policy, _ = policy_repo
    with pytest.raises(ValueError, match='Brak regionu'):
        review_context(root, policy, [Path('combat_new_boss_1280x720.png')])
    (root / policy['class_references'][0]).unlink()
    with pytest.raises(ValueError, match='Brak lokalnego'):
        load_art_policy(root)


@pytest.mark.parametrize('path', ['C:/secrets.png', 'godot/assets/../../outside.png', 'https://example.com/a.png'])
def test_policy_cannot_attach_non_asset_paths(policy_repo, path):
    root, policy, save = policy_repo
    policy['class_references'][0] = path
    save(policy)
    with pytest.raises(ValueError, match='Niedozwolona'):
        load_art_policy(root)


def test_legacy_blocked_run_reason_visible_on_selection(tmp_path):
    directory = tmp_path / 'RUN-example'
    directory.mkdir()
    (directory / 'state.json').write_text(json.dumps({'status': 'BLOCKED', 'error': 'Tool edit forbidden'}))
    message = job_details({'status': 'BLOCKED', 'directory': str(directory)}, tmp_path)
    assert 'Tool edit forbidden' in message
    assert 'Wznów zaznaczone' in message


def test_start_requested_job_does_not_start_older_queued_audit(tmp_path):
    panel = Panel.__new__(Panel)
    panel.jobs = [{'id': 'old-audit', 'status': 'QUEUED'}]
    panel.worker = None
    panel.auto_queue = True
    panel._settings = lambda: Settings()
    panel._persist = lambda: None
    panel.tree = type('Tree', (), {'selection_set': lambda *a: None, 'see': lambda *a: None})()
    started = []
    panel._next = started.append
    panel._enqueue('task', 'Resume selected task', start=True, resume=str(tmp_path))
    assert started == [panel.jobs[-1]['id']]
    assert started != ['old-audit']
    assert panel.auto_queue is False


def test_blocked_reason_emitted_to_live_log(tmp_path):
    messages = []
    runner = Autopilot(Settings(), root=tmp_path, on_event=messages.append)
    runner.directory = tmp_path
    runner.state = {'error': 'Missing style capability'}
    runner.save('BLOCKED')
    assert any('Missing style capability' in m for m in messages)


def test_art_workflow_script_is_now_editable_and_developer_knows_scope(tmp_path):
    assert safe_edit_path(tmp_path, 'scripts/build_art_reference_board.py').name == 'build_art_reference_board.py'
    runner = Autopilot(Settings(), root=tmp_path)
    runner.directory = tmp_path
    runner.state = {'task': 'Change global enemy policy'}
    prompts = []
    def agent(label, model, prompt, schema, images=()):
        prompts.append(prompt)
        return {'status': 'NO_CHANGE', 'summary': 'fixture', 'edits': []}
    runner.agent = agent
    runner.develop(1, '')
    assert 'scripts/build_art_reference_board.py' in prompts[0]
    assert 'autopilot-art-policy' in prompts[0]
    assert 'ani narzędzi' not in prompts[0]



def test_source_pixel_gate_detects_missing_alpha_and_clipped_silhouette(policy_repo):
    from PIL import Image
    from echoes_autopilot_desktop.art_policy import enemy_source_checks
    root, policy, _ = policy_repo
    path = root / policy['scenario_enemies']['combat_wolf']
    Image.new('RGB', (10, 10), 'white').save(path)
    checks = enemy_source_checks(root, policy, [Path('combat_wolf_1280x720.png')])
    assert checks[0]['status'] == 'FAIL'
    assert len(checks[0]['problems']) == 3
    image = Image.new('RGBA', (10, 10), (0, 0, 0, 0))
    image.paste((100, 100, 100, 255), (2, 2, 8, 8))
    image.save(path)
    checks = enemy_source_checks(root, policy, [Path('combat_wolf_1280x720.png')])
    assert checks[0]['status'] == 'PASS'
    assert checks[0]['alpha_bounds'] == (2, 2, 8, 8)


def test_review_accepts_real_attachment_paths_and_rejects_unknown_files():
    from echoes_autopilot_desktop.schemas import validate_review
    images = [Path('run/before/a.png'), Path('run/after/a.png'), Path('assets/reference.png')]
    review = {'verdict': 'PASS', 'summary': 'fixture', 'findings': [], 'suggestions': [],
              'reviewed_images': ['before/a.png', 'after/a.png', 'reference.png']}
    validate_review(review, images)
    review['reviewed_images'].append('unattached/a.png')
    with pytest.raises(ValueError, match='nieznane'):
        validate_review(review, images)


def test_developer_receives_current_checkout_and_knows_controller_runs_tests(tmp_path, monkeypatch):
    import echoes_autopilot_desktop.runner as module
    monkeypatch.setattr(module, 'git_context', lambda root: {
        'branch': 'ai/test-current', 'head': '123456abcdef', 'status': ' M docs/current.md'})
    runner = Autopilot(Settings(), root=tmp_path)
    runner.directory = tmp_path
    runner.state = {'task': 'Use the current project'}
    prompts = []
    def agent(label, model, prompt, schema, images=()):
        prompts.append(prompt)
        return {'status': 'NO_CHANGE', 'summary': 'fixture', 'edits': []}
    runner.agent = agent
    runner.develop(1, 'An old report mentions a missing historical asset.')
    assert 'ai/test-current' in prompts[0] and '123456abcdef' in prompts[0]
    assert str(tmp_path.resolve()) in prompts[0]
    assert 'Kontroler zapisuje propozycję, uruchamia check.ps1, GUT i renderer' in prompts[0]
    assert 'sandbox Astry' in prompts[0]


def test_legacy_report_identifies_its_original_branch(tmp_path):
    directory = tmp_path / 'RUN-old'
    directory.mkdir()
    (directory / 'state.json').write_text(json.dumps({
        'status': 'BLOCKED', 'error': 'missing old asset',
        'git_before': {'branch': 'snapshot/old', 'head': 'a' * 40}}))
    details = job_details({'directory': str(directory)}, tmp_path)
    assert 'snapshot/old' in details
    assert 'aaaaaaaa' in details
