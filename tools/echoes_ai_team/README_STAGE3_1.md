# Echoes AI Team — Stage 3.1: Automatic Context Escalation

Stage 3.1 keeps the original Stage 3 safety model, but stops treating
"context is insufficient" as an immediate dead end.

## What changes

Normal path:

```text
Developer/Astra
  -> READY_TO_APPLY
  -> local exact-text replacement
  -> Reviewer/Sol
```

Escalation path:

```text
Developer/Astra
  -> BLOCKED: missing repository context
  -> local Python expands up to 2 named files (0 API)
  -> Developer/Astra retry using expanded evidence
  -> Reviewer/Sol only if a real diff exists
```

The controller does not tell Astra to guess. It expands safe existing files
that Astra itself named in the blocker, preferring files already selected in
REPO_BRIEF.

## Defaults

```text
EOP_ESCALATED_BRIEF_MAX_CHARS=45000
EOP_ESCALATED_MAX_FILES=2
EOP_MAX_DEVELOPER_ATTEMPTS=2
```

`EOP_MAX_MODEL_CALLS_PER_TASK` remains the hard paid-call fuse.

For fully automatic escalation in one command:

```text
EOP_MAX_MODEL_CALLS_PER_TASK=3
```

This allows at most:
1. Developer attempt 1
2. Developer attempt 2 after local context expansion
3. Reviewer

If the fuse remains `2`, Stage 3.1 prepares the expanded context and stops.
Use `--resume-blocked-latest` to perform only the retry + review in a new
max-2-call run. This avoids paying for the first blocked Developer attempt
again.

## Current blocked task: zero-cost preview

Use the exact task string from the blocked run:

```powershell
python tools\echoes_ai_team\stage3.py `
  --escalation-preview-latest `
  --task "..."
```

## Resume current blocked task

```powershell
python tools\echoes_ai_team\stage3.py `
  --resume-blocked-latest `
  --task "..."
```

Maximum paid calls in that run: 2.

## Future fully automatic mode

In `tools\echoes_ai_team\.env`:

```text
EOP_MAX_MODEL_CALLS_PER_TASK=3
EOP_MAX_DEVELOPER_ATTEMPTS=2
EOP_ESCALATED_BRIEF_MAX_CHARS=45000
EOP_ESCALATED_MAX_FILES=2
```

Then ordinary:

```powershell
python tools\echoes_ai_team\stage3.py --apply-task "..."
```

can automatically recover from one context-related BLOCKED state.
