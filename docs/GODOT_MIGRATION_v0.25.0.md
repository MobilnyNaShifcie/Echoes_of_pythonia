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
6. Preserve the terminal game's turn-based mechanics. Presentation may expose
   outcomes more clearly but does not become the source of combat results.
7. Preview visual and audio proposals before integrating them, following
   `ART_AND_AUDIO_PIPELINE_v0.25.0.md`.

## Proposed milestones

1. **Foundation:** bootstrap scene, theme, navigation shell, test and lint tools.
2. **Domain core:** player statistics, inventory, items, damage, and saves.
3. **Playable loop:** main menu, new game, exploration, combat, rewards.
4. **Feature parity:** cities, merchants, crafting, quests, dungeons, companions,
   rifts, guild systems, and the remaining progression mechanics.
5. **Presentation:** final layouts, animation, audio, accessibility, input, and
   export configuration.

## Completed vertical slices

The migrated flow is runnable in Godot:

1. Open the main menu.
2. Select one of four save slots and enter a validated player name.
3. Create an in-memory game session through a player factory.
4. Equip the typed `Stary Miecz` and `Zużyta Skórzana Zbroja` resources.
5. Calculate the legacy starting state: 20 HP, 3 ATK, 2 DEF, zero Mana,
   Dodge, attributes, currency, and experience.
6. Review progression, primary statistics, attributes, and equipped item names
   on the character sheet.
7. Open the equipment screen, inspect all eleven legacy slots, move equipment
   to the backpack, equip it again, and observe live stat recalculation.
8. Play the five-part prologue, including the tutorial fight against the
   `Przeklęty Strach na Wróble`, and enter Varenhold with guild rank F.
9. Navigate the complete Varenhold menu: guild, gate, hero, class preview,
   blacksmith, workshop, merchant, inn, and expedition preparation.
10. Accept the first story quest, `Ci, którzy nie wrócili`, and track its exact
    objective of defeating two wolves.
11. Explore a modular `Zmierzchowe Równiny` map with the original 80% encounter
    chance and separate day/night enemy tables.
12. Fight all first-region enemies in turns using attack, defense, potion, and
    flee actions; receive original EXP, Gold, and loot-table rewards.
13. Inspect both equippable items and stackable materials or consumables in the
    backpack, including loot quantities and descriptions.
14. Compare all four class paths from level zero and make the permanent class
    choice at the original level-five unlock point.

The GDScript model also carries the legacy attribute formulas, level-zero
experience threshold, four attribute points per level, and Pierrot-only Luck.
GUT parity tests protect those rules while the Python suite remains the complete
behavioral reference.

Equipment in the backpack remains a separate instance with its own identifier,
matching the swap and unequip behavior of v0.24.7. The menu deliberately keeps
load and persistent save actions disabled. Save schema v15 also contains the
complete item catalog, stack inventory, affixes, quests, party, expeditions,
and world state. A partial writer would silently discard data, so persistent
saves will be enabled only after those required domain objects have been
migrated.

The current city service screens are intentionally asymmetric. The merchant
can sell the first healing consumable and the inn performs paid full recovery
with time advancement. The blacksmith and workshop expose their locations and
already recognize migrated loot, while enhancement recipes, crafting, item
sets, and the broader economy remain subsequent parity slices. This keeps the
playable prologue-to-quest loop honest without inventing replacement rules.

## Add-on policy

- GUT is the test runner for migrated GDScript behavior.
- State Charts may coordinate high-level UI and gameplay states, but domain
  rules remain regular typed GDScript.
- Dialogic owns authored conversations only; quests and rewards remain in the
  project's domain layer.
- Add-on source is committed under `godot/addons/` at known release tags.
