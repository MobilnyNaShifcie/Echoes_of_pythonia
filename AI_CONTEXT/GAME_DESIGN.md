# Echoes of Pythonia — Game Design

> Role: detailed gameplay source of truth for AI-assisted development  
> Baseline: Godot migration line v0.25.x  
> Protected baseline: `snapshot/pre-ai-team-2026-09-10`  
> Working branch: `ai/echoes-team`  
> Terminal reference: v0.24.7 remains the behavioral reference for migrated mechanics unless an explicit newer decision supersedes it.

---

## 1. Purpose

This document explains **how Echoes of Pythonia is meant to play**.

`PROJECT_BIBLE.md` defines the identity and non-negotiable direction of the project.  
This file defines concrete gameplay rules, progression structure, system boundaries, current canonical content, and design guardrails.

Every AI agent changing gameplay must read:

1. `AI_CONTEXT/PROJECT_BIBLE.md`
2. `AI_CONTEXT/GAME_DESIGN.md`
3. the specialized AI_CONTEXT file relevant to the task
4. the current implementation and tests for exact formulas

If this document gives a design rule but does not provide an exact numerical formula, the agent must **inspect the current domain code and regression tests instead of inventing a value**.

---

## 2. Design-state labels

When discussing systems, use these meanings:

### CANONICAL — IMPLEMENTED
The rule exists in the current Godot build and is protected by current code/tests.

### CANONICAL — DESIGN
The rule is an explicit project decision and should be preserved even if presentation is not final.

### PLANNED
Accepted direction that may not yet be fully implemented.

### HISTORICAL
Older design or terminal-era naming kept only for context.

Do not silently promote a HISTORICAL or PLANNED rule over a current CANONICAL implementation.

---

## 3. Core design pillars

Echoes of Pythonia should consistently support these pillars:

### 3.1 Meaningful progression
The player should regularly gain:

- levels;
- attributes;
- equipment;
- upgrades;
- talents;
- passive ranks;
- specializations;
- class mechanics;
- access to harder regions;
- guild standing;
- companion options;
- dungeon and Rift opportunities.

Progression should produce new decisions, not only larger numbers.

### 3.2 Distinct class identity
Warrior, Hunter, Mage and Pierrot must not become four versions of the same damage loop.

Each class should have a recognizable combat rhythm and unique resources/mechanics.

### 3.3 Preparation matters
Choosing where to go, what to carry, which companions to take, how they behave and what supplies are available is part of the game.

### 3.4 Risk should be readable
Danger may be severe, including permanent companion death, but serious consequences must be understandable and signalled.

### 3.5 The world is systemically connected
Regions, loot, crafting, quests, guild progression, bosses, dungeons, companions and the Black Market should feed into one another.

### 3.6 Graphical presentation should improve clarity
The Godot version is not a graphical terminal. Systems may keep terminal rules while receiving better visual presentation.

---

## 4. High-level gameplay loop

The intended normal loop is:

```text
Varenhold / city
    ↓
manage hero
    ↓
equipment / talents / passives / crafting / guild / companions
    ↓
choose destination
    ↓
Przygotowanie do wyprawy
    ↓
validate party, supplies, weight and warnings
    ↓
world expedition / dungeon / Rift / boss objective
    ↓
combat and events
    ↓
loot / EXP / Gold / quest progress / reputation
    ↓
return to city
    ↓
upgrade / sell / craft / heal / plan next expedition
```

The player should feel that town preparation and expedition results form one connected economy.

---

## 5. Starting state and early progression

Current migrated starting-state rules include:

- 20 starting HP;
- 3 starting ATK;
- 2 starting DEF;
- 0 starting Mana before class-specific Mana is applied;
- legacy Dodge and attribute formulas;
- starting currency and EXP according to the migrated terminal rules;
- starting equipment created from typed item definitions.

The prologue includes the tutorial encounter with:

**Przeklęty Strach na Wróble**

The player reaches Varenhold with Guild rank:

**F — Nowicjusz**

Exact derived-stat formulas remain authoritative in the domain implementation and regression tests.

---

## 6. Attributes and level progression

Core attributes:

- STR
- INT
- VIT
- DEX
- END

The player gains:

**4 attribute points per level**

The UI should allow efficient multi-point allocation.

Derived statistics must be recalculated through the authoritative player/stat domain logic rather than duplicated in UI scripts.

Important player-facing statistics include:

- HP
- Mana
- ATK
- DEF
- Dodge
- elemental/physical resistance where relevant
- critical-related values where unlocked by progression

### 6.1 EXP
The UI should always make it possible to understand:

- current level;
- current EXP;
- EXP required for next level.

Do not create a second independent leveling curve in UI or content scripts.

---

## 7. Class selection

There are four primary Paths/classes:

- Warrior
- Hunter
- Mage
- Pierrot

The permanent Path choice unlocks at:

**level 5**

Before that point the player may inspect/preview class identities, but the save system must reject an invalid state that grants a Path too early.

Class rules should come from one authoritative catalog rather than duplicated UI constants.

---

## 8. Pierrot terminology

Pierrot has a class-exclusive Luck/Fate identity.

In player-facing Polish content use:

**Szczęście**

Do not use:

`LCK`

Szczęście must remain exclusive to Pierrot unless an explicit later design decision changes the rule.

Invalid saves that grant this stat to another class should be rejected or migrated safely according to the save rules.

---

## 9. Shared turn-based combat

Normal combat is turn based.

The battle layer may improve presentation, but the UI must not become the source of gameplay outcomes.

