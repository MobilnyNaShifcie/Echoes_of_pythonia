# Echoes of Pythonia — Art Direction

> Role: visual production contract for AI-assisted development  
> Project: Echoes of Pythonia  
> Godot line: v0.25.x  
> Presentation direction: anime-fantasy 2D / 2.5D with selective 3D  
> Protected baseline: `snapshot/pre-ai-team-2026-09-10`

---

## 1. Purpose

This document defines **how visual assets for Echoes of Pythonia should be designed, generated, reviewed, approved, prepared and integrated**.

It is written for:

- the Developer agent;
- the Reviewer/Designer agent;
- image-generation workflows;
- future 2D rigging;
- future 3D experiments;
- UI artists;
- animation/VFX work;
- asset-validation scripts;
- future collaborators.

This file does not authorize an AI agent to approve its own art.

**Owner approval remains mandatory for production art.**

---

# PART I — VISUAL IDENTITY

## 2. Overall direction

Echoes of Pythonia uses an:

**anime-fantasy 2D / 2.5D presentation with a dark, serious world**

The target should feel:

- intentionally illustrated;
- cohesive;
- animation-ready;
- readable in gameplay;
- atmospheric;
- stylized rather than photorealistic;
- distinct from generic AI-fantasy art.

The game may selectively use 3D or hybrid 2.5D when it adds clear value.

Examples:

- Pierrot's Fate dice;
- cinematic moments;
- selected characters/creatures;
- special environment elements.

Do not convert the entire game to 3D simply because a 3D pipeline exists.

---

## 3. Tone

The world should feel:

- mysterious;
- dangerous;
- melancholic in places;
- adventurous;
- dark without becoming visually unreadable;
- fantastical without excessive ornament.

Avoid making every region:

- bright heroic high-fantasy;
- grim monochrome;
- horror-only;
- neon magical;
- overloaded with glowing runes.

Each region should have its own atmosphere while still belonging to the same game.

---

## 4. Anime influence

Anime influence should appear through:

- readable silhouettes;
- expressive faces;
- clean shape language;
- controlled stylization;
- strong character identity;
- cinematic skill presentation;
- deliberate pose language.

Avoid:

- extreme chibi proportions for normal combat characters;
- exaggerated parody anatomy;
- generic mobile-gacha visual noise;
- every costume covered in decorative metal;
- hyper-saturated effects on every asset.

---

## 5. Painterly detail

Avoid hyper-detailed painterly rendering that creates:

- noisy silhouettes;
- inconsistent brush texture;
- impossible-to-rig costume complexity;
- visual mismatch between enemies;
- tiny details invisible at gameplay scale.

Detail should serve:

- character identity;
- region identity;
- equipment readability;
- animation.

---

# PART II — SOURCE OF TRUTH AND APPROVAL

## 6. Art source priority

When visual instructions conflict, use this order:

1. explicit latest owner instruction;
2. approved current production asset;
3. `AI_CONTEXT/PROJECT_BIBLE.md`;
4. this `ART_DIRECTION.md`;
5. `AI_CONTEXT/UI_RULES.md`;
6. `docs/ART_AND_AUDIO_PIPELINE_v0.25.0.md`;
7. `godot/assets/ASSET_MANIFEST.md`;
8. specialized asset documents;
9. historical draft notes.

A newer draft is not automatically more authoritative than an older approved asset.

---

## 7. Owner approval gate

No proposed visual asset becomes a production asset before explicit approval.

Required lifecycle:

```text
CONCEPT
↓
PREVIEW
↓
CONTEXT / intended use
↓
PROVENANCE / rights
↓
OWNER DECISION
↓
APPROVED
↓
TECHNICAL PREPARATION
↓
VALIDATION
↓
FINAL integration
```

Silence is not approval.

"Looks okay" from an AI reviewer is not owner approval.

---

## 8. Status vocabulary

Use these statuses consistently:

### IDEA
Only a concept.

### WORK
Draft or work in progress.

### REVIEW
Prepared for owner review.

### APPROVED
Owner approved visual direction/asset.

### FINAL
Approved and technically prepared production asset.

### REJECTED
Do not reuse as a direction unless explicitly revisited.

Do not label a generated draft `FINAL` merely because it has transparent background.

---

## 9. WORK vs FINAL folders

Where the external art library uses:

```text
WORK
FINAL
```

the meaning is strict:

- `WORK` = drafts, alternatives, intermediate exports;
- `FINAL` = approved production-ready assets.

An AI agent must not move a file from WORK to FINAL without approval.

---

# PART III — RIGHTS AND PROVENANCE

## 10. Project-owned generated art

The project contains owner-requested generated artwork tracked in:

```text
godot/assets/ASSET_MANIFEST.md
```

Approved production files should have:

- project path;
- asset description;
- source/provenance;
- checksum where the manifest convention requires it;
- rights status.

Do not remove provenance records during cleanup.

---

## 11. Rights status

Current project-owned generated artwork is treated as:

**all rights reserved for use as part of Echoes of Pythonia**

The manifest is not permission to redistribute raw artwork separately.

AI agents must not casually publish source-art packs.

---

## 12. Third-party art

Before integrating third-party art, record:

- creator;
- source URL;
- asset/store page;
- license;
- download/purchase date;
- price if paid;
- redistribution limits;
- attribution requirement;
- modified/unmodified status.

Never assume:

```text
downloadable = commercially usable
```

---

## 13. Paid assets

Do not autonomously:

- purchase;
- subscribe;
- spend credits;
- accept commercial license terms;
- publish paid source assets.

Paid asset integration requires explicit owner decision.

Git LFS does not make licensed content private.

---

# PART IV — CHARACTER PRODUCTION STANDARD

## 14. Default full-body rule

For standalone combat character/enemy assets, default to:

**full figure, head to toe**

Do not crop:

- feet;
- head;
- weapon;
- essential cape/tail/wings;

unless the specific asset category intentionally requires a portrait.

The full-body rule exists to support:

- combat staging;
- consistent scaling;
- future 2D rigging;
- future pose/animation extraction.

---

## 15. One subject per character asset

Default:

**one character per image**

Do not include:

- second random fighter;
- pet;
- unrelated silhouette;
- decorative people in background.

If a summon/familiar is part of the gameplay identity, it should normally have its own production layer/asset unless deliberately composed as one inseparable design.

---

## 16. Transparent standalone assets

Standalone combatants should normally be isolated on:

**real alpha transparency**

Not:

- white background;
- checkerboard baked into pixels;
- fake transparent pattern;
- blurred scenery.

Characters should be reusable in:

- combat;
- equipment/paperdoll;
- class presentation where appropriate;
- party UI;
- promotional compositions.

---

## 17. Combat idle

Default pose:

**combat idle**

The character should look:

- ready;
- alert;
- balanced;
- readable;
- not frozen in a T-pose;
- not already in a giant attack pose.

A good idle allows later animation into:

- attack;
- hit reaction;
- cast;
- dodge;
- block;
- death/downed.

---

## 18. Limb readability

For future 2D rigging:

- arms should not merge into torso;
- forearms should remain readable;
- hands should be visible where practical;
- legs should not completely overlap;
- weapons should have clear attachment logic;
- cape/hair should have separable masses;
- silhouette should remain understandable.

Avoid poses where every limb crosses every other limb.

---

# PART V — COMBAT ORIENTATION

## 19. Hero placement

Default side-view combat layout:

**Hero on the LEFT**

The hero generally faces:

**RIGHT**

toward the enemy.

---

## 20. Enemy placement

Enemies are presented on the:

**RIGHT**

and should face:

**LEFT**

toward the hero.

This is a critical production rule.

Do not generate enemies looking away from the hero unless the encounter intentionally requires it.

---

## 21. Body angle

Preferred enemy/hero angle:

- profile;
- side-oriented 3/4;
- readable torso rotation.

Avoid full frontal mugshot staging for standard side-view combat.

The face/eyes should support combat direction.

---

## 22. Do not mirror blindly

If a character contains:

- asymmetric armor;
- readable text/runes;
- weapon handedness;
- scars;
- signature accessories;

do not simply mirror a final asset without checking design continuity.

Generate/export the intended orientation where possible.

---

# PART VI — SCALE AND STAGING

## 23. Relative scale

Character scale should reflect:

- species;
- threat;
- narrative role.

But gameplay staging must remain readable.

Do not make a miniboss 10× taller than a hero if it destroys:

- UI;
- targeting;
- silhouette;
- animation space.

Scale can imply danger without becoming unusable.

---

## 24. Ground contact

Every combatant should have believable ground contact.

Avoid:

- floating feet;
- different invisible ground lines;
- shadow baked at wrong height;
- cropped ankles.

The current combat pipeline normalizes individual crop/stage framing without changing source proportions.

---

## 25. Breathing room

Leave transparent margin around:

- head;
- weapon tip;
- hands;
- feet;
- hair/cape.

Do not crop source art tightly to the exact opaque pixel bounds if animation will need movement.

---

# PART VII — HEROES AND CLASS IDENTITY

## 26. Neutral Seeker

Before level-5 permanent class selection, the player is visually represented by:

- female Seeker;
- male Seeker;

depending on selected presentation gender.

Do not display Pierrot or another class as the default hero before class choice.

---

## 27. Gender rule

Gender affects:

- appearance variant;
- player-facing grammatical form where relevant.

Gender does **not** change:

- stats;
- combat formulas;
- class power;
- equipment rules.

Do not encode gameplay differences into visual variants.

---

## 28. Variant consistency

Male/female variants of the same class should share:

- class identity;
- equipment tier;
- visual power level;
- silhouette logic;
- color family;
- framing.

They do not need identical clothing, but neither should look like a higher-tier specialization by accident.

---

## 29. Warrior

Base Warrior should communicate:

- physical durability;
- practical melee identity;
- shield/weapon compatibility;
- grounded fantasy.

Avoid over-ornamenting the base Warrior until it visually competes with Heavy Knight.

---

## 30. Heavy Knight

Heavy Knight is a separate progression identity.

Its art should communicate:

- greater defensive mass;
- stronger armor;
- controlled intimidation;
- tank/counter identity.

It must not silently replace base Warrior art before the specialization is unlocked.

Missing variants should remain explicit placeholders rather than borrowing the wrong hero identity.

---

## 31. Hunter

Hunter should communicate:

- mobility;
- ranged combat;
- practical field equipment;
- precision.

Avoid turning every Hunter into:

- hooded assassin;
- generic elf;
- overloaded ranger cliché.

Equipment should support readable bow/crossbow/technique presentation.

---

## 32. Mage

Mage should communicate:

- controlled magical power;
- intelligence;
- elemental/Splot identity;
- movement suitable for casting.

Avoid robes so complex that hands/arms disappear completely.

Hands are especially important for spell animation.

---

## 33. Pierrot

Pierrot is a visually striking adult character with a distinct Fate identity.

Approved palette direction includes:

- red;
- rose;
- pink;
- crimson.

Pierrot Fate effects use:

**pink-to-crimson glow**

Do not default Pierrot Fate magic to:

- violet;
- generic blue;
- gold-purple "luxury magic".

---

## 34. Pierrot class identity vs global palette

Pierrot's palette belongs to:

- Pierrot;
- Fate skills;
- Fate dice;
- class-specific effects.

It must not recolor:

- every enemy;
- battlefield;
- shared UI;
- world map.

Class color is local identity, not a global filter.

---

# PART VIII — ENEMY DESIGN

## 35. Region identity first

Every enemy should visually belong to its region.

Ask:

- what climate shaped it?
- what materials exist there?
- what culture/faction exists there?
- what weather is common?
- what terrain does it move through?
- what role does it play in encounter hierarchy?

Do not generate a generic monster and recolor it for five regions.

### Global enemy and boss production policy

Owner direction, 2026-09-12: **stylized fantasy game illustration** matching
current region maps/landscapes and approved class illustrations. This applies
to every new or regenerated enemy: ordinary monsters, elites, minibosses and
bosses, including dungeon creatures. It does not authorize retroactive bitmap
changes or gameplay changes. Existing realistic enemies preserve design identity,
not rendering-style precedence over this policy.

The following is the **single machine-readable policy** used by the reference
board, Art Studio generation and Autopilot visual review. Class references define
contours, grouped shading, material treatment and shape language; they do not
impose human anatomy, costumes or class palettes on monsters. Regional landscapes
and the current world map define environmental palette and motifs. ID masks are
not style art. Keep controlled detail without flattening the art into chibi or
featureless cartoons. Preserve species anatomy, including limbless creatures.

One subject, complete silhouette, real alpha, combat idle, enemy staged RIGHT and
facing LEFT toward the hero, readable separable limbs: these are mandatory.
Center the cutout on its own canvas with breathing room; do not right-align its
pixels just because the combat slot is on the right. Use a readable side/3/4 pose.

Reference paths below point at approved production art tracked in
`godot/assets/ASSET_MANIFEST.md`. Adding a region/scenario requires its approved
references and source mapping; do not guess a replacement or invent Region 6.
Generated briefs and cached Studio catalogs are derived outputs, never competing
sources of truth. Re-read this policy before every generation and review; a policy
or reference change invalidates an earlier visual approval. Owner approval is
still required for integration. Follow `docs/ART_AND_AUDIO_PIPELINE_v0.25.0.md`.

