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
49. Replace the first-region reward constant with one validated loot catalog
    covering all 36 open-world enemies and preserving future elite chances.
50. Register 72 additional regional materials, consumables, keys, and equipment
    definitions with terminal Item Power, level requirements, base statistics,
    elemental resistances, and item metadata.
51. Group Mirela's 42 open-region recipes by their five source regions and make
    material plus Gold consumption atomic.
52. Carry regional loot through backpack equipment instances, upgrades,
    elemental combat resistance, and existing schema-v6 save round-trips.
53. Generate zero to four unique Equipment 2.0 affixes by rarity, slot role,
    Item Power, source quality, and terminal T1–T5 value curves.
54. Apply flat, percentage, resistance, critical, skill, armor-penetration, and
    enemy-rank bonuses to the live player and turn-based damage resolver.
55. Activate the complete four-piece Nature set and the three regional class
    effects: Odwet, Drapieżny Odruch, and Przypływ Many.
56. Show Item Power, affix tiers, set progress, and class effects in the
    placeholder equipment comparison panel.
57. Persist and validate generated equipment in Godot save schema v7 while
    deterministically backfilling schema-v1 through schema-v6 instances.
58. Roll Sunny, Storm, Frost, Wind, and Aurora from the terminal weights and
    advance that state in six-hour cycles through the shared world clock.
59. Preserve encounter-start weather, apply its regular-enemy and miniboss
    modifiers, and increase EXP, Gold, and loot chances by 50% under Aurora.
60. Rest at a field camp for partial HP and Mana recovery, consume two hours,
    and reopen the free rest only after another expedition.
61. Present weather and camp controls with placeholders and persist their state
    in validated schema v8 while migrating schema-v1 through schema-v7 saves.
62. Register all nine ordered Act I quests with their terminal levels,
    objectives, rewards, completion text, and total Guild reputation.
63. Run kill and collection objectives through one generic quest service,
    including consumed evidence, retained trophies, sequential prerequisites,
    and live updates from combat, city, and world flows.
64. Derive the seven Guild ranks from exact reputation thresholds, present the
    complete Act I on a placeholder Guild board, and validate every quest state
    in the existing schema v8 without inventing unavailable late-game sources.
65. Generate exactly three Daily contracts and one multi-objective Weekly from
    the player's accessible regions, their enemies, and real material drops.
66. Rotate Daily by local calendar date and Weekly by ISO Monday week while
    persisting generated definitions to prevent restart rerolls and ignoring
    clock rollback.
67. Track enemy, region, elite, miniboss, collection, and dungeon objectives;
    consume deliveries atomically and award one-time EXP, Gold, items, and
    exact `15/75` Guild reputation behind ranks E and D.
68. Present story, Daily, and Weekly as separate placeholder Guild-board views,
    report unmigrated elite and dungeon sources, and persist all contract state
    in validated schema v9 while safely migrating schema-v1 through schema-v8.
69. Register the four one-time Guild world milestones with their exact terminal
    reputation values and reusable boss/dungeon integration points.
70. Preserve all 32 terminal Guild rumors and filter them by rank, Black Market
    access, and permanent milestone state without exposing locked information.
71. Record timestamped major events through one Adventure Log API, keep the
    newest 50 entries, and show the latest 30 on a city-accessible placeholder.
72. Expose milestones and rumors as separate Guild tabs and persist both Guild
    milestones and journal entries in validated schema v10 while safely
    migrating schema-v1 through schema-v9.
73. Check for the inn informant once per eligible Pythonia day behind rank C and
    a completed qualifying dungeon, preserving the 20% roll and fifth-day pity.
74. Permanently expose the Black Market after the authored informant scene and
    rotate four deterministic offers every real calendar day.
75. Carry terminal rare goods, all Mastery Books, and rarer Path Books through
    single-stock purchases plus one-copy book sales.
76. Apply one persisted 30% bargaining attempt per purchase offer or sold book,
    using the original success and failure price ranges and 50-gold rounding.
77. Save every anti-reroll mutation immediately and persist the complete market
    state in validated schema v11 while safely migrating schema-v1 through
    schema-v10.
78. Own all companion-specific state through `CompanionState` and the roster
    through `PartyState`, preserving the terminal limits of four recruited and
    three active companions.
