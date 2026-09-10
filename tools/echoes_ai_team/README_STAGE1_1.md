# Echoes AI Team — Stage 1.1: Cost Optimizer

This patch keeps Stage 1 planning-only, but sends only task-relevant excerpts
from the six large AI_CONTEXT files.

## Install
Extract the ZIP into:

C:\Projects\Echoes_of_Pythonia

and allow it to overwrite the matching files.

The ZIP does NOT contain your `.env`.

## Zero-cost preview
Run:

```powershell
python tools\echoes_ai_team\main.py --context-preview --task "Zaplanuj drobną poprawę hoveru regionów na mapie świata bez zmiany mechanik gry."
```

This makes zero API calls.

You will see:
- full AI_CONTEXT character count,
- selected context-pack size,
- reduction percentage,
- selected sections.

## Paid dry run
Only after the preview looks sensible:

```powershell
python tools\echoes_ai_team\main.py --task "Zaplanuj drobną poprawę hoveru regionów na mapie świata bez zmiany mechanik gry."
```

Stage 1.1 still cannot edit game files.

## Optional tuning in existing .env
```text
EOP_CONTEXT_MAX_CHARS=22000
EOP_CONTEXT_MAX_SECTIONS=18
```

Keep the defaults for the first run.