```autopilot-art-policy
{
  "version": 1,
  "style_rules": [
    "Wszystkie nowe i regenerowane potwory oraz bossowie: stylized fantasy game illustration, zgodna z aktualnymi mapami regionów i zatwierdzonymi ilustracjami klas.",
    "Wyraźnie mniej realistyczne materiały: bez fotorealistycznej mikrofaktury skóry, futra, kamienia, metalu i tkanin. Kontrolowana ilość detalu, czytelny kontur, duże grupy światła i cienia oraz shape language pasujący do bohaterów i map.",
    "Zachowaj regionalną tożsamość kolorystyczną i tematyczną. Referencje klas określają sposób rysowania, nie wymuszają ich stroju, anatomii ani palety na przeciwniku.",
    "Enemy asset: jedna postać, pełna nieucięta sylwetka, prawdziwe RGBA i całkowicie przezroczyste narożniki. Wycentruj postać bez zmiany proporcji; docelowy margines 5–8% płótna, co najmniej 5% z każdej strony całej sylwetki. Spokojna poza combat idle w prawym slocie, zwrócona w lewo ku bohaterowi. Przy kolejnej regeneracji Lodowego Kraba wymagane ujęcie 3/4 w lewo: oczy i szczypce prowadzą ku lewemu slotowi; samo odbicie frontalnej pozy nie wystarcza.",
    "Czytelne, rozdzielone kończyny i elementy wyposażenia do przyszłego riggingu 2D; bez nieuzasadnionych zrostów i zasłaniania ważnych stawów. Zachowaj anatomię gatunku, także stworzeń bez kończyn.",
    "Nowe referencje wymagają świadomego wyboru zatwierdzonych ilustracji; starszy realistyczny enemy art nie jest wzorcem stylu. Ta polityka nie zmienia istniejących bitmap ani mechanik.",
    "Zatwierdzone starsze enemy arty zachowują tożsamość gatunku, rekwizyty i anatomię, ale nie mają pierwszeństwa jako wzorce renderowania przy regeneracji. Nie kopiuj ich realistycznych faktur. Sylwetka jest wycentrowana na przezroczystym płótnie; prawy slot oznacza ustawienie w scenie, nie przesunięcie rysunku do prawej krawędzi."
  ],
  "review_rules": [
    "Porównaj enemy art z dołączonymi klasami, aktualną mapą i krajobrazem jego regionu: kontur, kształty, poziom detalu, cieniowanie i sposób przedstawiania materiałów.",
    "Zbyt realistyczna skóra, pojedyncze fotorealistyczne włosy futra, fotograficzne materiały lub wygląd renderu 3D są niespójnością wymagającą poprawy. Wskaż konkretny obszar oraz referencję, która potwierdza różnicę.",
    "Oceń zachowanie regionalnej palety i motywów; nie uznawaj celowych różnic gatunku, anatomii czy materiału za błąd stylu.",
    "Sprawdź pełną sylwetkę, jedną postać, combat idle, kierunek w lewo i separację kończyn na oryginalnym enemy PNG. Wymagaj wyniku bramki RGBA, przezroczystych narożników i minimum 5% marginesu każdej krawędzi, z rozmiarem płótna, alpha_bounds i SHA-256. Brak dotykania krawędzi nie dowodzi marginesu 5%. Piksele nie potwierdzają kompletnej anatomii: obejrzyj końce ogona, łap, szczypiec oraz stawy.",
    "Każdy nowy lub zmieniony enemy PNG musi mieć mapowanie scenario_enemies i scenario_regions, manifest scenariusza z enemy_source oraz review źródła i renderu. Brak mapowania, źródła, zgodnego pomiaru lub scenariusza obejmującego zmianę oznacza niepełne dowody i wyklucza PASS. Źródłowy enemy PNG jest przedmiotem kontroli, nie zatwierdzonym wzorcem stylu.",
    "Oddziel błędy samego assetu od problemów skali, zakotwiczenia lub oświetlenia sceny. Przegląd AI wskazuje poprawki i dowody, nie nadaje automatycznie akceptacji autora nowej grafice.",
    "Dla każdego kontrolowanego enemy PNG jawnie oceń: material_stylization, shape_detail_shading, regional_identity, full_body_single_subject, left_facing_idle, rigging_readability. Każda ocena wymaga PASS, FAIL lub NOT_ASSESSABLE i konkretnego dowodu (obraz + obszar). Realizm i spójność porównaj z nazwanymi wzorcami klasy i regionu. FAIL wymaga poprawki; NOT_ASSESSABLE wymaga dodatkowych dowodów i wyklucza PASS. Dawny niezmieniony asset to dług wizualny, nie zgoda na kopiowanie jego stylu do nowej wersji."
  ],
  "class_references": [
    "godot/assets/combat/heroes/hunter_male.png",
    "godot/assets/combat/heroes/mage_female.png"
  ],
  "world_references": [
    "godot/assets/world_map/pythonia_world_map_integrated.png"
  ],
  "region_references": {
    "twilight_plains": [
      "godot/assets/combat/backgrounds/twilight_plains_day.png"
    ],
    "black_forest": [
      "godot/assets/combat/backgrounds/black_forest_day.png"
    ],
    "silentwater_marshes": [
      "godot/assets/combat/backgrounds/silentwater_marshes_day.png"
    ],
    "ashen_borderlands": [
      "godot/assets/combat/backgrounds/ashen_borderlands_day.png"
    ],
    "ice_coast": [
      "godot/assets/combat/backgrounds/ice_coast_day.png"
    ]
  },
  "scenario_regions": {
    "combat_wolf": "twilight_plains",
    "combat_ice_crab": "ice_coast"
  },
  "scenario_enemies": {
    "combat_wolf": "godot/assets/combat/enemies/wolf.png",
    "combat_ice_crab": "godot/assets/combat/enemies/ice_crab.png"
  }
}
```


---

## 36. Ordinary enemy readability

Ordinary enemies should be:

- distinct;
- readable;
- memorable;
- less visually dominant than miniboss/boss tiers.

They still deserve intentional design.

Avoid making every normal enemy look like a raid boss.

---

## 37. Elite readability

An elite can use:

- stronger silhouette;
- subtle effect;
- variant detail;
- presentation framing.

Do not permanently bake giant `[ELITA]` text into enemy art.

Elite status is UI-owned.

---

## 38. Miniboss readability

Miniboss should feel meaningfully above ordinary enemies through:

- size;
- silhouette;
- weapon;
- costume;
- visual effect;
- pose;
- unique shape language.

But it should still preserve the region's visual language.

---

## 39. Boss readability

Boss art should support:

- immediate recognition;
- stronger stage presence;
- cinematic reveal;
- unique VFX;
- possible multi-phase animation.

