# Grandmaster Elixir — reference-driven 3D study

Source: `godot/assets/items/consumables/grandmaster_elixir.png`.
Builder: `godot/ui/screens/black_market/elixir_reference_model.gd`.

The counter uses a closed bottle volume with measured cross-sections, fixed UVs
from the approved image, separate raised fittings, cords, and a contact shadow.
It is not a billboard or a new generated illustration. Other goods are unchanged.

This is a single-view reconstruction optimized for the existing counter camera.
The original painted illumination is retained in the texture. The unseen rear
reuses mirrored front detail; this is not physically simulated transparent glass
and not a fully authored unique 360-degree texture set. Check the rotated view
before deciding whether it is suitable for another camera.

Reproduce previews and the self-contained GLB from the project root:

```powershell
.tools/godot/Godot_v4.7.1-stable_win64_console.exe --path godot --resolution 1920x1080 -s res://tools/render_elixir_reference_preview.gd
```

The helper replaces the app save service before entering the scene tree. It must
never use the default save service: opening the market emits an autosave signal.
The market-routing test uses the same no-disk strategy.

Outputs in `output/`:

- `elixir_reference_comparison.png`: source vs rendered mesh.
- `elixir_reference_counter.png`: actual in-game size.
- `elixir_reference_front.png`, `elixir_reference_turned.png`: angle checks.
- `grandmaster_elixir_reference.glb`: 8 meshes, embedded source texture; contact
  shadow excluded because it is a Godot-specific shader.
