# Art and audio pipeline — v0.25.0

## Approved presentation direction

Echoes of Pythonia will use an anime-fantasy 2D/2.5D presentation with a dark,
serious world:

- node-based world travel and illustrated location hubs,
- side-view, turn-based combat,
- layered backgrounds with restrained parallax, weather, light, and particles,
- clean character portraits and readable combat silhouettes with restrained
  costume and armor detail,
- a dark, flat UI with class-specific accents instead of ornate gold filigree,
- selective 3D or 2.5D presentation where it adds value, such as Pierrot's dice.

The visual target should feel intentionally drawn and animation-ready. Avoid
hyper-detailed painterly rendering, excessive armor ornament, ubiquitous gold
outlines, and other patterns associated with generic generated fantasy art.
Pierrot's Fate magic uses a pink-to-crimson glow rather than violet and gold.

Pierrot is presented as a charismatic, visually striking adult woman. Her
costume and Fate effects may use red, rose, and pink accents, but a class palette
must not recolor the battlefield, enemies, or shared interface. Those elements
have independent art direction and color ownership.

This character and combat-art direction is approved as the target. The preview
itself is not a production asset and must not be imported directly.

The preferred combat action layout uses illustrated vertical skill panels
grouped at the bottom center, including compact resource indicators. Their
shared frame belongs to the game UI theme; character-specific colors belong to
skill artwork and effects.

The action panel is not one fixed row used in every combat state. Its contents,
panel type, layout, and available interactions follow the current turn phase and
the actions exposed by the migrated terminal mechanics. Skill selection, basic
actions, item use, target selection, paired skills, and other contextual choices
may use different presentations while sharing one coherent UI language.

## Fate dice presentation

One reusable dice presentation system supports the existing 1d6, 2d6, and 3d6
Pierrot skills. It receives already resolved die faces from the migrated Fate
Engine and never determines combat outcomes through visual physics.

The presentation uses the same dice model, timing language, pink-to-crimson Fate
effect, and audio family for every count. Spawn positions adapt to one centered
die, two balanced dice, or three dice in a readable triangular arrangement. The
animation sequence can expose existing rerolls and Fate manipulations without
changing their rules: anticipation, throw, tumble, settle on prescribed faces,
result emphasis, optional manipulation or reroll, and combat resolution.

## Expedition-driven battle environments

A battle backdrop must represent the expedition that produced the encounter.
Region, current segment or location, time, weather, and encounter type select
the environment independently of the active character and enemy. This rule is
recorded now, but its implementation belongs to the later combat migration
slice.

## Modular city rule

Varenhold and later settlements are authored as expandable maps in Godot, not
as single generated panoramic illustrations. Buildings and services are
separate reusable scene elements placed on a controlled layout. Adding a new
city function must mean adding or changing a building node without regenerating
the rest of the city. City art must therefore come from an approved coherent
modular set or purpose-built components.

The presentation must serve the existing terminal game's pacing and rules. It
must not turn combat into real-time action or silently change progression,
balance, encounter, skill, expedition, economy, or save behavior.

## Source of truth

The Python v0.24.7 implementation, its regression tests, changelog, versioned
design documents, and player-facing descriptions are the executable design
specification. Migration means translating those mechanics into typed GDScript
and Godot scenes. A deliberate mechanic change requires separate approval.

## Author approval gate

No proposed visual or audio asset becomes a production Godot asset before the
project owner approves it. Every proposal follows this lifecycle:

1. **Preview:** show an image, animation capture, or playable audio sample
   outside the production asset tree.
2. **Context:** explain where it would be used and what can still be changed.
3. **Provenance:** identify whether it is original, generated, free, or paid.
4. **License and cost:** provide the source, license, current price, and relevant
   redistribution limits for third-party assets.
5. **Decision:** record approval, requested revision, rejection, or temporary
   placeholder status.
6. **Integration:** only an approved asset is copied into `godot/assets` and
   connected to scenes or resources.

Silence is not approval. Rejected previews remain outside the game and should
not shape later assets unless the owner asks to revisit them.

## Paid and third-party assets

- Never purchase or download a paid asset on the owner's behalf without an
  explicit decision.
- Always present at least the intended use, seller, price, license, and a viable
  alternative before requesting a purchase decision.
- A public Git repository must not contain raw paid assets when their license
  forbids source redistribution. Git LFS does not make a public file private.
- Every accepted external asset needs an entry in a future asset manifest with
  its author, source URL, version or download date, license, and attribution.
- Prefer assets whose style can be maintained across the full content scope,
  not isolated pieces that only look good on one screen.

## Production priorities

1. Establish one approved visual target for combat, Varenhold, character UI,
   inventory, and the world map.
2. Build a golden vertical slice using one region and one complete turn-based
   encounter.
3. Validate Pierrot's dice presentation without changing Fate Engine results.
4. Expand the approved visual language to other classes, enemies, items, and
   regions.
5. Add final music, ambience, UI sounds, and combat effects through the same
   preview and approval process.

## Implemented presentation foundation

The combat screen now has a placeholder-only composition matching the approved
direction: a full battlefield area, separate large hero and enemy slots, a
central VFX/dice stage, a top turn strip, compact combatant HUDs, a centered
action dock, and a collapsible combat log.

`CombatantVisual` is the presentation boundary for combatant artwork. It can
show a temporary placeholder, a static `Texture2D`, or an instantiated animated
`PackedScene`. Combat rules do not depend on the selected presentation mode, so
static approved artwork can be connected first and replaced by rigged scenes
later without changing the combat engine.

The first approved static integration covers the Region 1 golden combat slice:

- Zmierzchowe Równiny select their day or night background from the current
  session time for surface expedition and region-boss combat,
- Wilk uses its approved transparent combat illustration,
- combatants without an integrated asset keep a named placeholder,
- the hero asset is selected by `character_class_code`; Pierrot is never used
  as a generic or default hero,
- dungeon and prologue contexts do not reuse the surface background by
  accident.

`CombatPresentationCatalog` owns presentation lookup independently from combat
rules. Adding a new static asset must not consume RNG or change an encounter.
The approved files, provenance, rights status, and checksums are recorded in
`godot/assets/ASSET_MANIFEST.md`.

The Region 1 static combat pass integrates Dziki Pies, Slime, Wilk, Spaczony
Dzik, Bandyta, Przeklęty Strach na Wróble, Duch Równin, Nocny Strażnik,
Myśliwy, Strażnik Natury, and the Pierrot hero. Each integrated combatant uses
an independent crop and normalized stage frame, keeping its proportions and
ground contact stable without editing the source bitmap. Pierrot is selected
only for the `pierrot` class; the other three hero classes never borrow her
artwork.

## Combat HUD 2.0 placeholder contract

The golden combat shell now reserves stable presentation zones for the target
layout without requiring final artwork:

- the top queue identifies the player and opponent and exposes the current
  combat round,
- compact combatant HUDs include portrait slots, resources, and live effect
  summaries,
- the lower center uses horizontally scrollable, directly actionable skill
  cards so additional skills never overlap or shrink existing cards,
- the lower side HUDs expose class-specific resources and current target state,
- basic attack, defense, consumable, escape, Mage double weave, collapsible
  combat log, and Pierrot dice remain functional,
- cards and class resources are selected from the actual player class; Pierrot
  presentation never appears for another class.

The round display is presentation-only and counts consumed player action
cycles. The ordinary combat engine still resolves the player and immediate
enemy response synchronously; the HUD does not invent an initiative mechanic.
Portraits, card illustrations, status icons, animations, and audio remain
placeholders subject to the approval gate.
