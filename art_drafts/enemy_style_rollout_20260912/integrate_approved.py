"""Integrate the exact owner-approved cutouts, retaining a recoverable backup.

No generation, resampling, game data or save changes. Text metadata is patched
separately with apply_patch. All paths and SHA-256 values are pinned by review.
"""
import argparse
import hashlib
import json
from pathlib import Path
import shutil
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
OUT = HERE / 'integration'
sys.path.insert(0, str(ROOT / 'tools'))
from echoes_autopilot_desktop.art_policy import inspect_enemy_png


def read(path):
    return json.loads(path.read_text(encoding='utf-8'))


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def rooted(relative, parent):
    path = (ROOT / relative).resolve()
    if not path.is_relative_to(parent.resolve()) or not path.is_file():
        raise ValueError(f'Unexpected asset path: {relative}')
    return path


def prepare():
    manifest = read(HERE / 'review/batch_manifest.json')
    if (OUT / 'approval.json').exists():
        raise ValueError('Approval receipt already exists; use --verify or --install')
    records = []
    for asset in manifest['assets']:
        source = rooted(asset['source'], ROOT / 'godot/assets/combat/enemies')
        if sha(source) != asset['source_sha256']:
            raise ValueError(f'Source changed after preview: {asset["enemy"]}')
        if not asset.get('candidate') or asset.get('source_art_review') == 'NEEDS_REVISION':
            continue
        candidate = rooted(asset['candidate'], ROOT / 'art_drafts')
        gate = inspect_enemy_png(candidate)
        if gate['status'] != 'PASS' or gate['sha256'] != asset['pixel_gate']['sha256']:
            raise ValueError(f'Candidate changed or failed alpha gate: {asset["enemy"]}')
        records.append({**asset, 'approved_sha256': sha(candidate),
                        'owner_art_approval': True,
                        'backup': (OUT / 'before/enemies' / source.name).relative_to(ROOT).as_posix()})
    if len(records) != 25 or any(r['enemy'] == 'venom_spider' for r in records):
        raise ValueError('Expected exactly 25 approved candidates; spider is deferred')
    OUT.mkdir(exist_ok=True)
    for record in records:
        backup = ROOT / record['backup']
        backup.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / record['source'], backup)
    for relative in ['AI_CONTEXT/ART_DIRECTION.md', 'godot/assets/ASSET_MANIFEST.md',
                     'godot/ui/presentation/combat_presentation_catalog.gd',
                     'godot/tests/test_combat_presentation.gd', 'godot/tools/autopilot_capture.gd',
                     'docs/ART_AND_AUDIO_PIPELINE_v0.25.0.md']:
        backup = OUT / 'before' / relative
        backup.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / relative, backup)
    approval = dict(owner_message='pasują wprowadzaj', owner_art_approval=True,
                    date='2026-09-12', production_status='NOT_INSTALLED',
                    preview_policy_fingerprint=manifest['policy_fingerprint'],
                    deferred={'venom_spider': manifest['unresolved_revisions']['venom_spider']},
                    assets=records)
    (OUT / 'approval.json').write_text(json.dumps(approval, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print('Prepared 25 hash-pinned approvals and original backups; no production image changed.')


def install():
    approval = read(OUT / 'approval.json')
    # Validate the entire batch before the first overwrite; allow safe resume.
    for record in approval['assets']:
        source = rooted(record['source'], ROOT / 'godot/assets/combat/enemies')
        candidate = rooted(record['candidate'], ROOT / 'art_drafts')
        if sha(candidate) != record['approved_sha256']:
            raise ValueError(f'Approved candidate modified: {candidate}')
        if sha(ROOT / record['backup']) != record['source_sha256']:
            raise ValueError('Backup mismatch')
        if sha(source) not in [record['source_sha256'], record['approved_sha256']]:
            raise ValueError(f'Concurrent production edit: {source}')
    for record in approval['assets']:
        shutil.copyfile(ROOT / record['candidate'], ROOT / record['source'])
    approval['production_status'] = 'INSTALLED_PENDING_ENGINE_REVIEW'
    (OUT / 'approval.json').write_text(json.dumps(approval, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    verify()


def verify():
    approval = read(OUT / 'approval.json')
    approved = {r['enemy']: r for r in approval['assets']}
    evidence = []
    for original in read(HERE / 'audit/inventory.json')['assets']:
        target = ROOT / original['source']
        expected = approved.get(original['enemy'], {}).get('approved_sha256', original['source_sha256'])
        if sha(target) != expected:
            raise ValueError(f'Wrong production bytes: {original["enemy"]}')
        if original['enemy'] in approved:
            gate = inspect_enemy_png(target)
            if gate['status'] != 'PASS':
                raise ValueError(f'PNG gate failed: {original["enemy"]}')
            evidence.append({'enemy': original['enemy'], **gate})
    (OUT / 'installed_checks.json').write_text(json.dumps(dict(
        installed=25, unchanged=18, owner_art_approval=True, asset_checks=evidence,
        note='Byte identity and PNG gate only; engine captures have a separate review.'
    ), ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print('Verified: 25 byte-identical approved cutouts; 18 untouched sources including deferred spider.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('mode', choices=['prepare', 'install', 'verify'])
    args = parser.parse_args()
    globals()[args.mode]()
