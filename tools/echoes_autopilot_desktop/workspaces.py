"""Explicit branch selection and isolated, detached Git worktrees."""
from __future__ import annotations

import hashlib
import json
import os
import shutil
import subprocess
import uuid
from pathlib import Path

from .config import write_json
from .repo_agent_tools import AutopilotError, file_hash, safe_edit_path, source_snapshot

NO_WINDOW = subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0


def git(root, *args, data=None, timeout=180):
    result = subprocess.run(['git', '-C', str(root), *args], input=data, capture_output=True,
                            timeout=timeout, creationflags=NO_WINDOW)
    if result.returncode:
        raise AutopilotError(result.stderr.decode('utf-8', errors='replace').strip())
    return result.stdout


def branches(root, fetch=False):
    if fetch:
        git(root, 'fetch', 'origin')
    refs = git(root, 'for-each-ref', '--format=%(refname:short)', 'refs/heads', 'refs/remotes/origin')
    return [line for line in refs.decode().splitlines() if line != 'origin/HEAD']


def managed_path(output, path):
    base = (output / 'workspaces').resolve()
    path = Path(path).resolve()
    if path.parent != base or not path.name.startswith('WORK-') or path.is_symlink():
        raise AutopilotError('Katalog roboczy musi należeć do tego Autopilota.')
    return path


def create_workspace(root, output, ref='', include_local=True, event=lambda _: None):
    root, output = Path(root).resolve(), Path(output).resolve()
    ref = ref or git(root, 'branch', '--show-current').decode().strip() or 'HEAD'
    if ref.startswith('-') or any(c in ref for c in '\r\n\0'):
        raise AutopilotError('Nieprawidłowy branch.')
    commit = git(root, 'rev-parse', '--verify', ref + '^{commit}').decode().strip()
    head = git(root, 'rev-parse', 'HEAD').decode().strip()
    initial_sources = source_snapshot(root) if include_local else None
    if include_local and commit != head:
        raise AutopilotError('Lokalne zmiany można dołączyć tylko do obecnie otwartej wersji. Wybierz sam branch albo bieżące pliki.')
    target = managed_path(output, output / 'workspaces' / ('WORK-' + uuid.uuid4().hex[:12]))
    target.parent.mkdir(parents=True, exist_ok=True)
    event('Przygotowanie osobnego katalogu gry: ' + str(target))
    git(root, 'worktree', 'add', '--detach', str(target), commit)
    # Never copy credentials, saves, environments or generated outputs.
    if include_local:
        patch = git(root, 'diff', '--binary', 'HEAD', '--', 'godot', 'scripts', 'docs', 'tests', 'tools',
                    'AI_CONTEXT/ART_DIRECTION.md',
                    'requirements-dev.txt', 'pyproject.toml', 'pytest.ini')
        if patch:
            git(target, 'apply', '--binary', '--whitespace=nowarn', '-', data=patch)
        for raw in git(root, 'ls-files', '--others', '--exclude-standard', '-z').split(b'\0'):
            if not raw:
                continue
            relative = raw.decode('utf-8')
            if not relative.startswith(('godot/', 'scripts/', 'docs/', 'tests/', 'tools/echoes_autopilot_desktop/')):
                continue
            source = (root / relative).resolve()
            if not source.is_relative_to(root) or not source.is_file() or source.is_symlink():
                continue
            if any(p.startswith('.') or p == '__pycache__' for p in Path(relative).parts):
                continue
            destination = target / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, destination)
    # The controller's fixtures and gate adapters must accompany every selected branch.
    for relative in ('tools/echoes_autopilot_desktop', 'godot/tools/autopilot_capture.gd',
                     'godot/tools/autopilot_journey.gd', 'godot/tools/autopilot_art_preview.gd', 'scripts/check.ps1'):
        source, destination = root / relative, target / relative
        if source.is_dir():
            shutil.copytree(source, destination, dirs_exist_ok=True, ignore=shutil.ignore_patterns('__pycache__'))
        elif source.is_file():
            destination.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(source, destination)
    metadata = {'source_root': str(root), 'root': str(target), 'ref': ref, 'commit': commit,
                'include_local': include_local, 'baseline': source_snapshot(target)}
    if include_local and source_snapshot(root) != initial_sources:
        raise AutopilotError('Gra zmieniła się podczas kopiowania. Zachowano kopię; ponów po zakończeniu równoległych zmian.')
    write_json(target.parent / (target.name + '.json'), metadata)
    event('Kopia gotowa: ' + ref + ' · ' + commit[:12])
    return metadata


def workspace_changes(metadata):
    root = Path(metadata['root'])
    current = source_snapshot(root)
    baseline = metadata['baseline']
    return {name: {'before': baseline.get(name), 'after': current.get(name)}
            for name in sorted(set(baseline) | set(current)) if baseline.get(name) != current.get(name)}


def apply_workspace(metadata, output, validated_snapshot=None):
    """Apply only the job delta; refuse stale destination files. Preserve all originals."""
    root = managed_path(output, metadata['root'])
    if validated_snapshot is not None and source_snapshot(root) != validated_snapshot:
        raise AutopilotError('Kopia zmieniła się po testach. Wykonaj ponowny audyt przed przeniesieniem zmian.')
    destination = Path(metadata['source_root']).resolve()
    changes = workspace_changes(metadata)
    prepared = {}
    for relative, hashes in changes.items():
        target = safe_edit_path(destination, relative)
        if hashes['after'] is None:
            raise AutopilotError('Usuwanie plików wymaga osobnego przeglądu: ' + relative)
        if file_hash(target) != hashes['before']:
            raise AutopilotError('Plik zmienił się poza zadaniem; zachowano obie wersje: ' + relative)
        content = (root / relative).read_bytes()
        if hashlib.sha256(content).hexdigest() != hashes['after']:
            raise AutopilotError('Plik kopii zmienił się podczas przenoszenia: ' + relative)
        prepared[relative] = (target, content)
    backup = output / 'workspace-backups' / uuid.uuid4().hex
    backup.mkdir(parents=True)
    originals = {name: target.read_bytes() if target.exists() else None
                 for name, (target, _) in prepared.items()}
    for name, content in originals.items():
        if content is not None:
            path = backup / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_bytes(content)
    write_json(backup / 'manifest.json', {'workspace': str(root), 'changes': changes})
    applied = []
    try:
        for name, (target, content) in prepared.items():
            if file_hash(target) != changes[name]['before']:
                raise AutopilotError('Równoległa zmiana pliku: ' + name)
            target.parent.mkdir(parents=True, exist_ok=True)
            temporary = target.with_name(target.name + '.' + uuid.uuid4().hex + '.tmp')
            temporary.write_bytes(content)
            os.replace(temporary, target)
            applied.append(name)
    except Exception:
        for name in reversed(applied):
            target = prepared[name][0]
            if file_hash(target) != changes[name]['after']:
                continue  # Never clobber a concurrent edit during rollback.
            if originals[name] is None:
                target.unlink()
            else:
                target.write_bytes(originals[name])
        raise
    return {'applied': list(prepared), 'backup': str(backup)}