A player action that is invalid because of unmet requirements should not consume:

- Mana;
- the player turn;
- an enemy turn;

unless the specific mechanic explicitly says otherwise.

Shared mechanics already include:

- normal attacks;
- defense/guard;
- healing supplies;
- flee;
- multi-hit attacks;
- guaranteed-hit attacks;
- bleeding;
- DEF reduction;
- temporary Dodge bonuses;
- class-specific states;
- elemental and physical resistance.

---

## 10. Damage types and resistances

The migrated combat model supports six damage/resistance categories:

- physical;
- fire;
- wind;
- frost;
- earth;
- water.

Elemental/related resistances are clamped to:

**0–75%**

The original terminal damage floor must remain preserved.

Do not alter resistance caps or the damage floor casually as part of an unrelated refactor.

---

## 11. Encounter-local state

The following kinds of state are intentionally encounter-local rather than permanent save progression:

- active temporary Dodge;
- Fate roll history for the current encounter;
- Fate Tokens for the current encounter;
- mirror/reflection readiness;
- Hunter current Volley sequence;
- pending Hunter delayed effects;
- explosive charges used as encounter state where defined;
- Mage elemental sequence;
- Arcane Weave temporary state;
- Warrior Provoke/block/retaliation readiness;
- temporary combat statuses;
- party-combat downed counters.

Do not serialize temporary battle state into long-term progression unless the mechanic is explicitly redesigned.

---

# CLASS SYSTEMS

## 12. Warrior

### CANONICAL identity

Warrior combines:

- weapon pressure;
- shield defense;
- blocking;
- counterplay;
- Provoke;
- retaliation.

The class should reward deliberate defensive timing rather than functioning as a pure HP sponge.

### 12.1 Shield mechanics

Current migrated combat supports:

- base shield block chance;
- a one-use Provoke-related bonus;
- Shield Bash;
- forced basic enemy attack after Provoke where defined;
- heavy counter after a successful block;
- retaliation prepared through Defense.

Exact probabilities and multipliers must come from current combat code/tests.

### 12.2 Heavy Knight direction

Heavy Knight is an accepted deeper specialization direction for Warrior.

Desired identity:

- DEF can become an offensive scaling resource;
- tanking should create counterattack opportunities;
- Provoke should matter tactically;
- defensive building should not mean giving up all damage.

Do not make Heavy Knight a generic high-HP variant.

---

## 13. Hunter

### CANONICAL identity

Hunter uses ranged techniques, sequencing and combination discovery.

The class has a richer skill/technique pool than a simple four-button ranged class.

### 13.1 Volley Technique sequence

Hunter uses a three-technique sequence.

Current migrated system includes the base:

**Krwawiący Strzał**

and six additional Volley Techniques.

Established techniques/mechanics include:

- Przebijająca Strzała;
- Lodowa Strzała;
- Wybuchowa Strzała;
- Widmowa Strzała;
- Rozszczepiająca Strzała;
- Deszcz Strzał;
- Explosive Charges;
- Phantom Echo;
- delayed Rain of Arrows;
- armor penetration;
- splitting fragments.

### 13.2 Combinations

There are:

**6 named Hunter combinations**

A valid three-technique sequence can resolve a named finisher.

An unknown third-shot sequence must still be cleared correctly and must not create false progression.

Discovered combinations are durable progression and are saved.

### 13.3 Design guardrail

Do not simplify Hunter into:

```text
basic shot
strong shot
AOE shot
ultimate
```

Sequencing and combination discovery are core class identity.

---

## 14. Mage

### CANONICAL identity

Mage revolves around elemental sequencing and **Splot / Arcane Weave**.

The class should reward spell ordering and resource planning.

### 14.1 Elemental sequence

Mage tracks different elemental casts.

A key migrated rule grants a bonus around the:

**third different spell/element in sequence**

Exact damage and state rules must remain in domain code/tests.

### 14.2 Splot

Mage can build:

**3 Splot charges**

and can unlock/use:

**Podwójne Tkanie**

which allows two spells in one turn under the appropriate mechanics.

Variants can alter:

- Mana cost;
- damage;
- Mana recovery;
- turn economy;

through relevant progression/masteries.

### 14.3 Arcana direction

The accepted class direction is that Arcana should emphasize the ability to combine two abilities/spells within one turn.

Do not reduce this identity to passive spell-damage bonuses.

---

## 15. Pierrot

### CANONICAL identity

Pierrot is based on:

- fate;
- dice;
- controlled uncertainty;
- Szczęście;
- Fate Tokens / Żetony Losu;
- manipulation of risk.

### 15.1 Fate Engine

There is one authoritative Fate Engine with testable roll input/history.

Dice configurations include:

- `1k6`
- `2k6`
- `3k6`

The system includes special handling for:

- doubles;
- triples;
- extreme sums;
- exact terminal multipliers.

Do not recreate these tables from memory. Read the Fate Engine and tests.

### 15.2 Base Pierrot abilities

Migrated abilities include:

- Pchnięcie Losu;
- Podwójny Rzut;
- Błazeński Unik;
- Wielki Zakład.

Effects across the class include:

- ATK reduction;
- double hits;
- Dodge bonuses;
- Kurtyna Lustrzana / reflection;
- Fate Token generation/use.

### 15.3 Advanced Fate manipulation

Progression includes mechanics such as:

- Dociążona Kość;
- Kant;
- Druga Szansa;
- Wybraniec Fortuny;
- Krzywe Zwierciadło;
- Podwójna Stawka;
- Efekt Domina;
- Va Banque.

