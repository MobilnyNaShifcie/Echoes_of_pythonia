"""Inventory production enemy art and build review boards; no production edits."""
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from echoes_autopilot_desktop.art_policy import load_art_policy, inspect_enemy_png, policy_fingerprint


def main():
    catalog = (ROOT / 'godot/ui/presentation/combat_presentation_catalog.gd').read_text(encoding='utf-8')
    section = catalog.split('const ENEMY_PRESENTATIONS := {', 1)[1].split('const HERO_PRESENTATIONS', 1)[0]
    pairs = re.findall(r'"([a-z_]+)":\s*\{\s*"texture": preload\("res://([^\"]+)"\)', section)
    mapping = dict(pairs)
    regions = ['twilight_plains', 'black_forest', 'silentwater_marshes', 'ashen_borderlands', 'ice_coast']
    groups, used = {}, set()
    for number, region in zip(['ONE','TWO','THREE','FOUR','FIVE'], regions):
        body = re.search(r'const REGION_' + number + r'_ENEMY_IDS := \[(.*?)\]', catalog, re.S).group(1)
        ids = re.findall(r'"([a-z_]+)"', body)
        groups[region] = ids
        used.update(ids)
    groups['dungeon'] = [enemy for enemy in mapping if enemy not in used]
    boards = HERE / 'audit'
    boards.mkdir(parents=True, exist_ok=True)
    policy = load_art_policy(ROOT)
    records = []
    for region, ids in groups.items():
        paths = [ROOT / 'godot' / mapping[enemy] for enemy in ids]
        subprocess.run([sys.executable, str(ROOT / 'scripts/build_art_reference_board.py'),
                        '--output', str(boards / (region + '_current.png')), *map(str, paths)], check=True)
        if region in regions:
            subprocess.run([sys.executable, str(ROOT / 'scripts/build_art_reference_board.py'),
                            '--region', region, '--output', str(boards / (region + '_references.png'))], check=True)
        for enemy, path in zip(ids, paths):
            records.append(dict(enemy=enemy, region=region, source=path.relative_to(ROOT).as_posix(),
                                source_sha256=hashlib.sha256(path.read_bytes()).hexdigest(),
                                pixel_gate=inspect_enemy_png(path), decision='PENDING_VISUAL_AUDIT'))
    active = {r['source'] for r in records}
    unused = [p.relative_to(ROOT).as_posix() for p in (ROOT/'godot/assets/combat/enemies').glob('*.png')
              if p.relative_to(ROOT).as_posix() not in active]
    if unused:
        subprocess.run([sys.executable, str(ROOT / 'scripts/build_art_reference_board.py'),
                        '--output', str(boards / 'unused_current.png'), *[str(ROOT / p) for p in unused]], check=True)
    report = dict(policy='AI_CONTEXT/ART_DIRECTION.md', policy_fingerprint=policy_fingerprint(ROOT,policy),
                  production_changed=False, assets=records, unused_source_pngs=unused)
    target = boards / 'inventory.json'
    if target.exists():
        raise FileExistsError('Preserve the existing audit; do not reset decisions')
    target.write_text(json.dumps(report, ensure_ascii=False, indent=2)+'\n',encoding='utf-8')
    print('Active unique sources:',len(records),'Unused:',unused)


if __name__ == '__main__':
    main()
