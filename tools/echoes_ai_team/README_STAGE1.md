# Echoes AI Team — Stage 1

Stage 1 is deliberately **planning-only**.

It proves:

- GPT-6 Astra can act as Developer;
- GPT-5.6 Sol can act as independent Reviewer;
- both read the same `AI_CONTEXT`;
- Reviewer can request changes;
- Developer can revise;
- the loop stops after the configured maximum;
- no game files are edited yet.

## 1. Install

From repository root:

```powershell
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements-ai.txt
```

## 2. Configure key

Copy:

```text
tools\echoes_ai_team\.env.example
```

to:

```text
tools\echoes_ai_team\.env
```

Then put your API key after:

```text
OPENAI_API_KEY=
```

Do not commit `.env`.
Do not send screenshots containing the key.

## 3. Show configuration

```powershell
python tools\echoes_ai_team\main.py --show-config
```

Expected:

```text
Developer model: gpt-6-astra
Reviewer model:  gpt-5.6-sol
API key:         SET
```

## 4. Cheap smoke test first

```powershell
python tools\echoes_ai_team\main.py --smoke
```

This does NOT load the large project context.

## 5. First planning dry run

Example:

```powershell
python tools\echoes_ai_team\main.py --task "Oceń i zaplanuj drobną poprawę hoveru na ekranie mapy świata bez zmiany mechanik."
```

The system can perform up to 4 Developer ↔ Reviewer planning rounds.

## 6. Logs

Run logs are written to:

```text
output\ai-team\DRYRUN-YYYYMMDD-HHMMSS\
```

`output/` is ignored by Git.

## 7. Safety

Stage 1 has no file-editing or shell tools.

The models can only:

- read the provided context;
- propose a plan;
- review the plan.

After Stage 1 passes, Stage 2 will add controlled READ-ONLY repository tools.
