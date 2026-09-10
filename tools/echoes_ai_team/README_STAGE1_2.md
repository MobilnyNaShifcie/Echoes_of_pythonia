# Echoes AI Team — Stage 1.2 Context Router Fix

Fixes Polish inflections and domain weighting in the Stage 1.1 router.

For a task such as:

```text
Zaplanuj drobną poprawę hoveru regionów na mapie świata bez zmiany mechanik gry.
```

the router should now prefer sections from `UI_RULES.md` such as:

- World Map
- Region hover
- Region selection
- Modular world map
- Developer UI workflow / screenshot review

instead of unrelated Region 5 / Region 6 design sections.

## Install

Extract this ZIP into:

```text
C:\Projects\Echoes_of_Pythonia
```

and overwrite the matching file.

Your `.env` is not included.

## Zero-cost test

Run the same preview again:

```powershell
python tools\echoes_ai_team\main.py --context-preview --task "Zaplanuj drobną poprawę hoveru regionów na mapie świata bez zmiany mechanik gry."
```

Do NOT run the paid `--task` until the selected sections look sensible.
