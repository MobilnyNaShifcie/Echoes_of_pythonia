"""One-shot transcription of the completed Codex visual inspection, not an AI judge.

Run only for this reviewed batch. Refuses to overwrite the signed-off review.
Owner consent is recorded separately; diagnostics are deliberately not hidden.
"""
import hashlib
import html
import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
OUT = HERE / 'integration'
sys.path.insert(0, str(ROOT / 'tools'))
from echoes_autopilot_desktop.schemas import ENEMY_CRITERIA, validate_enemy_review

# Observed in final Godot boards 01–13, both resolutions, after frame corrections.
ENGINE_NOTES = {
    'wild_dog': 'Lean dog is now smaller than the hero; four paws, ears and tail complete, brown fur separates from the grey plain.',
    'slime': 'Compact teal body stays low on the battlefield; entire lobe outline and violet core visible. Droplets are effects, not extra creatures.',
    'wolf': 'Grey wolf is larger than dog but below hero height; four paws and tail remain visible, muzzle directed toward mage.',
    'boar': 'Heavy russet body, full tusks, hooves and back bristles remain inside the slot at reduced scale.',
    'cursed_scarecrow': 'Complete ochre straw crown, scythe arc and both straw feet; wrists and limbs remain traceable against the dry plain.',
    'plains_spirit': 'Blue lantern, two hands and flowing robe tips remain distinct; no cropping of the naturally dissolving lower silhouette.',
    'nature_guardian': 'Branch crown now below the HUD and inside slot; amber core, shield and root feet are complete after frame correction.',
    'forest_cultist': 'Skull mask and antlers, staff, hands and boot silhouettes fit under HUD; olive cloth belongs to Black Forest.',
    'rotting_knight': 'Green visor, sword, shield and boots are readable against forest; strong armor blocks match illustrated hero materials.',
    'corrupted_bear': 'Large charcoal bear remains distinct from forest; purple fissures localized to body, full paws visible.',
    'black_hart': 'Complete antler branches, four thin hooved legs and dark plum body; magenta veins provide restrained contrast against forest.',
    'gallows_wraith': 'Grey arms, ochre noose, robe ribbons and both bare feet readable; complete single hanging-ghost silhouette.',
    'blackwood_executioner': 'Full axe blade, branching shoulder armor and two heavy boots; both grips readable and no overlap with mage or HUD.',
    'bog_crawler': 'Low olive reptile shows four limbs and complete curling tail; muzzle points left, body rests on the marsh plane.',
    'drowned_dead': 'Slate face, both hands and boots remain readable; teal coat strips follow the muted marsh palette.',
    'swamp_witch': 'Drawn face and grouped hair match the illustrated mage; branch staff, extended hand and both boots remain clear.',
    'bone_crocodile': 'All four clawed feet, long jaw and curled tail remain in frame; ivory armor groups stay readable over olive hide.',
    'mist_walker': 'Long skull beak points left; reed bundles, two hanging arms and separated long legs form a clear marsh silhouette.',
    'drowned_mother': 'Complete crown, tall staff, trailing robe and bare feet; grouped hair and muted olive fabrics sit naturally against marsh.',
    'boneburner': 'Charred rib shapes, both long arms and feet remain clear; rust ribbons connect visually to the ash region.',
    'red_salamander': 'Four clawed legs and complete curling crest/tail visible; grouped red plates and orange highlights fit the scorched region.',
    'hearth_devourer': 'Horns, two clawed hands, furnace ribs and both feet readable; limited orange glow separates the charcoal body from ruins.',
    'azhar': 'Full crown, pale hair, curved polearm and boots; layered ochre/rust cloth retains ash-boss identity without copying mage colors.',
    'frozen_castaway': 'Full cutlass, ice hand and two boots visible; large navy folds and ice facets echo coastal greys and blues.',
    'ice_crab': 'Complete claws and exposed leg tips under angular blue shell; reduced height grounds the crab below hero, without clipping ice spikes.',
}


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def write(path, value):
    path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')


