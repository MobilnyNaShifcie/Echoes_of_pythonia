# Echoes AI Team — Stage 5: Controlled Commit

Stage 5 closes the autonomous local-development loop.

It does **not** call Astra or Sol. All expensive reasoning/review has already
happened in Stages 3–4.3.

Stage 5 verifies the exact current diff against saved evidence and only then
creates one local commit.

## Required evidence

For the exact current diff:

- Stage 4.2 targeted validation must have `PASS`.
- Full-check classification must be either:
  - `FULL_CHECK_PASS`, or
  - `PREEXISTING_UNRELATED_FORMAT_DEBT`.
- Visual/UI/shader changes must have a matching Stage 4.3 visual review with:
  - `verdict = APPROVED`;
  - current file SHA matching the reviewed screenshot manifest.

Stage 5 then re-runs the blocking targeted gate one final time before commit.

## Safety

Stage 5:

- runs only on `ai/*` branches;
- refuses protected branches;
- refuses staged files;
- refuses untracked files;
- accepts max 3 existing Godot files;
- verifies exact staged filenames;
- verifies staged diff equals the reviewed diff;
- runs `git diff --cached --check`;
- performs exactly one local commit;
- performs NO push;
- performs 0 API calls.

## Install

Extract into:

```text
C:\Projects\Echoes_of_Pythonia
```

Commit the Stage 5 orchestrator while leaving the game shader uncommitted:

```powershell
git add tools/echoes_ai_team/stage5.py tools/echoes_ai_team/README_STAGE5.md
git commit -m "chore(ai): add controlled commit gate"
```

## 1. Zero-cost preview

```powershell
python tools\echoes_ai_team\stage5.py --preview
```

Expected for the current hover task:

```text
targeted validation: MATCH / PASS
full-check classification: PREEXISTING_UNRELATED_FORMAT_DEBT
visual review: MATCH / APPROVED
API calls: 0
```

## 2. Controlled local commit

```powershell
python tools\echoes_ai_team\stage5.py --commit-current --message "fix(ui): refine world map region hover"
```

Stage 5 re-runs the targeted validation locally, stages only the verified shader,
checks staged diff integrity, commits it, and leaves the branch local.

Expected ending:

```text
CONTROLLED COMMIT: PASS
Release gate: BLOCKED_BY_BASELINE_DEBT
Push: NOT PERFORMED
API calls: 0
```

The next optional stage is Stage 6: task branches, push and PR orchestration.
