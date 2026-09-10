# Echoes of Pythonia — UI Rules

> Role: visual interface and UX contract for AI-assisted development  
> Project: Echoes of Pythonia  
> Godot line: v0.25.x  
> Reference resolution: 1920×1080  
> Functional minimum: 1280×720  
> Protected baseline: `snapshot/pre-ai-team-2026-09-10`

---

## 1. Purpose

This document defines **how Echoes of Pythonia should look, behave and communicate through its graphical interface**.

It is written for:

- the Developer agent implementing screens;
- the Reviewer agent judging visual/UX quality;
- future automated screenshot review;
- future UI refactors;
- new regions, classes, shops and systems.

This file does not own gameplay formulas.

Gameplay rules belong primarily to:

- `AI_CONTEXT/PROJECT_BIBLE.md`
- `AI_CONTEXT/GAME_DESIGN.md`

Engineering rules belong primarily to:

- `AI_CONTEXT/TECHNICAL_RULES.md`

Art-production rules belong primarily to:

- `AI_CONTEXT/ART_DIRECTION.md`

If a UI concept would require changing gameplay behavior, the Developer must treat that as a separate gameplay change rather than hiding it inside presentation work.

---

# PART I — UI VISION

## 2. Core UI direction

The Godot version must feel like a **real graphical fantasy RPG**, not a terminal application placed inside decorative panels.

The interface should become:

- more visual;
- more spatial;
- more atmospheric;
- easier to scan;
- more game-like;
- less list-heavy;
- more suitable for art and animation;
- modular enough for continued expansion.

The terminal version is a rules reference, not a visual template.

---

## 3. Primary visual identity

The current interface already establishes a fantasy identity built around:

- deep blue / blue-black surfaces;
- gold accents;
- pale readable text;
- subtle borders;
- layered panels;
- restrained glow;
- dark atmospheric backgrounds.

This **gold + dark blue fantasy identity** should remain the shared baseline unless a specific location intentionally overrides it.

Do not make every screen use an unrelated visual language.

---

## 4. Atmosphere without sacrificing readability

Atmosphere is important, but information must remain readable.

Preferred hierarchy:

```text
world/art/background
    ↓
subtle darkening / atmospheric layer
    ↓
interface surfaces
    ↓
primary content
    ↓
interactive states / highlights
```

Do not place important text directly over a visually busy background without:

- contrast support;
- shadow/outline;
- panel;
- gradient;
- readable negative space.

---

## 5. Graphical, not decorative

A graphical UI is not achieved by adding random frames around lists.

Good transformation:

```text
region list
→ interactive world map with selectable regions
```

Good transformation:

```text
class list
→ class carousel / hero showcase
```

Good transformation:

```text
inventory list
→ inventory grid + paperdoll + details
```

Bad transformation:

```text
large text list
→ same text list with ornate border
```

When redesigning a screen, ask whether the interaction itself became more visual.

---

# PART II — CURRENT UI BASELINE

## 6. Existing screens are the starting point

Current Godot UI already contains graphical versions of systems such as:

- city hub;
- world map;
- class selection;
- equipment/inventory;
- Black Market;
- combat;
- Guild;
- progression;
- skills;
- dungeon;
- expedition preparation;
- achievements;
- adventure log;
- city economy/services.

Do not assume an old screenshot or terminal menu is the current implementation.

Inspect the current scene and script before changing it.

---

## 7. Shared style helper

The project contains a shared presentation helper:

```text
res://ui/presentation/interface_style.gd
```

It establishes common:

- dark blue panel surfaces;
- gold-highlighted interaction feedback;
- readable text colors;
- button hover/pressed behavior;
- heading treatment.

Use existing shared styling where it fits.

Do not reimplement slightly different button hover colors in every screen unless there is a deliberate local visual reason.

---

## 8. Reusable components first

Before building a new interaction from scratch, inspect:

```text
godot/ui/components/
godot/ui/presentation/
```

Existing reusable concepts include, among others:

- class carousel selectors;
- inventory grid;
- inventory item slots;
- character paperdoll;
- slide drawer;
- combat presentation components;
- Black Market offer slots;
- world region map.

Prefer extending a reusable component over duplicating its behavior inside a new screen.

---

# PART III — RESOLUTION AND LAYOUT

## 9. Resolution contract

Reference design target:

**1920×1080**

Minimum functional target:

**1280×720**

A screen is not accepted if:

- it only works at 1920×1080;
- text disappears at 1280×720;
- critical buttons move outside the viewport;
- panels overlap;
- scroll containers become unusable;
- a modal becomes larger than the screen;
- the user must resize the window manually to continue.

---

## 10. Reference vs minimum behavior

At 1920×1080:

- composition should feel spacious and intentional;
- primary art may breathe;
- panels should not be unnecessarily stretched;
- important imagery should remain prominent.

At 1280×720:

- the same functionality must remain available;
- less important decoration may compress;
- optional whitespace may shrink;
- scroll may appear where appropriate;
- major character art may scale down;
- actions must remain reachable.

Do not solve 1280×720 by making all text tiny.

---

## 11. Anchors and containers

Prefer responsive Godot layout tools:

- anchors;
- size flags;
- MarginContainer;
- HBox/VBox/Grid containers;
- AspectRatioContainer where useful;
- scroll containers for genuinely variable content.

Avoid relying on a long chain of absolute pixel offsets for entire screens.

Absolute positioning is acceptable for intentional map hotspots or artwork overlays when those coordinates are tied to a known source-art coordinate system and scale correctly with the asset.

---

## 12. Do not waste screen width

A panel should not occupy 40% of the screen when its meaningful content uses only 15%.

Common examples to avoid:

