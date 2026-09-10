# Echoes of Pythonia — Project Bible

> Status: living source of truth for AI-assisted development  
> Project phase: Godot 4 migration / v0.25.x line  
> Terminal baseline: v0.24.7 was the final terminal-focused milestone before migration

---

## 1. Purpose

This file defines the stable design identity, major systems, terminology, and non-negotiable decisions of **Echoes of Pythonia**.

Every AI agent working on the project must read this document before making design, code, UI, content, balance, asset, animation, or architecture changes.

If an implementation idea conflicts with this document, the agent must not silently override the project direction. It must flag the conflict and propose an alternative.

More detailed rules may live in:

- `AI_CONTEXT/GAME_DESIGN.md`
- `AI_CONTEXT/TECHNICAL_RULES.md`
- `AI_CONTEXT/UI_RULES.md`
- `AI_CONTEXT/ART_DIRECTION.md`
- `AI_CONTEXT/AI_WORKFLOW.md`
- existing documentation under `docs/`
- the current asset manifest / tracker

---

## 2. Project identity

**Echoes of Pythonia** is a fantasy RPG evolving from a Python terminal prototype into a full Godot 4 game.

Core direction:

- readable, memorable fantasy instead of generic placeholder fantasy;
- strong RPG progression;
- equipment and upgrading inspired partly by MMORPG structure;
- region-based exploration;
- mechanically distinct classes and specializations;
- meaningful expedition preparation;
- companions, quests, guild systems, economy, dungeons and bosses;
- graphical UI instead of list-heavy terminal presentation;
- increasingly complete audiovisual presentation: item art, character art, animation, skills, voice and music.

The game should feel like one coherent commercial RPG, not a collection of disconnected mechanics.

---

## 3. Project phase and history

### 3.1 Terminal era

The terminal version evolved through many iterations and culminated in **v0.24.7**.

Important systems established there include:

- player stats and level progression;
- combat;
- maps and regions;
- day/night progression;
- inventory and shops;
- equipment and upgrades;
- quests;
- elites, bosses and dungeons;
- guild systems;
- Black Market concept;
- companions;
- expedition preparation;
- save system and save migration.

### 3.2 Godot migration

After v0.24.7 the project entered the Godot 4 migration / visual-production phase.

The Godot project is now the primary implementation target.

The objective is **not** to recreate the terminal UI visually. The systems and design choices should be preserved while presentation is rebuilt as a proper graphical RPG.

---

## 4. Core player statistics

Core attributes:

- **STR**
- **INT**
- **VIT**
- **DEX**
- **END**

The player receives **4 attribute points per level**.

The UI should allow assigning multiple points efficiently instead of forcing one-click-at-a-time allocation when avoidable.

Core combat resources/statistics include:

- HP
- ATK
- DEF
- Mana

Progression UI should clearly show current level, current EXP, and EXP required for the next level.

### Terminology rule

For Pierrot and related systems, always use the full Polish player-facing term:

**Szczęście**

Do not replace it with `LCK` in player-facing UI or descriptions.

---

## 5. Classes and specialization direction

Classes must feel mechanically different, not like cosmetic variations.

### Warrior / Heavy Knight

Heavy Knight is a defensive-offensive specialization.

Identity:

- meaningful damage scaling with DEF where designed;
- tank-oriented gameplay;
- counters;
- provoking enemies;
- durability can become an offensive resource, not only passive mitigation.

Representative concepts include **Prowokacja**, counterattacks, defensive scaling and tank control.

### Mage / Arcana

Arcana should feel mechanically distinct from ordinary single-action spellcasting.

Key identity: under its class mechanics it can enable **two abilities in one turn**.

### Hunter

Hunter is a distinct ranged class identity and has historically had a larger skill pool than some other classes.

Do not flatten Hunter into a generic bow user.

### Pierrot

Pierrot is a separate class identity associated strongly with fate / luck systems.

Use **Szczęście** in player-facing terminology.

### Accepted passive/specialization families

**Regeneracja**
- Żelazna Wola
- Drugi Oddech

**Szybkość ataku**
- Nawałnica Ciosów
- Zabójcze Tempo

**Obrażenia krytyczne**
- Precyzja
- Egzekucja

**Zwiększenie ataku**
- Furia
- Żądza Krwi

**Unik**
- Cień
- Przewaga Taktyczna

Passive progression should use limited points and meaningful specialization choices.

---

## 6. Combat principles

Combat feedback should be clear and readable.

Established presentation examples:

- `[ELITA]` before an elite enemy name;
- critical-hit messaging should clearly state that a target **otrzymuje X obrażeń krytycznych**.

