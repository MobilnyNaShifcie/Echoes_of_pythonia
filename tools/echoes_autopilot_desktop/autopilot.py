from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

if not __package__:
    sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
    __package__ = 'echoes_autopilot_desktop'

try:
    from .config import REPO_ROOT, load_settings
    from .runner import Autopilot
except ImportError:
    from config import REPO_ROOT, load_settings
    from runner import Autopilot


def main(argv=None):
    parser = argparse.ArgumentParser(description='Echoes Autopilot — Astra wprowadza zmiany, Sol ocenia grę.')
    parser.add_argument('task', nargs='?', help='Opis zadania dla Astry')
    mode = parser.add_mutually_exclusive_group()
    mode.add_argument('--doctor', action='store_true', help='Diagnostyka narzędzi i logowania')
    mode.add_argument('--audit', action='store_true', help='Testy, obrazy i ocena Sola bez zmian')
    mode.add_argument('--capture', action='store_true', help='Tylko obrazy, bez modeli')
    mode.add_argument('--test', action='store_true', help='Tylko kontrole techniczne, bez modeli')
    mode.add_argument('--gui', action='store_true', help='Panel okienkowy')
    mode.add_argument('--resume-latest', action='store_true', help='Wznów ostatni niezaliczony przebieg')
    mode.add_argument('--journey', action='store_true', help='Test sekwencji czynności gracza')
    parser.add_argument('--isolated', action='store_true', help='Osobna kopia gry dla zadania')
    parser.add_argument('--branch', help='Branch dla osobnej kopii gry')
    parser.add_argument('--branch-only', action='store_true', help='Nie dołączaj lokalnych zmian')
    parser.add_argument('--settings', type=Path, help='Alternatywny plik ustawień JSON')
    parser.add_argument('--scenarios', help='Scenariusze oddzielone przecinkami')
    parser.add_argument('--max-cycles', type=int, help='Maksymalnie 1–5 cykli poprawek')
    args = parser.parse_args(argv)
    try:
        settings = load_settings(args.settings) if args.settings else load_settings()
        if args.isolated or args.branch:
            settings.isolated_workspace = True
        if args.branch:
            settings.branch = args.branch
        if args.branch_only:
            settings.include_local_changes = False
        if args.scenarios:
            settings.scenarios = args.scenarios.split(',')
        if args.max_cycles is not None:
            settings.max_cycles = args.max_cycles
        settings.validate()
        if args.gui or not any([args.task, args.doctor, args.audit, args.capture, args.test, args.resume_latest, args.journey]):
            try:
                from .panel import launch
            except ImportError:
                from panel import launch
            launch(settings)
            return 0
        runner = Autopilot(settings, on_event=lambda text: print(text, flush=True))
        if args.doctor:
            checks = runner.doctor()
            print(json.dumps(checks, ensure_ascii=False, indent=2))
            return 0 if all(c['ok'] for c in checks) else 1
        resume = None
        if args.resume_latest:
            runs = sorted((REPO_ROOT / 'output/ai-team').glob('RUN-*/state.json'), reverse=True)
            if not runs:
                raise ValueError('Brak przebiegu do wznowienia.')
            resume = runs[0].parent
        mode = 'journey' if args.journey else 'audit' if args.audit else 'capture' if args.capture else 'test' if args.test else 'task'
        descriptions = {'journey': 'Sekwencja czynności gracza', 'audit': 'Audyt błędów, rozgrywki i spójności grafiki',
                        'capture': 'Zrzuty scen gry', 'test': 'Kontrole techniczne gry', 'task': 'Wznowienie'}
        directory = runner.run(args.task or descriptions[mode], mode, resume=resume)
        print(f'Raport: {directory / "report.html"}')
        return 0 if runner.state['status'] in {'PASSED', 'CAPTURED', 'TESTED'} else 2
    except (ValueError, RuntimeError, OSError) as exc:
        print(f'Błąd: {exc}')
        return 2


if __name__ == '__main__':
    raise SystemExit(main())
