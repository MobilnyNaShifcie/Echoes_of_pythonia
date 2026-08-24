# Item asset golden slice

## Contract

Pierrot remains the visual quality master for character art. Item artwork uses
the same dark anime-fantasy direction, but each file contains only the item.
The UI owns the slot frame, rarity treatment, stack quantity, labels, selection
state and tooltips.

Production item icons must:

- be 32-bit RGBA PNG files with a genuine alpha channel,
- have transparent, RGB-clean pixels outside the artwork,
- contain no checkerboard, baked background, frame, text or quantity,
- keep a minimum transparent safety margin around the visible object,
- avoid bright low-alpha fringe along cutout edges,
- use a consistent three-quarter presentation, neutral key light and detail
  level suitable for a 68-pixel inventory cell.

## Footprints and files

| Footprint | Production canvas | Golden-slice items |
| --- | --- | --- |
| 1×1 | 512×512 | `leather_hood`, `weak_healing_potion`, `whetstone`, `wolf_fur`, `wolf_fang`, `slime_gel`, `mastery_strength_book` |
| 1×2 | 512×1024 | `starter_sword`, `training_shield` |
| 2×2 | 1024×1024 | `worn_leather_armor` |

Files use the stable catalog identifier as the filename and live below
`res://assets/items/<category>/<item_id>.png`. The corresponding
`ItemDefinition` resource owns the texture reference.

The earlier folded pelt draft is reserved as a possible future processed or
tanned-pelt item. It is deliberately not mapped to `wolf_fur` and is not part of
the production golden slice.

## Acceptance contexts

The same `ItemDefinition.icon` is rendered through the reusable inventory slot
in all required contexts:

1. backpack,
2. equipped paperdoll slots,
3. Oren's shop,
4. Garran's forge,
5. Guild storage,
6. icon-aware hover tooltip,
7. combat reward/loot presentation.

Mirela's crafting grid also resolves the icon and footprint of the recipe
output, so recipes do not introduce a second item-art contract.

## Automated gate

`scripts/normalize-item-assets.ps1` creates the approved production canvases
without stretching the art and clears hidden RGB from fully transparent pixels.

`scripts/check-item-assets.ps1` fails when a golden-slice asset is missing, has
the wrong dimensions, lacks alpha, is empty, touches the safety edge, contains
hidden RGB under zero alpha, or crosses the bright low-alpha fringe threshold.
It is part of `scripts/check.ps1`, so the asset gate runs with the regular full
project validation.
