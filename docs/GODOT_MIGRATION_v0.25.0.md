# Godot migration plan — v0.25.0

## Objective

Move Echoes of Pythonia from a terminal application to a windowed Godot 4 game
without losing the behavior covered by the existing Python test suite.

## Migration rules

1. The Python implementation is the executable specification until a feature is
   ported and covered by GUT tests.
2. Port domain logic before presentation. UI scenes call tested GDScript
   services; they do not own combat, economy, quest, or save rules.
3. Migrate in vertical slices that remain runnable after every commit.
4. Store gameplay definitions as typed Godot resources or validated data, not as
   hard-coded control-tree state.
5. Pin engine and add-on versions. Upgrade them only on a dedicated branch after
   tests pass.

## Proposed milestones

1. **Foundation:** bootstrap scene, theme, navigation shell, test and lint tools.
2. **Domain core:** player statistics, inventory, items, damage, and saves.
3. **Playable loop:** main menu, new game, exploration, combat, rewards.
4. **Feature parity:** cities, merchants, crafting, quests, dungeons, companions,
   rifts, guild systems, and the remaining progression mechanics.
5. **Presentation:** final layouts, animation, audio, accessibility, input, and
   export configuration.

## Current vertical slice

The first migrated flow is runnable in Godot:

1. Open the main menu.
2. Select one of four save slots and enter a validated player name.
3. Create an in-memory game session with the legacy starting values.
4. Review the player, location, time, and starter equipment on the session
   checkpoint screen.

The menu deliberately keeps load and persistent save actions disabled. The next
slice will introduce the save repository and overwrite confirmation before the
Dialogic prologue is connected.

## Add-on policy

- GUT is the test runner for migrated GDScript behavior.
- State Charts may coordinate high-level UI and gameplay states, but domain
  rules remain regular typed GDScript.
- Dialogic owns authored conversations only; quests and rewards remain in the
  project's domain layer.
- Add-on source is committed under `godot/addons/` at known release tags.
