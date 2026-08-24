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

The current playable migration includes stages 0–3, stages 4A–4E, stages
5A–5E, stages 6A–6K, Stage 7, and stages 8A–8E, including all eight class
talent paths, 41 talents, passive Masteries, and specializations. All sixteen
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
Stage 6A introduces explicit `CompanionState` and `PartyState` models, the 12
authored terminal companion templates, and a party service enforcing the
four-companion roster, three-active limit, SOLO mode, injuries, death, and
composition locks. The Guild now opens a functional party placeholder without
owning those rules. Save schema v13 delegates companion equipment and complete
party state to dedicated codecs and safely migrates schema-v1 through
schema-v12 files with an empty party.
Stage 6B adds the persisted two-candidate daily rotation, Guild-rank gates,
authored first conversations, one-attempt recruitment, dismissal and returning
companions. All 12 companions now have their terminal messages, idle/camp and
pair banter plus 16 authored personal-arc variants represented by explicit arc,
stage, and choice models. Relations, unique memories, unread state, seen banter,
Rift-based story gates, and candidate decisions remain domain-owned and survive
reload. The existing Party screen exposes roster, candidate, message, and
personal-story flows using placeholder panels. Existing schema v13 already
contained every required field, so 6B validates that data without a schema bump.
Stages 6C–6K subsequently complete companion builds and equipment, preparation,
AI tactics, party combat, casualties, SOLO dungeons, Rifts, and the final
Stage 6 save/load audit; the detailed boundaries are recorded in the migration
documents.

Stage 7 adds the safe terminal-save transition. The existing Load Game screen
can inspect an exact terminal `v0.24.7` schema-`v15` file and import it only as a
new Godot schema-`v17` copy in an empty slot. The original is opened read-only
and guarded by SHA-256 checks. Every successful copy receives a JSON report of
normalizations. Stage 8A adds a dedicated persistent open-world encounter state,
so elite discoveries, elite miss streaks, and regional-boss respawn counters
are now fully mapped instead of reported as unsupported. Full mapping, refusal,
rollback, source-immutability, UI, and save-load-save-load tests protect the
flow. Stage 8B activates the five terminal random elite modifiers for every
compatible normal overworld enemy. Per-region pity, day/night/Aurora chances,
weather-first stat changes, lifesteal, status resistance, elemental variants,
reward and loot multipliers, elite contracts, and one-time Adventure Log
discoveries are handled by domain services and the existing combat flow. Save
schema remains v17. Stage 8C adds the voluntary Azhar and Leviathan regional
boss challenges with exact combat data, weather snapshots, dedicated three-phase
engines, terminal loot and rare-book/class-equipment chances, story objectives,
Guild milestones, and the one-hour attempt cost. Boss rules remain outside UI;
Stage 8D now starts a six-expedition regional respawn only after victory,
decrements it exclusively through ordinary expeditions in the matching region,
blocks premature rematches, updates the map counter, and records the boss's
return. Stage 8E closes the final parity audit, including live behavior after
terminal-v15 import and repeated save/load. It also aligns boss-attempt order
with the terminal runtime: one hour passes before a victorious respawn is
started and logged. Existing schema-v17 state preserves the complete lifecycle.
See `../docs/STAGE_8_PARITY_REPORT_v0.25.0.md` for the current parity matrix.

Open the project with the pinned local editor from the repository root:

```powershell
.\scripts\open-godot.ps1
```

Run formatting checks, lint, the legacy Python suite, the bootstrap smoke test,
and GUT tests with one command:

```powershell
.\scripts\check.ps1
```

Create the versioned Windows debug build after installing the pinned Godot
export templates:

```powershell
.\scripts\export-windows.ps1
```

The output is written under `build/windows/`, which is intentionally ignored by
Git. Final art and audio production has not started.