- very wide inventory panel with a narrow grid inside;
- oversized quest panel with three lines of text;
- huge empty details pane;
- full-width buttons with short labels when no hierarchy benefits.

Use width to improve:

- art visibility;
- comparison;
- information grouping;
- interaction.

---

## 13. Avoid black/dead margins

Large unused black bars or dead margins at the top/bottom/side of an important full-screen scene are undesirable unless they are a deliberate cinematic treatment.

City, world map and major selection screens should use the available viewport.

Background art should:

- crop/scale intentionally;
- maintain composition;
- not look pasted into a smaller rectangle inside the window.

---

## 14. Safe spacing

Spacing should communicate grouping.

Use:

- tighter spacing inside a logical group;
- larger spacing between groups;
- consistent margins;
- consistent panel padding;
- aligned baselines.

Do not fill every empty area with another widget.

Whitespace is useful when it improves hierarchy.

---

# PART IV — INFORMATION HIERARCHY

## 15. Every screen needs one primary purpose

The player should understand in seconds:

- where they are;
- what the screen is for;
- what the main action is;
- how to go back.

A screen should not present ten equally loud actions.

---

## 16. Visual hierarchy

Recommended priority:

### Level 1 — Current context
Examples:

- region name;
- shop/NPC name;
- class name;
- dungeon room;
- combat encounter.

### Level 2 — Decision-critical information
Examples:

- HP/Mana;
- cost;
- level requirement;
- danger;
- item comparison;
- inventory weight;
- quest objective.

### Level 3 — Primary action
Examples:

- Wyrusz;
- Kup;
- Ulepsz;
- Wybierz klasę;
- Wejdź do lochu.

### Level 4 — Secondary context
Examples:

- flavor text;
- detailed description;
- historical information;
- optional hints.

Do not make flavor text visually louder than a blocked departure warning.

---

## 17. Progressive disclosure

Do not show every possible detail at once.

Good:

```text
item grid
→ hover/selection
→ details panel
→ comparison
```

Good:

```text
world map
→ hover region
→ select region
→ detailed threat/actions
```

Good:

```text
class carousel
→ select class
→ reveal details
→ confirm
```

Avoid giant walls of text where selection can reveal contextual information.

---

## 18. Repeated information

Do not repeat the same information in three neighboring places without a UX reason.

For example, if:

- player Gold is visible in a shop header;
- price is visible on an offer;

there is rarely a need for another permanent panel saying the same Gold value again.

Use repetition only where it materially reduces mistakes.

---

# PART V — TYPOGRAPHY AND TEXT

## 19. Player-facing language

The current primary player-facing language is Polish.

Use correct Polish:

- diacritics;
- capitalization;
- grammar;
- fantasy terminology.

Never replace Polish characters with ASCII approximations simply to avoid encoding problems.

---

## 20. Canonical terminology

Use established terms consistently.

Examples:

- PŻ
- Mana
- ATK
- DEF
- Unik
- Udźwig
- Szczęście
- Ciężko Ranny
- Powrót do sił
- Czarny Rynek
- Gildia Poszukiwaczy
- Szczelina

For Pierrot, player-facing UI must use:

**Szczęście**

not:

`LCK`

---

## 21. Internal IDs are not UI labels

Do not show:

```text
black_fleet_wreck
silentwater_marshes
ancient_order_key
hunter_combo_04
```

to the player unless the screen is a debug/development tool.

Use canonical display names from catalogs.

---

## 22. Short labels beat paragraphs

Buttons should describe actions concisely.

Prefer:

```text
Wyrusz
Kup
Sprzedaj
Ulepsz
Użyj
Załóż
Zdejmij
Wróć
```

over sentence-length buttons.

Explanatory detail belongs in:

- tooltip;
- subtitle;
- warning;
- details panel.

---

## 23. Numbers need context

Avoid unexplained numbers.

Bad:

```text
75
```

Good:

```text
Udźwig: 42.5 / 75.0 kg
```

Bad:

```text
7–10
```

Good:

```text
Zalecany poziom: 7–10
```

---

## 24. Status text

Status text should answer:

- what happened;
- why an action failed;
- what the player can do next.

Bad:

```text
Nie można.
```

Better:

```text
Brakuje Starożytnego Klucza Zakonu.
```

Do not expose raw parser/service diagnostics in normal UI.

---

# PART VI — COLOR AND CONTRAST

## 25. Shared identity

Default fantasy surfaces should remain compatible with the current:

- blue-black base;
- desaturated cool borders;
- gold interaction accents;
- pale neutral text.

Location-specific accents may vary.

Example:

- Black Market may feel warmer/dirtier;
- ice region may feel colder;
- desert may feel warmer;
- Pierrot may use stronger red/magenta identity.

But shared controls should still feel like the same game.

---

## 26. Gold means importance, not everything

Gold should usually signal:

- hover/focus;
- premium/rare importance;
- primary fantasy accent;
- selection;
- important frame detail.

If every border and every word is gold, gold loses meaning.

---

## 27. Red and warning colors

Use red/warm warning colors for:

- invalid action;
- dangerous state;
- overload;
- lethal risk;
- failed requirement.

Do not use the same warning red as decorative accent on unrelated content.

---

## 28. Do not rely on color alone

A disabled, dangerous or selected state should also use:

- label;
- icon;
- border;
- shape;
- checkmark;
- state text;

where appropriate.

This improves readability and accessibility.

---

# PART VII — BUTTONS AND INTERACTION

## 29. Hover feedback

Interactive controls should visibly respond on hover.

Current shared behavior uses:

- brighter/different background;
- gold-ish border/highlight;
- brighter text;
- pointing-hand cursor.

