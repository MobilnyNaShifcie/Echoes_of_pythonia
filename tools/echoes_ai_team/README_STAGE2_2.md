# Echoes AI Team — Stage 2.2: Repo Brief Relevance Fix

This patch improves only the local zero-cost repository selector.

Changes:

- excludes Godot `.uid` sidecar files from the model brief;
- expands Polish/English task synonyms for map/hover work;
- strongly prefers the current Godot world-map implementation;
- promotes:
  - `world_region_map.gd`
  - `world_map.gd`
  - `region_hover.gdshader`
  - `region_highlight.gdshaderinc`
  - `varenhold_valley.gdshader`
  - `godot/tests/test_world_map_interaction.gd`
  when they exist;
- penalizes legacy root-level Python region tests for current Godot map-UI tasks.

No `.env` is included.

## Install

Extract into:

```text
C:\Projects\Echoes_of_Pythonia
```

and overwrite:

```text
tools\echoes_ai_team\repo_brief.py
```

## Then commit this patch

```powershell
git add tools/echoes_ai_team/repo_brief.py tools/echoes_ai_team/README_STAGE2_2.md
git commit -m "chore(ai): improve local repo brief relevance"
```

## Zero-cost preview

```powershell
python tools\echoes_ai_team\main.py --brief-preview --task "Przeanalizuj obecny hover regionów na mapie świata i zaplanuj najmniejszą poprawę wizualną bez zmiany mechanik gry."
```

For this task, `.uid` files and old root `tests/test_*region*` files should no
longer displace the current Godot world-map sources.

Do not run the paid `--repo-task` until this preview looks sensible.