The class must feel risky but manipulable rather than purely random.

---

# TALENTS AND PASSIVES

## 16. Talent architecture

Current migrated progression contains:

- **8 class paths**
- **41 talents** across the four classes

Talent purchase is authoritative.

Older compatibility identifiers may remain in save data, but unlocked mechanics should be driven by actual purchased talent ranks.

Talent rules include:

- level-derived points;
- rank requirements;
- prerequisites;
- Path requirements;
- book-locked branches;
- paid reset.

Do not grant talent mechanics automatically merely because a class reaches a certain level unless the current rule explicitly does so.

---

## 17. Passives

There are four core passive categories with base ranks and Mastery expansion.

Base ranks:

**1–5**

Mastery ranks:

**6–10**

A Mastery Book permanently expands the corresponding passive's cap.

Accepted passive families:

### Regeneracja
Specializations:
- Żelazna Wola
- Drugi Oddech

### Szybkość ataku
Specializations:
- Nawałnica Ciosów
- Zabójcze Tempo

### Obrażenia krytyczne
Specializations:
- Precyzja
- Egzekucja

### Zwiększenie ataku
Specializations:
- Furia
- Żądza Krwi

There are **8 permanent passive specialization choices** in total.

A specialization is meaningful and should not be silently reset by a normal talent reset unless the design explicitly permits it.

---

## 18. Books

Books are normal inventory items until successfully used.

Two important categories:

### Księgi Mistrzostwa
Used to unlock passive Mastery ranks 6–10.

Known titles include:

- Traktat Mistrzowskiej Regeneracji
- Manuskrypt Szybkiego Ostrza
- Kodeks Krytycznego Uderzenia
- Traktat Siły

### Księgi Ścieżki
Used to unlock special class-tree branches.

A failed use because of:

- wrong class;
- missing requirement;
- duplicate unlock;

must not consume the item.

Unread books remain inventory stacks.

---

# EQUIPMENT AND ITEMS

## 19. Equipment structure

The migrated equipment model supports:

- **11 equipment slots**
- a second-hand slot;
- weapon types;
- level requirements;
- class requirements;
- backpack item instances;
- equipped item instances;
- comparison against currently equipped items.

Equipment instances must retain unique identity when moved between backpack and equipped state.

---

## 20. Slot-role philosophy

Design grouping:

### Defensive
- boots
- helmet
- armor
- gloves

### Mixed
- belt

### Offensive
- other offensive-focused slots

Do not clutter player-facing item names with labels such as:

- `[DEFENSYWNY]`
- `[OFENSYWNY]`
- `[MIESZANY]`

The equipment screen and slot context should communicate the role.

---

## 21. Upgrading

The Blacksmith upgrade range is:

**+0 to +10**

Upgrades consume the exact required:

- Gold;
- materials;

atomically.

Multi-level upgrading may be offered in UI as long as the service validates the complete cost safely.

Do not duplicate upgrade curves inside presentation code.

---

## 22. Equipment 2.0

Current migrated Equipment 2.0 supports generated equipment with:

- Item Power;
- rarity;
- slot role;
- source quality;
- **0–4 unique affixes**;
- affix tiers **T1–T5**.

Affixes may include:

- flat statistics;
- percentage statistics;
- resistance;
- critical-related bonuses;
- skill-related bonuses;
- armor penetration;
- enemy-rank bonuses.

The exact roll curves remain authoritative in the equipment-generation code/tests.

### 22.1 High-level bonus philosophy

Higher rarity/source quality should create noticeably better items.

Previously accepted broad design ranges include examples such as:

- flat HP bonuses from roughly +500 to +2500;
- percentage damage bonuses from roughly 3% to 20%.

These are design-scale examples, not permission to replace the current generation curves without review.

---

## 23. Sets and class effects

Current migrated gear systems include:

### Nature set
A complete:

**4-piece Nature set**

with its active set effect.

### Regional class effects
Current class-specific regional effects include:

- Odwet
- Drapieżny Odruch
- Przypływ Many

These effects participate in live combat and must be included in balance reviews.

---

## 24. Inventory and carry weight

Inventory is tied to carry weight.

The player may exceed the comfortable/soft carrying range during normal inventory management, but expedition departure rules must enforce the current overload logic.

For `Przygotowanie do wyprawy`:

**overload is a hard departure block**

Do not silently delete items or auto-drop equipment to solve overload.

---

# CITY ECONOMY

## 25. Merchant

The migrated merchant supports:

- current authored stock;
- buying;
- stack sales by quantity;
- selling a selected equipment instance;
- protection against accidentally selling equipped items.

Economy UI should support quantity operations where appropriate.

---

## 26. Blacksmith

The Blacksmith owns equipment upgrades.

Rules:

- validate resources before mutation;
- Gold/material use is atomic;
- support +0–+10;
- do not partially consume resources if the upgrade cannot complete.

---

## 27. Mirela's Workshop

Crafting is region-linked.

The migrated world contains:

**42 open-region recipes**

across the five current regions.

Crafting must consume:

- materials;
- Gold;

atomically.

A recipe should not be presented as normally craftable if required materials have no legitimate source in the current playable world, unless intentionally marked future/unavailable.

---

## 28. Inn

Current inn rules include:

- paid full recovery;
- once-per-Pythonia-day rest cooldown;
- six in-game hours consumed by normal inn rest;
- level-scaled price according to the terminal rules.

The inn is also relevant to the Black Market informant system.

---

## 29. Guild Storage

Guild Storage capacity:

**200 slots**

