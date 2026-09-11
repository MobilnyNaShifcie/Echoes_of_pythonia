# Echoes AI Team — Stage 4.3: Automated Visual Gate

Stage 4.3 performs the visual review that Stage 4.2 correctly left pending.

The current hover-shader change already has:
- git diff --check: PASS
- Godot bootstrap: PASS
- world-map GUT: PASS
- 669/669 GUT tests passed in the targeted run
- repository release gate still blocked by unrelated formatting debt

Stage 4.3 only answers:
**Does the hover shader actually look good?**

## What Stage 4.3 captures locally

Six real Godot screenshots:

```text
1920x1080 no hover
1920x1080 ice_coast hover
1920x1080 black_forest hover
1280x720 no hover
1280x720 ice_coast hover
1280x720 black_forest hover
```

The capture harness instantiates:

```text
res://ui/screens/world_map/world_map.tscn
```

with a real `NewGameService` session and uses the real `WorldRegionMap`.

The temporary capture script is removed after capture. Stage 4.3 verifies that
Godot did not leave unexpected tracked/untracked project files.

## Cost

Capture:

```text
0 API calls
```

Visual review:

```text
1 × GPT-5.6 Sol
```

No Astra call is needed.

## Install

Extract into:

```text
C:\Projects\Echoes_of_Pythonia
```

Commit only these new orchestration files:

```powershell
git add tools/echoes_ai_team/stage4_3.py tools/echoes_ai_team/visual_capture.py tools/echoes_ai_team/visual_review_prompts.py tools/echoes_ai_team/visual_review_schemas.py tools/echoes_ai_team/README_STAGE4_3.md
git commit -m "chore(ai): add automated visual review gate"
```

Leave this file uncommitted:

```text
godot/ui/screens/world_map/region_highlight.gdshaderinc
```

## 1. Close Godot editor

The capture runner launches its own Godot windows. The normal editor should be
closed first.

## 2. Free capture

```powershell
python tools\echoes_ai_team\stage4_3.py --capture
```

Godot windows may briefly appear while screenshots are rendered.

Expected:

```text
VISUAL CAPTURE: PASS
6 screenshots
No model was called.
```

Screenshots are stored under:

```text
output\ai-team\VISUAL-YYYYMMDD-HHMMSS\
```

## 3. Free review preview

```powershell
python tools\echoes_ai_team\stage4_3.py --preview-latest
```

No API call is made.

## 4. Paid visual review

```powershell
python tools\echoes_ai_team\stage4_3.py --review-latest "Wprowadź najmniejszą bezpieczną poprawę wizualną hoveru regionów na mapie świata, ograniczając przepalanie jasnych partii bez zmiany mechanik."
```

Sol receives:
- six screenshots,
- screenshot labels,
- the real git diff,
- the relevant AI_CONTEXT.

A successful outcome is:

```text
VISUAL GATE: APPROVED
CURRENT CHANGE: ready for Stage 5 commit gate
RELEASE GATE: BLOCKED_BY_BASELINE_DEBT
```

Stage 4.3 never commits or pushes the game change.