79. Keep all twelve authored companion templates in a catalog separate from UI
    and change active composition only through a tested party service.
80. Persist full party, candidate, message, equipment-ownership, private
    storage, and fallen-companion state in schema v13 while migrating earlier
    Godot saves with a safe empty party.
81. Rotate two persisted candidates per Pythonia day behind the terminal Guild
    rank gates, keeping generated identity, level, Path, personal arc, and the
    one-attempt recruitment roll stable across reloads.
82. Keep the twelve authored recruitment conversations, responses, idle/camp
    lines, messages, pair banter, and all sixteen personal-arc variants in
    catalogs and explicit dialogue/arc/stage models outside UI.
83. Apply relation deltas, unique memory tags, unread state, seen banter, and
    Rift-based personal-stage gates only through companion domain services.
84. Expand the existing Guild party screen with roster, candidate, message,
    and personal-story flows while retaining placeholder presentation and save
    schema v13.

The GDScript model also carries the legacy attribute formulas, level-zero
experience threshold, four attribute points per level, and Pierrot-only Luck.
GUT parity tests protect those rules while the Python suite remains the complete
behavioral reference.

Equipment in the backpack remains a separate instance with its own identifier,
matching the swap and unequip behavior of v0.24.7. The Godot build now writes a
separate migration schema containing every system currently available in the
windowed build. Its four files live below `user://godot_migration_saves` and do
not read or overwrite terminal save schema v15. Although Rift expeditions and
party combat are now migrated and the Stage 6K parity audit is complete, the
legacy format still requires the dedicated read-only mapping and migration-copy
report assigned to Stage 7. Therefore importing terminal saves remains disabled
until no supported value could be silently discarded. Detailed ordering and
acceptance criteria are in
`SYSTEM_MIGRATION_STAGES_v0.25.0.md`.

The current city service screens are intentionally asymmetric. The merchant
supports the terminal stock plus stack and equipment sales, the blacksmith
handles atomic multi-level upgrades, Mirela exposes recipes whose materials
already have sources in the migrated world, and the inn performs paid full
recovery with its daily cooldown. Final item art, shop animation, and audio
remain outside this domain slice and continue to use placeholder presentation.

