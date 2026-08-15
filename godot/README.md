# Echoes of Pythonia — Godot v0.25.0

This directory contains the Godot 4 migration of Echoes of Pythonia. The Python
implementation remains the behavioral reference until each feature has an
equivalent, tested GDScript implementation.

## Pinned toolchain

- Godot 4.7.1 stable
- GUT 9.7.0
- Godot State Charts 0.22.5
- Dialogic 2.0 Alpha 20
- GDScript Toolkit 4.5.0

## Layout

- `addons/` — pinned third-party Godot add-ons
- `assets/` — source-controlled game assets
- `autoload/` — intentionally small application-wide services
- `core/` — engine-independent domain rules and data models
- `features/` — vertical gameplay slices
- `scenes/` — composition and entry-point scenes
- `tests/` — GUT tests mirroring migrated behavior
- `ui/` — reusable controls, themes, and presentation logic

The current playable migration includes stages 0–3, stages 4A–4E, and stages
5A–5E, including all eight class talent paths, 41 talents, passive Masteries, and
specializations. All sixteen
base Path skills are active. Pierrot uses a dedicated
Fate Engine with encounter-local Fate Tokens and exact 1d6/2d6/3d6 tables.
Hunter has all additional Volley Techniques and named combinations. Mage has
elemental sequences and Arcane Weave, while Warrior has shield blocking,
Provoke, Shield Bash, counters, and retaliation. Purchased talents now drive
those mechanics, including Pierrot's Fate manipulation and four talent-only
active skills. The progression and combat panels remain placeholders; final
presentation is a later, separately approved step. Stage 4A adds all eight
Path and Mastery books as readable backpack items, plus a typed catalog and
placeholder browser for the five terminal regions. Recommended levels remain
warnings rather than access locks, matching the terminal game. Stage 4B makes
all five regions explorable with their separate day/night encounter tables and
all 36 open-world enemies. Regional fights use terminal stats, special attacks,
physical and elemental defenses, status resistance, EXP, and gold rewards.
Stage 4C connects all 36 open-world loot tables to a regional item catalog. Its
72 additional definitions bring the Godot catalog to 118 items, while Mirela's
42 recipes are grouped across all five regions. Loot now reaches the backpack
as real stacks or separate equipment instances, regional Item Power drives
upgrade materials, recipe gold costs are atomic, and equipped elemental
resistances affect combat. Stage 4D completes Equipment 2.0 for the migrated
open world: rarity controls zero to four unique affixes, source quality shifts
their T1–T5 rolls, and every advanced bonus participates in derived stats and
turn-based damage. The four Nature accessories activate their original set
bonus. Pancerz Północy, Płaszcz Śnieżnego Gryfa, and Amulet Czarnego Morza
activate the terminal Warrior, Hunter, and Mage effects for the matching class.
The placeholder equipment details expose Item Power, affixes, sets, and class
effects. Save schema v7 validates each roll and deterministically supplies
affixes when loading schema-v1 through schema-v6 files. Stage 4E adds all five
weighted terminal weather states on six-hour world-clock cycles. Weather from
the start of an encounter modifies regular enemies, minibosses, Aurora rewards,
and loot chances. The placeholder world map now includes the two-hour field
camp with partial PŻ/Mana recovery and an expedition-reset cooldown. Save schema
v8 persists weather, its remaining duration, and camp availability while safely
migrating schema-v1 through schema-v7 files. Stage 5A replaces the single-quest
prototype with all nine ordered Act I chapters, generic kill and collection
objectives, exact rewards, and Guild ranks F–S. The placeholder Guild board
shows prerequisites and unavailable late-world dependencies without introducing
final art or substitute encounters. Stage 5B adds three automatic Daily
contracts and one Weekly, with calendar rotation, anti-reroll persistence,
multi-objective progress, exact rank requirements and reputation rewards, and
separate placeholder views on the Guild board. Save schema v9 stores their
generated definitions, progress, and claimed rewards and migrates schema-v1
through schema-v8 files with a safe empty board.
Stage 5C adds four one-time world milestones worth exactly 650 total Guild
reputation, all 32 rank- and progress-filtered terminal rumors, and the
timestamped Adventure Log. The Guild exposes milestone and rumor placeholder
tabs, while the city opens a dedicated journal showing the latest 30 of at most
50 entries. Combat, weather, rests, economy actions, quests, contracts, and
Guild rank changes feed one shared log API. Save schema v10 validates and
persists milestones plus journal entries and safely migrates schema-v1 through
schema-v9 files.
Stage 5D implements the rank-C and dungeon-milestone informant check in the inn,
including its one-check-per-Pythonia-day rule, 20% chance, and guaranteed fifth
eligible day. Meeting the informant permanently exposes the Black Market city
location. Its four deterministic daily offers include the terminal rare goods,
Mastery Books, and rarer Path Books; purchases are single-stock, all eight books
can be sold, and each buy or sale price can be bargained once per delivery.
Every roll and mutation is saved immediately. Save schema v11 validates and
persists the complete contact, rotation, purchase, and negotiated-price state
while safely migrating schema-v1 through schema-v10 files.
Stage 5E ports the exact seven terminal achievements and their titles. Victories,
three migrated minibosses, Aurora weather, a +10 item, and Guild rank S feed one
idempotent achievement service. A dedicated placeholder screen lists locked and
unlocked accomplishments and equips available titles, which are shown next to
the hero name. Save schema v12 validates achievement identifiers and selected
titles, preserves them across sessions, reconciles unambiguous legacy progress,
and safely migrates schema-v1 through schema-v11 files. The closing Guild audit
locks the F–S thresholds, nine-story-quest total, contract reputation, four
milestones, 32 rumors, and Black Market gates in regression tests.

Open the project with the pinned local editor from the repository root:

```powershell
.\scripts\open-godot.ps1
```

Run formatting checks, lint, the legacy Python suite, the bootstrap smoke test,
and GUT tests with one command:

```powershell
.\scripts\check.ps1
```
