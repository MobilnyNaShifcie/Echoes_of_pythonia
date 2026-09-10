# Hearth Core and Azhar Sigil — Black Market reference models

The two old procedural placeholders are replaced by closed, textured geometry.
Original inventory images, item IDs, prices, loot sources and delivery rules are
unchanged. Hanging price signs and the previously approved manuscript pose are
untouched.

## Art and construction

- Hearth Core (`hearth_core`, 9500 gold): the Hearth Devourer's volcanic core,
  with angular obsidian, two molten apertures, five separate bone bindings,
  hollow suspension ring, four chain links, sun charm and faceted amber.
- Azhar Sigil (`azhar_sigil`, 12000 gold): Azhar's heavy basalt seal, with a thick
  rear, nine broken gold frame sections, raised crest, inset faceted red gem,
  small diamond studs and a hollow handle behind the right edge. The missing
  lower-right frame section remains broken.

`artifact_reference_mesh.gd` builds closed subdivided solids, conforming relief,
hollow oval tubes and faceted jewels. Fixed UVs reference the existing PNGs;
neither object is a camera-facing billboard. Godot clockwise winding is used
for outward normals. Border samples move into opaque texture pixels to avoid
cutout-color fringes.

This is a single-reference textured reconstruction, not a 360-degree scan.
Unseen rear surfaces reuse the illustration; the source's painted lighting is
retained, with restrained scene lighting added. There are no particle effects.

Both models use the elixir/pearl reference height and 1.5 display scale while
preserving their distinct proportions. Their actual lowest solid point rests
at Y=0.018 and the contact shadow at Y=0.004. No generic plinth is added.
The existing live-view drag path moves the same world, hides the mat shadow,
restores it on cancellation and clears geometry after a successful purchase.

## Verification

`test_market_artifact_reference.gd` covers geometry, original UV/materials,
grounding, apparent scale, framing, live dragging, cancellation, hanging signs,
unchanged prices and inventory delivery. Run it with the other `test_market_`
tests. `tools/render_core_and_sigil_preview.gd` uses an isolated in-memory
6 September 2026 delivery and exports counter, held, comparison and turned
views, plus GLBs. It never creates the main app or reads/writes player saves.
