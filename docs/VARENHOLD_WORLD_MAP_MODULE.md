# Western Varenhold valley

The owner provisionally accepted the two-city valley preview on 2026-09-03.
The live world-map scene now draws `varenhold_valley_two_cities_v2.png` as a
separate TextureRect at `(100, 350, 850, 850)` in the existing 2560×1440 map
coordinate system. The base continent and both valley source illustrations are
preserved. The old `varenhold_valley_v1.png` and old region IDs are retained;
the live interaction now uses `pythonia_region_atlas_v2.png` (see below).

The approved artwork matches the current city panorama: pale fortifications,
blue-grey roofs and Varenhold's central clocktower, plus the smaller distant
fortified city at the mountain foothills. Farmland connects them. The eastern
ochre terrain overlaps the Twilight Plains over a broad land connection.

## Rendering and interaction

- The source is RGB, not a true-alpha PNG. `varenhold_valley.gdshader` removes
  its pale neutral backdrop and reduces pale fringes at runtime. The raw source
  is preserved byte-for-byte, rather than flattening the new territory into the map.
- The technical atlas incorporates the module's colour-key coverage and a
  separate political boundary through the eastern foothills. Both art layers
  and CPU picking use that same atlas. The eastward art fade is independent:
  the Plains can highlight across the feathered artwork without an abrupt seam.
- Only the foreground Varenhold polygon returns to the existing city hub. Its
  hover light follows that polygon, not the entire rectangular asset.
- The surrounding valley highlights separately and has no combat-region entry.
  Clicking farmland or the distant settlement does not open Varenhold. The second
  settlement has no invented name, quests, or navigation.
- All map layers and hit coordinates share the same zoom and pan transform.
  Locked expeditions still cannot navigate to the city through this hotspot.
- The five combat-region definitions remain unchanged. Highlighting no longer
  uses the old five-pixel mask erosion/dilation workaround.

## Exact region atlas (2026-09-03)

`scripts/build_exact_world_regions.py` generates only technical data. It does
not repaint or flatten the approved illustrations. Shared gold border paths
are traced once at 1672×941 source resolution using image-guided shortest paths
inside manually reviewed corridors, then placed at `(444, 249)` on the 2560×1440
world canvas. Coast segments without a painted gold ridge use silhouette guides.
Neighbouring polygons reuse the same path in reverse, avoiding competing edges.

The RGB atlas stores region ID in red (ocean 0, valley 26, original regions
51/102/153/204/255), painted-border protection in green, and the new visible
valley/Plains seam in blue. Blue is extracted directly from adjacent valley and
Plains IDs and drawn as a mouse-ignoring layer above both illustrations. Its
coastal ends cannot extend beyond the actual shared land boundary.

`region_highlight.gdshaderinc` is shared by the base map and valley shaders.
ID sampling is nearest-neighbour, without `source_color`, mipmaps, or lossy
compression. There is no dilation, inset, blur, or independently placed hit
polygon for a region. City entry remains the foreground city's local polygon.

## Verification

`test_world_map_interaction.gd` and `test_varenhold_valley_module.gd` cover
real mouse hover/click events, scenery versus city navigation, original regions,
transparent and blended edges, locking, pan and resize, and the real app's return
to the city hub. Input fixtures notify the SubViewport that the mouse entered.

`build/render_varenhold_live_validation.gd` renders the production scene with
the project theme at 1600×900, 1920×1080 and 2560×1080. Output stays under
`build/world-map-validation`; use an isolated APPDATA profile when running it.

`test_world_region_atlas.gd` additionally checks the shared materials, dense
CPU picking against the atlas after resize/pan, complete valley-border coverage,
and non-blocking overlay placement. `scripts/validate_world_region_render.py`
compares real Godot hover renders against the picking IDs for all six areas;
this detects GPU/CPU transform mismatches and glow leaking across region IDs.
Visual review is still required to judge the paths against the illustration.

Generation prompts and the approved preview are retained under
`output/imagegen/varenhold-region-preview`. No regeneration was performed during
integration, and no player saves were modified.
