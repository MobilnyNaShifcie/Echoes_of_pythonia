# Echoes AI Team — Stage 6

Stage 6 is the Git/GitHub autonomy boundary.

Stages 1–5 decide, implement, review, validate and create an approved local
commit. Stage 6 adds the safe repository lifecycle around those commits:

1. verify the local environment;
2. synchronize the AI integration branch;
3. create one isolated `ai/task/...` branch per task;
4. require a matching Stage 5 receipt with `release_gate_status = CLEAR`;
5. rerun the canonical `scripts/check.ps1`;
6. push without force;
7. create a Pull Request into `ai/echoes-team`;
8. never merge automatically.

Stage 6 itself makes **0 OpenAI API calls**.

## Safety rules

- `main`, `master`, the protected snapshot branch and `release/*` are refused.
- A dirty working tree is refused.
- New tasks can start only from a base branch exactly synchronized with origin.
- Stage 6 never performs automatic merge/rebase.
- Stage 6 never uses force push.
- Publishing a task requires the exact current HEAD to have a Stage 5 receipt.
- That receipt must say `release_gate_status = CLEAR`.
- The full canonical check is rerun immediately before push.
- PR creation uses the authenticated GitHub CLI (`gh`).
- PR merge remains a human decision.

## Install

Extract this package into the repository root:

```text
C:\Projects\Echoes_of_Pythonia
```

Then commit the Stage 6 tool on `ai/echoes-team`:

```powershell
git add tools/echoes_ai_team/stage6.py tools/echoes_ai_team/README_STAGE6.md
git commit -m "chore(ai): add Stage 6 GitHub task lifecycle"
```

## First run: doctor

```powershell
python tools\echoes_ai_team\stage6.py --doctor
```

The doctor checks:

- clean Git state;
- `origin`;
- `origin/ai/echoes-team`;
- base divergence;
- pytest + NumPy in `.venv`;
- local Godot executable;
- GitHub CLI installation and authentication.

No OpenAI request is made.

## Publish the cleaned base

After doctor is healthy:

```powershell
python tools\echoes_ai_team\stage6.py --publish-base
```

This reruns `scripts/check.ps1`, then pushes `ai/echoes-team` only when it is
not behind origin. No force push is possible.

## Start a task

Example:

```powershell
python tools\echoes_ai_team\stage6.py --start-task --task "Przebuduj ekran ekwipunku bez zmiany mechanik."
```

A branch is created automatically, e.g.:

```text
ai/task/EOP-20260911-191500-przebuduj-ekran-ekwipunku-bez-zmiany-mechanik
```

You can optionally supply a stable ID:

```powershell
python tools\echoes_ai_team\stage6.py --start-task --task "..." --task-id EOP-101
```

Run the normal Astra + Sol pipeline on this branch. Stage 5 must produce the
approved commit.

## Finish preview

```powershell
python tools\echoes_ai_team\stage6.py --preview-finish
```

This verifies:

- task branch format;
- clean working tree;
- no base divergence;
- task commits exist;
- a matching Stage 5 receipt exists;
- its release gate is CLEAR;
- GitHub CLI is authenticated.

## Publish task + create PR

```powershell
python tools\echoes_ai_team\stage6.py --finish-task
```

It reruns the full project gate, pushes the task branch, and creates/reuses a
PR into `ai/echoes-team`.

It does **not** merge the PR.

Optional PR title override:

```powershell
python tools\echoes_ai_team\stage6.py --finish-task --title "Improve inventory screen layout"
```

## Status

```powershell
python tools\echoes_ai_team\stage6.py --status
```
