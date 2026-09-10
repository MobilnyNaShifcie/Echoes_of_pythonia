# Echoes AI Team — Stage 2.1: Single-Shot Repo Brief

Stage 2.1 replaces model-driven repository browsing with a local, free scanner.

```text
LOCAL PYTHON (free)
  -> scans repository
  -> ranks relevant files
  -> extracts bounded snippets
  -> verifies clean Git state
  -> builds REPO_BRIEF

Astra: 1 model call
Sol:   1 model call
```

If Sol requests changes, the default hard fuse allows at most one correction
round: 4 model calls total.

## Safety

Still no file writing, shell, commit, push or deletion. The scanner blocks
`.git`, `.venv`, `.tools`, `.godot`, `output`, `build`, `.env` and key files.
It refuses paid calls when the working tree is dirty or a protected branch is active.

## Install

Extract into `C:\Projects\Echoes_of_Pythonia` and overwrite matching files.
The ZIP does not contain your real `.env`.

## Zero-cost preview

```powershell
python tools\echoes_ai_team\main.py --brief-preview --task "Przeanalizuj obecny hover regionów na mapie świata i zaplanuj najmniejszą poprawę wizualną bez zmiany mechanik gry."
```

Check the selected files. No API call is made.

## Paid run

```powershell
python tools\echoes_ai_team\main.py --repo-task "Przeanalizuj obecny hover regionów na mapie świata i zaplanuj najmniejszą poprawę wizualną bez zmiany mechanik gry."
```

Normally this should use two requests total: one Astra and one Sol.

## Harder cost fuse

For the first run you can add to your real `.env`:

```text
EOP_MAX_MODEL_CALLS_PER_TASK=2
```

That guarantees only one Developer call + one Reviewer call and disables an
automatic correction round.

## Cost report

The program prints per-request input, cached input, cache writes, output,
reasoning tokens and an estimated USD cost for `gpt-6-astra` and `gpt-5.6-sol`.
The OpenAI billing dashboard remains the final billing authority.