Do not create invisible hotspots with no feedback unless the underlying art itself visibly highlights.

---

## 30. Pressed feedback

Clicking should feel distinct from hovering.

Use:

- pressed state;
- small animation;
- sound later;
- state transition.

Do not resize buttons dramatically on hover/press if it causes layout movement.

---

## 31. Focus

Keyboard/controller focus must be visible.

Class selection already uses explicit focus behavior and relative navigation.

New interactive screens should not be mouse-only by accident.

At minimum, major actions must be reachable by:

- keyboard;
- controller-friendly focus model where the screen architecture supports it.

---

## 32. Click target

Interactive targets should not require pixel-perfect clicking.

For major navigation, use comfortably sized targets.

The current city navigation uses a minimum height around 48 px for its buttons; new navigation controls should stay in a similarly comfortable range unless the design has a clear alternative.

---

## 33. Disabled state

Disabled controls must visually look disabled and, when useful, explain why.

Examples:

- class locked before level 5;
- dungeon missing entry item;
- bargain already attempted;
- sold Black Market offer;
- camp unavailable;
- overloaded expedition.

Use tooltips/status text for important blockers.

---

## 34. Confirmation

Require confirmation for actions with meaningful irreversible cost.

Examples:

- permanent class choice;
- destructive item operation;
- permanent specialization if applicable;
- intentionally leaving a high-stakes flow;
- other irreversible decisions.

Do not add confirmations to every harmless click.

---

## 35. Back behavior

Every modal/full-screen subsection should have predictable return behavior.

`Wróć` should:

- return to the logical parent screen;
- not unexpectedly jump to main menu;
- not discard persistent state unless clearly stated.

Escape/controller-back should behave consistently where implemented.

---

# PART VIII — CITY / VARENHOLD

## 36. City identity

Varenhold must feel like a **city**, not a small settlement or a list of services.

Desired city presentation:

- large urban footprint;
- strong central-space feeling;
- prominent civic landmark / town hall;
- clear service districts/buildings;
- enough negative space to read the city;
- not excessively cluttered.

---

## 37. City navigation

The current city hub already supports map hotspots for:

- Gildia;
- Brama Zachodnia;
- Kuźnia;
- Kram;
- Karczma;
- Warsztat.

This spatial interaction is the preferred direction.

Do not regress primary city navigation into a terminal-style vertical list as the only interface.

A secondary navigation drawer may remain for:

- accessibility;
- keyboard/controller support;
- quick access;
- features not represented by a map building.

The city artwork should remain the star.

---

## 38. Service buildings must be distinguishable

NPC/service buildings should not look identical to generic houses.

A player should be able to learn the city visually.

Distinction can come from:

- silhouette;
- sign;
- architecture;
- props;
- lighting;
- icon marker;
- environmental storytelling.

Do not overload every building with floating UI labels.

---

## 39. City hotspot behavior

A city hotspot should:

- highlight on hover;
- show a concise name/purpose;
- use a pointing cursor;
- align accurately with the building;
- remain clickable after scaling;
- avoid covering important visual details.

If background art changes, hotspot coordinates must be revalidated.

---

## 40. City day/night parity

Day and night city backgrounds should depict the **same city layout**.

When a day/night pair is intended to match:

- same camera;
- same buildings;
- same crop;
- same major geometry;
- same hotspot alignment.

Only lighting, sky, lamps, atmosphere and other time-dependent elements should change.

Do not create a night version that subtly moves buildings and breaks hotspots.

---

## 41. City screen density

Avoid stacking:

- giant side menu;
- permanent quick-action dock;
- large top bar;
- labels on every building;
- multiple duplicate navigation methods;

all at the same time.

The current direction favors a map-centric city with a controlled navigation drawer.

---

# PART IX — WORLD MAP

## 42. Map-first navigation

Regions should be represented on a **world map**, not primarily as a list.

The current screen already has:

- `WorldRegionMap`;
- region hover;
- region selection;
- city return point;
- region details/actions.

This is the preferred foundation.

---

## 43. Region hover

Hovering a region should communicate:

- that the area is interactive;
- region name;
- current availability/selection;
- optional danger cue.

The highlight should follow the actual region silhouette or an intentional map marker—not a random rectangular overlay when a regional mask exists.

---

## 44. Region selection

Selecting a region should update a dedicated information area with:

- region name;
- danger;
- recommended level;
- description;
- current weather if relevant;
- threats;
- available boss/dungeon action;
- expedition action.

The map should remain visible enough that the player does not lose geographic context.

---

## 45. Secondary region list

If a region list remains internally for:

- accessibility;
- testing;
- controller navigation;
- fallback;

it should not visually dominate the final world-map design.

The map is primary.

---

## 46. Modular world map

The world map must be modular.

Adding Region 6 should not require repainting selection logic into one monolithic script.

Keep separate:

- region data;
- region visual/mask definition;
- hover/selection;
- details rendering;
- gameplay service.

---

## 47. World-map visual consistency

Region borders should be:

- readable;
- not excessively thick;
- consistent in style;
- clear enough to distinguish land divisions.

Hover/select glow should not obscure the underlying map illustration.

---

# PART X — CLASS SELECTION

## 48. Class selection is a showcase

Choosing a class is a major RPG identity decision.

The screen should feel closer to:

```text
hero showcase
```

than:

```text
settings menu
```

---

## 49. Current carousel direction

The current class-selection implementation already uses:

- a central selected character;
- neighboring class figures;
- previous/next navigation;
- per-class artwork;
- class-specific accents;
- class details;
- selection confirmation.

This is the preferred base direction.

Do not regress it to four text rows.

---

## 50. Selected class dominance

