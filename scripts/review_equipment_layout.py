"""Isolated Godot import/boot, equipment capture and optional GUT tests."""
import argparse
import os
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('stage', choices=['before', 'after'])
    parser.add_argument('--tests', action='store_true')
    args = parser.parse_args()
    work = ROOT / 'build/equipment-layout-review' / args.stage
    work.mkdir(parents=True, exist_ok=True)
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
    commands = [('import', ['--headless', '--editor', '--import']),
                ('boot', ['--headless', '--quit-after', '4']),
                ('capture', ['--rendering-method', 'gl_compatibility', '--rendering-driver', 'opengl3',
                             '--position', '-20000,-20000', '--resolution', '640x360',
                             '--script', 'res://tools/capture_equipment_layout.gd',
                             '--', str(output), str(work / 'fixture_saves')])]
    if args.tests:
        commands.append(('gut', ['--headless', '-s', 'res://addons/gut/gut_cmdln.gd',
                                 '-gdir=res://tests', '-ginclude_subdirs', '-gexit']))
    for label, flags in commands:
        print('Running', label, flush=True)
        result = subprocess.run(common + flags, cwd=ROOT, env=env, startupinfo=startup,
                                capture_output=True, timeout=600)
        log = (result.stdout + result.stderr).decode('utf-8', errors='replace')
        (work / (label + '.log')).write_text(log, encoding='utf-8')
        diagnostics = [line for line in log.splitlines() if 'ERROR:' in line or 'WARNING:' in line]
        print(label, 'exit', result.returncode, '\n'.join(diagnostics), flush=True)
        # Windows host certificate diagnostics remain visible, never silently filtered from logs.
        failures = [line for line in diagnostics if 'ERROR:' in line and
                    'Failed to read the root certificate store.' not in line]
        if result.returncode or failures:
            raise RuntimeError(f'{label} failed; see {work / (label + ".log")}\n' + log[-5000:])
    print('Review evidence:', output, flush=True)


if __name__ == '__main__':
    main()
