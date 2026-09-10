# Echoes AI Team — Stage 3: Controlled Write

Stage 3 is the first mode that can modify the Godot project.

The models still do **not** receive shell or file-write tools.

Workflow:

```text
LOCAL PYTHON
  -> checks clean Git state
  -> builds AI_CONTEXT pack + REPO_BRIEF

Astra (1 API call)
  -> returns exact old_text -> new_text replacements

LOCAL CONTROLLER
  -> validates paths
  -> validates exact/unique old_text
  -> applies changes atomically
  -> runs git diff --check
  -> captures the real git diff

Sol (1 API call)
  -> reviews the real git diff

APPROVED
  -> changes stay UNCOMMITTED

CHANGES_REQUESTED / HUMAN_DECISION_REQUIRED
  -> local controller restores original file contents automatically
```

## Safety limits

Stage 3:

- edits existing files only;
- edits only files included in REPO_BRIEF;
- edits only under `godot/`;
- allows only `.gd`, `.gdshader`, `.gdshaderinc`, `.tscn`, `.tres`;
- refuses `project.godot`, `.env`, paths outside the repository and symlinks;
- max 3 files per task;
- max 6 replacements per file;
- max 18,000 replacement characters;
- no model shell;
- no model file tools;
- no file creation/deletion;
- no commit;
- no push;
- no automated project tests yet;
- automatic rollback on Reviewer rejection.

Stage 4 will add controlled test execution and visual review.

## Install

Extract into:

```text
C:\Projects\Echoes_of_Pythonia
```

This package adds new Stage 3 files and does not contain your real `.env`.

## Commit the Stage 3 orchestrator first

```powershell
git add tools/echoes_ai_team/stage3.py tools/echoes_ai_team/controlled_write.py tools/echoes_ai_team/write_prompts.py tools/echoes_ai_team/write_schemas.py tools/echoes_ai_team/README_STAGE3.md
git commit -m "chore(ai): add controlled write stage"
```

The working tree must be clean before any paid Stage 3 task.

## Zero-cost safety smoke

```powershell
python tools\echoes_ai_team\stage3.py --write-smoke
```

Expected:

```text
godot_source_guard=PASS
denied_path_guard=PASS

WRITE SAFETY SMOKE: PASS — API nie zostało wywołane.
No files were edited.
```

## Zero-cost task preview

```powershell
python tools\echoes_ai_team\stage3.py --write-preview --task "Doprecyzuj hover regionów na mapie świata bez zmiany mechanik gry."
```

This should select the same current world-map files as Stage 2.2.

## First paid controlled-write test

Use a small UI-only task:

```powershell
python tools\echoes_ai_team\stage3.py --apply-task "Wprowadź najmniejszą bezpieczną poprawę wizualną hoveru regionów na mapie świata, ograniczając przepalanie jasnych partii bez zmiany mechanik."
```

With:

```text
EOP_MAX_MODEL_CALLS_PER_TASK=2
```

Stage 3 uses at most:

```text
1 x Astra
1 x Sol
```

If Sol approves, inspect the uncommitted result:

```powershell
git status -sb
git --no-pager diff
```

Do not commit the game change yet. Stage 4 will add controlled tests before
we allow the AI workflow to create commits.