The selected class should clearly dominate.

Use:

- larger central art;
- stronger light/glow;
- name;
- short identity subtitle;
- primary attributes;
- Mana;
- starting equipment / identity info;
- clear confirm action.

Neighboring classes should remain visible enough to imply carousel navigation but not compete with the selected class.

---

## 51. Class colors

Class-specific accent colors may help identity.

Current screen already differentiates:

- Warrior;
- Hunter;
- Mage;
- Pierrot;

through distinct accent atmospheres.

Class color should decorate the shared UI identity, not replace it.

---

## 52. Gender/art variants

The class screen supports male/female art variants.

If one variant is missing:

- do not silently use an unrelated class image;
- use the documented fallback;
- report missing final asset.

Keep framing/scale consistent between gender variants so the carousel does not jump.

---

## 53. Locked choice

Before the permanent class unlock requirement is satisfied:

- inspection may remain available;
- confirmation must communicate the lock;
- the player should understand when the choice becomes available.

Do not hide class information merely because selection is locked.

---

## 54. Permanent choice warning

When the choice is permanent, say so near the confirm action.

Do not hide permanence in a distant tooltip.

---

# PART XI — EQUIPMENT AND INVENTORY

## 55. Equipment screen composition

Preferred composition:

```text
stats / character
    +
paperdoll / equipped slots
    +
backpack grid
    +
contextual item details
```

The current screen already contains:

- CharacterPaperdoll;
- 11 slot controls;
- InventoryGridView;
- category tabs;
- stats;
- details;
- drag/drop behavior.

Preserve this visual direction.

---

## 56. Do not make inventory needlessly wide

The backpack grid should define the useful width of its area.

If the grid uses only part of the panel, reduce or repurpose the excess space.

Useful neighboring space can contain:

- item details;
- comparison;
- filters;
- player stats;
- paperdoll.

---

## 57. Paperdoll importance

The hero should not feel like an afterthought between spreadsheets.

The character visual should remain prominent enough to:

- reinforce class identity;
- show equipment context;
- support future animated/rigged character presentation.

---

## 58. Slot spatial logic

Equipment slots should be visually associated with the character/body where possible.

At minimum, the layout should make categories easy to understand.

Use canonical display names such as:

- Broń;
- Druga ręka;
- Hełm;
- Zbroja;
- Rękawice;
- Buty;
- Pas;
- Naszyjnik;
- Bransoleta;
- Kolczyki;
- Pierścień.

Do not append `[DEFENSYWNY]`, `[OFENSYWNY]`, `[MIESZANY]` to player-facing item names.

---

## 59. Inventory grid

The grid should support quick scanning.

Each cell should communicate, when applicable:

- icon;
- rarity;
- stack count;
- selected state;
- equipped/locked/special state.

Do not put full item descriptions inside cells.

---

## 60. Hover and selection details

Hover may preview details.

Selection should lock the current details long enough for:

- comparison;
- equipping;
- reading;
- use;
- sale;
- upgrade.

Do not make details disappear because the pointer moves from the item to the action button.

---

## 61. Comparison

When inspecting equipment, clearly separate:

- candidate item;
- currently equipped item;
- resulting stat difference where available.

Use:

- arrows;
- +/- values;
- consistent ordering.

Do not rely on the player manually comparing two long paragraphs.

---

## 62. Item Power and affixes

Equipment 2.0 presentation should make visible:

- Item Power;
- rarity;
- upgrade level;
- affixes;
- affix tier where relevant;
- set membership;
- set progress;
- class effect;
- required level/class.

The most important information should come first.

Do not bury the item name and core stats below lore text.

---

## 63. Drag and drop

Drag-and-drop should feel predictable.

Valid targets should highlight.

Invalid targets should not silently accept and then undo the operation.

If drag-and-drop is implemented, retain a button/keyboard route for important operations where practical.

---

## 64. Carry weight

Carry status should be easy to see without dominating the screen.

States such as:

- normal;
- Obciążony;
- Przeciążony;

should have clear visual distinction.

Overload warning should become especially prominent in expedition preparation.

---

# PART XII — SHOPS AND CITY SERVICES

## 65. Shops should feel like places

A merchant, blacksmith, workshop and inn should not all be the same list with a different title.

Different services may share interaction components but should have distinct:

- NPC/context art;
- workspace;
- primary action;
- relevant resource display.

---

## 66. NPC integration

If an NPC is shown at a counter:

- the body should not look arbitrarily cut off;
- the counter should plausibly occlude the lower body;
- the NPC should look placed behind/in the environment;
- avoid a random rectangular asset behind the character;
- lighting/color should fit the scene.

The character should not look pasted on top of the UI.

---

## 67. Merchant

Merchant interface should prioritize:

- item identity;
- price;
- quantity;
- player Gold;
- inventory/carry implications;
- buy/sell mode.

Bulk purchase/sale should remain easy.

---

## 68. Blacksmith

Blacksmith interface should prioritize:

- selected equipment;
- current upgrade level;
- target upgrade;
- material requirements;
- Gold cost;
- resulting stat improvement;
- clear multi-level option if supported.

Missing requirements should be obvious.

---

## 69. Workshop / crafting

Crafting should visually connect:

```text
recipe
→ ingredients
→ Gold
→ result
```

Available vs missing ingredients should be readable at a glance.

Avoid presenting 42 recipes as one endless undifferentiated text list.

Use:

- region category;
- type filters;
- cards;
- recipe groups;
- search later if necessary.

---

## 70. Inn

Inn should feel like a service/location, not a status dialog.

Clearly communicate:

- healing/rest effect;
- cost;
- current availability;
- next allowed rest;
- time passage.

---

