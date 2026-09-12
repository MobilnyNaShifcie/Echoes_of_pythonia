"""Derive per-enemy prompts from canonical policy and the reviewed inventory."""
import json
from pathlib import Path
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0,str(ROOT/'tools'))
from echoes_autopilot_desktop.art_policy import load_art_policy, references_for_region, generation_brief, policy_fingerprint


def main():
    decisions=json.loads((HERE/'decisions.json').read_text(encoding='utf-8'))
    inventory=json.loads((HERE/'audit/inventory.json').read_text(encoding='utf-8'))
    policy=load_art_policy(ROOT)
    assigned=set(decisions['regenerate']) | set(decisions['reuse_pilot']) | set(decisions['keep'])
    assert assigned == {a['enemy'] for a in inventory['assets']}
    assert sum(len(decisions[k]) for k in ['regenerate','reuse_pilot','keep']) == len(assigned)
    jobs=[]
    for asset in inventory['assets']:
        name=asset['enemy']
        if name not in decisions['regenerate']:
            continue
        reason,identity=decisions['regenerate'][name]
        references=references_for_region(ROOT,policy,asset['region'])
        prompt=(
            'Use case: style-transfer. Asset: one complete enemy combat sprite for Echoes of Pythonia.\n'
            'Image 1: existing enemy, identity/design reference and edit target ONLY, not a rendering-style reference. '
            'Images 2 and 3: approved class STYLE references. Use their mature anime-fantasy linework, deliberate shapes, '
            'clean material shading and grouped details, NOT their human anatomy, costume or colors. '
            'Image 4: current world map context. Image 5: correct regional landscape, PALETTE context only, do not paint scenery.\n'
            'Primary correction: '+reason+'\n'
            'Identity invariants: '+identity+'\n'
            'Rendering: stylized fantasy GAME ILLUSTRATION. Strong drawn contour, controlled large light/shadow groups, '
            'selective softer transitions and purposeful detail. Not photorealism, not a PBR/3D render, not photographic skin, '
            'fur, fabric, wetness or material grain. Also not flat/chibi, clipart or toy-like. Preserve the original creature, '
            'do not redesign its species or repaint it with class colors.\n'
            'Composition: one full body only, side/three-quarter combat IDLE facing LEFT toward a hero offscreen. '
            'Face, gaze and weapon leading left, body trailing right. Do not face the viewer symmetrically. '
            'Separate visible limbs at joints and preserve complete tips, tail, horns, wings and weapon. '
            'Center its full silhouette on the canvas with at least 8% blank margin on every side. '
            'Grounded weight for walking creatures; naturally floating ghosts keep their complete connected lower shape.\n'
            'THIS IS THE RAW FIRST PASS FOR AUTHORIZED LOCAL EXTRACTION. Background: one perfectly uniform '
            'saturated MAGENTA #FF00FF solid-color matte. Fill every empty pixel and hole with that exact magenta. '
            'Do NOT draw transparency, a checkerboard or a grey backdrop. Do NOT tint the subject with magenta. '
            'No floor, shadow puddle, scenery, text, UI, border, labels, extra creatures, glitter or disconnected debris. '
            'A separate local second pass removes the matte and creates true RGBA required by the canonical final-asset rules below.\n\n'
            +generation_brief(ROOT,policy,asset['region'])
        )
        jobs.append(dict(enemy=name,region=asset['region'],source=asset['source'],source_sha256=asset['source_sha256'],
                         prompt=prompt,references=[str(ROOT/asset['source'])]+[str(p) for p,_ in references],
                         policy_fingerprint=policy_fingerprint(ROOT,policy),status='PLANNED'))
    (HERE/'jobs.json').write_text(json.dumps(jobs,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print(len(jobs),'regenerations;',len(decisions['reuse_pilot']),'pilot candidates;',len(decisions['keep']),'kept')


if __name__=='__main__':
    main()
