"""Capture the real combat screen; isolate profiles and keep evidence out of Git."""
import argparse
import array
import json
import math
import os
from pathlib import Path
import shutil
import subprocess
import wave

ROOT = Path(__file__).resolve().parents[1]


def validate_audio(path):
    """Check the actual offline engine mix, not just play() calls or filenames."""
    with wave.open(str(path), 'rb') as wav:
        if wav.getsampwidth() != 4:
            raise RuntimeError('Expected Godot Movie Maker 32-bit PCM WAV')
        rate, channels = wav.getframerate(), wav.getnchannels()
        samples = array.array('i', wav.readframes(wav.getnframes()))
    peak = max(abs(sample) for sample in samples) / 2147483648
    measurements = {}
    for index, cue in enumerate(['hit', 'critical', 'block', 'dodge', 'victory', 'muted']):
        start, end = 1.1 + index * 3, 3.9 + index * 3
        segment = samples[int(start * rate) * channels:int(end * rate) * channels]
        rms = math.sqrt(sum((sample / 2147483648) ** 2 for sample in segment) / len(segment))
        measurements[cue] = rms
        if (cue == 'muted' and rms != 0) or (cue != 'muted' and rms < 0.00001):
            raise RuntimeError(f'Unexpected audio level for {cue}: {rms}')
    if peak >= 0.95:
        raise RuntimeError(f'Audio mix has insufficient peak headroom: {peak}')
    report = {'sample_rate': rate, 'channels': channels,
              'duration_seconds': len(samples) / channels / rate,
              'peak': peak, 'rms_by_cue': measurements}
    path.with_suffix('.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    print('Audio mix validated:', report, flush=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('stage', choices=['before', 'after'])
    parser.add_argument('--only-tests', action='store_true')
    parser.add_argument('--only-capture', action='store_true')
    parser.add_argument('--tests', action='store_true')
    parser.add_argument('--only-audio', action='store_true',
                        help='Offline PNG/WAV Movie Maker demo, without playing through speakers')
    parser.add_argument('--test-script')
    parser.add_argument('--review-name', choices=['combat-presentation-review', 'combat-victory-review',
                                                'combat-impact-review', 'combat-audio-review'],
                        default='combat-presentation-review')
    parser.add_argument('--capture-script', choices=['render_combat_hud_preview.gd',
                                                    'render_combat_feedback_preview.gd'],
                        default='render_combat_hud_preview.gd')
    args = parser.parse_args()
    work = ROOT / 'build' / args.review_name / args.stage
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
                     '--script', 'res://tools/' + args.capture_script, '--', str(output)])]
    if args.only_capture:
        commands = [(label, flags) for label, flags in commands if label == 'capture']
    if args.only_audio:
        audio_dir = output / 'audio'
        audio_dir.mkdir(exist_ok=True)
        commands = [('audio', ['--rendering-method', 'gl_compatibility',
                              '--rendering-driver', 'opengl3', '--position', '-20000,-20000',
                              '--resolution', '640x360', '--fixed-fps', '20',
                              '--write-movie', str(audio_dir / 'combat-audio.png'),
                              '--script', 'res://tools/render_combat_audio_preview.gd'])]
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
        if label == 'audio':
            validate_audio(audio_dir / 'combat-audio.wav')
    print('Evidence:', output, flush=True)


if __name__ == '__main__':
    main()