# PART XIII — BLACK MARKET

## 71. Black Market identity

Czarny Rynek must feel:

- hidden;
- illicit;
- atmospheric;
- distinct from ordinary city commerce.

It should not look like Oren's normal shop with darker colors.

---

## 72. Visual offers are primary

The current implementation already places four offers on authored source-art positions using dedicated offer slots.

This is the preferred purchasing presentation.

The four physical/visual offers should be the focus.

A list may remain for:

- selling;
- accessibility;
- internal fallback;

but the buying experience should not regress to a plain list.

---

## 73. Offer placement

Offers aligned to background art must:

- sit on the intended mats/table positions;
- scale correctly with background;
- not drift when window size changes;
- keep price signage readable;
- avoid covering the product art.

If the source background changes dimensions, recalculate layout against source-art coordinates.

---

## 74. Sold state

A sold offer should remain visually understandable.

Good cues:

- SOLD / SPRZEDANE board;
- removed/dimmed item;
- unavailable action;
- retained slot so the market layout does not jump.

Do not delete the slot and shift all remaining offers.

---

## 75. Bargaining feedback

The bargain action must communicate:

- attempt availability;
- success/failure;
- new price;
- that the result is final for this rotation.

Do not imply the player can retry if the backend has persisted the attempt.

---

## 76. Market rotation

The screen should show:

- current delivery/rotation;
- next rotation timing/date in a readable way.

Do not overwhelm the player with internal rotation keys.

---

# PART XIV — COMBAT UI

## 77. Combat priority

During combat, the player primarily needs:

- hero state;
- enemy state;
- available actions;
- turn result;
- class mechanic;
- statuses;
- danger.

Decorative art must not obscure these.

---

## 78. Character orientation

Default combat composition:

```text
Hero / Pierrot side: LEFT
Enemy side: RIGHT
Enemy faces LEFT toward hero
```

This matches the art-production direction.

Do not flip assets inconsistently between encounters.

---

## 79. Combat feedback

Combat text should be concise and readable.

Preferred critical phrasing:

```text
<cel> otrzymuje X obrażeń krytycznych.
```

Elite marker:

```text
[ELITA] Nazwa
```

rather than placing `[ELITA]` ambiguously at the end.

---

## 80. Class-specific combat panels

Each class may require a dedicated compact mechanic area.

Examples:

### Warrior
- block readiness;
- Provoke;
- retaliation/counter state.

### Hunter
- current three-technique sequence;
- explosive charges;
- pending effects;
- last combination.

### Mage
- elemental sequence;
- Splot charges;
- dual-cast availability.

### Pierrot
- current dice;
- Żetony Losu;
- mirror/reflection state;
- recent roll.

Do not force every class mechanic into the same generic text box.

---

## 81. Turn result pacing

Future animation should improve comprehension, not delay every small action excessively.

The player should be able to understand:

```text
action
→ hit/miss
→ damage/status
→ enemy response
```

Use animation/audio to reinforce this sequence.

---

## 82. Combat log

If a detailed log exists, it is secondary.

The main battle presentation should not require reading a scrolling transcript to know what happened.

---

# PART XV — EXPEDITION PREPARATION

## 83. Preparation screen purpose

This screen is a **pre-flight dashboard**.

It should make the player feel:

```text
I know where I am going.
I know who is going.
I know their condition.
I know what I am carrying.
I know the risks.
```

---

## 84. Required visual sections

The screen should make room for:

- destination;
- hero HP/Mana;
- carry weight;
- active companions;
- companion HP/Mana;
- tactic;
- supplies;
- Guild Storage replenishment;
- quick equipment;
- presets;
- warnings;
- departure action.

Do not hide all of this behind nested text menus.

---

## 85. Priority order

Suggested hierarchy:

### Top / context
- destination;
- danger/recommended level;
- weather where relevant.

### Main center
- hero and party condition;
- inventory/supplies.

### Supporting
- tactic/preset;
- storage replenishment;
- equipment shortcut.

### Bottom/final action
- warnings;
- Wyrusz.

---

## 86. Warnings

Warnings must be visually grouped and ordered by severity.

Example severity:

```text
BLOCKER
Przeciążony — nie możesz wyruszyć.

HIGH RISK
Kompan: Ciężko Ranny.

WARNING
Brak mikstur leczniczych.
```

Do not display all warnings in the same neutral gray.

---

## 87. Conscious confirmation

When a risk is allowed despite warning, the UI should make the second confirmation deliberate.

Do not make the player re-click because nothing happened without explaining why.

---

## 88. Presets

Preset buttons:

- SOLO;
- BOSS;
- DUNGEON;
- SZCZELINA;

should be quickly distinguishable.

After applying a preset, clearly show:

- what changed;
- shortages;
- whether supplies were pulled from storage;
- any blocker.

---

# PART XVI — GUILD AND COMPANIONS

## 89. Guild is a hub, not one giant page

Guild contains multiple conceptual areas:

- story;
- Daily;
- Weekly;
- ranks/reputation;
- rumors;
- milestones;
- party/companions;
- candidates;
- messages;
- personal stories;
- Rifts.

Do not place everything in one long scroll.

Use tabs/subsections or spatial navigation.

---

## 90. Quest board

Story/Daily/Weekly should be visually distinguishable.

A quest card/entry should show:

- title;
- type;
- objective;
- progress;
- reward;
- requirement/state.

Completed/claimable/locked/active states should be obvious.

---

## 91. Guild reputation

Show:

- current rank;
- current reputation;
- progress to next rank;
- meaningful unlocks.

Avoid requiring the player to memorize rank thresholds.

---

## 92. Companion roster

Companion presentation should emphasize characters.

