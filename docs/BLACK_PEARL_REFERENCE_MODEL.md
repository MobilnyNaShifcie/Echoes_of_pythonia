# Black Pearl — reference-driven 3D model

Source: `godot/assets/items/materials/black_pearl.png` (unchanged inventory icon).
Builder: `godot/ui/screens/black_market/black_pearl_reference_model.gd`.

The previous plain sphere and generic pedestal are replaced by a closed rounded
pearl, five separately traced curved gold fittings, three raised gold edges and
a soft contact shadow. The approved illustration supplies fixed UV textures,
with the same restrained painted-light / scene-light balance as the elixir.
Border UVs are sampled inside the opaque image to avoid transparent PNG fringe
colors. No new image or camera-facing item card is generated.

The reference height is normalized to the elixir's height; both use the same
1.5x counter display scale, preserving their different shapes and the existing
perspective between display positions. Both have a projected foot anchor on
their leather pad. Dragging moves the existing 3D viewport/world, not a duplicate
inventory sprite. The contact shadow hides while held and returns on cancellation.
The price sign remains on the counter. Purchase, stock quantity and inventory
artwork are unchanged. Other goods and price-sign positions are not modified.

This is a single-reference reconstruction for the counter camera, just like
the elixir. The unseen rear reuses front artwork and the texture contains painted
reflections. It is not a uniquely textured 360-degree asset or an optical pearl
simulation. A turned preview is included to make that limitation inspectable.

## Verification

Use the isolated helper from the project root; it never instantiates the app or
a save service, and never accesses player saves:

```powershell
.tools/godot/Godot_v4.7.1-stable_win64_console.exe --path godot --resolution 1920x1080 -s res://tools/render_black_pearl_reference_preview.gd
```

Outputs under `output/`:

- `black_pearl_reference_counter.png`, `black_pearl_reference_held.png`
- `black_pearl_reference_comparison.png`
- `black_pearl_reference_front.png`, `black_pearl_reference_turned.png`
- `black_pearl_reference.glb`: solid meshes with the embedded approved texture;
  the Godot-specific contact-shadow shader is excluded from the portable export.

Regression tests cover geometry, original texture references, fixed UVs under
rotation, matching model height, 1.5x display size, live dragging/cancellation,
the original two-pearl purchase lot, and cleanup after purchase. Existing elixir,
price-sign and transaction tests remain in place.
