"""Versioned PNG candidates, built-in Codex generation and real Godot previews."""
from __future__ import annotations

import copy
import json
import os
import shutil
import time
import uuid
from pathlib import Path

from PIL import Image

from .art_policy import (load_art_policy, reference_path, references_for_region,
                         generation_brief, inspect_enemy_png, is_enemy_source,
                         policy_fingerprint, POLICY_DOCUMENT)
from .config import write_json
from .repo_agent_tools import AutopilotError, file_hash, source_snapshot
from .schemas import (REVIEW, ENEMY_REVIEW, STRING, STRINGS, obj, validate_review,
                      enemy_review_instructions, validate_enemy_review)
from .workspaces import create_workspace


def png_quality(path, transparent=False, enemy=False):
    if path.stat().st_size > 40_000_000:
        raise AutopilotError('PNG przekracza 40 MB.')
    with Image.open(path) as image:
        if image.format != 'PNG' or not (64 <= image.width <= 4096 and 64 <= image.height <= 4096):
            raise AutopilotError('Wymagany PNG o wymiarach od 64 do 4096 pikseli.')
        image.load()
        if enemy:
            checks = inspect_enemy_png(path)
            return {**checks, 'ok': checks['status'] == 'PASS'}
        problems = []
        bounds = None
        if transparent:
            if image.mode != 'RGBA':
                problems.append('Brak kanału alfa RGBA.')
            else:
                alpha = image.getchannel('A')
                bounds = alpha.getbbox()
                if alpha.getextrema()[0] != 0 or bounds is None:
                    problems.append('Brak przezroczystości lub pusta sylwetka.')
                elif bounds[0] <= 0 or bounds[1] <= 0 or bounds[2] >= image.width or bounds[3] >= image.height:
                    problems.append('Sylwetka dotyka krawędzi obrazu.')
        return {'ok': not problems, 'size': list(image.size), 'mode': image.mode,
                'alpha_bounds': bounds, 'problems': problems}


