# Echoes AI Team — Stage 2: Read-only repository access

Stage 2 gives both models controlled local **read-only** access to the real
Echoes of Pythonia repository.

It does NOT provide:

- shell access;
- file writing;
- patch application;
- Git commit/push;
- deletion.

## Read-only tools

The agents can:

- inspect current Git branch/HEAD/status;
- list repository directories;
- find filenames;
- search text in source files;
- read bounded line ranges from approved text/source files.

The tools block:

- `.git`;
- `.venv`;
- `.tools`;
- `output`;
- `build`;
- `.env`;
- credential/key files;
- paths that escape the repository.

## 1. Install

Extract this ZIP into:

```text
C:\Projects\Echoes_of_Pythonia
```

and overwrite matching files.

Your `.env` is not included.

## 2. Zero-cost local safety test

Run:

```powershell
python tools\echoes_ai_team\main.py --repo-smoke
```

Expected:

```text
git_info=PASS
project_read=PASS
find_world_map=PASS
secret_guard=PASS

REPO TOOL SMOKE: PASS — API nie zostało wywołane.
```

## 3. First paid repository-aware dry run

Only after the zero-cost smoke passes:

```powershell
python tools\echoes_ai_team\main.py --repo-task "Przeanalizuj obecny hover regionów na mapie świata i zaplanuj najmniejszą poprawę wizualną bez zmiany mechanik gry."
```

Developer must inspect the real repository and provide at least two evidence
items. Reviewer independently checks repository evidence before approving.

Stage 2 is still planning-only.

## 4. Cost note

Repository tools can cause additional model turns. For the first Stage 2 run,
using `medium` reasoning for both agents is a reasonable cost-control test.
