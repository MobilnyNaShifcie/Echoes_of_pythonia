# Manuskrypt Szybkiego Ostrza — reference-driven 3D

Item: `mastery_attack_speed_book`.
Source: `godot/assets/items/books/mastery_attack_speed_book.png` (1199 × 1312).
Builder: `godot/ui/screens/black_market/swift_blade_manuscript_reference_model.gd`.

The primitive box book is replaced for this item only. The model uses the same
reference-textured solid-mesh method and painted-light / scene-light balance as
the Grandmaster Elixir and Black Pearl. No billboard or replacement inventory
image is generated.

There are 47 solid meshes: leather covers, a thick parchment block, rounded
binding spanning both covers, four curved raised spine bands, silver corner
guards and studs, three raised blade motifs with wind inlays, a leather clasp
and metal buckle, domed rivets, paper-edge reliefs, and a folded crimson ribbon.
The separate soft contact shadow is hidden while the book is held.

The reference dimensions are calibrated against the elixir before the book is
rotated into its physical resting pose. Both covers lie parallel to the table;
the bottom cover rests at Y=0.018, the binding stays above Y=0.012, and the
bookmark folds onto the table. A rounded rectangular contact shadow follows
the book's footprint. The lying silhouette is naturally foreshortened rather
than stretched to the height of an upright bottle. Clockwise front-face winding
keeps the cover and fittings outward-facing from this low tabletop angle.
All three detailed items retain the same 1.5× display scale, with the existing
per-slot counter perspective and projected contact anchor. A wider hit area
keeps the upper book and its corners grabbable. Dragging moves the existing
viewport/world/model, not an inventory sprite or duplicate. A cancelled drag
returns the book to its pad; a successful purchase removes the display model
and adds the original manuscript item to the inventory.

The price, daily rotation, item behavior, inventory artwork and other goods are
unchanged. The four price boards now hang on the counter's front, outside the
leather mats. Each has two cord meshes, metal eyelets and lip mounts. They stay
in place during item dragging, update negotiated prices and show SPRZEDANE after
a purchase. Source-art coordinates anchor the rope mounts through window resizing.

## Scope of the reconstruction

This is a single-illustration reconstruction for the fixed market camera, as
with the elixir and pearl. UVs are fixed on real geometry and remain unchanged
under rotation, but the unseen rear reuses the illustration and its painted
lighting. It is not a uniquely textured 360-degree scan. A turned preview is
included for inspection of the geometry and that limitation.

## Verification

Run the isolated scene helper from the project root:

```powershell
.tools/godot/Godot_v4.7.1-stable_win64_console.exe --path godot --resolution 1920x1080 -s res://tools/render_swift_blade_manuscript_preview.gd
```

It instantiates only a standalone market with an in-memory test session; it
never starts the application or a save service and never accesses player saves.

Outputs under `output/swift_blade_manuscript_reference*`:

- `_counter.png`, `_held.png`: actual market view and live dragging.
- `_comparison.png`: inventory reference alongside the 3D model.
- `_front.png`, `_turned.png`: transparent model renders.
- `.glb`: 47 solid meshes and embedded original artwork; the Godot-specific
  contact-shadow shader is omitted from the portable export.

Targeted regression suite:

```powershell
.tools/godot/Godot_v4.7.1-stable_win64_console.exe --headless --path godot -s res://addons/gut/gut_cmdln.gd -gdir=res://tests -gselect=test_market_ -gexit
```

The 16-test market suite covers the three reference models, texture identity and
fixed UVs, the book's horizontal covers and table contact, outward-facing cover
normals, framing, model reuse, dragging/return, purchase cleanup and original
inventory quantity. Hanging-sign tests cover four aspect ratios, cord/eyelet
geometry, front-lip mounting, negotiated/sold prices and staying in place during
dragging. `output/black_market_hanging_prices_detail.png` shows the actual counter
with the resting book and hanging signs.