It supports:

- stacks;
- exact equipment instances;
- transfer to/from player inventory.

Expedition presets may pull missing supplies from Guild Storage through the expedition-preparation service.

No system may create missing items when a preset requests more than storage contains.

---

## 30. Backpack upgrades

The migrated economy includes:

**3 backpack upgrades**

Carry-capacity values and prices should remain in their current authoritative service/data definitions.

---

# WORLD AND EXPLORATION

## 31. Canonical current region order

The current Godot region catalog defines five regions in this order:

1. **Zmierzchowe Równiny** — `twilight_plains`
2. **Czarny Bór** — `black_forest`
3. **Mokradła Głuchej Wody** — `silentwater_marshes`
4. **Popielne Pogranicze** — `ashen_borderlands`
5. **Lodowe Wybrzeże** — `ice_coast`

These display names and IDs are the current migrated source of truth.

Older art/conversation labels such as **Zatopiony Trakt** should be treated as historical/concept labels unless explicitly promoted again.

---

## 32. Region level bands

Current region catalog:

| Region | Recommended level |
|---|---:|
| Zmierzchowe Równiny | 0–2 |
| Czarny Bór | 2–4 |
| Mokradła Głuchej Wody | 5–8 |
| Popielne Pogranicze | 10–14 |
| Lodowe Wybrzeże | 14–18 |

Recommended level is:

**advisory, not a hard access lock**

The game may warn the player about danger, but the player can enter a harder known region.

---

## 33. Regional encounter structure

Each region has:

- day enemy weights;
- night enemy weights;
- quiet/no-combat events;
- region-specific encounter definitions;
- region-specific loot and crafting sources.

There are currently:

**36 unique open-world enemy encounters**

across the five migrated regions.

Do not flatten all regions into one shared enemy table.

### 33.1 Zmierzchowe Równiny

Current day roster includes:

- Dziki Pies
- Slime
- Wilk
- Spaczony Dzik
- Bandyta
- Przeklęty Strach na Wróble

Night adds/weights content such as:

- Duch Równin
- Nocny Strażnik
- Myśliwy
- Strażnik Natury

The starting-region expedition preserves the original:

**80% encounter chance**

where the current service/test suite applies it.

### 33.2 Czarny Bór

Current identities include:

- Jadowity Pająk
- Kultysta Boru
- Zgniły Rycerz
- Spaczony Niedźwiedź
- Czarny Jeleń / current catalog identity
- Zjawa Szubienicy
- Leśny Egzekutor

Use current display names from enemy catalogs for final UI.

### 33.3 Mokradła Głuchej Wody

Current region identities include:

- Bagienny Pełzacz
- Topielec / drowned enemy line
- Wiedźma Bagienna
- Kościany Krokodyl
- Zatopiony Rycerz
- Wędrowiec Mgły
- Matka Głuchej Wody as high-threat content

This region hosts:

**Krypta Zatopionego Zakonu**

### 33.4 Popielne Pogranicze

Established desert identities include:

- Pustynny Wędrowiec
- Pustynna Harpia
- Czerwona Salamandra
- Piaskowy Golem
- Kościopal
- Pożeracz Palenisk

The region is associated with:

**Azhar**

Current exact boss display title should come from the boss catalog/quest data.

### 33.5 Lodowe Wybrzeże

Current identities include:

- Zamarznięty Rozbitek
- Lodowy Niedźwiedź
- Śnieżny Gryf
- Lodowy Krab
- Syrena Czarnego Morza
- Widmo Kapitana Statku

The region is associated with:

**Lewiatan Północy**

and hosts:

**Wrak Czarnej Floty**

---

## 34. Day and night

Regions have separate day and night encounter weighting.

Night should affect:

- encounter composition;
- atmosphere;
- visual state;
- danger where authored.

Do not treat day/night as only a cosmetic shader swap if domain rules depend on it.

---

## 35. World clock

The project uses a Pythonia world clock.

An earlier established pacing rule is:

**1 real minute ≈ 1 Pythonia hour**

Do not change this globally during unrelated work.

Some systems advance time directly in larger chunks, including:

- expeditions;
- inn rest;
- field-camp rest;
- weather cycles.

Exact clock ownership belongs to the world-time service.

---

## 36. Normal expeditions

Normal regional expeditions:

- select a known region;
- respect region encounter tables;
- use day/night state;
- use weather state;
- consume the current expedition duration;
- validate overload;
- warn rather than hard-lock for recommended level;
- update quest/contract progress;
- award normal combat/loot rewards.

Current ordinary expedition duration:

**1 Pythonia hour**

where defined by the migrated service.

---

# WEATHER AND CAMP

## 37. Weather states

Current migrated weather system includes:

- Sunny
- Storm
- Frost
- Wind
- Aurora

Weather advances in:

**6-hour world-clock cycles**

Weather can modify:

- regular enemies;
- miniboss behavior/stats where authored;
- rewards;
- encounter context.

### 37.1 Aurora

Under Aurora:

- EXP reward increases by **50%**
- Gold reward increases by **50%**
- loot chance increases by **50%**

Use current service code for exact probability composition and rounding.

---

## 38. Field camp

Field camp provides:

- partial HP recovery;
- partial Mana recovery;
- **2 hours** of world time consumed;
- a rest availability/cooldown tied to expedition flow.

The free field-camp rest becomes available again only after the relevant new expedition cycle according to the current service.

Do not turn field camp into unlimited free healing.

---

# QUESTS AND GUILD

## 39. Story quests

Current migrated Act I contains:

**9 ordered story quests**

Story progression uses:

- levels;
- prerequisites;
- objectives;
- rewards;
- completion text;
- Guild reputation.

Objectives are processed by generic quest/domain services rather than hard-coded UI buttons.

Quest types include at least:

- kill;
- collection;
- boss/dungeon/world dependency where authored.

---

## 40. Active quest guardrail

Historical terminal rule:

**maximum 3 active quests**

Where the current quest implementation preserves this rule, it should remain enforced.

Turn-in should avoid:

- duplicate rewards;
- completed quest remaining incorrectly active;
- reaccepting non-repeatable quests endlessly.

---

## 41. Guild ranks

Canonical Guild thresholds:

| Rank | Name | Reputation |
|---|---|---:|
| F | Nowicjusz | 0 |
| E | Adept | 100 |
| D | Poszukiwacz | 300 |
| C | Łowca | 700 |
| B | Weteran | 1400 |
| A | Mistrz | 2600 |
| S | Legenda | 4500 |

Ranks should be **derived from reputation**, not separately editable without validation.

---

## 42. Guild reputation sources

Established reputation rewards include:

- story quest: **+50** where authored;
- Daily completion: **+15**;
- Weekly completion: **+75**;
- one-time world milestones.

Known one-time milestone values include:

- Azhar: +100
- Lewiatan Północy: +150
- Krypta Zatopionego Zakonu: +150
- Wrak Czarnej Floty: +250

A one-time world milestone must never award reputation repeatedly.

---

## 43. Daily and Weekly contracts

Current Guild contract structure:

- exactly **3 Daily** contracts;
- exactly **1 Weekly** multi-objective contract.

Generation must use accessible content rather than impossible objectives.

Daily rotation:

- based on local calendar date.

Weekly rotation:

- based on ISO week beginning Monday.

Generated definitions are persisted so:

- restart does not reroll them;
- save reload does not reroll them;
- clock rollback does not produce exploitable rerolls.

Rank gates:

- Daily contracts: rank **E**
- Weekly contract: rank **D**

---

## 44. Guild rumors and Adventure Log

Current Guild content includes:

- **32 authored rumors**
- filtering by rank;
- filtering by Black Market state;
- filtering by permanent milestones.

Locked information should not leak through rumors before its conditions are met.

Adventure Log:

- records timestamped major events;
- keeps newest **50** entries;
- current UI can show latest **30**.

---

# BLACK MARKET

## 45. Informant unlock

The Black Market is not a normal always-visible shop.

Current unlock conditions:

- Guild rank **C or higher**
- completion of a qualifying dungeon:
  - Krypta Zatopionego Zakonu, or
  - Wrak Czarnej Floty

When eligible, the inn performs:

**one informant roll per new Pythonia day**

Chance:

**20%**

Pity rule:

- after 4 failed eligible days;
- the 5th attempt is guaranteed.

Re-entering the inn on the same day must not reroll the encounter.

The informant:

- does not trade;
- permanently unlocks **Czarny Rynek** after the authored interaction.

---

## 46. Black Market rotation

Current rule after the v0.23.1 update:

**rotation every 1 real calendar day**

Each rotation contains:

**4 offers**

Current behavior includes:

- deterministic/persisted rotation;
- restart does not change stock;
- single-stock purchase behavior;
- rare materials/consumables;
- Mastery Books;
- rarer Path Books in current migrated content.

Historical/current authored probability:

**55% chance that a rotation includes one Mastery Book**

Use the current Black Market service as final authority if the implementation has evolved.

---

## 47. Bargaining

Each concrete offer / eligible sold-book title receives:

**one bargaining attempt per rotation**

Base success chance:

**30%**

Purchase:

- success: price decreases by **10–15%**
- failure: price increases by **5–10%**

Sale:

- success: offered price increases by **10–15%**
- failure: offered price decreases by **5–10%**

Current migrated implementation uses:

**50-Gold rounding**

The result must be persisted immediately so restarting cannot create another attempt.

---

# COMPANIONS AND PARTY

## 48. Party ownership model

Companion-specific state belongs to:

`CompanionState`

Roster/party state belongs to:

`PartyState`

Do not spread companion state through unrelated UI or GameSession fields when domain models already own it.

---

## 49. Companion roster limits

Canonical terminal/migrated limits:

- maximum **4 recruited companions**
- maximum **3 active companions**

The hero is separate from the companion count.

---

## 50. Companion templates and recruitment

Current content contains:

**12 authored companion templates**

Templates define authored identity such as:

- allowed class/Path;
- origin;
- voice/personality direction;
- attitude;
- minimum Guild rank.

Recruitment candidate rotation:

- **2 persisted candidates per Pythonia day**
- rank-gated;
- candidate identity/build remains stable during that day;
- restarting/re-entering does not reroll the candidate offer;
- the recruitment roll/attempt remains persistent where defined.

---

## 51. Companion progression

Companion builds follow the same broad RPG structure as the player where applicable.

Current migrated build generation includes:

- `4 × level` attribute-point budget;
- talent allocation;
- weapon/second-hand progression;
- equipment slot pools;
- upgrades;
- affixes;
- rare Rift uniques.

Companion level progression uses the same level curve where the current service defines it.

Do not simply copy the player's exact UI or manual decision model onto AI companions if companion generation/service rules are intentionally different.

---

## 52. Relationships and personal stories

Authored companion content includes:

- recruitment conversations;
- response choices;
- idle/camp lines;
- messages;
- pair banter;
- personal-story arcs;
- memory tags;
- unread state;
- seen-banter state.

