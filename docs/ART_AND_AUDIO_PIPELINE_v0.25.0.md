# Art and audio pipeline — v0.25.0

## Approved presentation direction

Echoes of Pythonia will use an illustrated dark-fantasy 2D/2.5D presentation:

- node-based world travel and illustrated location hubs,
- side-view, turn-based combat,
- layered backgrounds with restrained parallax, weather, light, and particles,
- character portraits and readable combat silhouettes,
- a midnight-blue, charcoal, tarnished-gold, and class-accent UI palette,
- selective 3D or 2.5D presentation where it adds value, such as Pierrot's dice.

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
