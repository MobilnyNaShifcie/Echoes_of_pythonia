# Echoes AI Team — Stage 4.2: Baseline-Aware Validation

Why this exists:

The migrated repository has pre-existing validation debt. A project-wide
`gdformat --check` currently reports many unrelated files. That should remain
visible and must block a release, but it should not falsely blame a one-line
shader change.

Stage 4.2 separates two concepts:

1. **Current-change gate** — blocking
2. **Repository release gate** — still reported, may remain blocked by baseline debt

For the current world-map shader change, the blocking gate is:

```text
git diff --check
Godot headless bootstrap
GUT res://tests/test_world_map_interaction.gd
```

For changed `.gd` files it also runs `gdformat --check` and `gdlint` only on
the changed `.gd` files.

Then it runs the canonical:

```powershell
.\scripts\check.ps1
```

as an advisory/release-debt scan.

If the first full-check failure is `gdformat` listing only files unrelated to
the current diff, Stage 4.2 classifies it as:

```text
PREEXISTING_UNRELATED_FORMAT_DEBT
```

That does **not** mean the repository is clean. Release remains blocked.

## Safety

- no shell commands come from a model;
- only hardcoded local commands are executed;
- Reviewer is called at most once;
- Reviewer is skipped when targeted validation fails;
- no commit and no push;
- current change stays uncommitted;
- full-check debt is never silently converted into PASS.

## Install

Extract into:

```text
C:\Projects\Echoes_of_Pythonia
```

Commit only the new orchestrator files:

```powershell
git add tools/echoes_ai_team/stage4_2.py tools/echoes_ai_team/targeted_validation.py tools/echoes_ai_team/baseline_review_prompts.py tools/echoes_ai_team/baseline_review_schemas.py tools/echoes_ai_team/README_STAGE4_2.md
git commit -m "chore(ai): add baseline-aware targeted validation"
```

Leave the Godot shader uncommitted.

## Zero-cost preview

```powershell
python tools\echoes_ai_team\stage4_2.py --preview
```

Paste the current hover task when asked.

## Run

```powershell
python tools\echoes_ai_team\stage4_2.py --validate-current "Wprowadź najmniejszą bezpieczną poprawę wizualną hoveru regionów na mapie świata, ograniczając przepalanie jasnych partii bez zmiany mechanik."
```

Expected for the current repository state:

```text
TARGETED VALIDATION: PASS
Canonical full check: PREEXISTING_UNRELATED_FORMAT_DEBT
Reviewer/Sol: up to 1 API call
CURRENT CHANGE VALIDATION: APPROVED
RELEASE GATE: BLOCKED_BY_BASELINE_DEBT
VISUAL GATE: PENDING
```

The repository-wide formatting debt should be cleaned later as a dedicated task,
not mixed into an unrelated one-line shader change.
