"""Run the existing Godot capture fixture for the approved batch, isolated saves."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(ROOT / 'tools'))
from echoes_autopilot_desktop.art_policy import load_art_policy, policy_fingerprint


def run():
    parser = argparse.ArgumentParser()
    parser.add_argument('--label', default='in_game')
    parser.add_argument('--only', nargs='*')
    parser.add_argument('--hour', type=int, default=12)
    parser.add_argument('--hero', default='mage')
    parser.add_argument('--skip-import', action='store_true')
    args = parser.parse_args()
    if not args.label.replace('_', '').isalnum():
        raise ValueError('Invalid capture label')
    output = HERE / 'integration' / args.label
    output.mkdir(parents=True, exist_ok=True)
    approval = json.loads((HERE / 'integration/approval.json').read_text(encoding='utf-8'))
    selected = [a for a in approval['assets'] if not args.only or a['enemy'] in args.only]
    if args.only and set(args.only) != {a['enemy'] for a in selected}:
        raise ValueError('Capture is restricted to approved batch IDs')
    policy = load_art_policy(ROOT)
    for a in selected:
        scenario = 'combat_' + a['enemy']
        assert policy['scenario_regions'][scenario] == a['region']
        assert policy['scenario_enemies'][scenario] == a['source']
    request = dict(output=str(output), scenarios=['combat_' + a['enemy'] for a in selected],
                   resolutions=[[1280,720],[1920,1080]], hero_class=args.hero, hour=args.hour)
    (output / 'request.json').write_text(json.dumps(request, indent=2)+'\n', encoding='utf-8')
    runtime = HERE / 'integration/runtime'
    runtime.mkdir(exist_ok=True)
    for name in ['Godot_v4.7.1-stable_win64_console.exe', 'Godot_v4.7.1-stable_win64.exe']:
        if not (runtime / name).exists():
            shutil.copy2(ROOT / '.tools/godot' / name, runtime / name)
    executable = runtime / 'Godot_v4.7.1-stable_win64_console.exe'
    env = os.environ.copy()
    for key in ['APPDATA', 'LOCALAPPDATA', 'XDG_DATA_HOME']:
        location = output / 'profile' / key.lower()
        location.mkdir(parents=True, exist_ok=True)
        env[key] = str(location)
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    common = [str(executable), '--path', str(ROOT / 'godot'), '--audio-driver', 'Dummy', '--verbose']
    stages = []
    if not args.skip_import:
        stages.append(('import', common + ['--headless', '--editor', '--import']))
    stages.append(('capture', common + ['--rendering-method', 'gl_compatibility',
                  '--rendering-driver', 'opengl3', '--resolution', '640x360',
                  '--position', '-20000,-20000', '--script', 'res://tools/autopilot_capture.gd',
                  '--', str(output / 'request.json')]))
    for label, command in stages:
        print('Running', label, flush=True)
        result = subprocess.run(command, cwd=ROOT, env=env, startupinfo=startup,
                                capture_output=True, timeout=360)
        content = (result.stdout + result.stderr).decode('utf-8', errors='replace')
        (output / (label+'.log')).write_text(content, encoding='utf-8')
        if result.returncode or 'SCRIPT ERROR:' in content:
            raise RuntimeError(f'{label} failed; see {output / (label+".log")}\n'+content[-5000:])
        print(label, 'exit', result.returncode, 'ERROR lines', content.count('ERROR:'), flush=True)
    evidence = json.loads((output / 'manifest.json').read_text(encoding='utf-8'))
    expected = {f'{s}_{w}x{h}.png' for s in request['scenarios'] for w,h in request['resolutions']}
    assert evidence['ok'] and set(evidence['images']) == expected
    assert len(evidence['layouts']) == len(expected)
    evidence['policy_fingerprint'] = policy_fingerprint(ROOT, policy)
    (output / 'manifest.json').write_text(json.dumps(evidence, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    print('Captured', len(expected), 'actual Godot frames:', output, flush=True)


if __name__ == '__main__':
    run()