Preferred content:

- portrait/full character art;
- name;
- class;
- level;
- condition;
- relation;
- active/reserve status;
- tactic;
- personal-story indicator.

Do not reduce companions to rows of numbers.

---

## 93. Candidate recruitment

Candidates should feel like people, not loot.

Before recruitment, emphasize:

- identity;
- personality/origin;
- visible class/path information allowed by design;
- conversation;
- recruitment state.

Do not reveal intentionally hidden equipment/build details before recruitment if the gameplay system says they are hidden.

---

## 94. Heavy injury

Use:

**CIĘŻKO RANNY**

and:

**Powrót do sił: X dni Pythonii**

Make the condition visually significant.

Do not use medical/administrative presentation.

---

## 95. Permanent death / Egzekucja

A lethal companion threat requires strong UI signaling.

The player must understand:

- who is in danger;
- what the threat is;
- how much time/opportunity remains;
- what action can save them;
- that failure can be permanent.

Never bury lethal risk in a small combat-log line.

---

# PART XVII — DUNGEONS AND RIFTS

## 96. Dungeon presentation

Dungeons should feel structured and dangerous.

Show:

- dungeon identity;
- current room/phase;
- health/resource attrition;
- major decision;
- retreat when available;
- boss warning;
- one-use recovery location.

Do not present a dungeon as a standard region screen with another background.

---

## 97. Boss threshold

Before a major boss where retreat/preparation choice exists, presentation should visually communicate:

**point of commitment / final danger**

This can use:

- stronger framing;
- boss title;
- warning;
- scene art;
- audio later.

---

## 98. Rift presentation

Szczeliny should communicate long-run structure.

Useful elements:

- rank;
- theme;
- anomaly;
- segment progress;
- party;
- next known milestone;
- camp/miniboss/final Lord context;
- expiry/lifecycle when outside the active run.

Because Rifts are long, the player should always know progress through the expedition.

---

## 99. Rift danger

Elite/miniboss/Lord encounters should have distinct presentation tiers.

Do not use the same tiny label for:

- regular encounter;
- elite;
- Władca Szczeliny.

---

# PART XVIII — ACHIEVEMENTS, LOGS AND SECONDARY SCREENS

## 100. Achievements

Achievement entries should prioritize:

- icon/art;
- title;
- requirement;
- completion;
- title reward.

Locked achievements should remain readable without revealing spoilers beyond intended design.

---

## 101. Adventure Log

The log is chronological support information.

Use:

- date/time;
- category/icon;
- concise event;
- clear scrolling.

Do not make it compete visually with primary gameplay screens.

---

## 102. Skills and progression

Skill/talent screens should show relationships visually.

Prefer:

- cards;
- paths;
- connectors;
- tier grouping;
- unlock states.

Avoid long unstructured lists of 41 talents.

---

## 103. Locked talents

A locked node should say why:

- level;
- prerequisite;
- Path;
- book;
- insufficient points.

Do not show only a padlock with no explanation.

---

# PART XIX — MODALS, TOOLTIPS AND FEEDBACK

## 104. Modal use

Use modals for:

- irreversible confirmation;
- focused choice;
- error requiring acknowledgment;
- detailed comparison when space is genuinely insufficient.

Do not turn normal navigation into a chain of popups.

---

## 105. Tooltip use

Tooltips are good for:

- explanation;
- detailed stat meaning;
- requirement details;
- icon clarification.

Critical information must not exist **only** in a tooltip.

Touch/controller users may not hover.

---

## 106. Toast/status feedback

Small actions can use lightweight feedback.

Examples:

- item moved;
- preset applied;
- Gold gained;
- save completed.

Do not open a modal for every minor success.

---

# PART XX — SCROLLING

## 107. Scroll only variable content

Good scroll candidates:

- long quest lists;
- inventory;
- logs;
- recipe collections;
- talent descriptions.

Avoid requiring scrolling to reach:

- Back;
- primary Confirm;
- current HP;
- critical blocker;

on a standard supported resolution.

---

## 108. Nested scroll

Avoid nested scroll containers where wheel/controller behavior becomes confusing.

Prefer one obvious scroll context per panel.

---

# PART XXI — ACCESSIBILITY AND INPUT

## 109. Keyboard

Major screens should have:

- sensible focus order;
- visible focus;
- Enter/confirm;
- Escape/back where appropriate.

Do not require the mouse for class selection, menus or basic item actions if the existing architecture supports focus navigation.

---

## 110. Controller readiness

Even before full controller polish, do not design interactions that are impossible to represent with focus navigation.

Examples to avoid:

- hover-only mandatory controls;
- tiny freeform map click as the only route;
- drag-only inventory action.

Provide alternate focused actions.

---

## 111. Readability

Avoid:

- tiny decorative fonts;
- excessive all-caps paragraphs;
- low-contrast gray on dark blue;
- long centered body text.

Use all caps sparingly for:

- category;
- alert;
- rank;
- short header.

---

## 112. Motion sensitivity

Future animation should not:

- constantly shake the full screen;
- pulse every UI element;
- endlessly zoom backgrounds;
- move critical text while reading.

Keep ambient motion restrained.

---

# PART XXII — ANIMATION

## 113. Motion should explain state

Good UI animation:

- selected class slides to center;
- hovered region softly highlights;
- drawer opens;
- details panel transitions;
- item moves to slot;
- warning appears;
- boss panel enters.

Bad UI animation:

- random constant bouncing;
- every button spinning;
- large motion that delays input.

---

## 114. Duration hierarchy

Fast interactions should feel fast.

Use shorter motion for:

- hover;
- button;
- small selection.

Use longer motion for:

- screen entrance;
- class transition;
- major boss reveal.

