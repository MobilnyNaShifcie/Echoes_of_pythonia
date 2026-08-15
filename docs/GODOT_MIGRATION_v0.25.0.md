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
8. Design and export at a Full HD `1920×1080` reference resolution while
   keeping all functional screens usable at a tested `1280×720` minimum.

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
15. Buy all six merchant offers, sell stackable loot by quantity, and sell a
    selected equipment instance without touching equipped items.
16. Craft all ten Twilight Plains recipes in Mirela's workshop and use the
    migrated healing supplies during turn-based combat.
17. Upgrade equipped or backpack gear from `+0` through `+10` using the exact
    gold curve, material plans, and stat scaling of the terminal build.
18. Rest at the inn for six hours no more than once per Pythonia day, with the
    original level-scaled price and full resource restoration.
19. Track backpack weight, block only the start of a normal expedition while
    overloaded, and transfer stacks or exact equipment instances through the
    200-slot Guild Storage.
20. Persist the inn cooldown, carry upgrade, and complete Guild Storage in
    Godot save schema v2 while safely upgrading schema-v1 Godot saves.
21. Spend attribute points directly on the character sheet and immediately
    recalculate the same derived statistics as the terminal build.
22. Use one typed class catalog for all four Paths, their base Mana, identity,
    and starter equipment instead of duplicating those rules in UI code.
23. Inspect the full eleven-slot equipment set and backpack, compare candidate
    statistics with the currently equipped instance, and enforce level and
    class requirements before equipping.
24. Reject invalid save state that assigns a Path before level five, grants
    Luck outside Pierrot, or bypasses equipped-item requirements.
25. Inspect the four base active skills for the selected Path on a dedicated
    character-screen catalog, including unlock level, Mana cost, and equipment
    requirements.
26. Use all twelve shared-execution Warrior, Hunter, and Mage base skills from
    a dynamic combat selector, with invalid actions consuming neither Mana nor
    an enemy turn.
27. Resolve multi-hit and guaranteed-hit attacks, ATK, Dexterity, and
    Intelligence scaling, bleeding, defense reduction, guard, and temporary
    dodge using tested combat-domain code.
28. Execute all four Pierrot base skills through one Fate Engine, preserving
    their exact one-, two-, and three-die outcome tables, Fate Token gains,
    temporary dodge effects, attack reduction, double hits, and reflection.
29. Present Pierrot's encounter-local Luck, Fate Tokens, mirror readiness, and
    last one-to-three die results in an adaptive placeholder combat panel.
30. Execute Hunter's six additional Volley Techniques and the base Bleeding
    Shot as a three-technique sequence, including Explosive Charges, Phantom
    Echo, delayed Rain of Arrows, splitting fragments, and armor penetration.
31. Discover and resolve all six named Hunter combinations while clearing an
    unknown third-shot sequence without creating false progression.
32. Present the current Hunter sequence, pending effects, explosive charges,
    and last finisher in a compact placeholder combat panel.
33. Persist unlocked Hunter techniques and discovered combinations in the
    validated Godot save schema v3 while safely migrating schema-v1 and
    schema-v2 Godot saves.
34. Apply physical, fire, wind, frost, earth, and water resistance through one
    clamped combat-domain model while preserving the terminal damage floor.
35. Build Mage elemental sequences and Arcane Weave, including a validated
    two-spell action with the original power, Mana, and turn-economy variants.
36. Resolve Warrior shield blocking, Shield Bash, Provoke, block counters, and
    defense-prepared retaliation through encounter-local combat state.
37. Present live Warrior and Mage mechanics in compact placeholder panels and
    persist their unlocked mechanic identifiers in validated save schema v4.
38. Spend level-derived points across all eight class paths and 41 terminal
    talents, enforcing ranks, prerequisites, book-locked paths, and paid reset.
39. Develop four passive abilities through base and Mastery ranks, then make
    one permanent specialization choice for each completed passive.
40. Drive combat behavior from purchased ranks, including class multipliers,
    talent skills, Fate manipulation, critical hits, extra attacks,
    regeneration, Second Wind, and Momentum.
41. Manage the complete progression flow from the placeholder Talents and
    Passives screen reached through the character sheet.
42. Persist and validate all stage-3F progression in Godot save schema v5 while
    safely migrating schema-v1 through schema-v4 files.
43. Register all eight terminal Path and Mastery books as backpack items and
    consume them only after their class, ownership, and duplicate checks pass.
44. Separate five complete terminal region definitions from their placeholder
    presentation while keeping recommended level as a warning, not a lock.
45. Persist and validate known regions in Godot save schema v6 and migrate
    schema-v1 through schema-v5 saves with all terminal regions known.
46. Run ordinary expeditions through one region-aware service for all five
    terminal regions, preserving encounter chances, day/night weights, quiet
    events, one-hour duration, overload checks, and non-blocking level advice.
47. Register all 36 unique open-world encounters, including the 26 enemies
    beyond Twilight Plains, with terminal combat stats, specials, ranks,
    physical reduction, elemental resistances, status resistance, EXP, and
    gold rewards.
48. Carry the selected region into combat presentation and validated save
    round-trips without introducing a new schema after v6.

The GDScript model also carries the legacy attribute formulas, level-zero
experience threshold, four attribute points per level, and Pierrot-only Luck.
GUT parity tests protect those rules while the Python suite remains the complete
behavioral reference.

Equipment in the backpack remains a separate instance with its own identifier,
matching the swap and unequip behavior of v0.24.7. The Godot build now writes a
separate migration schema containing every system currently available in the
windowed build. Its four files live below `user://godot_migration_saves` and do
not read or overwrite terminal save schema v15. That legacy schema also contains
affixes, party, expeditions, and world state which have not been migrated yet;
therefore importing terminal saves remains disabled until no supported field
could be silently discarded. Detailed ordering and acceptance criteria are in
`SYSTEM_MIGRATION_STAGES_v0.25.0.md`.

The current city service screens are intentionally asymmetric. The merchant
supports the terminal stock plus stack and equipment sales, the blacksmith
handles atomic multi-level upgrades, Mirela exposes recipes whose materials
already have sources in the migrated world, and the inn performs paid full
recovery with its daily cooldown. Final item art, shop animation, and audio
remain outside this domain slice and continue to use placeholder presentation.

Stages 3C through 3F and stages 4A–4B are complete. Dice history, Fate Tokens,
temporary dodge,
mirror readiness, Hunter sequence, delayed effects, explosive charges, Arcane
Weave, elemental sequence, Provoke, block bonus, and retaliation readiness are
intentionally encounter-local. Godot save schema v6 keeps durable talent ranks,
book-unlocked class paths, passive ranks, Masteries, specializations, Hunter
progression, compatibility identifiers from earlier slices, and the list of
known regions. Unread books remain ordinary inventory stacks. All five regions
now launch real day/night expeditions against their terminal enemy catalogs;
recommended levels remain advisory. Purchased
talents are now the authoritative source for class mechanics; the older
identifier collections remain only for schema compatibility. Affixes, item
sets, book acquisition sources, regional item drops, weather, camps, elites,
bosses, and later regional equipment remain in the world-and-expeditions stage.

## Add-on policy

- GUT is the test runner for migrated GDScript behavior.
- State Charts may coordinate high-level UI and gameplay states, but domain
  rules remain regular typed GDScript.
- Dialogic owns authored conversations only; quests and rewards remain in the
  project's domain layer.
- Add-on source is committed under `godot/addons/` at known release tags.