Avoid debug-like player-facing messages.

Night-time encounters may be stronger than daytime encounters.

### Elite system

Elites belong on regular maps and should not appear in areas where existing dungeon rules exclude them.

Established pity-like progression:

- base elite chance;
- **+2% for each non-elite encounter**;
- tracking per monster and per map;
- counter resets when an elite appears;
- no design requirement to visibly cap the system at 100%.

Do not casually replace this with a flat random chance.

---

## 7. Equipment philosophy

Equipment is a major progression pillar.

The system uses MMORPG-style clarity of slots and upgrading, partly inspired by Metin2-like progression structure without copying its protected content.

### Equipment grouping

**Defensive**
- boots
- helmet
- armor
- gloves

**Mixed**
- belt

**Offensive**
- remaining offensive-focused equipment slots

Do not clutter player-facing item names with labels such as `[DEFENSYWNY]`, `[OFENSYWNY]`, `[MIESZANY]` when the slot/presentation already communicates the role.

### Rarity and bonuses

Higher rarity should generally support more and/or stronger bonuses.

Established examples of intended bonus magnitude include:

- flat HP bonuses roughly +500 to +2500;
- percentage damage bonuses roughly 3% to 20%.

Exact balance may evolve, but high-end gear should feel meaningfully stronger.

### Requirements and upgrading

Equipment may have required level and required materials/items.

When requirements are missing, readable feedback such as **[brak wymaganych przedmiotów]** is preferred.

Dungeon/boss-specific weapons may use **średnie obrażenia** when appropriate.

Equipment UX goals:

- easy review of currently equipped items;
- multi-level upgrading where practical;
- readable upgrade lists;
- quantity-based buy/sell operations where appropriate;
- inventory panels should not waste large horizontal areas when the grid itself is narrower.

---

## 8. Inventory, economy and shops

The economy should remain meaningful throughout progression.

Past testing showed that dungeon progression could produce around 15,000 gold too easily relative to useful spending options.

Therefore:

- avoid runaway gold inflation;
- preserve meaningful expensive sinks;
- expensive equipment and services should remain relevant;
- buying/selling should support practical quantity handling.

Shops should increasingly be visual interfaces instead of plain lists.

---

## 9. Black Market

The Black Market should not feel like a normal permanent city shop.

Established access concept:

- an informant / handler may occasionally appear in town or the tavern;
- after conditions are met, the NPC points the player toward the hidden market;
- the Black Market should feel secret and separate from normal commerce.

Do not automatically turn it into a normal always-visible shop building unless a later explicit design decision changes this.

Its UI should not default to a plain product list.

---

## 10. Guild

The guild is a progression and story pillar.

Known design state/direction includes:

- guild rank C at one stage of progression;
- daily reputation gain around +15 in the established iteration;
- more story quests are desired;
- discussed rhythm: roughly 2–3 meaningful guild/story quests per ~5 player levels.

Guild Storage is an important supporting system and connects to expedition preparation.

---

## 11. Quests

Established principles:

- maximum **3 active quests** at once;
- turn-in confirmation where appropriate;
- completed/turned-in quests must not remain incorrectly active;
- non-repeatable quests must not be accepted endlessly.

Daily/weekly direction:

- around 3 daily quests or a weekly structure;
- large quest pool to reduce repetition.

Quest systems must be robust against duplication, stale state and repeated rewards.

---

## 12. Dungeons

### First dungeon — Krypta

The first dungeon is **Krypta**.

It was previously cleared around level 12 during testing.

Important design decision: the required key should come from outside the dungeon loop, for example:

- boss reward;
- crafting;
- quest / mission.

This creates world integration and preparation before dungeon access.

### Region 5 dungeon

Region 5 includes **Lodowa Jaskinia**.

Dungeons should feel like progression milestones, not ordinary maps with a different background.

---

## 13. Companions

Companions can be injured and temporarily unavailable.

For a heavily wounded companion, do not use modern/clinical wording such as **rekonwalescencja**.

Preferred fantasy/MMORPG terminology:

**Ciężko Ranny**

and:

**Powrót do sił: X dni Pythonii**

or similar wound-healing wording.

### Permanent death

Permanent companion death is allowed as a dramatic mechanic, but:

- it must **never** be an arbitrary hidden RNG proc;
- the player must receive a clearly signalled mortal-risk situation;
- death must result from an understandable event, decision, failure or clearly communicated danger.

No hidden percentage roll should randomly erase a companion.

---

## 14. Expedition Preparation

v0.24.7 established **Przygotowanie do wyprawy** as a major strategic hub before the Godot migration.

Established scope:

- destination selection;
- hero HP and Mana;
- carry weight;
- active party;
- companion HP and Mana;
- companion AI tactics;
- healing supplies;
- quick equipment access;
- pulling items from Guild Storage;
- pre-expedition potions;
- tavern shortcut;
- expedition presets/loadouts;
- warnings before departure.

Leaving town should feel like a deliberate preparation decision.

Do not reduce this system to a single “Start Expedition” button.

---

## 15. Time and world state

An earlier time model used **1 real minute = 1 in-game hour**.

The game also uses day/night states.

Night can affect visuals, atmosphere, encounter strength and potentially spawn composition.

If time scaling changes later, it should be an explicit design decision rather than accidental drift during refactoring.

---

## 16. Regions and naming philosophy

Avoid generic placeholder fantasy naming.

Names should be readable, memorable, coherent with the region, not overcomplicated, and distinct enough to build a recognizable world.

### Forest-era content

Established enemies/concepts include:

- Dziki Pies
- Slime
- Wilk
- Spaczony Dzik
- Bandyta
- Duch Równin
- Nocny Strażnik
- Myśliwy
- Jadowity Pająk
- Kultysta Boru
- Zgniły Rycerz
- Spaczony Niedźwiedź
- Czarny Niedźwiedź
- Zjawa
- Leśny Egzekutor

### Region 3 — Zatopiony Trakt

Background identity moved away from repeatedly showing a generic road into the distance.

Preferred visual concept: **plac dzwonnicy**.

Known enemies include **Topielec** and **Wiedźma**, plus other region-specific content already present in project data/assets.

### Region 4 — Desert

Ordinary enemies:

- Piaskowy Golem
- Pustynna Harpia
- Pustynny Wędrowiec
- Kościopal
- Czerwona Salamandra

Miniboss: **Pożeracz Palenisk**  
Boss: **Azhar, Władca Pustkowi**

### Region 5 — Lodowe Wybrzeże

Target level band: **14–18**.

Ordinary enemies:

- Zamarznięty Rozbitek
- Lodowy Niedźwiedź
- Śnieżny Gryf
- Lodowy Krab
- Syrena Czarnego Morza

**Syrena Czarnego Morza** should be the strongest ordinary enemy of the region.

Miniboss: **Widmo Kapitana Statku**  
Boss: **Lodowy Lewiatan**  
Dungeon: **Lodowa Jaskinia**

### Region count direction

Current long-term direction discussed for the main regional structure is to finish around **Region 6**, then place heavier focus on complete assets, animation, audio and release-quality production.

---

## 17. World map and city presentation

### World map

Desired direction:

- visible lands/regions on a map;
- spatial selection instead of a list;
- hover highlighting;
- modular structure so regions can be added or rearranged cleanly.

### City

The city should feel like a real city rather than a small walled settlement.

Visual direction:

- larger footprint;
- large central square;
- prominent town hall;
- avoid excessive visual clutter;
- NPC/service buildings should be distinguishable from generic houses;
- avoid black unused margins where possible;
- day and night versions should match structurally as closely as practical.

---

## 18. UI philosophy

The Godot version should not preserve terminal-era list presentation when a graphical solution is more appropriate.

General rules:

- prefer visual layouts over large plain lists;
- avoid unnecessary empty margins;
- do not make panels much wider than their useful content;
- important choices should feel deliberate and visually distinct;
- class selection should feel like choosing a hero archetype, not a list item;
- shops and Black Market should be visual;
- world regions should be selected from a map;
- equipment should be readable, spatial and compact;
- UI should support future art, animation and controller/mouse interaction;
- systems should be modular enough to evolve without total rewrites for each region/class.

---

## 19. Global character-art rules

These rules are especially important for standalone combat characters/enemies intended for future rigging.

### Framing

- full figure;
- head to toe visible;
- isolated character;
- transparent/no background when intended as a standalone combat asset;
- one character per asset.

### Orientation

The hero/Pierrot is positioned on the **left**.

Enemies are positioned on the **right** and face **left**, toward the hero.

Preferred body angle:

- side view or 3/4 view toward the left;
- face/eyes toward the hero.

### Pose

Preferred: **combat idle**.

Limbs should remain readable and separable enough for future 2D rigging.

### Style

Maintain coherence with the accepted Pierrot reference and established game art.

Avoid hyper-realism, random style changes between regions, and excessive detail that harms sprite readability/rigging.

---

## 20. Asset workflow

External asset-library concept: `Echoes_of_Pythonia_Assets`.

Important status rule:

- `WORK` = draft / work in progress
- `FINAL` = approved asset

Do not treat drafts as production-approved assets.

