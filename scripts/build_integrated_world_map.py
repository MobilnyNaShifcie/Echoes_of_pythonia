#!/usr/bin/env python3
"""Build the single world-map canvas and its pixel-aligned region ID texture."""

from __future__ import annotations

import argparse
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter


CANVAS_SIZE = (2560, 1440)
REGION_IDS = {
    "twilight_plains": 51,
    "black_forest": 102,
    "silentwater_marshes": 153,
    "ashen_borderlands": 204,
    "ice_coast": 255,
}


def _center_offset(canvas_size: tuple[int, int], image_size: tuple[int, int]) -> tuple[int, int]:
    return (
        (canvas_size[0] - image_size[0]) // 2,
        (canvas_size[1] - image_size[1]) // 2,
    )


def _load_region_masks(mask_dir: Path) -> dict[str, Image.Image]:
    return {
        region_id: Image.open(mask_dir / f"{region_id}_mask.png").getchannel("A")
        for region_id in REGION_IDS
    }


def _edge_guard(size: tuple[int, int], feather: int) -> np.ndarray:
    width, height = size
    y, x = np.ogrid[:height, :width]
    distance = np.minimum.reduce(
        (
            np.broadcast_to(x, (height, width)),
            np.broadcast_to(width - 1 - x, (height, width)),
            np.broadcast_to(y, (height, width)),
            np.broadcast_to(height - 1 - y, (height, width)),
        )
    )
    return np.clip(distance / float(feather), 0.0, 1.0)


def build_map(
    source_map: Path,
    ocean: Path,
    mask_dir: Path,
    output: Path,
) -> tuple[int, int]:
    continent = Image.open(source_map).convert("RGB")
    ocean_image = Image.open(ocean).convert("RGB").resize(CANVAS_SIZE, Image.Resampling.LANCZOS)
    offset = _center_offset(CANVAS_SIZE, continent.size)

    masks = _load_region_masks(mask_dir)
    land_union = Image.new("L", continent.size, 0)
    for mask in masks.values():
        land_union = Image.fromarray(
            np.maximum(np.asarray(land_union), np.asarray(mask)).astype(np.uint8), mode="L"
        )

    # Copy the land and its immediate coastline exactly, then dissolve only the
    # surrounding source water into the larger ocean. No rectangular source
    # edge remains in the final canvas.
    protected_coast = land_union.filter(ImageFilter.MaxFilter(21))
    soft_coast = protected_coast.filter(ImageFilter.GaussianBlur(45))
    alpha_data = np.maximum(np.asarray(protected_coast), np.asarray(soft_coast)).astype(
        np.float32
    )
    alpha_data *= _edge_guard(continent.size, 24)
    composite_alpha = Image.fromarray(np.round(alpha_data).astype(np.uint8), mode="L")
    ocean_image.paste(continent, offset, composite_alpha)
    output.parent.mkdir(parents=True, exist_ok=True)
    ocean_image.save(output, optimize=True)
    return offset


def build_region_ids(mask_dir: Path, output: Path, offset: tuple[int, int]) -> None:
    masks = _load_region_masks(mask_dir)
    result = Image.new("L", CANVAS_SIZE, 0)
    occupied = np.zeros((CANVAS_SIZE[1], CANVAS_SIZE[0]), dtype=bool)
    result_data = np.zeros((CANVAS_SIZE[1], CANVAS_SIZE[0]), dtype=np.uint8)
    offset_x, offset_y = offset

    for region_id, region_code in REGION_IDS.items():
        # A five-pixel inset keeps the hover fill strictly inside the painted seam.
        inset = masks[region_id].filter(ImageFilter.MinFilter(11))
        mask_data = np.asarray(inset) >= 128
        target = np.zeros_like(occupied)
        height, width = mask_data.shape
        target[offset_y : offset_y + height, offset_x : offset_x + width] = mask_data
        target &= ~occupied
        result_data[target] = region_code
        occupied |= target

    result = Image.fromarray(result_data, mode="L").convert("RGB")
    output.parent.mkdir(parents=True, exist_ok=True)
    result.save(output, optimize=True)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--map", type=Path, required=True)
    parser.add_argument("--ocean", type=Path, required=True)
    parser.add_argument("--masks", type=Path, required=True)
    parser.add_argument("--output-map", type=Path, required=True)
    parser.add_argument("--output-ids", type=Path, required=True)
    args = parser.parse_args()

    offset = build_map(args.map, args.ocean, args.masks, args.output_map)
    build_region_ids(args.masks, args.output_ids, offset)
    print(f"Built {args.output_map} and {args.output_ids}; continent offset={offset}")


if __name__ == "__main__":
    main()
