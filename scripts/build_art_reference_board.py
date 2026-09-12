"""Read-only reference overview and source PNG gate; artwork is never modified."""
import argparse
import json
import math
import subprocess
import sys
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from echoes_autopilot_desktop.art_policy import (
    POLICY_DOCUMENT, load_art_policy, reference_path, references_for_region,
    generation_brief, inspect_enemy_png, policy_fingerprint,
    changed_enemy_sources,
)


def inspect_enemy_source(root, relative):
    path = reference_path(root, relative)
    if path.suffix.lower() != '.png' or not path.resolve().is_relative_to(
        (root / 'godot/assets').resolve()
    ):
        raise ValueError(f'Enemy source must be a PNG inside godot/assets: {relative}')
    return inspect_enemy_png(path)


def scenario_manifest(root, policy, scenario):
    region = policy['scenario_regions'].get(scenario)
    source = policy['scenario_enemies'].get(scenario)
    if not region or not source:
        raise ValueError(f'Missing region or enemy_source mapping for {scenario}')
    return {
        'scenario': scenario, 'region': region, 'enemy_source': source,
        'enemy_checks': inspect_enemy_source(root, source),
    }


def unmapped_enemy_sources(root, policy, base_ref='HEAD'):
    enemy_sources = set(changed_enemy_sources(root, base_ref))
    return sorted(enemy_sources - set(policy['scenario_enemies'].values()))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', type=Path, required=True)
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--region', help='Prepare canonical generation references.')
    mode.add_argument('--scenario', help='Include and inspect the mapped original enemy PNG.')
    mode.add_argument('--check-enemies', action='store_true', help='Write a source-gate JSON report.')
    parser.add_argument('--base-ref', default='HEAD', help='Git revision before the reviewed asset changes.')
    parser.add_argument('images', nargs='*', type=Path)
    args = parser.parse_args()
    canonical = args.region or args.scenario or args.check_enemies
    if canonical and args.images:
        parser.error('Use a canonical mode or explicit images for a manual board.')
    brief = None
    manifest = None
    source_path = None
    failed = False
    if canonical:
        try:
            policy = load_art_policy(ROOT)
            if policy is None:
                raise ValueError(f'Missing {POLICY_DOCUMENT}')
            if args.check_enemies or args.scenario:
                unmapped = unmapped_enemy_sources(ROOT, policy, args.base_ref)
                if unmapped:
                    raise ValueError('Missing scenario enemy_source mappings: ' + ', '.join(unmapped))
            if args.check_enemies:
                records = [scenario_manifest(ROOT, policy, name)
                           for name in policy['scenario_regions']]
                args.output.parent.mkdir(parents=True, exist_ok=True)
                args.output.write_text(json.dumps({
                    'policy_document': POLICY_DOCUMENT, 'base_ref': args.base_ref,
                    'scenarios': records,
                }, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')
                return int(any(r['enemy_checks']['status'] != 'PASS' for r in records))
            if args.scenario:
                manifest = scenario_manifest(ROOT, policy, args.scenario)
                args.region = manifest['region']
                source_path = reference_path(ROOT, manifest['enemy_source'])
                failed = manifest['enemy_checks']['status'] != 'PASS'
            references = references_for_region(ROOT, policy, args.region)
            if source_path is not None:
                references.append((source_path, 'SOURCE ENEMY PNG UNDER REVIEW; NOT A STYLE REFERENCE'))
        except (OSError, ValueError, subprocess.CalledProcessError) as exc:
            parser.error(str(exc))
        args.images = [path for path, _ in references]
        brief = generation_brief(ROOT, policy, args.region)
        if source_path:
            brief += '\nIDENTITY ONLY, not a style reference: ' + manifest['enemy_source']
    if not args.images:
        parser.error('Provide --region, --scenario, --check-enemies or at least one image.')
    cols, w, h = 4, 420, 440
    board = Image.new('RGB', (cols*w, math.ceil(len(args.images)/cols)*h), '#162330')
    draw = ImageDraw.Draw(board)
    try:
        font = ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf', 20)
    except OSError:
        font = ImageFont.load_default(size=20)
    for i, path in enumerate(args.images):
        with Image.open(path) as source:
            art = source.convert('RGBA')
        bounds = art.getchannel('A').getbbox()
        # Preserve the entire source canvas so the board does not conceal poor margins.
        if bounds and path != source_path:
            art = art.crop(bounds)
        art.thumbnail((w-26, h-55), Image.Resampling.LANCZOS)
        x, y = (i%cols)*w, (i//cols)*h
        board.paste(art, (x+(w-art.width)//2, y+8+(h-55-art.height)//2), art)
        draw.text((x+10, y+h-35), path.stem, font=font, fill='#e6e9ee')
    args.output.parent.mkdir(parents=True, exist_ok=True)
    board.save(args.output)
    if brief:
        args.output.with_suffix('.prompt.txt').write_text(brief + '\n', encoding='utf-8')
        manifest = {
            **(manifest or {}), 'region': args.region, 'policy_document': POLICY_DOCUMENT,
            'policy_fingerprint': policy_fingerprint(ROOT, policy),
            'references': [{'path': p.relative_to(ROOT).as_posix(), 'role': role} for p, role in references],
        }
        args.output.with_suffix('.references.json').write_text(
            json.dumps(manifest, ensure_ascii=False, indent=2) + '\n', encoding='utf-8',
        )
    print(args.output)
    return int(failed)


if __name__ == '__main__':
    raise SystemExit(main())
