"""Enemy style workflow contracts; no image generation, network or game mutation."""
import copy
import json
import sys
from pathlib import Path

import pytest
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from echoes_autopilot_desktop import art_policy as art
from echoes_autopilot_desktop.art_studio import ArtStudio, png_quality
from echoes_autopilot_desktop.config import Settings, write_json
from echoes_autopilot_desktop.repo_agent_tools import AutopilotError, file_hash, source_snapshot
from echoes_autopilot_desktop.schemas import (
    REVIEW, ENEMY_REVIEW, ENEMY_CRITERIA, validate_enemy_review,
)
from scripts import build_art_reference_board as board


def save_policy(root, policy):
    path = root / art.POLICY_DOCUMENT
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text('```autopilot-art-policy\n' + json.dumps(policy) + '\n```\n', encoding='utf-8')


def png(path, bounds=(8, 8, 91, 91)):
    path.parent.mkdir(parents=True, exist_ok=True)
    with Image.new('RGBA', (100, 100)) as image:
        ImageDraw.Draw(image).rectangle(bounds, fill='red')
        image.save(path)


@pytest.fixture
def policy_repo(tmp_path):
    policy = art.load_art_policy(ROOT)
    paths = policy['class_references'] + policy['world_references'] + [
        p for paths in policy['region_references'].values() for p in paths
    ] + list(policy['scenario_enemies'].values())
    for relative in paths:
        png(tmp_path / relative)
    save_policy(tmp_path, policy)
    return tmp_path, policy


def studio_request(root, policy):
    studio = ArtStudio(root, root / 'output/ai-team', Settings())
    directory = studio.request(policy['scenario_enemies']['combat_wolf'], 'Keep its identity',
                               'twilight_plains', 'combat_wolf')
    return studio, directory


def good_review(targets, images):
    return {
        'verdict': 'PASS', 'summary': 'Fixture review, not an artistic judgment',
        'findings': [], 'suggestions': [], 'reviewed_images': list(dict.fromkeys(p.name for p in images)),
        'enemy_art_checks': [{
            'source': t['source'], 'compared_references': t['references'],
            'criteria': [{'criterion': c, 'status': 'PASS',
                          'evidence': ['candidate.png: torso contours vs hunter_male.png torso']}
                         for c in ENEMY_CRITERIA],
        } for t in targets],
    }


def test_single_policy_is_in_ai_context_not_a_parallel_document():
    assert art.POLICY_DOCUMENT == 'AI_CONTEXT/ART_DIRECTION.md'
    assert (ROOT / art.POLICY_DOCUMENT).read_text(encoding='utf-8').count('```autopilot-art-policy') == 1
    assert '```autopilot-art-policy' not in (ROOT / 'docs/ART_DIRECTION_ANIME_FANTASY.md').read_text(encoding='utf-8')
    assert art.load_art_policy(ROOT)


@pytest.mark.parametrize('region', [
    'twilight_plains', 'black_forest', 'silentwater_marshes', 'ashen_borderlands', 'ice_coast',
])
def test_all_regions_use_current_classes_map_and_correct_landscape(policy_repo, region):
    root, policy = policy_repo
    refs = [p.relative_to(root).as_posix() for p, _ in art.references_for_region(root, policy, region)]
    assert refs == policy['class_references'] + policy['world_references'] + policy['region_references'][region]
    brief = art.generation_brief(root, policy, region)
    assert all(rule in brief for rule in policy['style_rules'] + policy['review_rules'])
    assert all(p in brief for p in refs)
    assert not any('/enemies/' in p for p in refs)


def test_missing_policy_or_unknown_region_never_passes_combat_review(policy_repo):
    root, policy = policy_repo
    with pytest.raises(ValueError):
        art.references_for_region(root, policy, 'unknown_region')
    with pytest.raises(ValueError):
        art.review_context(root, None, [Path('combat_wolf_1280x720.png')])


