"""Durable stage receipts and issue history. Never infer a pass from an absent result."""
from __future__ import annotations

import hashlib
import json
import re
from dataclasses import asdict
from pathlib import Path

from .config import write_json
from .repo_agent_tools import file_hash, git_context, source_snapshot

VERSION = 3


def digest(value):
    return hashlib.sha256(json.dumps(value, sort_keys=True, ensure_ascii=False).encode()).hexdigest()


def fingerprint(root, settings):
    sources = source_snapshot(root)
    # Controller, fixtures and gates are part of the validation contract too.
    for directory in ('scripts', 'tools/echoes_autopilot_desktop', 'godot/tools', 'godot/addons', 'godot/data'):
        for path in (root / directory).rglob('*'):
            if path.is_file() and path.suffix in {'.py', '.ps1', '.gd', '.json', '.cfg', '.tscn', '.tres'}:
                if '__pycache__' not in path.parts and not path.is_symlink():
                    sources[path.relative_to(root).as_posix()] = file_hash(path)
    for name in ('requirements-dev.txt', 'pyproject.toml', 'pytest.ini'):
        sources[name] = file_hash(root / name)
    tools = {}
    for name in ('codex', 'godot', 'powershell'):
        path = Path(getattr(settings, name))
        tools[name] = [str(path), path.stat().st_size, path.stat().st_mtime_ns] if path.is_file() else None
    return digest({'version': VERSION, 'root': str(root), 'head': git_context(root)['head'],
                   'sources': sources, 'settings': asdict(settings), 'tools': tools})


def encode(value):
    if isinstance(value, Path):
        return {'__path__': str(value)}
    if isinstance(value, list):
        return [encode(v) for v in value]
    if isinstance(value, dict):
        return {k: encode(v) for k, v in value.items()}
    return value


def decode(value):
    if isinstance(value, dict):
        if set(value) == {'__path__'}:
            return Path(value['__path__'])
        return {k: decode(v) for k, v in value.items()}
    if isinstance(value, list):
        return [decode(v) for v in value]
    return value


def receipts_valid(directory, checkpoints):
    for checkpoint in checkpoints.values():
        for relative, expected in checkpoint.get('artifacts', {}).items():
            path = (directory / relative).resolve()
            if not path.is_relative_to(directory.resolve()) or file_hash(path) != expected:
                return False
    return True


class StageBook:
    def __init__(self, runner):
        self.runner = runner

    def execute(self, label, operation):
        r = self.runner
        checkpoints = r.state.setdefault('checkpoints', {})
        if label in checkpoints:
            record = checkpoints[label]
            if not receipts_valid(r.directory, {label: record}):
                raise RuntimeError('Dowody etapu zmieniły się. Wymagany nowy przebieg: ' + label)
            r.event('Użyto zapisanego wyniku: ' + label)
            for field in ('checks', 'reviews'):
                r.state.setdefault(field, []).extend(record.get(field, []))
            r.state.update(record.get('effects', {}))
            return decode(record['result'])
        r.state['phase'] = label
        r.state['resume_signature'] = fingerprint(r.root, r.settings)
        r.save()
        counts = {k: len(r.state.get(k, [])) for k in ('checks', 'reviews')}
        result = operation()
        artifacts = {}
        stage = r.directory / label
        if stage.is_dir():
            for path in stage.rglob('*'):
                if path.is_file() and 'profile' not in path.relative_to(stage).parts and 'fixture_saves' not in path.parts:
                    artifacts[path.relative_to(r.directory).as_posix()] = file_hash(path)
        record = {'result': encode(result), 'artifacts': artifacts,
                  'effects': {k: r.state[k] for k in ('screenshots', 'developer_summary', 'journeys') if k in r.state}}
        for field, start in counts.items():
            record[field] = r.state.get(field, [])[start:]
        referenced = [r.directory / c['log'] for c in record['checks']]
        referenced += [r.directory / name for name in record['effects'].get('screenshots', [])]
        for path in referenced:
            if path.is_file() and path.resolve().is_relative_to(r.directory.resolve()):
                artifacts[path.relative_to(r.directory).as_posix()] = file_hash(path)
        checkpoints[label] = record
        r.state['resume_signature'] = fingerprint(r.root, r.settings)
        r.state['completed_stages'] = list(checkpoints)
        r.save()
        return result


def issue_key(finding):
    # Line numbers and changing before/after run directories do not define identity.
    evidence = ' '.join(finding.get('evidence', []))
    paths = re.findall(r'(?:godot/|scripts/|docs/)[\w./-]+|[\w-]+_\d+x\d+\.png', evidence)
    title = re.sub(r'[^\w ]', ' ', finding['title'].casefold())
    return digest([finding['category'], ' '.join(title.split()), sorted(set(paths))])[:12]


def update_issues(path, reviews, run_id, cycle, complete, scope):
    ledger = json.loads(path.read_text(encoding='utf-8')) if path.exists() else {'issues': []}
    records = {issue['key']: issue for issue in ledger['issues']}
    observed = set()
    for review in reviews:
        for finding in review.get('findings', []):
            if not finding['must_fix']:
                continue
            key = issue_key(finding)
            observed.add(key)
            issue = records.setdefault(key, {'id': 'E-' + key[:8].upper(), 'key': key, 'history': [], 'status': 'open'})
            status = 'returned' if issue['status'] == 'fixed' else issue['status']
            if status == 'unverified':
                status = 'open'
            issue.update(finding, status=status, scope=scope, last_run=run_id)
            observation = {'run': run_id, 'cycle': cycle, 'status': status}
            if observation not in issue['history']:
                issue['history'].append(observation)
    # Missing findings close only following a complete PASS of the same review scope.
    all_pass = complete and reviews and all(r['verdict'] == 'PASS' for r in reviews)
    for key, issue in records.items():
        if key not in observed and issue.get('scope') == scope:
            issue['status'] = 'fixed' if all_pass else 'unverified'
            observation = {'run': run_id, 'cycle': cycle, 'status': issue['status']}
            if observation not in issue['history']:
                issue['history'].append(observation)
    ledger['issues'] = list(records.values())
    write_json(path, ledger)
    return ledger['issues']


def log_result(name, rc, content, relative):
    plain = re.sub(r'\x1b\[[0-9;]*m', '', content)
    errors = [line.strip() for line in plain.splitlines() if 'ERROR:' in line]
    return {'name': name, 'status': 'PASS' if rc == 0 and not errors else 'FAIL',
            'detail': '; '.join(errors[:3]) if errors else f'kod {rc}', 'log': relative}


def canonical_coverage(content):
    plain = re.sub(r'\x1b\[[0-9;]*m', '', content)
    # A completed failure is evidence too; the canonical result remains FAIL.
    return {stage: bool(re.search(r'^AUTOPILOT_STAGE ' + stage + r' (?:PASS|FAIL)$', plain, re.MULTILINE))
            for stage in ('boot', 'gut')}