Relationship changes should occur through companion domain services.

Personal-story stage gates may depend on:

- relationship;
- progression;
- Rift-related conditions;
- authored requirements.

Do not award personal-story progress from UI-only state.

---

## 53. Companion tactics

There are four saved tactics:

- **Agresywna**
- **Zrównoważona**
- **Ostrożna**
- **Obronna**

Tactic selection is durable companion configuration.

`CompanionTacticService`/equivalent domain logic owns what the tactic means.

The UI:

- selects the tactic;
- shows its description;

but does not implement combat turns.

---

# EXPEDITION PREPARATION

## 54. System identity

`Przygotowanie do wyprawy` is a separate strategic subsystem.

It is not:

- merely the world map;
- merely the party screen;
- merely the AI-tactics screen.

It assembles and validates expedition readiness.

---

## 55. Preparation information

The preparation flow should expose at least:

- selected destination;
- hero HP;
- hero Mana;
- current carry weight;
- active party;
- companion HP;
- companion Mana;
- selected companion tactic;
- healing supplies;
- relevant provisions/consumables;
- quick equipment access;
- Guild Storage supply pull;
- warnings;
- presets.

---

## 56. Expedition presets

There are four canonical preset categories:

- `SOLO`
- `BOSS`
- `DUNGEON`
- `SZCZELINA`

A preset stores:

- party composition;
- target supply quantities;
- relevant configured preparation choices.

A preset must not store arbitrary transient UI-widget state.

---

## 57. Applying a preset

Preset application must be calculated safely before mutation.

Rules:

- pull only missing quantities from Guild Storage;
- report shortages;
- never create items;
- never duplicate items;
- if the complete transfer would exceed carry weight, do not partially mutate party/supplies as though successful.

---

## 58. Pre-expedition consumables

Before departure the player may use eligible:

- potions;
- provisions.

Shared consumable rule:

**an item is not consumed if it would restore neither HP nor Mana**

Do not consume a healing item on a full-resource target simply because the UI button was pressed.

---

## 59. Expedition warnings vs blockers

### Hard blocker
- overload / invalid carry state

### Explicit warnings that may be consciously confirmed
- low HP;
- lack of healing;
- heavily injured companions;
- other authored preparation dangers.

Warnings should not become silent auto-fixes.

The player should understand the risk and confirm it.

---

# PARTY COMBAT, INJURY AND DEATH

## 60. Separate combat engines

Architecture and design intentionally distinguish:

1. normal 1v1 combat;
2. party combat;
3. SOLO dungeon combat;
4. Rift expedition party combat.

Do not merge these systems merely to reduce file count if doing so erases their different lifecycle rules.

---

## 61. Downed state

A party combatant can be **Powalony** during party combat.

Temporary downed timers/state belong to the current battle, not the permanent companion record.

A companion at zero HP stops acting according to party-combat rules.

Exact downed timers, rescue rules and escalation thresholds must come from the party-combat code/tests.

---

## 62. Heavy injury

Persistent post-combat serious injury should use fantasy/MMORPG wording.

Preferred player-facing state:

**Ciężko Ranny**

Preferred recovery text:

**Powrót do sił: X dni Pythonii**

Avoid clinical wording such as:

`rekonwalescencja`

unless used in internal technical prose, not player-facing fantasy UI.

---

## 63. Permanent companion death

Permanent death is allowed, but:

**never as a hidden random death proc**

A permanent death must follow:

- a clearly signalled lethal state/threat;
- an understandable failure, decision or unresolved danger;
- explicit domain rules;
- clear reporting to the player.

No arbitrary:

```text
5% chance companion permanently dies after battle
```

style mechanic is allowed.

The fallen-companion record / memorial state must remain consistent with save/load.

---

# DUNGEONS

## 64. Dungeon identity

Dungeons are separate structured runs, not ordinary region encounters with a different background.

Current migrated dungeons are:

1. **Krypta Zatopionego Zakonu**
2. **Wrak Czarnej Floty**

Both currently use:

**SOLO combat**

through the normal turn-based combat engine rather than party combat.

HP and Mana do not simply refill between every dungeon encounter.

---

## 65. Krypta Zatopionego Zakonu

Region:

**Mokradła Głuchej Wody**

Recommended level:

**7–10**

Entry item:

**ancient_order_key / ancient order key**

Current authored source text:

**Matka Głuchej Wody, crafting lub zlecenie Gildii.**

Important design principle:

The key is acquired **outside the dungeon**, reinforcing world integration.

Structure includes:

- multiple authored rooms;
- branching/choice flow;
- a one-use recovery opportunity;
- mandatory elite encounter;
- final boss.

Mandatory elite:

**Strażnik Krypty / crypt_warden**

Boss:

**Wielki Mistrz Zatopionego Zakonu / order_grandmaster**

Use current enemy display catalog as final naming authority.

---

## 66. Wrak Czarnej Floty

Region:

**Lodowe Wybrzeże**

Recommended level:

**16–20**

Entry item:

**black_fleet_medallion**

Authored source:

**Widmo Kapitana Statku lub crafting.**

Structure includes:

- frozen ship graveyard;
- multiple encounters/rooms;
- one-use recovery opportunity;
- mandatory elite;
- final flagship encounter.

Mandatory elite:

**Pierwszy Oficer Czarnej Floty**

Boss:

**Admirał Varek**

---

## 67. Planned dungeon content

**Lodowa Jaskinia** exists as accepted region-design direction from earlier planning, but the current migrated canonical dungeon catalog contains Krypta Zatopionego Zakonu and Wrak Czarnej Floty.