def test_enemy_cannot_be_promoted_to_rendering_reference(policy_repo):
    root, policy = policy_repo
    policy['class_references'][0] = policy['scenario_enemies']['combat_wolf']
    save_policy(root, policy)
    with pytest.raises(ValueError, match='nie są wzorcami'):
        art.load_art_policy(root)


def test_studio_forces_enemy_alpha_and_rejects_wrong_region_scene(policy_repo):
    root, policy = policy_repo
    source = root / policy['scenario_enemies']['combat_wolf']
    Image.new('RGB', (100, 100), 'red').save(source)
    studio, directory = studio_request(root, policy)
    assert studio.read(directory)['transparent'] is True
    with pytest.raises(AutopilotError, match='mapowaniu'):
        studio.request(source.relative_to(root).as_posix(), 'Test', 'ice_coast', 'combat_ice_crab')


def test_studio_refreshes_old_requests_and_ignores_additive_catalog_style(policy_repo):
    root, policy = policy_repo
    studio, directory = studio_request(root, policy)
    old = studio.read(directory)
    old_fingerprint = old['policy_fingerprint']
    extra = policy['scenario_enemies']['combat_ice_crab']
    studio.approve_reference(extra, 'class', 'twilight_plains')
    policy['style_rules'].append('CURRENT STYLE RULE, NOT THE CACHED REQUEST')
    save_policy(root, policy)
    studio.refresh_enemy_policy(old)
    assert extra not in [a['path'] for a in old['references']]
    assert 'CURRENT STYLE RULE' in old['art_brief']
    assert old['policy_fingerprint'] != old_fingerprint
    assert old['review_rules'] == policy['review_rules']


def test_policy_reference_replacement_does_not_keep_old_cached_class(policy_repo):
    root, policy = policy_repo
    studio, directory = studio_request(root, policy)
    data = studio.read(directory)
    previous = policy['class_references'][0]
    replacement = 'godot/assets/combat/heroes/replacement.png'
    png(root / replacement)
    policy['class_references'][0] = replacement
    save_policy(root, policy)
    studio.refresh_enemy_policy(data)
    assert previous not in [a['path'] for a in data['references']]
    assert replacement in [a['path'] for a in data['references']]


def test_studio_requires_approval_again_if_reference_bytes_change(policy_repo):
    root, policy = policy_repo
    studio, directory = studio_request(root, policy)
    fingerprint = art.policy_fingerprint(root, policy)
    png(root / policy['class_references'][0], (10, 10, 89, 89))
    assert art.policy_fingerprint(root, policy) != fingerprint
    with pytest.raises(AutopilotError, match='wzorzec zmienił'):
        studio.refresh_enemy_policy(studio.read(directory))


def test_all_three_pixel_gates_agree_on_too_narrow_margin(policy_repo):
    root, policy = policy_repo
    relative = policy['scenario_enemies']['combat_wolf']
    png(root / relative, (1, 8, 91, 91))
    direct = board.inspect_enemy_source(root, relative)
    automated = art.enemy_source_checks(root, policy, [Path('combat_wolf_1280x720.png')])[0]
    studio = png_quality(root / relative, True, enemy=True)
    assert direct['status'] == automated['status'] == studio['status'] == 'FAIL'
    assert direct['sha256'] == automated['sha256'] == studio['sha256']
    assert direct['margin_fractions_ltrb'] == automated['margin_fractions_ltrb'] == studio['margin_fractions_ltrb']


def test_changed_enemy_must_be_captured_not_just_mapped(policy_repo):
    root, policy = policy_repo
    shots = [Path('combat_wolf_1280x720.png')]
    art.require_enemy_coverage(root, policy, shots, [policy['scenario_enemies']['combat_wolf']])
    with pytest.raises(ValueError, match='Brak scen'):
        art.require_enemy_coverage(root, policy, shots, [policy['scenario_enemies']['combat_ice_crab']])
    with pytest.raises(ValueError):
        art.require_enemy_coverage(root, None, shots, ['godot/assets/combat/enemies/new_boss.png'])