Avoid simply scaling an ordinary enemy up.

---

# PART IX — CURRENT REGION ART DIRECTION

## 40. Zmierzchowe Równiny

Visual qualities:

- open fields;
- wind;
- dangerous roads/trails;
- transitional frontier feeling;
- stronger supernatural tone at night.

The day and night combat backgrounds are approved production assets.

Known approved combat identities include:

- Dziki Pies;
- Slime;
- Wilk;
- Spaczony Dzik;
- Bandyta;
- Przeklęty Strach na Wróble;
- Duch Równin;
- Nocny Strażnik;
- Myśliwy;
- Strażnik Natury.

---

## 41. Dziki Pies rule

Dziki Pies is a **dog**, not a wolf.

Do not drift the design toward:

- oversized wolf;
- werewolf;
- fantasy dire wolf.

The distinction is intentional.

---

## 42. Duch Równin

Established visual direction includes:

- spectral/rural supernatural feel;
- lantern as a readable prop;
- extended-hand interaction/attack potential.

The lantern should read clearly at gameplay scale.

---

## 43. Nocny Strażnik

Established accepted direction:

- no shield;
- torch in hand;
- sword sheathed;
- no hood;
- black cape.

Do not casually reintroduce a shield/hood.

---

## 44. Myśliwy

Established direction:

- younger hunter identity;
- crossbow/heavy leather concept in prior approved direction;
- readable ranged silhouette.

Use current approved production asset as primary reference.

---

## 45. Czarny Bór

Visual qualities:

- dense old forest;
- black resin;
- hanging/rope motifs;
- corrupted wildlife;
- cult traces;
- claustrophobic supernatural woodland.

Approved day and night backgrounds exist.

Known approved identities include:

- Jadowity Pająk;
- Kultysta Boru;
- Zgniły Rycerz;
- Spaczony Niedźwiedź;
- Czarny Jeleń;
- Zjawa Wisielca;
- Leśny Egzekutor.

---

## 46. Forest silhouette policy

Use shape language such as:

- branches;
- blackened bark;
- resin;
- ropes;
- old metal;
- ritual traces;
- corrupted anatomy.

Avoid turning the region into a generic green fantasy forest.

---

## 47. Mokradła Głuchej Wody

Visual qualities:

- black water;
- mist;
- drowned roads;
- sunken religious/order remnants;
- rotting structures;
- uncanny reflections;
- bell/chapel imagery.

Approved day and night combat backgrounds exist.

Known approved identities include:

- Błotny Pełzacz;
- Topielec;
- Bagienna Wiedźma;
- Kościany Krokodyl;
- Rycerz Zatopionego Zakonu;
- Trzcinowy Brodziec / current approved equivalent;
- Matka Głuchej Wody.

---

## 48. Swamp Witch

Established direction from production work:

- adult;
- young-adult rather than elderly hag;
- combat-ready;
- full body;
- readable 3/4 side orientation;
- no background.

Do not automatically turn "witch" into an old crone.

---

## 49. Popielne Pogranicze

Visual qualities:

- desert;
- ash;
- cracked ground;
- hot wind;
- exposed routes;
- ancient ruin traces;
- hostile elemental life.

Known approved identities include:

- Piaskowy Golem;
- Pustynna Harpia;
- Pustynny Wędrowiec;
- Kościopal;
- Czerwona Salamandra;
- Pożeracz Palenisk;
- Azhar, Władca Pustkowi.

---

## 50. Desert color policy

Avoid a single orange filter over everything.

Use variation through:

- pale sand;
- burned ash;
- dark rock;
- red heat;
- bone;
- faded fabrics;
- selective fire.

Enemy silhouettes should remain distinct against desert backgrounds.

---

## 51. Lodowe Wybrzeże

Visual qualities:

- black sea;
- ice;
- cliffs;
- shipwrecks;
- snow;
- ghost-mariner influence;
- northern danger.

Known content includes:

- Zamarznięty Rozbitek;
- Lodowy Niedźwiedź;
- Śnieżny Gryf;
- Lodowy Krab;
- Syrena Czarnego Morza;
- Widmo Kapitana Statku;
- Lewiatan Północy;
- Black Fleet content.

---

## 52. Ice-region color policy

Avoid making every object:

- cyan;
- blue glow;
- white.

Use contrast through:

- black water;
- dark wood;
- weathered cloth;
- steel;
- pale skin/fur;
- restrained frost accents.

This keeps ice effects special.

---

# PART X — BACKGROUND ART

## 53. Combat backgrounds

Battle backgrounds represent the expedition context that produced the encounter.

Selection may depend on:

- region;
- location/segment;
- day/night;
- weather;
- encounter type;
- dungeon;
- Rift.

Background choice is independent of active hero/enemy identity.

---

## 54. Surface expedition background

A surface encounter must use the correct regional environment.

Do not accidentally reuse:

- Zmierzchowe Równiny background in dungeon;
- generic forest for every region;
- city background for overworld boss.

---

## 55. Day/night pair

When creating a day/night pair from one approved composition:

**match the scene 1:1**

Preserve:

- camera;
- horizon;
- foreground;
- path;
- landmark;
- tree/building placement;
- crop.

Change:

- lighting;
- sky;
- lamps;
- moon/sun;
- atmosphere;
- fog;
- subtle effects.

Do not regenerate a different geography for the night version.

---

## 56. Background detail level

Backgrounds should support characters, not compete with them.

Avoid excessive micro-detail behind combat silhouettes.

Reserve strongest contrast/detail for:

- focal landmarks;
- story-relevant area;
- environment identity.

Leave readable combat zones.

---

## 57. Layering

Preferred future background structure may include:

- far background;
- midground;
- foreground;
- fog;
- light;
- weather;
- particles.

Use restrained parallax.

Do not create aggressive scrolling layers that distract from turn-based combat.

---

# PART XI — WORLD MAP ART

## 58. Current world-map production assets

Current approved world-map production includes:

- Pythonia continent/map;
- ocean extension;
- integrated map composite;
- technical region-ID map;
- Varenhold valley modules.

These are tracked in the asset manifest.

---

## 59. Map readability

World-map art should prioritize:

- region silhouette;
- geography;
- landmarks;
- routes;
- hierarchy.

Avoid:

- tiny decorative objects everywhere;
- excessively noisy terrain texture;
- borders hidden by illustration.

---

## 60. Modular map rule

World map must support Region 6 and future expansions without rebuilding all interaction logic.

Art and interaction should separate:

- visual map;
- region mask/IDs;
- hover;
- selection;
- labels;
- availability.

Do not bake hover glow or region names directly into base map pixels.

---

## 61. Region borders

Borders should be:

- readable;
- elegant;
- consistent;
- not thick comic outlines.

The hover system may strengthen the active boundary.

---

# PART XII — VARENHOLD / CITY ART

## 62. City direction

Varenhold should look like:

**a real city**

not:

- tiny village;
- isolated keep;
- cramped walled camp.

Important visual goals:

- larger city footprint;
- major central square;
- civic/town-hall presence;
- distinct services;
- enough urban density;
- readable routes.

---

## 63. Avoid overcrowding

More buildings do not automatically mean a better city.

Avoid:

- every street full of carts;
- hundreds of tiny props;
- dense roof noise;
- NPC crowds hiding service buildings.

The city must remain readable as an interactive game hub.

---

## 64. Modular Varenhold rule

Varenhold should remain expandable.

Current approved pipeline separates:

- base district/city plan;
- buildings/modules;
- interiors;
- NPC cutouts;
- UI hotspots.

Adding a service should not require regenerating the entire city painting.

---

## 65. Hotspot ownership

Do not bake into city background:

- clickable hitbox;
- hover state;
- locked icon;
- location label;
- quest indicator.

Those belong to Godot UI.

The art supplies landmarks.

---

## 66. Service distinction

Key places should have unique visual identity.

Examples:

- Guild;
- West Gate;
- Garran's forge;
- Oren's stall;
- inn;
- Mirela's workshop.

Players should gradually recognize them without relying only on labels.

---

# PART XIII — NPC ART

## 67. NPC framing

For reusable shop/interior NPCs, default to:

- full body or technically complete lower body even if later occluded;
- clean isolated cutout;
- pose appropriate to role;
- no random attached background panel.

If the counter hides the lower body in-game, the occlusion should come from the scene/counter layer.

---

## 68. Behind-counter rule

NPC should look **behind the counter**, not pasted in front.

Counter should plausibly cover:

- lower torso;
- legs;
- hands only when intended.

The crop must not make the NPC look amputated.

---

## 69. NPC role readability

A shop NPC should communicate role through:

- clothing;
- tools;
- posture;
- environment;
- props.

Avoid changing every NPC into a combat adventurer.

---

## 70. Quartermaster

The veteran Quartermaster / Guild head should read as:

- experienced retired adventurer;
- logistical authority;
- mentor;
- not an active combat-class showcase.

Do not replace that identity with random heroic armor.

---

# PART XIV — ITEM ART

## 71. Item icon principle

Production item source art contains:

**only the object**

No baked:

- frame;
- rarity color;
- text;
- quantity;
- level;
- selection glow;
- price;
- background card.

UI owns those layers.

---

## 72. Alpha item art

Item icons should use genuine transparency and clean edges.

Object must remain readable at small size.

Avoid:

- dramatic wide environment lighting;
- complex background;
- scattered decorative particles beyond object identity.

---

## 73. Item footprint

Current visual-grid footprints include baseline categories such as:

- 1×1;
- 1×2;
- 2×2.

Footprint is presentation metadata.

Do not change gameplay carry-weight rules because an icon occupies more cells visually.

---

## 74. Equipment visual consistency

Equipment of similar progression tier should have coherent:

- material quality;
- ornament level;
- silhouette complexity.

Do not make a level-2 sword look like a legendary relic unless that contrast is narratively intentional.

---

## 75. Materials

Crafting material icons should be:

- quickly identifiable;
- visually distinct;
- simple enough at small scale.

Avoid every material being a glowing crystal.

---

## 76. Books

Mastery and Path books should look valuable but category-readable.

Use:

- cover shape;
- emblem;
- material;
- magical detail.

Do not bake the full title into the book texture.

---

# PART XV — SKILL CARD ART

## 77. Card composition

Approved skill-card source art uses:

**3:4 composition**

Current golden-slice source size:

**1086×1448 PNG**

The source artwork is opaque unless the specialized pipeline says otherwise.

---

## 78. Skill art owns the action, not the UI

Skill card art should communicate:

- weapon;
- projectile;
- element;
- movement;
- impact;
- result.

It should not bake:

- card frame;
- skill name;
- Mana cost;
- cooldown/state;
- rarity;
- dice count;
- button highlight.

Godot owns those layers.

---

## 79. Avoid repeating hero portrait

Skill art should usually depict the mechanic rather than showing the same hero face 20 times.

Examples:

- Fate Lance;
- shield and incoming weapons;
- arrow volley;
- elemental impact;
- dodge silhouette.

---

## 80. Pierrot skill palette

Pierrot cards/effects may use:

- magenta;
- rose;
- crimson.

Do not apply one global magenta overlay to every card.

Effect identity should determine palette.

---

## 81. Unique art per skill

If a skill has no approved art:

**show a named placeholder**

Do not silently borrow art from another skill.

Wrong art is worse than an explicit placeholder.

---

# PART XVI — TRANSPARENCY WORKFLOW

## 82. Mandatory two-pass extraction

Generated character/item cutouts follow:

### Pass 1
Generate subject against a clean simple background.

### Pass 2
Run dedicated background extraction to real alpha.

Do not trust a generated checkerboard.

A checkerboard may be baked pixels.

---

## 83. Alpha validation

Before approval/integration, transparent raster should be checked for:

- RGBA channel;
- transparent corners;
- residual background;
- fake checkerboard;
- hidden RGB under zero alpha;
- bright low-alpha fringe;
- damaged outline;
- missing body/weapon pixels.

---

## 84. Edge quality

Avoid:

- white halo;
- green-screen halo;
- dark matte fringe;
- semi-transparent checkerboard pixels.

Edges should remain clean over:

- light background;
- dark background;
- saturated background.

---

## 85. Hair and fur

Hair/fur edges may use controlled soft alpha.

But do not leave:

- opaque box;
- giant blurred cloud;
- shredded noisy edge from bad extraction.

---

# PART XVII — 2D RIGGING READINESS

## 86. Rigging target

Many characters/enemies should remain suitable for future 2D rigging.

Potential animation set:

- breathing/idle;
- attack;
- hit;
- cast;
- block;
- dodge;
- downed;
- death;
- special skill.

---

## 87. Layer planning

When moving from flat illustration to rigged source, consider separable layers:

- head;
- torso;
- upper/lower arms;
- hands;
- upper/lower legs;
- feet;
- hair groups;
- cape/cloth;
- weapon;
- shield;
- accessories.

Not every character requires identical segmentation.

---

## 88. Flat production PNG remains valid

Do not discard approved flat character art simply because a rigged version is planned.

Flat art may remain:

- fallback;
- UI portrait source;
- loading asset;
- production reference.

Rigging should preserve the approved design.

---

## 89. Redraw rule

If rigging requires a redraw, the redraw must preserve:

- identity;
- costume;
- colors;
- proportions;
- silhouette;
- face;
- equipment.

It is not permission for an AI agent to redesign the character.

---

# PART XVIII — 3D AND HYBRID

## 90. 3D is selective

Use 3D when it solves a presentation need.

Good candidates:

- Fate dice;
- cinematic camera moves;
- selected character animation studies;
- reusable environmental props;
- special transitions.

Do not create expensive 3D versions of every 2D asset without a clear production reason.

---

## 91. 3D character conversion

A 3D interpretation of an approved 2D character must preserve:

- facial identity;
- silhouette;
- costume;
- palette;
- proportions;
- class role.

The 2D approved art is the reference.

---

## 92. Anime-styled 3D

If 3D characters are used, prefer rendering/stylization that fits the 2D anime-fantasy world.

Avoid:

- photoreal skin;
- realistic PBR contrast that clashes with UI;
- generic mannequin faces;
- plastic toy materials.

---

## 93. Cinematics

Future cinematic scenes may use:

- 2D cut animation;
- rigged 2D;
- 3D;
- hybrid 2.5D.

Choose per scene.

The target is high-impact anime-style presentation, not a requirement that all gameplay become cinematic.

---

# PART XIX — PIERROT DICE

## 94. Fate dice ownership

Dice visuals receive:

**already resolved die faces**

from the Fate Engine.

Visual physics must never determine gameplay outcomes.

---

## 95. Dice counts

One reusable system supports:

- 1d6;
- 2d6;
- 3d6.

Composition:

- one centered die;
- two balanced dice;
- three dice in a readable triangular arrangement.

---

## 96. Dice animation language

Suggested sequence:

```text
anticipation
→ throw
→ tumble
→ settle on prescribed result
→ result emphasis
→ optional manipulation/reroll visualization
→ combat resolution
```

The visual system follows domain results.

---

## 97. Fate VFX

Fate dice/effects use:

**pink → rose → crimson**

with controlled energy.

Avoid default violet-gold magic.

---

# PART XX — VFX

## 98. VFX purpose

VFX should communicate:

- hit;
- element;
- class identity;
- status;
- critical;
- block;
- dodge;
- heal;
- Fate manipulation.

Do not add particles only because empty space exists.

---

## 99. Readability over spectacle

Turn-based combat gives room for attractive effects, but the player must still see:

- target;
- damage;
- current HP;
- action result.

Effects should resolve rather than leave permanent visual fog.

---

## 100. Element distinction

Element families should have distinct motion/shape, not only recolor.

Examples:

- fire → heat/embers;
- frost → crystal/snap;
- wind → directional streak/pressure;
- earth → weight/fracture;
- water → flow/splash.

Do not make all elements the same explosion with a different hue.

---

## 101. Status VFX

Persistent status effect should use restrained indicators.

Do not surround every affected combatant with a huge permanent particle system.

---

# PART XXI — WEATHER ART

## 102. Weather belongs to world

Weather affects environment, not class palette.

Current weather identities include:

- Sunny;
- Storm;
- Frost;
- Wind;
- Aurora.

---

## 103. Storm

Storm presentation may use:

- darker sky;
- rain;
- lightning;
- wet highlights;
- wind.

Avoid constant lightning flashes that impair readability.

---

## 104. Frost

Frost weather should feel different from permanently snowy regions.

Use:

- cold haze;
- frost edges;
- breath;
- altered ground/light.

Do not turn every region into Lodowe Wybrzeże.

---

## 105. Wind

Wind should be visible through:

- grass;
- cloth;
- dust;
- leaves;
- directional particles.

Avoid only using a blue swirl icon.

---

## 106. Aurora

Aurora is rare and special.

Use:

- distinctive sky/light;
- subtle supernatural effect;
- readable reward/danger identity.

Do not flood the full combat screen with neon color.

---

# PART XXII — AUDIO-VISUAL COHESION

## 107. Art prepares for audio

Visual identity should leave room for:

- weapon sounds;
- spell audio;
- ambient layers;
- UI sounds;
- voice lines.

Do not rely on visual clutter to communicate everything.

---

## 108. Region audio alignment

Future audio should mirror regional visual language.

Examples:

- forest → wood/rope/wind;
- swamp → water/bells/mist ambience;
- desert → wind/ash/stone;
- ice coast → sea/ice/shipwreck.

---

# PART XXIII — ASSET NAMING AND PATHS

## 109. Production filenames

Prefer stable descriptive snake_case filenames.

Examples:

```text
wild_dog.png
blackwood_executioner.png
twilight_plains_day.png
mage_female.png
```

Avoid:

```text
final_final_v7_REAL.png
newone2.png
image_12345.png
```

Versioning belongs to source/work archive when needed.

---

## 110. Stable production path

When an asset is integrated, choose a canonical path and avoid moving it repeatedly.

Current production tree includes categories such as:

```text
godot/assets/combat/
godot/assets/ui/
godot/assets/world_map/
godot/assets/city/
```

Use the current manifest/tree before inventing a new top-level layout.

---

## 111. Enemy folder strategy

Current production combat enemies are centralized under:

```text
godot/assets/combat/enemies/
```

Do not create a competing region-folder structure in production unless a deliberate reorganization is approved.

External WORK libraries may organize by region for convenience.

---

## 112. Source vs production

Keep source files separate where appropriate.

Examples:

- PSD/Krita/Blender/rig source;
- generation draft;
- extraction source;
- production PNG;
- Godot import.

Do not force all heavyweight source files into the public Git repository.

---

# PART XXIV — ASSET TRACKING

## 113. Manifest update

When a new production asset is approved and integrated, update:

```text
godot/assets/ASSET_MANIFEST.md
```

according to its current convention.

Include accurate provenance.

---

## 114. External tracker

Where the external art library still uses:

```text
ART_DIRECTION.md
ASSET_TRACKER.md
```

update the relevant status after approval.

Track at least:

- asset name;
- filename;
- destination;
- status;
- variant;
- notes.

---

## 115. Do not overwrite historical decisions

If a draft was rejected:

- mark rejected;
- keep enough note to avoid accidentally selecting it later.

Do not rewrite history to make every latest file appear approved.

---

# PART XXV — CURRENT APPROVED PRODUCTION FOUNDATION

## 116. Combat backgrounds

The manifest currently contains approved/production combat backgrounds for:

- Zmierzchowe Równiny — day/night;
- Czarny Bór — day/night;
- Mokradła Głuchej Wody — day/night;
- Popielne Pogranicze — day/night;

plus additional assets as the production pass expands.

Use the manifest, not memory, to determine whether a final background actually exists.

---

## 117. Current approved enemy foundation

The manifest already tracks a substantial approved static enemy roster, including early regions and Popielne Pogranicze.