Do not make exact durations universal; match the existing screen and test usability.

---

## 115. Interruptibility

Navigation animation should not trap the player.

If the player changes selection quickly, transitions should:

- cancel;
- update target;
- resolve cleanly.

Do not queue ten animations because the player pressed Right ten times.

---

# PART XXIII — ASSET INTEGRATION WITH UI

## 116. Transparent character art

Standalone character/enemy art intended for UI/combat should normally:

- have transparent background;
- avoid baked UI frames;
- leave enough margin for scaling;
- keep full intended figure visible.

Specific character art rules belong in `ART_DIRECTION.md`.

---

## 117. Do not bake mutable text into art

Avoid putting into raster art:

- item prices;
- NPC names;
- stats;
- button labels;
- quest text;
- region level.

Render mutable/localizable text in UI.

---

## 118. Art should match interaction

If a button overlays a map/building:

- art composition must leave usable interaction space.

If an item sits on a shop counter:

- item art should fit the intended pad.

If a class art is used in a carousel:

- all class variants need compatible framing.

---

# PART XXIV — PLACEHOLDERS

## 119. Placeholder policy

Placeholders are allowed during implementation.

They must be clearly treated as temporary.

A placeholder must not silently become the final asset because "the feature works".

---

## 120. Placeholder text

Internal development may use:

```text
PLACEHOLDER
```

but release-facing screens should not.

Reviewer should flag visible placeholder leakage when a task is claimed final/polished.

---

# PART XXV — UI ARCHITECTURE

## 121. UI must not calculate domain outcomes

Forbidden examples:

```text
button_pressed:
    gold -= 500
```

when an economy service owns the transaction.

Forbidden:

```text
if level >= 5:
    class_unlocked = true
```

if class validity belongs to the player/progression domain.

UI asks the service.

Service validates.

UI renders result.

---

## 122. UI can calculate presentation geometry

Appropriate UI responsibilities include:

- panel sizes;
- hotspot positions;
- visual interpolation;
- animation;
- text formatting;
- selected visual state;
- scroll position;
- focus;
- tooltip placement.

---

## 123. Screen state vs game state

Safe screen-local state:

- currently selected inventory cell;
- hovered region;
- open tab;
- carousel index;
- drawer open/closed.

Persistent game state:

- equipment;
- class;
- Gold;
- quest state;
- Black Market purchase;
- companion tactic;
- Rift progress.

Do not confuse them.

---

# PART XXVI — SCREENSHOT REVIEW PROTOCOL

## 124. Screenshots are required for meaningful visual changes

For a material UI redesign, Developer should provide Reviewer with screenshots whenever automation/environment allows.

Minimum preferred set:

- 1920×1080;
- 1280×720;
- relevant hover/selected state;
- relevant blocked/error state if changed.

---

## 125. Reviewer screenshot checklist

Reviewer inspects:

- Is the main purpose obvious?
- Is the primary action obvious?
- Is the screen too list-heavy?
- Is important art large enough?
- Are margins balanced?
- Is there wasted space?
- Is any content clipped?
- Is text readable?
- Are controls aligned?
- Does hover/focus read clearly?
- Are disabled states understandable?
- Does the style match the rest of Echoes?
- Does the screen still work at 1280×720?
- Does it look like a game rather than a developer tool?

---

## 126. Review at full frame

Do not review only a cropped widget screenshot if the change affects full-screen composition.

The Reviewer should see enough context to judge:

- hierarchy;
- margins;
- artwork;
- navigation;
- screen balance.

---

## 127. Before/after comparison

For redesigns, before/after comparison is preferred.

Reviewer should determine whether the redesign actually improved:

- clarity;
- visual hierarchy;
- use of space;
- game feel.

"More decoration" alone is not improvement.

---

# PART XXVII — COMMON FAILURE MODES

## 128. List regression

Reject when a graphical screen becomes primarily:

```text
1. option
2. option
3. option
4. option
```

without a strong accessibility/fallback reason.

---

## 129. Oversized panels

Reject when:

- panel width greatly exceeds content;
- map/art is unnecessarily squeezed;
- inventory grid is surrounded by dead space.

---

## 130. Overcrowding

Reject when every part of the screen contains:

- text;
- icon;
- button;
- border;
- glow.

A fantasy interface still needs visual rest.

---

## 131. Tiny art

Reject when character/class/NPC art is technically present but so small that it does not contribute to the screen.

---

## 132. Pasted-on NPC

Reject when NPC:

- has mismatched lighting;
- has a leftover rectangular background;
- ends abruptly at counter edge without plausible occlusion;
- floats above the scene.

---

## 133. Unclear selection

Reject when the player cannot quickly tell:

- selected class;
- selected region;
- selected item;
- selected tab;
- active companion.

---

## 134. Hover layout shift

Reject when hover changes control size and causes neighboring UI to move.

Hover should usually change:

- color;
- border;
- glow;
- subtle scale inside reserved space;

not reflow the layout.

---

## 135. Text wall

Reject when a core interaction is represented mainly by paragraphs where:

- cards;
- icons;
- grouping;
- map;
- progress;
- comparison;

would communicate faster.

---

## 136. Broken aspect

Reject when artwork:

- stretches faces;
- changes body proportions;
- distorts map geography;
- squashes icons.

Use correct aspect handling.

---

## 137. Duplicate navigation overload

Reject when the same screen has:

- left menu;
- bottom dock;
- building hotspot;
- top buttons;

all permanently visible for the same actions without a strong reason.

---

# PART XXVIII — SCREEN-SPECIFIC ACCEPTANCE

## 138. City Hub accepted when