@pytest.mark.parametrize('bad', ['missing_criterion', 'duplicate_criterion', 'missing_source',
                                'wrong_reference', 'empty_evidence', 'FAIL', 'NOT_ASSESSABLE'])
def test_review_cannot_claim_pass_without_all_style_evidence(policy_repo, bad):
    root, policy = policy_repo
    targets = art.enemy_review_targets(root, policy, [Path('combat_wolf_1280x720.png')])
    images = [Path('candidate.png')]
    result = good_review(targets, images)
    validate_enemy_review(result, images, targets)
    check = result['enemy_art_checks'][0]
    if bad == 'missing_criterion':
        check['criteria'].pop()
    elif bad == 'duplicate_criterion':
        check['criteria'][-1] = copy.deepcopy(check['criteria'][0])
    elif bad == 'missing_source':
        result['enemy_art_checks'] = []
    elif bad == 'wrong_reference':
        check['compared_references'] = ['city.png']
    elif bad == 'empty_evidence':
        check['criteria'][0]['evidence'] = []
    else:
        check['criteria'][0]['status'] = bad
    with pytest.raises(ValueError):
        validate_enemy_review(result, images, targets)


def test_realism_failure_needs_a_concrete_visual_fix(policy_repo):
    root, policy = policy_repo
    targets = art.enemy_review_targets(root, policy, [Path('combat_wolf_1280x720.png')])
    result = good_review(targets, [])
    result['verdict'] = 'CHANGES_REQUIRED'
    result['enemy_art_checks'][0]['criteria'][0]['status'] = 'FAIL'
    with pytest.raises(ValueError, match='konkretnej poprawki'):
        validate_enemy_review(result, [], targets)
    result['findings'] = [{'title': 'Photographic fur', 'priority': 'P2', 'category': 'visual',
                           'must_fix': True, 'evidence': ['candidate.png: head fur vs hunter_male.png'],
                           'recommendation': 'Group fur into illustrated masses and simplify fine highlights.'}]
    validate_enemy_review(result, [], targets)


def test_policy_change_invalidates_previous_variant_review(policy_repo):
    root, policy = policy_repo
    studio, directory = studio_request(root, policy)
    data = studio.read(directory)
    # A historical successful review must not be grandfathered into new policy.
    data['variants'] = [{'reviewed_policy': data['policy_fingerprint']}]
    write_json(directory / 'request.json', data)
    policy['style_rules'].append('Updated style contract')
    save_policy(root, policy)
    original_hash = file_hash(root / data['target'])
    with pytest.raises(AutopilotError, match='ponowny podgląd'):
        studio.install(directory, 0)
    assert file_hash(root / data['target']) == original_hash


def test_canonical_policy_is_part_of_review_snapshot(policy_repo):
    root, policy = policy_repo
    before = source_snapshot(root)
    assert art.POLICY_DOCUMENT in before
    policy['style_rules'].append('A new rule')
    save_policy(root, policy)
    assert source_snapshot(root)[art.POLICY_DOCUMENT] != before[art.POLICY_DOCUMENT]


def test_autopilot_dispatches_structured_enemy_review(policy_repo, monkeypatch):
    from echoes_autopilot_desktop import runner as module
    root, policy = policy_repo
    monkeypatch.setattr(module, 'changed_enemy_sources', lambda root: [])
    runner = module.Autopilot(Settings(), root=root)
    runner.directory = root / 'output/ai-team/RUN-test'
    runner.state = {'task': 'Review enemy art', 'checks': [], 'reviews': []}
    runner.save = lambda *args: None
    shot = Path('combat_wolf_1280x720.png')
    targets = art.enemy_review_targets(root, policy, [shot])
    calls = []
    def agent(label, model, prompt, schema, images=()):
        calls.append((schema, prompt))
        result = good_review(targets, images)
        if schema == REVIEW:
            result.pop('enemy_art_checks')
        return result
    runner.agent = agent
    assert runner.review(1, '', [shot], None)
    assert calls[0][0] == REVIEW
    assert calls[1][0] == ENEMY_REVIEW
    assert all(rule in calls[1][1] for rule in policy['review_rules'])


