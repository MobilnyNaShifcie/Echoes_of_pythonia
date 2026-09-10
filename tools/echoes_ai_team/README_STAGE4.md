# Echoes AI Team — Stage 4: Controlled Validation

Stage 4 validates the **existing uncommitted change left by Stage 3**.

It does not ask Astra to rewrite the code again.

That keeps this stage cheap:

```text
Local validation: 0 API calls
Sol review:       max 1 API call
```

## Workflow

```text
existing Stage 3 diff
        ↓
LOCAL PYTHON
  - branch guard
  - staged/untracked guard
  - changed-path allowlist
  - git diff --check
  - scripts/check.ps1
        ↓
if tests FAIL:
  STOP, no Reviewer API call
        ↓
if tests PASS:
  Sol gets actual diff + actual validation log
        ↓
APPROVED / CHANGES_REQUESTED / HUMAN_DECISION_REQUIRED
```

## Important visual gate

Stage 4 does **not** yet capture screenshots automatically.

For visual/UI/shader/art changes, Sol may approve code/tests but set:

```text
VISUAL GATE: PENDING
```

That means the change must not be auto-committed yet.

The screenshot/visual-review harness is the next substage.

## Safety

Stage 4 accepts only:

- an uncommitted diff under `godot/`;
- max 3 changed files;
- existing `.gd`, `.gdshader`, `.gdshaderinc`, `.tscn`, `.tres`;
- no staged files;
- no untracked files;
- no protected branch;
- no `project.godot`.

Commands are hardcoded. Models cannot provide shell commands.

The only project-wide validation command Stage 4 runs is:

```powershell
.\scripts\check.ps1
```

plus:

```powershell
git diff --check
```

No commit and no push are available.

## Install while your Stage 3 game change is still uncommitted

Extract into:

```text
C:\Projects\Echoes_of_Pythonia
```

This creates new files in `tools/echoes_ai_team/`.

Because Stage 4 refuses untracked files, commit **only the orchestrator files**
before running validation. Do not stage/commit the Godot shader change.

```powershell
git add tools/echoes_ai_team/stage4.py tools/echoes_ai_team/validation_runner.py tools/echoes_ai_team/validation_prompts.py tools/echoes_ai_team/validation_schemas.py tools/echoes_ai_team/README_STAGE4.md
git commit -m "chore(ai): add controlled validation stage"
```

Git will commit those Stage 4 files while leaving the existing Godot shader
change uncommitted.

## 1. Zero-cost safety smoke

```powershell
python tools\echoes_ai_team\stage4.py --validation-smoke
```

Expected:

```text
canonical_check_present=PASS
powershell_available=PASS
protected_branch_guard=PASS

VALIDATION SAFETY SMOKE: PASS — API nie zostało wywołane.
No validation suite was executed.
```

## 2. Zero-cost validation preview

Run:

```powershell
python tools\echoes_ai_team\stage4.py --validation-preview
```

When prompted for TASK, paste:

```text
Wprowadź najmniejszą bezpieczną poprawę wizualną hoveru regionów na mapie świata, ograniczając przepalanie jasnych partii bez zmiany mechanik.
```

Expected changed path:

```text
godot/ui/screens/world_map/region_highlight.gdshaderinc
```

And planned local commands:

```text
git diff --check
.\scripts\check.ps1
```

API calls remain 0.

## 3. Actual controlled validation

Only after preview:

```powershell
python tools\echoes_ai_team\stage4.py --validate-current "Wprowadź najmniejszą bezpieczną poprawę wizualną hoveru regionów na mapie świata, ograniczając przepalanie jasnych partii bez zmiany mechanik."
```

If local validation fails, Stage 4 does **not** call Sol, so you do not pay for a
review of already-failing code.

If validation passes, Sol is called exactly once to review the real diff and
real test output.

For this hover shader change, a likely successful end state is:

```text
CODE VALIDATION: APPROVED
VISUAL GATE: PENDING
```

Do not commit the game change at that point. The next substage will handle
visual evidence/review.