- city dominates the composition;
- hotspots align;
- service buildings are understandable;
- navigation drawer does not crush the city;
- no large black margins;
- day/night alignment remains stable;
- 1280×720 remains usable.

---

## 139. World Map accepted when

- map is primary;
- regions visibly respond to hover/select;
- region details are readable;
- known/locked state is clear;
- region list is not visually dominant;
- new regions can be added modularly;
- 1280×720 remains usable.

---

## 140. Class Selection accepted when

- selected hero dominates;
- neighboring classes imply carousel;
- class identity is readable without a text wall;
- class art does not distort;
- lock/permanence is clear;
- keyboard/focus navigation works;
- 1280×720 remains usable.

---

## 141. Equipment accepted when

- stats/paperdoll/backpack form a coherent workspace;
- hero art remains meaningful;
- 11 slots are understandable;
- grid is not needlessly stretched;
- item comparison is readable;
- drag/drop and button routes remain functional;
- carry state is visible;
- 1280×720 remains usable.

---

## 142. Black Market accepted when

- atmosphere differs from ordinary shop;
- four visual buy offers remain primary;
- items align with display surfaces;
- prices do not cover item art;
- sold state is clear;
- bargaining state is clear;
- 1280×720 remains usable.

---

## 143. Combat accepted when

- hero/enemy states are visible;
- actions are obvious;
- class mechanic is readable;
- enemy art faces hero correctly;
- important result does not require combat-log archaeology;
- danger/elite/boss state is clear;
- 1280×720 remains usable.

---

## 144. Expedition Preparation accepted when

- destination is obvious;
- party condition is obvious;
- supplies/weight are obvious;
- blocker vs warning is distinct;
- presets are understandable;
- final departure action is easy to find;
- 1280×720 remains usable.

---

# PART XXIX — DEVELOPER UI WORKFLOW

## 145. Before editing a screen

Developer should inspect:

1. the current `.tscn`;
2. the current `.gd`;
3. reusable components;
4. screenshot/current runtime;
5. relevant tests;
6. Project Bible;
7. this UI Rules file;
8. Art Direction when art is involved.

Do not redesign from an old screenshot alone.

---

## 146. State the design problem

Before implementing, identify the problem.

Examples:

```text
inventory panel wastes 35% of width
```

```text
region selection is visually list-first
```

```text
class art is cropped and selection lacks hierarchy
```

```text
NPC looks pasted in front of counter
```

This prevents purposeless redesign.

---

## 147. Preserve functionality

A prettier screen that breaks:

- keyboard navigation;
- drag/drop;
- quest updates;
- service calls;
- save flow;

is not an improvement.

Behavioral regression blocks approval.

---

## 148. Minimal coherent diff

UI refactor should touch:

- the target screen;
- required shared component;
- required tests;
- relevant assets;

not unrelated screens unless the shared change genuinely requires them.

---

## 149. Visual smoke test

After implementation:

- launch screen;
- interact with it;
- change selections;
- test hover;
- test disabled state;
- test Back;
- test 1920×1080;
- test 1280×720.

For inventory/shop:

- test empty state;
- test populated state;
- test long names;
- test quantity >1 where relevant.

---

# PART XXX — REVIEWER VERDICT

## 150. Reviewer categories

Reviewer should categorize feedback as:

### BLOCKER
Breaks functionality, accessibility, supported resolution, design identity or core UX.

### IMPORTANT
Significant visual/UX issue worth fixing before final acceptance.

### OPTIONAL
Polish that can be deferred.

Do not turn every 2-pixel preference into a blocker.

---

## 151. Reviewer must protect project direction

Reviewer should reject a technically functional redesign when it clearly violates established direction, for example:

- city becomes a button list;
- world map becomes a dropdown;
- class selection becomes four text rows;
- Black Market becomes a normal shop table;
- equipment loses paperdoll/grid identity;
- warnings become invisible;
- 1280×720 becomes unusable.

---

# PART XXXI — FUTURE UI EVOLUTION

## 152. Region 6

Region 6 UI integration should use existing map modularity.

Do not create a special one-off Region 6 screen that bypasses:

- WorldRegionMap;
- region catalog;
- region details pattern.

---

## 153. Animation-ready UI

Leave enough structure for future:

- character idle animation;
- skill animation;
- animated shop/NPC presentation;
- cinematic transitions;
- richer class showcase.

Do not tightly couple layout to one static PNG if future rigged/animated art is expected.

---

## 154. Audio-ready UI

Future UI should support:

- hover sound;
- click sound;
- tab transition;
- equip/use feedback;
- warning sound;
- rare item reveal;
- class select confirmation.

Audio should reinforce hierarchy rather than make every interaction loud.

---

## 155. Localization readiness

Even if Polish is the primary current language:

- avoid using text as logic keys;
- avoid baking labels into images;
- allow layout flexibility for different string lengths;
- centralize repeated terminology where practical.

Do not redesign the whole architecture for localization prematurely, but do not make future localization impossible.

---

# PART XXXII — FINAL UI PRINCIPLE

## 156. The question every UI change must answer

Before accepting a UI change, ask:

**Does this make the player understand the game faster while making Echoes of Pythonia feel more like its own fantasy RPG?**

A strong change should improve at least several of:

- clarity;
- atmosphere;
- hierarchy;
- speed of interaction;
- use of space;
- class/world identity;
- accessibility;
- visual cohesion;
- scalability for future content.

If the change adds decoration but makes decisions harder to understand, it is a regression.

If the change is technically clean but turns the game back into menus and lists, it is a regression.

If the change is visually impressive but hides gameplay-critical state, it is a regression.

The target is:

**visual RPG presentation + clear system information + preserved gameplay depth.**