def test_generator_reload_between_variants_uses_canonical_images_and_brief(policy_repo, monkeypatch):
    from echoes_autopilot_desktop import runner as module
    root, policy = policy_repo
    studio, directory = studio_request(root, policy)
    data = studio.read(directory)
    data['count'] = 2
    data['style_rules'] = ['STALE CACHED RULE, DO NOT USE']
    write_json(directory / 'request.json', data)
    calls = []
    class FakeProcess:
        def __init__(self, *args):
            pass

        def run(self, command, cwd, log, timeout, prompt, env):
            calls.append((command, prompt))
            png(cwd / 'candidate.png', (10, 10, 89, 89))
            policy['style_rules'].append('RULE ADDED AFTER FIRST GENERATION')
            save_policy(root, policy)
            return 0
    monkeypatch.setattr(module, 'ProcessRunner', FakeProcess)
    monkeypatch.setattr(module, 'codex_environment', lambda: {})
    studio.generate(directory)
    assert len(calls) == 2
    required = policy['class_references'] + policy['world_references'] + policy['region_references']['twilight_plains']
    for command, prompt in calls:
        images = [command[i + 1] for i, word in enumerate(command) if word == '--image']
        assert images == [str(directory / 'original.png')] + [str(root / p) for p in required]
        assert 'STALE CACHED RULE' not in prompt
        assert 'TOŻSAMOŚCI, nie stylu' in prompt
        assert all(rule in prompt for rule in policy['review_rules'])
    assert 'RULE ADDED AFTER FIRST GENERATION' not in calls[0][1]
    assert 'RULE ADDED AFTER FIRST GENERATION' in calls[1][1]
    assert len(studio.read(directory)['variants']) == 2


def test_studio_preview_uses_structured_review_and_policy_receipt(policy_repo, monkeypatch):
    import shutil
    from echoes_autopilot_desktop import art_studio as studio_module, runner as runner_module
    root, policy = policy_repo
    studio, directory = studio_request(root, policy)
    candidate = root / 'candidate.png'
    png(candidate, (10, 10, 89, 89))
    studio.import_variant(directory, candidate)
    work = root / 'output/fixture-work'
    report = root / 'output/fixture-report'
    report.mkdir(parents=True)
    shutil.copytree(root / 'godot', work / 'godot')
    monkeypatch.setattr(studio_module, 'create_workspace', lambda *args, **kwargs: {'root': str(work)})
    calls = []
    class FakeRunner:
        def __init__(self, settings, **kwargs):
            calls.append(settings.resolutions)
            self.state = {'status': 'CAPTURED', 'checks': [], 'screenshots': []}

        def run(self, *args):
            for size in ['1280x720', '1920x1080']:
                name = f'combat_wolf_{size}.png'
                png(report / name)
                self.state['screenshots'].append(name)
            return report

        def agent(self, label, model, prompt, schema, images):
            assert schema == ENEMY_REVIEW
            assert all(rule in prompt for rule in policy['review_rules'])
            return good_review(studio.enemy_targets(studio.read(directory)), images)

        def save(self, status):
            self.state['status'] = status
    monkeypatch.setattr(runner_module, 'Autopilot', FakeRunner)
    variant = studio.preview(directory, 0)
    assert calls == [[[1280, 720], [1920, 1080]]]
    assert variant['reviewed_policy'] == art.policy_fingerprint(root, policy)
    assert variant['review']['verdict'] == 'PASS'
    assert variant['quality']['ok'] is True
    # Installation is only exercised on the temporary fixture, never game art.
    studio.install(directory, 0)
    assert file_hash(root / policy['scenario_enemies']['combat_wolf']) == file_hash(candidate)