Examples include:

- wild_dog;
- slime;
- wolf;
- boar;
- bandit;
- cursed_scarecrow;
- plains_spirit;
- night_guard;
- hunter;
- nature_guardian;
- venom_spider;
- forest_cultist;
- rotting_knight;
- corrupted_bear;
- black_hart;
- gallows_wraith;
- blackwood_executioner;
- bog_crawler;
- drowned_dead;
- swamp_witch;
- bone_crocodile;
- mist_walker;
- sunken_knight;
- drowned_mother;
- sand_golem;
- desert_harpy;
- desert_wanderer;
- boneburner;
- red_salamander;
- hearth_devourer;
- azhar.

This list is descriptive, not a substitute for the current manifest.

---

## 118. Hero matrix

Current production direction supports:

- neutral Seeker male/female;
- Warrior male/female;
- Hunter male/female;
- Mage male/female;
- Pierrot male/female;

with specialization art treated separately when applicable.

Do not reuse one gender/class image as a silent fallback for a different identity.

---

# PART XXVI — REVIEW CHECKLIST FOR CHARACTER ART

## 119. Character review

Reviewer should check:

- full body visible;
- correct orientation;
- correct side of combat;
- correct class/enemy identity;
- one subject;
- no background;
- real alpha if required;
- no accidental crop;
- readable hands/feet;
- readable weapon;
- pose suitable for combat idle;
- proportions consistent with project;
- silhouette distinct;
- not hyper-detailed;
- lighting coherent;
- color palette appropriate;
- no random extra accessories;
- no unexplained glow;
- no anatomy/limb errors;
- rigging potential.

For every new/regenerated enemy, apply the machine-readable review rules in
section 35 and compare the original cutout AND real combat captures against its
approved class/map/region references. Report material stylization, shape/detail/
shading, regional identity, full-body single-subject composition, left-facing
idle and rigging readability separately with image/area evidence. Excessive
realism or stylistic mismatch requires changes. Missing evidence is NOT_ASSESSABLE,
never PASS. Pixel gates cannot judge artistic coherence. Review of unchanged
legacy assets records visual debt, not authorization to regenerate them.

---

## 120. Face review

Reviewer should check:

- both eyes/face structure are coherent for the chosen angle;
- expression fits role;
- face is not photorealistic if body is stylized;
- age matches design;
- gender presentation matches approved variant;
- no random scars/tattoos added without design reason.

---

## 121. Costume review

Reviewer should check:

- costume makes sense in world;
- region/class identity is readable;
- complexity is animation-friendly;
- material hierarchy is coherent;
- no random floating cloth;
- no impossible straps;
- no decorative objects with no attachment point.

---

# PART XXVII — REVIEW CHECKLIST FOR BACKGROUNDS

## 122. Background review

Reviewer should check:

- correct region;
- correct day/night;
- correct camera;
- usable combat staging;
- clear depth;
- no unreadable clutter;
- no random modern object;
- no baked UI;
- no characters unless intentionally part of background;
- day/night pair alignment;
- weather overlay compatibility.

---

## 123. City review

Reviewer should check:

- city reads as city;
- central space is strong;
- service buildings are distinguishable;
- no excessive black margins;
- not overcrowded;
- hotspots can be aligned;
- day/night pair remains same geometry.

---

## 124. World-map review

Reviewer should check:

- region silhouettes;
- border clarity;
- readable geography;
- modular expansion area;
- no labels baked if UI owns labels;
- no excessive micro-detail;
- map remains usable behind hover masks.

---

# PART XXVIII — REVIEW CHECKLIST FOR ITEMS/SKILLS

## 125. Item review

Reviewer should check:

- object only;
- transparent background;
- small-size readability;
- correct category;
- no frame/text/quantity;
- clean edge;
- appropriate visual tier;
- no excessive empty canvas;
- footprint-compatible silhouette.

---

## 126. Skill art review

Reviewer should check:

- mechanic is immediately understandable;
- 3:4 composition works;
- no card UI baked in;
- no Mana/text baked in;
- class/effect palette is correct;
- not just repeated portrait;
- distinguishable from neighboring skills;
- no wrong dice count or outcome baked into generic skill art.

---

# PART XXIX — ANIMATION REVIEW

## 127. Animation preserves gameplay clarity

Animation must not:

- change hit timing mechanically;
- add random damage;
- roll outcome;
- delay input excessively;
- move UI hitboxes unpredictably.

Presentation follows already-resolved game state.

---

## 128. Idle animation

Idle should be:

- subtle;
- loopable;
- not distracting.

Examples:

- breathing;
- cloth movement;
- weapon settling;
- small stance shift.

Avoid large repeated head/body movement every second.

---

## 129. Attack animation

Attack should:

- clearly communicate source;
- travel toward target;
- return to idle cleanly;
- preserve combat direction.

Do not end with character facing away unless intentional.

---

## 130. Hit reaction

Hit reaction should be:

- readable;
- brief;
- proportional.

Avoid huge knockback for every 1-damage hit.

---

# PART XXX — AI ART GENERATION RULES

## 131. Prompt must include production constraints

When asking an image model for combat character art, include the essential constraints:

```text
single character
full body, head to toe
isolated
combat idle
side/3-quarter combat orientation
correct facing direction
clear limbs
animation-ready
anime-fantasy style
no background
no text
no frame
```

Then add character-specific details.

For enemies and bosses, do not hand-maintain these as a separate prompt template.
Build the current brief and original-image references from section 35 using
`scripts/build_art_reference_board.py --region <region_id> --output <review.png>`.
Art Studio uses the same policy automatically, even for an older saved request.
Never use an old realistic enemy as the rendering reference for a regeneration.

---

## 132. Do not overload prompts

Do not add hundreds of contradictory adjectives.

Prioritize:

1. subject identity;
2. silhouette;
3. pose/orientation;
4. costume/weapon;
5. region style;
6. rendering style;
7. production constraints.

---

## 133. Generate alternatives when design is uncertain

For a new enemy/hero concept, 2–3 purposeful alternatives are useful.

Variants should change meaningful design choices, such as:

- silhouette;
- armor shape;
- weapon;
- age;
- supernatural intensity.

Do not produce ten recolors of the same image.

---

## 134. Approved direction narrows variation

Once owner selects a version:

- future revisions should preserve chosen identity;
- only requested attributes should change.

Do not redesign everything during a small correction.

---

## 135. "1:1" instruction

When the owner requests a day/night or correction version **1:1**, interpret it as:

- same dimensions;
- same camera;
- same composition;
- same body/objects;
- same positions;
- only requested changes.

Do not regenerate a loosely similar interpretation.

---

# PART XXXI — REJECTION PATTERNS