Relevant documentation should be updated as assets are approved, including art direction, asset tracking and the current Godot asset manifest where applicable.

Approved enemy art should track filename, destination folder, status and relevant art-direction notes.

---

## 21. Animation and presentation direction

Characters currently originate primarily from image-based assets, but long-term direction includes richer animation.

Desired capabilities include:

- breathing / idle;
- attack;
- reactions;
- skill animation;
- future 2D rigging where appropriate;
- potentially 3D models for selected uses;
- high-impact anime-style/cinematic sequences for major moments, with presentation ambition comparable to games such as Epic Seven without copying protected content.

Do not force the entire project into 3D merely because Godot supports it. Choose 2D, rigged 2D, 3D or hybrid presentation according to the feature.

---

## 22. Audio direction

Long-term commercial-quality target includes:

- soundtrack;
- region music;
- battle music;
- skill audio;
- UI audio;
- character voice lines / voice tracks where appropriate;
- cinematic audio for major sequences.

Audio should eventually be treated as a full production pillar.

---

## 23. Save compatibility

The project already has a save system and prior save-migration work.

Whenever persistent data structures change:

- consider backwards compatibility;
- avoid silently invalidating saves;
- add migration/default handling where practical;
- test loading older saves when relevant.

An AI refactor must not assume that renaming a serialized field is harmless.

---

## 24. Engineering philosophy

The project should maintain a professional, long-term structure.

Prefer:

- clear separation of logic and UI;
- reusable services/components;
- data-driven content where appropriate;
- small focused scripts instead of monoliths;
- tests for important gameplay systems;
- modular region/content definitions;
- readable naming;
- minimal duplication.

Do not perform broad architectural rewrites unless they solve a clear problem and preserve behavior.

The project already contains extensive Godot tests and validation scripts. Agents should use them.

---

## 25. Testing expectations

Before an AI agent marks work complete, it should run relevant available checks.

Depending on the task this can include:

- project configuration tests;
- gameplay service tests;
- combat tests;
- quest/guild tests;
- UI/content tests;
- asset validation;
- world/region tests;
- class-specific tests;
- skill-card tests;
- item-asset checks;
- existing PowerShell validation scripts.

Passing automated tests alone does not prove UI/UX quality.

Visual changes should also be reviewed visually when possible.

---

## 26. Non-negotiable AI rules

AI agents must not silently:

1. rename established classes, regions, bosses or systems;
2. replace `Szczęście` with `LCK` in player-facing content;
3. introduce RNG-based permanent companion death;
4. turn the Black Market into a generic permanent shop without explicit approval;
5. remove expedition-preparation depth merely to simplify code;
6. flatten class identities into similar damage kits;
7. convert map/city/shop/class-selection interfaces back into list-heavy presentation;
8. invalidate save compatibility without a migration plan;
9. rewrite large working systems purely for stylistic preference;
10. work directly on protected snapshot branches;
11. commit generated caches, secrets, local runtimes or temporary work files that belong in `.gitignore`;
12. claim a feature is complete without testing the relevant path.

---

## 27. Source-of-truth priority

When sources conflict, use this order:

1. explicit latest user decision;
2. `AI_CONTEXT/PROJECT_BIBLE.md`;
3. specialized files inside `AI_CONTEXT/`;
4. current approved docs under `docs/`;
5. current implementation and tests;
6. older historical notes.

If implementation and documentation disagree, do not guess which is correct. Flag the discrepancy.

---

## 28. Definition of a good AI change

A good change should:

- preserve the identity of Echoes of Pythonia;
- solve the assigned task without unnecessary collateral changes;
- fit existing architecture;
- improve rather than flatten RPG depth;
- remain readable and maintainable;
- pass relevant automated checks;
- produce a visually coherent result when UI/art is involved;
- keep future expansion in mind;
- be easy for another reviewer to understand from the diff.

---

## 29. Current AI-team working model

The intended workflow uses at least two AI roles.

### Developer

Responsible for:

- analysis;
- implementation;
- tests;
- local validation;
- concise change report.

### Reviewer / Designer

Responsible for independently checking:

- correctness;
- regressions;
- architecture;
- game-design consistency;
- UI/UX;
- balance risks;
- compliance with this Project Bible.

The reviewer must not approve a change merely because tests pass.

Detailed handoff/iteration rules belong in `AI_CONTEXT/AI_WORKFLOW.md`.

---

## 30. Final principle

**Echoes of Pythonia should become deeper, clearer and more polished with each iteration — not merely larger.**

AI exists to accelerate implementation and review, but it must preserve the project's intentional design decisions and the player's control over major creative direction.