Stages 3C through 3F, stages 4A–4E, stages 5A–5E, and stages 6A–6K are complete. Dice history,
Fate Tokens,
temporary dodge,
mirror readiness, Hunter sequence, delayed effects, explosive charges, Arcane
Weave, elemental sequence, Provoke, block bonus, and retaliation readiness are
intentionally encounter-local. Godot save schema v16 keeps durable talent ranks,
book-unlocked class paths, passive ranks, Masteries, specializations, Hunter
progression, compatibility identifiers from earlier slices, and the list of
known regions. Unread books remain ordinary inventory stacks. All five regions
now launch real day/night expeditions against their terminal enemy catalogs;
recommended levels remain advisory. Purchased
talents are now the authoritative source for class mechanics; the older
identifier collections remain only for schema compatibility. All regional
open-world loot and Equipment 2.0 are now connected. Generated instances carry
validated Item Power and T1–T5 affixes; the Nature set and three regional class
effects participate in live combat. Weather advances with the world clock,
changes encounters and Aurora rewards, while the field camp provides its
terminal partial recovery and cooldown. Book acquisition sources, elites,
weather-specific miniboss weapons, and bosses remain in the
world-and-expeditions stage. The full nine-chapter Act I catalog and Guild
ranks F–S are now active. Its first five chapters use already migrated targets;
later chapters explicitly report their dungeon, regional-boss, and Black Fleet
dependencies until those world systems are implemented.
The Guild board also owns three deterministic Daily contracts and one Weekly.
The seven terminal achievements and their title rewards are now driven by
victory, weather, upgrade, and Guild-rank events. Their dedicated placeholder
screen is reachable from Varenhold, and the selected title is rendered with the
hero name. The closing stage-5 audit fixes the migrated Guild totals and gates in
tests before dungeon work begins.
The Stage 6 foundation stores companions and the roster in explicit domain
models, exposes tested composition controls through the Guild, and validates
party equipment ownership independently of `SaveGameService`. Stage 6B adds
deterministic daily candidates, persisted one-attempt recruitment, returning
companions, authored relations, messages, banter, and personal histories for all
twelve templates. Stage 6C adds deterministic companion attributes, talents,
level progression, full personal equipment, and player-owned equipment transfer
through dedicated domain services. Attribute, talent, and gear generation use
separate named RNG substreams after the frozen Stage 6B candidate fields. The
existing Party Hub exposes the resulting build without owning its rules, and
dismissal returns every player-owned item before the companion leaves. Save
Stage 6C itself kept schema v13 because the Stage 6A party codec already owned the complete
build and equipment state; empty Stage 6B builds are backfilled once without
rerolling the candidate rotation. Stage 6D adds a separate expedition
preparation state and codec, raising the Godot schema to v14. Its four presets
store active companion IDs and target consumable quantities; applying one only
withdraws the missing stock from Guild Storage after an atomic carry-weight
check. The new placeholder preparation screen displays hero and companion
resources, warnings, supplies, and quick links to existing management screens.
Overload blocks departure while other warnings require explicit confirmation.
Stage 6E moves all four companion tactics into a presentation-independent AI
service. Stage 6F then adds shared stateless damage helpers and a separate
`PartyCombatEngine`; the existing 1v1 engine remains independent. A party round
runs the player, companions in party order, status ticks, and the enemy while
reusing the migrated skills, injected deterministic RNG, companion resources,
equipment effects, and terminal boss-frenzy rules. The engine deliberately has
no artificial UI entry or rewards before the Rift lifecycle is migrated. It
also does not mutate heavy injuries or death: downed/rescue/lethal-warning
behavior remains the explicit Stage 6G boundary. The save schema remains v14
because only already-persisted companion HP and Mana leave the transient battle.
Stage 6G completes that boundary with transient downed timers, player and
companion rescue actions, and deterministic consequence reports. Permanent
death is never rolled: only a high-rank Rift boss can announce an execution,
and the warning must expire without rescue or victory. A separate
`CompanionCasualtyService` applies heavy injuries or memorials outside combat
and UI, returns all player-owned gear on death, and uses injected RNG only for
the 2–5 day heavy-injury duration. The existing Party Hub now renders the
persisted Fallen Board. The schema remains v14 because Stage 6A already stores
injury deadlines, messages, equipment ownership, and memorials; in-battle
countdowns intentionally remain transient.
Stage 6H adds the two terminal SOLO dungeons through a dedicated transient
`DungeonRunState` and `DungeonService`. The Sunken Order Crypt and Black Fleet
Wreck preserve their entry items, random rooms, authored branches, recovery,
one-hour encounters, unsecured-loot snapshot, safe retreat, and completion
milestones. Dungeon fights reuse the ordinary 1v1 engine without surface
weather rewards; narrow Grand Master and Admiral Varek subclasses own only
their phase mechanics. Neither `PartyCombatEngine` nor Rift state is referenced.
The run itself is intentionally not persisted, matching the terminal checkpoint
boundary, while all resulting inventory, progression, contracts, milestones,
and journal entries already survive the current schema v16.
Stage 6I adds the terminal Rift lifecycle before expedition content is activated.
`RiftState`, `RiftInstance`, and the reserved `RiftExpedition` own the durable
world state, while `RiftLifecycleService` deterministically spawns ranked Guild
alarms, expires ignored Rifts through another authored searcher team, enforces
rank and party-size gates, binds the active composition, and safely abandons a
reservation. An active reservation protects even an expired Rift until it is
abandoned, matching v0.24.7. The Guild exposes the placeholder Rift board
introduced at that boundary. A separate `RiftSaveCodec` raises
the Godot-only schema to v15 and migrates schema-v14 saves to a safe empty Rift
state. This does not enable terminal-save-v15 import: both formats remain
separate and terminal values will be imported only after the Stage 7 parity
audit.
Stage 6J activates full Rift expeditions through a separate
`RiftSegmentService` and `RiftExpeditionService`. The terminal 12–24 segment
schedule, authored events, camps, elites, minibosses, bosses, rank/depth/party
scaling, mechanical modifiers, persistent companion resources, segment EXP,
defeat behavior, completion rewards, 16 class uniques, relationship progress,
and one-time closure are now connected to the lifecycle from 6I. Party battles
reuse `PartyCombatEngine` and the explicit casualty rules from 6F–6G; the
ordinary 1v1 engine and the lifecycle remain independent. Named Godot RNG
substreams preserve deterministic rules without claiming bit-identical Python
`random.Random` output. The existing Rift board owns no reward or combat-result
logic and now presents the complete placeholder flow without a second hub.
Schema remains v15: completed segments, party resources, casualties, and the
reservation survive save/load, while the in-memory combat engine is deliberately
recreated for the current segment after reload, matching the terminal boundary.
Stage 6K closes the full Stage 6 parity and save/load audit. Explicit companion
resource-initialization flags remove the former ambiguity between an unbuilt
resource and a valid zero-HP or zero-Mana state; the Godot-only schema therefore
rises to v16 with a one-time migration for older Godot saves. Party and Rift
codecs now enforce the terminal domain bounds, identity links, authored Rift
shape, calendar consistency, and a bounded message history. A populated
party/preparation/Rift snapshot is protected through save-load-save regression
tests. The terminal schema-v15 format remains separate and its importer is still
disabled until Stage 7.
Stage 7 completes the safe transition boundary. A dedicated read-only importer
accepts only terminal `v0.24.7` schema `v15`, maps supported state into the
separate Godot schema `v16`, validates it through `SaveGameService`, writes only
to an empty Godot slot, verifies a disk round trip, and emits a separate JSON
audit report. SHA-256 checks protect the terminal source throughout; the source
is never moved, rewritten, or deleted. The existing Load Game screen exposes
the flow without owning migration rules. Elite discovery/pity counters and
regional-boss respawn counters have no safe Godot equivalent yet, so their
validated values are recorded explicitly under `not_migrated` rather than
silently discarded. A Windows Desktop debug preset, export script, packaged
runtime smoke test, keyboard focus checks, and full-cycle regressions close the
stage. Final art, audio, and advanced animation remain unstarted and require a
separate approval.
Stage 8A closes the three persistence gaps left by that audit without enabling
new encounter behavior. `OpenWorldEncounterState` owns elite discoveries,
per-region elite miss streaks, and regional-boss respawn counters, while a
dedicated codec validates and persists them in Godot schema v17. Schema-v1
through schema-v16 Godot saves receive an empty state. Terminal v15 imports now
preserve all three recorded values in the migrated copy and report no unmapped
fields. Elite generation and regional-boss gameplay remain isolated future
vertical slices rather than UI or save-service responsibilities.
Stage 8B activates terminal random elites as a separate open-world subsystem.
`EliteCatalog` owns the five authored modifiers and their complete enemy
compatibility table, while `EliteEncounterService` owns eligibility, day/night
and Aurora chances, per-region miss streaks, weather-first modifier application,
grammar, rewards, and one-time discoveries. The ordinary combat engine only
shares the small enemy lifesteal hook; exploration passes the exact rolled
modifier to the existing combat screen without rerolling it. Victory feeds the
existing loot-quality, contract, inventory, achievement, and Adventure Log
services. No elite rule lives in UI and the save schema remains v17 because
8A already persisted every durable value. Regional bosses and their respawn
lifecycle remain isolated stages 8C–8D.
Their calendar periods, generated definitions, objective progress, and claimed
rewards survive reloads; existing schema-v8 files receive a safe empty board
before the next period is generated.
The Guild archive also tracks four permanent world milestones and exposes all
currently eligible authored rumors. The shared Adventure Log records major
combat, weather, economy, rest, quest, contract, and reputation events with
world time; its newest entries and milestone state survive reloads. Regional
boss and dungeon completion sources remain explicit dependencies of stages 4F
and 6 rather than placeholder reward shortcuts.
The inn now performs the persisted informant roll once per eligible world day.
After the permanent unlock, the city exposes a placeholder Black Market with a
deterministic four-offer daily delivery, one-stock purchases, book sales, and
one persisted bargaining attempt per price. The qualifying dungeon milestones
still originate in stage 6; no temporary unlock bypass has been introduced.

## Add-on policy

- GUT is the test runner for migrated GDScript behavior.
- State Charts may coordinate high-level UI and gameplay states, but domain
  rules remain regular typed GDScript.
- Dialogic owns authored conversations only; quests and rewards remain in the
  project's domain layer.
- Add-on source is committed under `godot/addons/` at known release tags.
