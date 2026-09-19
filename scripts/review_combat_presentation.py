"""Capture the real combat screen; isolate profiles and keep evidence out of Git."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('stage', choices=['before', 'after'])
    parser.add_argument('--only-tests', action='store_true')
    parser.add_argument('--only-capture', action='store_true')
    parser.add_argument('--tests', action='store_true')
    parser.add_argument('--test-script')
    args = parser.parse_args()
    work = ROOT / 'build/combat-presentation-review' / args.stage
    output = work / 'evidence'
    output.mkdir(parents=True, exist_ok=True)
    runtime = work.parent / 'runtime'
    runtime.mkdir(exist_ok=True)
    for name in ['Godot_v4.7.1-stable_win64_console.exe', 'Godot_v4.7.1-stable_win64.exe']:
        if not (runtime / name).exists():
            shutil.copy2(ROOT / '.tools/godot' / name, runtime / name)
    env = os.environ.copy()
    for key in ['APPDATA', 'LOCALAPPDATA', 'XDG_DATA_HOME']:
        profile = work / 'profile' / key.lower()
        profile.mkdir(parents=True, exist_ok=True)
        env[key] = str(profile)
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    common = [str(runtime / 'Godot_v4.7.1-stable_win64_console.exe'),
              '--path', str(ROOT / 'godot'), '--audio-driver', 'Dummy', '--verbose']
    commands = [] if args.only_tests else [
        ('import', ['--headless', '--editor', '--recovery-mode', '--import']),
        ('boot', ['--headless', '--quit-after', '4']),
        ('capture', ['--rendering-method', 'gl_compatibility', '--rendering-driver', 'opengl3',
                     '--position', '-20000,-20000', '--resolution', '640x360',
                     '--script', 'res://tools/render_combat_hud_preview.gd', '--', str(output)])]
    if args.only_capture:
        commands = [(label, flags) for label, flags in commands if label == 'capture']
    if args.tests or args.only_tests:
        selection = ['-gdir=', '-gtest=' + args.test_script] if args.test_script else [
            '-gdir=res://tests', '-ginclude_subdirs']
        commands.append(('gut', ['--headless', '-s', 'res://addons/gut/gut_cmdln.gd',
                                 *selection, '-gexit']))
    for label, flags in commands:
        print('Running', label, flush=True)
        result = subprocess.run(common + flags, cwd=ROOT, env=env, startupinfo=startup,
                                capture_output=True, timeout=600)
        log = (result.stdout + result.stderr).decode('utf-8', errors='replace')
        (work / (label + '.log')).write_text(log, encoding='utf-8')
        diagnostics = [line for line in log.splitlines() if 'ERROR:' in line or 'WARNING:' in line]
        print(label, 'exit', result.returncode, '\n'.join(diagnostics), flush=True)
        failures = [line for line in diagnostics if 'ERROR:' in line and
                    'Failed to read the root certificate store.' not in line]
        if result.returncode or failures:
            raise RuntimeError(f'{label} failed; see {work / (label + ".log")}\n' + log[-5000:])
    print('Evidence:', output, flush=True)


if __name__ == '__main__':
    main()