def main():
    destination = OUT / 'enemy_visual_review.json'
    if destination.exists():
        raise RuntimeError('Review already finalized; do not silently reapprove changed images.')
    approval = read(OUT / 'approval.json')
    checks = read(OUT / 'capture_checks.json')
    captured = read(OUT / 'in_game_final/manifest.json')
    observed = read(HERE / 'qualitative_review.json')['observations']
    assert set(ENGINE_NOTES) == {a['enemy'] for a in approval['assets']}
    assert len(captured['images']) == 50 and len(checks['geometry_checks']) == 50
    images = [OUT / 'in_game_final' / name for name in captured['images']]
    for asset in approval['assets']:
        assert hashlib.sha256((ROOT / asset['source']).read_bytes()).hexdigest() == asset['approved_sha256']
    targets = {t['source']: t['references'] for t in checks['review_targets']}
    review = dict(
        verdict='PASS',
        summary='Codex manual visual inspection: 25 owner-approved sources and 50 final Godot frames, viewed as boards 01–13. PASS applies to art/style/framing only, not a clean engine-log gate. Original source observations are supplemented by actual in-game review; this is not a separate Sol or human review.',
        reviewed_images=[p.name for p in images],
        findings=[dict(
            title='Host/import diagnostics retained; engine logs are not clean', priority='P3',
            category='bug', must_fix=False,
            evidence=['in_game_final/capture.log: ERROR: Failed to read the root certificate store.',
                      'in_game/import.log: two UndoRedo instances leaked at editor-import exit; absent from final capture.',
                      'tests/gut_final.log: same certificate error; 676/676 tests pass.'],
            recommendation='Investigate Windows certificate-store access and import-only editor cleanup separately. Do not suppress these logs or count this art PASS as a warning-free runtime gate.'
        )],
        suggestions=['venom_spider remains on its original production art pending readable eight-leg anatomy.',
                     'These are flattened idle cutouts; layered 2D rigging and animation deformation are not implemented or certified.',
                     'Coverage is static day combat with the female mage at 720p and 1080p; no night, animation or every-class coverage is claimed.'],
        enemy_art_checks=[],
    )
    for asset in approval['assets']:
        enemy = asset['enemy']
        shot = f'combat_{enemy}_1920x1080.png'
        small = f'combat_{enemy}_1280x720.png'
        source_note = f'{asset["source"]}, body/materials: {observed[enemy]}'
        frame_note = f'{shot} and {small}, right combatant slot: {ENGINE_NOTES[enemy]}'
        evidence = {
            'material_stylization': [source_note, frame_note],
            'shape_detail_shading': [frame_note, 'Compared to the class-reference drawn planes and grouped shadows; decorative detail remains subordinate to the silhouette.'],
            'regional_identity': [frame_note, f'Region reference: godot/assets/combat/backgrounds/{asset["region"]}_day.png; geography/palette also compared to the integrated world map.'],
            'full_body_single_subject': [frame_note, f'{asset["source"]}: transparent cutout with complete alpha bounds; no rectangular background or extra subject visible.'],
            'left_facing_idle': [frame_note, 'Head/weapon direction is toward the left-side mage in combat idle, not an attack impact; no horizontal flip applied.'],
            'rigging_readability': [frame_note, 'Visible limb/major-part boundaries are readable for future segmentation. Ordinary pose occlusion is not a layered rig; hidden surfaces and deformation still require production work.'],
        }
        review['enemy_art_checks'].append(dict(source=asset['source'],
            criteria=[dict(criterion=c, status='PASS', evidence=evidence[c]) for c in ENEMY_CRITERIA],
            compared_references=targets[asset['source']]))
    validate_enemy_review(review, images, checks['review_targets'])
    write(destination, review)
    checks['visual_review'] = 'PASS_ART_AND_FRAMING_ONLY'
    checks['visual_review_file'] = destination.name
    checks['source_review'] = '../qualitative_review.json'
    checks['engine_log_gate'] = 'DIAGNOSTICS_PRESENT_NOT_CLEAN'
    checks['reviewed_capture_sha256'] = {p.name: hashlib.sha256(p.read_bytes()).hexdigest() for p in images}
    write(OUT / 'capture_checks.json', checks)
    approval['production_status'] = 'INTEGRATED_VISUALLY_REVIEWED'
    approval['integration_policy_fingerprint'] = captured['policy_fingerprint']
    approval['visual_review'] = 'enemy_visual_review.json'
    approval['engine_log_gate'] = 'DIAGNOSTICS_PRESENT_NOT_CLEAN'
    for asset in approval['assets']:
        asset['decision'] = 'OWNER_APPROVED_INTEGRATED_VISUALLY_REVIEWED'
        asset['production_changed'] = True
    write(OUT / 'approval.json', approval)
    cards = []
    for board in checks['boards']:
        cards.append(f'<a href="boards/{board}"><img loading="lazy" src="boards/{board}" alt="{html.escape(board)}"></a>')
    links = ''.join(f'<li><a href="in_game_final/{p.name}">{html.escape(p.stem)}</a></li>' for p in images)
    page = '''<!doctype html><html lang="pl"><meta charset="utf-8"><title>Przeciwnicy — integracja</title>
<style>body{margin:32px auto;max-width:1536px;padding:0 20px;background:#101923;color:#d7e1ec;font:17px/1.5 system-ui}h1{color:#efc96c}a{color:#88c9f8}img{display:block;width:100%;height:auto;margin:24px 0}summary{cursor:pointer}</style>
<h1>25 zaakceptowanych przeciwników — podłączone</h1>
<p>12 września 2026. Poprawione kadrowanie, skala i wspólna linia podłoża. Bez zmian mechanik ani zapisów gracza. Pająk pozostaje w starej wersji — poprawka nóg odłożona.</p>
<p>50 końcowych ujęć: po lewej 1280×720, po prawej 1920×1080. Godot: 676/676 testów; Python: 96/96. To przegląd statycznych scen dziennych z maginią, nie test animacji ani wszystkich klas.</p>
<p>Diagnostyka środowiska: Godot zgłasza błąd odczytu magazynu certyfikatów Windows. Import edytora zgłosił też dwie pozostawione instancje UndoRedo; końcowy render ich nie zgłasza. Testy i renderowanie zakończyły się poprawnie, ale logów nie oznaczono jako czyste.</p>
<p><a href="approval.json">Zgoda i oryginalne sumy plików</a> · <a href="enemy_visual_review.json">Review wizualny</a> · <a href="capture_checks.json">Kontrole i sumy ujęć</a> · <a href="../review/index.html">Przed / po</a></p>
'''+''.join(cards)+'<details><summary>Pełne ujęcia</summary><ul>'+links+'</ul></details></html>'
    (OUT / 'index.html').write_text(page, encoding='utf-8')
    print('Finalized: 25 art reviews / 150 criteria / 50 frames. Host diagnostics preserved.')


if __name__ == '__main__':
    main()