Therefore an agent must not silently replace Wrak Czarnej Floty with Lodowa Jaskinia or claim Lodowa Jaskinia is already implemented.

Treat it as **PLANNED** until explicitly integrated.

---

# RIFTS / SZCZELINY

## 68. Rift identity

Szczeliny are a separate higher-complexity expedition system.

They combine:

- party composition;
- rank gates;
- procedural/deterministic structure;
- anomalies;
- events;
- elite encounters;
- camps;
- minibosses;
- final Rift Lord;
- party combat;
- persistent lifecycle.

Do not implement them as ordinary one-room dungeons.

---

## 69. Rift structure

Current migrated Rift content preserves:

- ranks **F–S**;
- **12–24 segments**;
- requirement for **2 or 3 companions** depending on Rift;
- **5 themes**;
- **6 anomalies**;
- Rift bosses;
- deterministic structure from persisted Rift state.

Segment structure can include:

- regular encounters;
- elites;
- authored events;
- fixed camp positions;
- a middle miniboss where compatible with camp index;
- a final Władca/Lord in the last segment.

Rift generation must remain stable across save/load and should not reroll exploitable outcomes on restart.

---

## 70. Rift lifecycle

Rift state can include:

- availability/schedule;
- expiry;
- active expedition;
- bound party composition;
- current progress;
- completion/closure;
- rewards.

An active expedition must be protected from lifecycle changes that would invalidate the run.

Completing/closing a Rift should happen exactly once.

---

# ELITES, MINIBOSSES AND BOSSES

## 71. Open-world elite rule

Historical/canonical design for regular-map elites:

- base elite chance;
- **+2 percentage points after each non-elite**;
- counters tracked per enemy and per map/region context;
- reset on elite appearance.

Do not replace this with a simple flat RNG roll unless the current implementation has explicitly superseded the rule.

Dungeon mandatory elites and Rift elites are authored structures and are not the same as ordinary open-world elite rolling.

---

## 72. Enemy rank separation

Treat these as distinct content tiers:

- ordinary enemy;
- elite;
- miniboss;
- boss;
- dungeon mandatory elite;
- dungeon boss;
- Rift elite;
- Rift miniboss;
- Rift Lord.

Their reward tables, quest hooks and generation rules should not be conflated.

---

# LOOT AND REWARDS

## 73. Reward pillars

Combat/exploration can reward:

- EXP;
- Gold;
- stackable materials;
- consumables;
- equipment;
- special keys/entry items;
- books;
- quest items;
- Guild progress;
- unique/special gear.

Rewards should reinforce the source content.

Example:
a dungeon key should have a believable source in bosses/crafting/Guild content, not appear arbitrarily in the dungeon it unlocks.

---

## 74. Regional loot

The migrated world includes:

**72 additional regional materials, consumables, keys and equipment definitions**

Regional items can carry:

- Item Power;
- level requirements;
- base stats;
- elemental resistance;
- equipment metadata.

Loot should preserve regional identity and feed local crafting progression.

---

## 75. Mastery Book drops

Established Mastery Book boss-drop behavior:

The boss does not predetermine the book type.

First:

- roll whether any Mastery Book drops.

Then:

- choose one of the four titles from the shared pool.

Historical/current authored chances:

- Azhar / Lewiatan Północy: **1%**
- Strażnik Krypty / Pierwszy Oficer Czarnej Floty: **2%**
- Wielki Mistrz Zatopionego Zakonu / Admirał Varek: **4%**

Ordinary monsters and overworld minibosses do not drop Mastery Books.

Weather does not increase these book-drop chances unless explicitly redesigned.

---

# SAVE AND PERSISTENCE

## 76. Save philosophy

Persistent mechanics must survive save/load without allowing reroll exploits or invalid states.

The Godot migration uses its own validated save schema and migration path.

Do not directly overwrite legacy terminal saves.

The terminal v15 format remains separate until a dedicated safe import/mapping process confirms that supported values will not be silently lost.

---

## 77. Save validation

Save loading should validate important invariants, including examples such as:

- valid class timing;
- Pierrot-only Szczęście;
- equipment class/level requirements;
- talent budgets;
- talent prerequisites;
- passive/mastery rules;
- specialization rules;
- known region IDs;
- Guild state;
- contract state;
- Black Market anti-reroll state;
- companion/party state;
- Rift state.

Invalid data should not be silently accepted just to make loading succeed.

---

## 78. Anti-reroll persistence

The following systems intentionally persist generated outcomes/state to prevent restart abuse:

- Daily/Weekly contracts;
- Black Market rotation;
- bargaining results;
- companion candidates;
- recruitment roll where defined;
- Rift generation/lifecycle;
- relevant world-state rolls.

An agent must not introduce a save/load loophole that refreshes these systems unexpectedly.

---

# REGION 6 AND FUTURE CONTENT

## 79. Region 6 direction

The current long-term content direction is that:

**Region 6 should complete the main regional structure before the project shifts heavily toward release-quality audiovisual completion.**

Region 6 is therefore a major future design milestone, not permission to endlessly add regions.

Before adding Region 6:

- current five-region systems should remain stable;
- item/art coverage should be tracked;
- existing classes need coherent visuals;
- animation/audio pipeline should be ready for scaling.

Exact Region 6 identity, enemy list, boss and dungeon should be treated as TBD until explicitly approved.

---

# BALANCE GUARDRAILS

## 80. Economy

Avoid a state where:

