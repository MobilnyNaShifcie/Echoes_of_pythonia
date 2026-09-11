# Echoes Autopilot — repo-aware one-command workflow

This replaces static task-file routing in the Developer stage.

## Goal

Run one command from a clean, synchronized `ai/echoes-team`:

```powershell
python tools\echoes_ai_team\autopilot.py "opis zadania"
```

Autopilot then:

1. creates a dedicated `ai/task/EOP-...` branch;
2. gives Astra safe read-only repository tools;
3. Astra searches/lists/reads the repo itself;
4. Astra proposes exact text replacements only for files it actually read;
5. the local controller applies the diff atomically;
6. Sol independently reviews the real diff and may inspect the repo himself;
7. one automatic correction cycle is allowed by default;
8. canonical `scripts/check.ps1` runs;
9. the approved change is committed;
10. the task branch is pushed and a PR into `ai/echoes-team` is created;
11. no automatic merge and no force push are performed.

There is no per-domain static router for map/inventory/enemy-art tasks.

## Cost control

The repo tool is batched:

- up to 8 search queries per call;
- up to 8 file/range reads per call;
- up to 4 directory listings per call.

Defaults:

```text
EOP_REPO_TOOL_MAX_CALLS=4
EOP_REPO_TOOL_MAX_OUTPUT_CHARS=45000
EOP_AUTOPILOT_DEVELOPER_MAX_TURNS=8
EOP_AUTOPILOT_REVIEWER_MAX_TURNS=5
EOP_AUTOPILOT_MAX_REVIEW_CYCLES=2
```

Astra is instructed to normally use one batched discovery call, one batched
read call, then produce the proposal.

## Safety

- starts only from `ai/echoes-team`;
- base must equal `origin/ai/echoes-team`;
- refuses dirty worktrees;
- read tools can access only safe tracked text files;
- secrets and `.env` are blocked;
- no shell/write tool is exposed to Astra or Sol;
- Developer may edit only existing files it explicitly read;
- exact text replacement is atomic;
- max 4 edited files by default;
- `git diff --check` is required;
- Sol reviews the actual diff;
- canonical `check.ps1` must pass before commit;
- no force push;
- no automatic merge.

## Visual/UI safety

For visual/UI source changes Autopilot currently refuses to commit without a
generic visual scenario. It rolls the diff back with:

```text
VISUAL_GATE_REQUIRED
```

Documentation, AI tooling and non-visual work can complete fully end-to-end.

The existing specialized visual gates remain available until the generic
visual runner is added.

## Install

Extract to:

```text
C:\Projects\Echoes_of_Pythonia
```

Commit on the base branch:

```powershell
git add tools/echoes_ai_team/autopilot.py tools/echoes_ai_team/repo_agent_tools.py tools/echoes_ai_team/README_AUTOPILOT.md
git commit -m "feat(ai): add repo-aware autonomous task runner"
python tools\echoes_ai_team\stage6.py --publish-base
```

## Doctor

```powershell
python tools\echoes_ai_team\autopilot.py --doctor
```

## Run a task

```powershell
python tools\echoes_ai_team\autopilot.py "Wprowadź globalną politykę stylu graficznego przeciwników..."
```

By default Autopilot commits, pushes and creates a PR after approval and full
validation.

To stop after local commit and skip push/PR:

```powershell
python tools\echoes_ai_team\autopilot.py --no-publish "opis zadania"
```


## Resume after a safe interruption

If the agent hit its turn budget before producing a proposal, the task branch
is kept and no project files are edited. After upgrading the runner, resume it
without creating another branch or retyping the task:

```powershell
python tools\echoes_ai_team\autopilot.py --resume-latest
```

The Developer default is now 8 turns. This is a ceiling, not a target; the
repo tool still has its own bounded call budget and the prompt tells Astra to
batch discovery/read operations and finish as soon as it has enough evidence.