class ArtStudio:
    def __init__(self, root, output, settings, event=lambda _: None, stop=None):
        self.root, self.output, self.settings = Path(root).resolve(), Path(output).resolve(), settings
        self.base = self.output / 'art-studio'
        self.event, self.stop = event, stop

    def catalog(self):
        path = self.base / 'catalog.json'
        saved = json.loads(path.read_text(encoding='utf-8')) if path.exists() else {'assets': []}
        policy = load_art_policy(self.root)
        known = {a['path'] for a in saved['assets']}
        defaults = [(p, 'class', '') for p in policy['class_references']]
        defaults += [(p, 'world', '') for p in policy['world_references']]
        defaults += [(p, 'region', region) for region, paths in policy['region_references'].items() for p in paths]
        for relative, kind, region in defaults:
            if relative not in known:
                saved['assets'].append({'path': relative, 'kind': kind, 'region': region,
                    'approved_hash': file_hash(reference_path(self.root, relative))})
        write_json(path, saved)
        return saved['assets']

    def approve_reference(self, relative, kind, region=''):
        source = reference_path(self.root, relative)
        png_quality(source)
        catalog = [a for a in self.catalog() if a['path'] != relative]
        catalog.append({'path': relative, 'kind': kind, 'region': region, 'approved_hash': file_hash(source)})
        write_json(self.base / 'catalog.json', {'assets': catalog})

    def refresh_enemy_policy(self, data):
        """Never let a saved request or an additive UI catalog override canon."""
        policy = load_art_policy(self.root)
        if not is_enemy_source(data['target'], policy):
            return None
        if policy is None:
            raise AutopilotError('Brak kanonicznej polityki enemy art: ' + POLICY_DOCUMENT)
        scenario = data['scenario']
        if (policy['scenario_enemies'].get(scenario) != data['target']
                or policy['scenario_regions'].get(scenario) != data['region']):
            raise AutopilotError('Enemy PNG, region i scena muszą odpowiadać mapowaniu w ' + POLICY_DOCUMENT)
        approved = {a['path']: a for a in self.catalog()}
        references = []
        for path, role in references_for_region(self.root, policy, data['region']):
            relative = path.relative_to(self.root).as_posix()
            entry = approved[relative]
            if file_hash(path) != entry['approved_hash']:
                raise AutopilotError('Zatwierdzony wzorzec zmienił się: ' + relative)
            references.append({**entry, 'role': role})
        data.update(references=references, style_rules=policy['style_rules'],
                    review_rules=policy['review_rules'], transparent=True,
                    policy_fingerprint=policy_fingerprint(self.root, policy),
                    art_brief=generation_brief(self.root, policy, data['region']))
        return policy

    @staticmethod
    def enemy_targets(data):
        return [{'source': data['target'], 'references': [a['path'] for a in data['references']]}]

    def request(self, target, prompt, region, scenario, variants=1):
        from .config import SCENARIOS
        if not prompt.strip() or not 1 <= variants <= 4 or scenario not in SCENARIOS:
            raise AutopilotError('Podaj opis, scenę i liczbę wariantów od 1 do 4.')
        source = reference_path(self.root, target)
        if source.suffix.lower() != '.png':
            raise AutopilotError('Studio wariantów obsługuje źródłowe PNG.')
        policy = load_art_policy(self.root)
        references_for_region(self.root, policy, region)  # Validate the selected region.
        enemy = is_enemy_source(target, policy)
        if enemy and (policy['scenario_enemies'].get(scenario) != target
                      or policy['scenario_regions'].get(scenario) != region):
            raise AutopilotError('Enemy PNG, region i scena muszą odpowiadać mapowaniu w ' + POLICY_DOCUMENT)
        canonical_paths = {p.relative_to(self.root).as_posix()
                           for p, _ in references_for_region(self.root, policy, region)}
        references = [a for a in self.catalog() if (a['path'] in canonical_paths if enemy
                      else a['kind'] in {'class', 'world'} or a['region'] == region)]
        for entry in references:
            if file_hash(reference_path(self.root, entry['path'])) != entry['approved_hash']:
                raise AutopilotError('Wzorzec zmienił się od zatwierdzenia: ' + entry['path'])
        with Image.open(source) as image:
            transparent = 'A' in image.getbands() and image.getchannel('A').getextrema()[0] == 0
        directory = self.base / ('ART-' + uuid.uuid4().hex[:12])
        directory.mkdir(parents=True)
        shutil.copy2(source, directory / 'original.png')
        request = {'target': target, 'prompt': prompt, 'region': region, 'scenario': scenario,
                   'count': variants, 'transparent': transparent, 'source_hash': file_hash(source),
                   'references': references, 'style_rules': policy['style_rules'], 'variants': []}
        self.refresh_enemy_policy(request)
        write_json(directory / 'request.json', request)
        return directory

    def read(self, directory):
        directory = Path(directory).resolve()
        if directory.parent != self.base.resolve() or not directory.name.startswith('ART-'):
            raise AutopilotError('Nieprawidłowy katalog studia grafik.')
        return json.loads((directory / 'request.json').read_text(encoding='utf-8'))

    def import_variant(self, directory, path):
        data = self.read(directory)
        policy = self.refresh_enemy_policy(data)
        path = Path(path)
        quality = png_quality(path, data['transparent'], enemy=policy is not None)
        destination = directory / ('variant-' + uuid.uuid4().hex[:8] + '.png')
        shutil.copy2(path, destination)
        variant = {'path': destination.name, 'hash': file_hash(destination), 'quality': quality,
                   'status': 'DRAFT', 'review': None, 'preview_report': ''}
        data['variants'].append(variant)
        write_json(directory / 'request.json', data)
        return variant

    def request_images(self, directory, data):
        original = directory / 'original.png'
        if file_hash(original) != data['source_hash']:
            raise AutopilotError('Zachowany oryginał zmienił się. Utwórz nowe zlecenie.')
        images = [original]
        for entry in data['references']:
            path = reference_path(self.root, entry['path'])
            if file_hash(path) != entry['approved_hash']:
                raise AutopilotError('Zatwierdzony wzorzec zmienił się: ' + entry['path'])
            images.append(path)
        return images

    def generate(self, directory):
        from .runner import ProcessRunner, agent_command, codex_environment
        data = self.read(directory)
        process = ProcessRunner(self.stop, self.event)
        for number in range(data['count']):
            data = self.read(directory)
            policy = self.refresh_enemy_policy(data)
            write_json(directory / 'request.json', data)
            images = self.request_images(directory, data)
            stage = directory / ('generate-' + uuid.uuid4().hex[:8])
            stage.mkdir()
            output = stage / 'candidate.png'
            schema = stage / 'schema.json'
            write_json(schema, obj({'summary': STRING, 'image_paths': STRINGS}))
            prompt = ('$imagegen. Wygeneruj jeden nowy wariant grafiki gry Echoes of Pythonia. '
                'Użyj wbudowanego image_gen__imagegen. Pierwszy obraz to cel zmiany, pozostałe to wzorce. '
                'Dla przeciwnika oryginał jest wyłącznie referencją TOŻSAMOŚCI, nie stylu: '
                'nie kopiuj jego realistycznych faktur, błędnego kierunku ani kadru. '
                'Zachowaj rozpoznawalność postaci/przedmiotu. Nie zastępuj ilustracji rysunkiem z kodu. Wykonaj dokładnie jedno wywołanie narzędzia generowania na wariant; nie ponawiaj automatycznie. Kontroler wykona pomiary PNG, podgląd i ocenę Sola. '
                'Nie używaj API ani kluczy. Nie edytuj projektu. Po generowaniu skopiuj otrzymany PNG do '
                + str(output) + '. Zwróć jego ścieżkę w JSON.\nOpis: ' + data['prompt']
                + '\nRegion: ' + data['region'] + '\nZasady stylu: ' + json.dumps(data['style_rules'], ensure_ascii=False)
                + ('\nPrzezroczyste tło RGBA, pełna sylwetka i wolny margines na wszystkich krawędziach.' if data['transparent'] else '\nZachowaj przeznaczenie i kompozycję oryginału.')
                + f'\nWariant {number + 1}/{data["count"]}.')
            if policy is not None:
                prompt += '\n' + data['art_brief']
            (stage / 'prompt.txt').write_text(prompt, encoding='utf-8')
            command = agent_command(self.settings, stage, self.settings.developer_model, schema, stage / 'answer.json', images)
            command[command.index('--sandbox') + 1] = 'workspace-write'
            command.insert(2, '--skip-git-repo-check')
            self.event(f'Generowanie PNG {number + 1}/{data["count"]}')
            rc = process.run(command, stage, stage / 'agent.jsonl', self.settings.agent_timeout, prompt, codex_environment())
            if rc or not output.is_file():
                raise AutopilotError('Generator nie zapisał PNG. Szczegóły: ' + str(stage / 'agent.jsonl'))
            if output.is_symlink() or not output.resolve().is_relative_to(stage.resolve()):
                raise AutopilotError('Generator musi zapisać PNG bezpośrednio w katalogu wariantu.')
            if file_hash(output) in {file_hash(p) for p in images}:
                raise AutopilotError('Wynik jest identyczny z wejściem; nie uznano go za nowy wariant.')
            self.import_variant(directory, output)
        return self.read(directory)

    def preview(self, directory, variant_index):
        from .runner import Autopilot
        data = self.read(directory)
        policy = self.refresh_enemy_policy(data)
        references = self.request_images(directory, data)
        source_state = source_snapshot(self.root)
        variant = data['variants'][variant_index]
        candidate = directory / variant['path']
        if file_hash(candidate) != variant['hash']:
            raise AutopilotError('PNG zmienił się od importu.')
        variant['quality'] = png_quality(candidate, data['transparent'], enemy=policy is not None)
        if file_hash(reference_path(self.root, data['target'])) != data['source_hash']:
            raise AutopilotError('Oryginał zmienił się od utworzenia wariantu. Utwórz nowy podgląd dla aktualnej wersji.')
        workspace = create_workspace(self.root, self.output, include_local=True, event=self.event)
        working_root = Path(workspace['root'])
        shutil.copy2(candidate, working_root / data['target'])
        settings = copy.deepcopy(self.settings)
        settings.isolated_workspace = False
        settings.branch = ''
        settings.scenarios = [data['scenario']]
        settings.resolutions = [[1280, 720], [1920, 1080]]
        runner = Autopilot(settings, root=working_root, on_event=self.event, stop=self.stop)
        runner.source_root = self.root
        # The capture workflow imports resources once, inside this isolated worktree.
        report_dir = runner.run('Podgląd wariantu PNG: ' + data['target'], 'capture')
        variant['preview_report'] = str(report_dir / 'report.html')
        if runner.state['status'] != 'CAPTURED' or any(c['status'] != 'PASS' for c in runner.state['checks']):
            write_json(directory / 'request.json', data)
            raise AutopilotError('Podgląd sceny nie przeszedł kontroli. Zobacz raport wariantu.')
        images = [references[0], candidate]
        images += [report_dir / p for p in runner.state['screenshots']]
        images += references[1:]
        prompt = ('Jesteś Sol. Oceń nowy wariant grafiki i jego wygląd w rzeczywistej scenie. '
            'Pierwszy obraz to oryginał (tożsamość, nie wzorzec stylu), drugi to wariant, '
            'dwa następne to sceny 1280x720 i 1920x1080, pozostałe to wzorce. '
            'Oceniaj styl, anatomię, kierunek, czytelność, region i krawędzie. Nie uruchamiaj poleceń. '
            'W reviewed_images wymień nazwy wszystkich załączników. PASS tylko bez wymaganych poprawek. '
            '\nZadanie: ' + data['prompt'] + '\nRegion: ' + data['region']
            + '\nZasady: ' + json.dumps(data['style_rules'], ensure_ascii=False)
            + '\nPomiary PNG: ' + json.dumps(variant['quality'], ensure_ascii=False))
        schema = REVIEW
        if policy is not None:
            schema = ENEMY_REVIEW
            prompt += '\n' + data['art_brief'] + enemy_review_instructions(self.enemy_targets(data))
        review = runner.agent('sol-art', settings.reviewer_model, prompt, schema, images)
        if policy is not None:
            validate_enemy_review(review, images, self.enemy_targets(data))
            variant['reviewed_policy'] = data['policy_fingerprint']
        else:
            validate_review(review, images)
        runner.state['reviews'] = [review]
        variant.update(review=review, status='REVIEWED', workspace=workspace)
        variant['source_snapshot'] = source_state
        variant['reviewed_hashes'] = {str(p): file_hash(p) for p in images}
        runner.save('PASSED' if review['verdict'] == 'PASS' and variant['quality']['ok'] else 'NEEDS_CHANGES')
        write_json(directory / 'request.json', data)
        return variant

    def install(self, directory, variant_index):
        data = self.read(directory)
        policy = self.refresh_enemy_policy(data)
        variant = data['variants'][variant_index]
        if policy is not None:
            if variant.get('reviewed_policy') != data['policy_fingerprint']:
                raise AutopilotError('Polityka lub referencje zmieniły się; wykonaj ponowny podgląd i review.')
            validate_enemy_review(variant['review'], [Path(p) for p in variant['reviewed_hashes']],
                                  self.enemy_targets(data))
            variant['quality'] = png_quality(directory / variant['path'], True, enemy=True)
        if not variant.get('review') or variant['review']['verdict'] != 'PASS' or not variant['quality']['ok']:
            raise AutopilotError('Wariant wymaga zaliczonej oceny Sola i kontroli PNG.')
        if any(file_hash(Path(p)) != checksum for p, checksum in variant['reviewed_hashes'].items()):
            raise AutopilotError('Dowody zmieniły się po ocenie. Wykonaj ponowny podgląd.')
        if source_snapshot(self.root) != variant.get('source_snapshot'):
            raise AutopilotError('Gra zmieniła się po podglądzie. Sprawdź wariant ponownie w aktualnej scenie.')
        target = reference_path(self.root, data['target'])
        if file_hash(target) != data['source_hash']:
            raise AutopilotError('Oryginał zmienił się. Zachowano oba pliki; wymagany nowy podgląd.')
        candidate = directory / variant['path']
        if file_hash(candidate) != variant['hash']:
            raise AutopilotError('Wariant zmienił się po ocenie.')
        shutil.copy2(target, directory / 'backup-before-install.png')
        temporary = target.with_name(target.name + '.' + uuid.uuid4().hex + '.tmp')
        shutil.copy2(candidate, temporary)
        os.replace(temporary, target)
        variant['status'] = 'APPLIED'
        write_json(directory / 'request.json', data)
        return target