- dungeon rewards create huge Gold reserves;
- ordinary shops have nothing meaningful to buy;
- upgrading becomes trivial;
- crafting costs become irrelevant.

Historical playtesting produced situations around ~15,000 Gold after dungeon progression, which triggered a desire for rebalancing and meaningful expensive sinks.

Balance changes should look at:

- income per expedition;
- upgrade costs;
- repair/service costs if present;
- crafting costs;
- Black Market prices;
- high-end equipment sinks.

Do not balance a single shop in isolation.

---

## 81. Difficulty

Recommended levels are guidance rather than hard locks.

Difficulty should come from:

- enemy stats;
- mechanics;
- regional encounter composition;
- equipment preparedness;
- resource attrition;
- dungeon structure;
- companion decisions;
- weather;
- Rift modifiers.

Avoid replacing difficulty with arbitrary access locks unless explicitly intended.

---

## 82. RNG policy

RNG should serve variety and tension, not erase player agency.

Good uses:

- encounter selection;
- loot;
- affix generation;
- weather;
- controlled class mechanics;
- persisted market/candidate generation.

Bad use:

- hidden permanent companion death;
- restart-reroll exploits;
- impossible-to-understand failure;
- changing authored progression state randomly.

Godot should preserve the rules and deterministic behavior expected by tests; it does not need to reproduce Python `random.Random` bit-for-bit unless a specific test requires it.

---

# UI-CONNECTED DESIGN RULES

## 83. UI must not own gameplay rules

Examples of logic that must remain domain-owned:

- damage;
- economy transactions;
- crafting;
- quest progress;
- Guild rank;
- Black Market rotation;
- bargaining;
- party composition validation;
- companion AI decisions;
- dungeon state;
- Rift lifecycle;
- save validation.

UI sends intents and renders results.

---

## 84. Visual presentation priorities

Prefer:

- visual world map;
- spatial equipment;
- class cards/presentation;
- visual shops;
- modular city navigation;
- readable combat feedback;
- visible preparation warnings.

Avoid falling back to:

- giant text lists;
- debug-style labels;
- terminal-like numbered menus;
- oversized panels with little useful content.

---

# AI CHANGE PROCEDURE FOR GAMEPLAY

## 85. Before changing a mechanic

The developer agent must answer internally:

1. Is the mechanic CANONICAL, PLANNED or HISTORICAL?
2. Which service/model owns it?
3. Which tests protect it?
4. Does it affect save data?
5. Does it affect balance/economy?
6. Does it affect UI only or actual domain rules?
7. Does it interact with another system?

If uncertain, inspect the repository before editing.

---

## 86. When exact numbers are missing here

Do not guess.

Inspect relevant sources such as:

- `godot/core/...`
- `godot/tests/...`
- `docs/SYSTEM_MIGRATION_STAGES_v0.25.0.md`
- `docs/GODOT_MIGRATION_v0.25.0.md`
- `docs/GUILD_BLACK_MARKET_v0.22.md`
- current typed catalogs/resources
- terminal implementation/tests when parity is still required

This file intentionally does not duplicate every multiplier or loot-table weight because duplicated numbers become stale.

---

## 87. Gameplay-review checklist

A gameplay change should be rejected or revised if it:

- breaks class identity;
- bypasses progression requirements;
- creates restart rerolls;
- duplicates authoritative domain logic in UI;
- invalidates existing saves without migration;
- makes region level recommendations hard locks unintentionally;
- breaks item ownership/atomic transactions;
- creates free resources;
- allows duplicate quest/reputation rewards;
- removes expedition-preparation decisions;
- makes permanent companion death random and hidden;
- merges distinct combat lifecycles incorrectly;
- silently renames canonical content;
- breaks current regression tests without a justified design change.

---

## 88. Definition of gameplay-complete

A gameplay feature is not complete merely because it compiles.

Completion requires:

- rules implemented in the correct domain layer;
- relevant automated tests passing;
- invalid-state handling;
- save/load consideration if persistent;
- no obvious resource duplication/loss;
- UI receives authoritative results rather than reproducing logic;
- interaction with existing systems checked;
- reviewer confirms consistency with Project Bible and Game Design;
- visual/manual smoke test when the mechanic has a player-facing flow.

---

## 89. Current canonical reference map

When working in the current Godot build, these concepts should be located through the existing domain structure rather than recreated:

```text
godot/core/combat/        combat, damage, class encounter mechanics
godot/core/companions/    companions, party, recruitment, relations, builds
godot/core/dungeons/      dungeon definitions and dungeon lifecycle
godot/core/economy/       shops, carry weight, storage, Black Market
godot/core/items/         item catalogs, equipment and consumables
godot/core/player/        player state/stat rules
godot/core/progression/   talents, passives, specializations
godot/core/quests/        story quests and contracts
godot/core/rifts/         Rift lifecycle and segments
godot/core/save/          codecs, schemas, validation and migration
godot/core/skills/        class skills and progression hooks
godot/core/world/         regions, expeditions, weather and world rules
```

Before creating a new service, search for an existing owner.

---

## 90. Final game-design principle

Every new system should answer at least one of these questions:

- Does it create a meaningful player decision?
- Does it strengthen a class identity?
- Does it make preparation more interesting?
- Does it make a region more distinct?
- Does it improve progression?
- Does it connect existing systems more coherently?
- Does it make presentation clearer without reducing depth?

If the answer to all of them is **no**, the feature probably does not need to exist.

**Echoes of Pythonia should become more coherent and more satisfying, not merely more complicated.**
