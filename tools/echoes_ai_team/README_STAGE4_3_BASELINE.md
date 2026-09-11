# Stage 4.3 patch — baseline-aware visual review

This patch fixes a false attribution discovered by the first visual review.

The current game diff changes only:

```text
godot/ui/screens/world_map/region_highlight.gdshaderinc
```

A clipped hover label cannot be caused by that shader formula. The original
Stage 4.3 only showed CURRENT screenshots, so Sol could see the pre-existing UI
defect but could not know whether the current diff introduced it.

The patched Stage 4.3 now captures exact BEFORE/AFTER pairs by temporarily
rendering the committed HEAD shader and then restoring/rendering the user's
current uncommitted shader bytes.

It creates 8 images:

```text
baseline/current × 1920x1080 × ice_coast
baseline/current × 1920x1080 × black_forest
baseline/current × 1280x720 × ice_coast
baseline/current × 1280x720 × black_forest
```

Safety:

- only the one expected shader is temporarily swapped;
- current uncommitted bytes are restored in `finally`;
- SHA-256 verifies the current shader was restored exactly;
- tracked working-tree verification still runs;
- temporary capture script is removed;
- no model call occurs during capture.

After extraction, commit only these orchestration updates:

```powershell
git add tools/echoes_ai_team/visual_capture.py tools/echoes_ai_team/visual_review_prompts.py tools/echoes_ai_team/visual_review_schemas.py tools/echoes_ai_team/README_STAGE4_3_BASELINE.md
git commit -m "fix(ai): make visual gate baseline-aware"
```

Leave the game shader uncommitted.

Then close the Godot editor and run:

```powershell
python tools\echoes_ai_team\stage4_3.py --capture
python tools\echoes_ai_team\stage4_3.py --preview-latest
python tools\echoes_ai_team\stage4_3.py --review-latest "Wprowadź najmniejszą bezpieczną poprawę wizualną hoveru regionów na mapie świata, ograniczając przepalanie jasnych partii bez zmiany mechanik."
```