## 136. Reject: generic AI fantasy

Reject when asset shows:

- random filigree everywhere;
- excessive gold;
- generic glowing runes;
- ornate armor without function;
- hyper-detailed painterly texture;
- no relation to region.

---

## 137. Reject: wrong orientation

Reject enemy combat art facing right when it should face left toward hero.

Do not "fix in engine" by mirroring if asymmetry makes the design incorrect.

---

## 138. Reject: fake transparency

Reject checkerboard background baked into PNG.

---

## 139. Reject: cropped body

Reject if:

- feet are cut;
- weapon is cut;
- head/hair is cut;

for a full-body production asset.

---

## 140. Reject: inconsistent style

Reject if one enemy suddenly looks:

- photoreal;
- 3D render;
- watercolor;
- comic cel-shaded;

while the approved class/map references use the established anime-fantasy
illustration style. Neighbouring legacy enemies are not the rendering benchmark.
Judge actual material treatment and grouped shading, not just a style label;
intentional regional colors/species differences are not a style violation.

---

## 141. Reject: random glow

Not every magical/corrupted enemy needs:

- red eyes;
- purple aura;
- glowing sword.

Use glow when it communicates a real design element.

---

## 142. Reject: over-detail for rigging

Reject if dozens of tiny armor pieces make animation unreadable and provide little identity.

---

## 143. Reject: baked UI

Reject if source image contains:

- price;
- name;
- rarity frame;
- HP bar;
- click marker;
- quest icon.

---

# PART XXXII — ART INTEGRATION PROCEDURE

## 144. Before integration

Developer must confirm:

- owner-approved status;
- correct filename;
- correct destination;
- acceptable dimensions;
- acceptable file size;
- provenance;
- alpha/edge quality if required;
- no conflicting existing production asset.

---

## 145. Integrate without gameplay changes

Adding visual art must not change:

- enemy stats;
- drop chance;
- class mechanics;
- quest state;
- encounter chance;
- save schema.

Presentation lookup must remain independent from gameplay rules.

---

## 146. Presentation catalog

Where `CombatPresentationCatalog` or another presentation catalog owns art lookup:

- update the catalog;
- do not hardcode image path in combat-domain logic.

Missing art should use named placeholder behavior.

---

## 147. Validation

Run relevant asset gates.

Current repository includes validation for areas such as:

- item assets;
- skill-card assets;
- modular city assets;
- broader full validation through `scripts/check.ps1`.

Do not claim production-ready integration before validation.

---

## 148. Visual smoke test

After integration, check the actual Godot scene.

Validate:

- scale;
- crop;
- ground contact;
- orientation;
- alpha;
- overlap with UI;
- 1920×1080;
- 1280×720.

An asset can pass file validation and still look wrong in-game.

---

## 149. Manifest update

Production integration should update the asset manifest in the same reviewed change where the project convention requires it.

Do not leave final assets untracked by provenance.

---

# PART XXXIII — LARGE SOURCE FILES

## 150. Blender/source files

Large Blender source files may exceed normal GitHub limits.

Do not push large WIP source files blindly.

Current local ignore includes the Pierrot mesh-repair draft area.

Use:

- local WORK storage;
- external asset storage;
- deliberately configured LFS only after approval;

depending on production need.

---

## 151. Production exports vs sources

A final game may need:

```text
.glb / .png / .webp / .ogg
```

while the editable source may remain outside the public repository.

Keep a clear source/export relationship in documentation.

---

# PART XXXIV — REGION 6 ART

## 152. Region 6 is not predesigned by this file

Region 6 is planned as the final main region in the current direction.

Its:

- biome;
- palette;
- enemy roster;
- boss;
- dungeon;
- music;
- city/settlement;

must not be invented as canonical by an autonomous Developer agent.

The agent may propose concepts.

Owner selects direction.

---

## 153. Region 6 consistency check

Any proposal should answer:

- how is it visually different from regions 1–5?
- what colors does it own?
- what shapes/materials does it own?
- what enemy silhouettes belong there?
- what is its landmark?
- how does it avoid generic fantasy repetition?

---

# PART XXXV — FUTURE PRODUCTION PRIORITIES

## 154. Completion order

Current long-term production intent:

1. ensure every important item has art;
2. complete character/enemy visual coverage;
3. add animation;
4. add skill visuals/VFX;
5. add voice work where appropriate;
6. add soundtrack and ambience;
7. add cinematic presentation;
8. polish release-quality consistency.

This is directional, not permission to skip gameplay bugs.

---

## 155. Golden slices

Before scaling a new art/animation system to every asset:

- prove it on one high-quality slice;
- review;
- refine;
- automate;
- then expand.

Examples:

- one complete combat scene;
- one rigged enemy;
- one animated hero;
- one VFX family;
- one item category.

Avoid multiplying a flawed pipeline across 100 assets.

---

# PART XXXVI — REVIEWER ART VERDICT FORMAT

## 156. Reviewer response

For an art asset/revision:

```text
VERDICT
APPROVED_FOR_OWNER_REVIEW
or
CHANGES_REQUESTED

IDENTITY
- ...

COMPOSITION
- ...

ORIENTATION
- ...

STYLE
- ...

TECHNICAL
- alpha / crop / dimensions / edge

RIGGING READINESS
- ...

IN-GAME FIT
- ...

BLOCKERS
- ...

OPTIONAL POLISH
- ...
```

Only the owner can mark final creative approval.

---

## 157. Reviewer does not redesign by stealth

If an asset has one issue:

```text
enemy faces wrong direction
```

Reviewer should not also demand:

- new armor;
- different weapon;
- changed age;
- changed color palette;

unless those are genuine project-direction violations.

Review should be scoped.

---

# PART XXXVII — DEVELOPER ART REPORT

## 158. Developer integration report

For an integrated asset:

```text
ASSET
<display name>

STATUS
OWNER APPROVED / FINAL

SOURCE
<provenance>

PRODUCTION FILE
<path>

USED BY
<scene/catalog>

TECHNICAL CHECKS
- dimensions
- alpha
- file size
- validation script

VISUAL CHECK
- 1920×1080
- 1280×720

MANIFEST
UPDATED / NOT APPLICABLE

GAMEPLAY IMPACT
NONE
```

---

# PART XXXVIII — FINAL ART PRINCIPLE

## 159. Core principle

Every visual asset should help answer:

**What is this character/place/object, where does it belong, and how should the player feel when they see it?**

The project should not become visually impressive at the cost of identity.

The target is:

**cohesive anime-fantasy art + dark world atmosphere + readable gameplay silhouettes + animation-ready production + strict owner approval.**

When in doubt:

**preserve the approved identity, simplify visual noise, keep silhouettes readable, and never let presentation rewrite gameplay.**
