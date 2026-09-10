#!/usr/bin/env python3
"""Generate pixel masks that follow the painted borders of the world map.

The polygons in WorldRegionMap remain the coarse spatial prior and click fallback.
A marker-controlled watershed snaps their visible masks to the strong painted seams
and coastlines in the source illustration.
"""

from __future__ import annotations

import argparse
import heapq
import re
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter


REGION_ORDER = (
    "twilight_plains",
    "black_forest",
    "silentwater_marshes",
    "ashen_borderlands",
    "ice_coast",
)

REGION_SEEDS = {
    "twilight_plains": ((330, 430), (260, 570), (410, 650)),
    "black_forest": ((620, 190), (770, 280), (850, 380)),
    "silentwater_marshes": ((1130, 220), (1300, 260), (1430, 340)),
    "ashen_borderlands": ((690, 610), (820, 700), (930, 760)),
    "ice_coast": ((1210, 610), (1370, 570), (1300, 730)),
}


def parse_polygons(script_path: Path) -> dict[str, list[tuple[int, int]]]:
    source = script_path.read_text(encoding="utf-8")
    polygon_block_start = source.index("var _region_polygons")
    polygons: dict[str, list[tuple[int, int]]] = {}
    for index, region_id in enumerate(REGION_ORDER):
        start = source.index(f'"{region_id}":', polygon_block_start)
        end = (
            source.index(f'"{REGION_ORDER[index + 1]}":', start)
            if index + 1 < len(REGION_ORDER)
            else source.index("\n}\n\nvar _available_region_ids", start)
        )
        points = [
            (int(x), int(y))
            for x, y in re.findall(r"Vector2\((\d+),\s*(\d+)\)", source[start:end])
        ]
        if len(points) < 3:
            raise RuntimeError(f"Could not parse polygon for {region_id}")
        polygons[region_id] = points
    return polygons


def dilate(mask: np.ndarray, iterations: int) -> np.ndarray:
    result = mask.copy()
    for _ in range(iterations):
        padded = np.pad(result, 1, mode="constant")
        result = np.maximum.reduce(
            (
                padded[1:-1, 1:-1],
                padded[:-2, 1:-1],
                padded[2:, 1:-1],
                padded[1:-1, :-2],
                padded[1:-1, 2:],
            )
        )
    return result


def erode(mask: np.ndarray, iterations: int) -> np.ndarray:
    return ~dilate(~mask, iterations)


def make_spatial_priors(
    size: tuple[int, int], polygons: dict[str, list[tuple[int, int]]], scale: int
) -> tuple[list[np.ndarray], np.ndarray]:
    width, height = size
    priors: list[np.ndarray] = []
    union = np.zeros((height, width), dtype=bool)
    for region_id in REGION_ORDER:
        canvas = Image.new("L", size, 0)
        points = [(round(x / scale), round(y / scale)) for x, y in polygons[region_id]]
        ImageDraw.Draw(canvas).polygon(points, fill=255)
        mask = np.asarray(canvas, dtype=np.uint8) > 0
        union |= mask
        priors.append(dilate(mask, max(8, round(52 / scale))))
    ocean_allowed = ~erode(union, max(6, round(34 / scale)))
    return priors, ocean_allowed


def edge_cost(image: Image.Image) -> np.ndarray:
    softened = image.filter(ImageFilter.GaussianBlur(radius=2.2))
    rgb = np.asarray(softened, dtype=np.float32) / 255.0
    luminance = rgb[..., 0] * 0.299 + rgb[..., 1] * 0.587 + rgb[..., 2] * 0.114
    gradient = np.zeros(luminance.shape, dtype=np.float32)
    for axis in (0, 1):
        forward = np.abs(np.diff(rgb, axis=axis)).max(axis=2)
        light_forward = np.abs(np.diff(luminance, axis=axis))
        combined = forward * 0.72 + light_forward * 0.28
        if axis == 0:
            gradient[:-1, :] = np.maximum(gradient[:-1, :], combined)
            gradient[1:, :] = np.maximum(gradient[1:, :], combined)
        else:
            gradient[:, :-1] = np.maximum(gradient[:, :-1], combined)
            gradient[:, 1:] = np.maximum(gradient[:, 1:], combined)

    # Painted borders are warm and narrow; this raises their watershed ridge
    # without mistaking the broad ochre plains for a boundary by itself.
    warm = np.clip((rgb[..., 0] - rgb[..., 2]) * 1.4, 0.0, 1.0)
    gold_line = warm * np.clip(gradient * 7.0, 0.0, 1.0)
    return np.clip(gradient * 4.6 + gold_line * 0.9, 0.0, 1.0)


def watershed(
    costs: np.ndarray, allowed_regions: list[np.ndarray], ocean_allowed: np.ndarray, scale: int
) -> np.ndarray:
    height, width = costs.shape
    label_count = len(REGION_ORDER) + 1
    allowed = np.stack([ocean_allowed, *allowed_regions])
    labels = np.full((height, width), -1, dtype=np.int8)
    best = np.full((height, width), np.inf, dtype=np.float32)
    heap: list[tuple[float, int, int]] = []

    def add_seed(x: int, y: int, label: int) -> None:
        if 0 <= x < width and 0 <= y < height:
            index = y * width + x
            best[y, x] = 0.0
            labels[y, x] = label
            heapq.heappush(heap, (0.0, index, label))

    border_step = max(1, round(5 / scale))
    for x in range(0, width, border_step):
        add_seed(x, 0, 0)
        add_seed(x, height - 1, 0)
    for y in range(0, height, border_step):
        add_seed(0, y, 0)
        add_seed(width - 1, y, 0)

    seed_radius = max(3, round(12 / scale))
    for label, region_id in enumerate(REGION_ORDER, start=1):
        for seed_x, seed_y in REGION_SEEDS[region_id]:
            center_x, center_y = round(seed_x / scale), round(seed_y / scale)
            for y in range(center_y - seed_radius, center_y + seed_radius + 1):
                for x in range(center_x - seed_radius, center_x + seed_radius + 1):
                    if (x - center_x) ** 2 + (y - center_y) ** 2 <= seed_radius**2:
                        add_seed(x, y, label)

    while heap:
        path_cost, index, label = heapq.heappop(heap)
        y, x = divmod(index, width)
        if path_cost != float(best[y, x]) or labels[y, x] != label:
            continue
        for nx, ny in ((x - 1, y), (x + 1, y), (x, y - 1), (x, y + 1)):
            if not (0 <= nx < width and 0 <= ny < height) or not allowed[label, ny, nx]:
                continue
            next_cost = max(path_cost, float(costs[ny, nx]))
            if next_cost + 1e-6 < float(best[ny, nx]):
                best[ny, nx] = next_cost
                labels[ny, nx] = label
                heapq.heappush(heap, (next_cost, ny * width + nx, label))

    # Spatial priors cover the complete map. This fallback only handles rare
    # pixels isolated by the strict allowed zones.
    unassigned = labels < 0
    labels[unassigned & ocean_allowed] = 0
    for label, prior in enumerate(allowed_regions, start=1):
        labels[unassigned & prior] = label
    return labels


def save_masks(
    labels: np.ndarray,
    source: Image.Image,
    target_size: tuple[int, int],
    output_dir: Path,
    preview_path: Path | None,
) -> None:
    output_dir.mkdir(parents=True, exist_ok=True)
    preview = source.convert("RGBA")
    preview_colors = (
        (151, 178, 191, 92),
        (114, 164, 150, 92),
        (115, 158, 177, 92),
        (149, 132, 132, 92),
        (142, 170, 194, 92),
    )
    for label, region_id in enumerate(REGION_ORDER, start=1):
        alpha = Image.fromarray(np.where(labels == label, 255, 0).astype(np.uint8), mode="L")
        alpha = alpha.resize(target_size, Image.Resampling.NEAREST)
        rgba = Image.new("RGBA", target_size, (255, 255, 255, 0))
        rgba.putalpha(alpha)
        rgba.save(output_dir / f"{region_id}_mask.png", optimize=True)
        if preview_path is not None:
            color = Image.new("RGBA", target_size, preview_colors[label - 1])
            color.putalpha(alpha.point(lambda value: round(value * 0.36)))
            preview = Image.alpha_composite(preview, color)
    if preview_path is not None:
        preview_path.parent.mkdir(parents=True, exist_ok=True)
        preview.save(preview_path)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--map", type=Path, required=True)
    parser.add_argument("--script", type=Path, required=True)
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("--preview", type=Path)
    parser.add_argument("--scale", type=int, default=2)
    args = parser.parse_args()

    source = Image.open(args.map).convert("RGB")
    working_size = (source.width // args.scale, source.height // args.scale)
    working = source.resize(working_size, Image.Resampling.LANCZOS)
    polygons = parse_polygons(args.script)
    priors, ocean_allowed = make_spatial_priors(working_size, polygons, args.scale)
    labels = watershed(edge_cost(working), priors, ocean_allowed, args.scale)
    save_masks(labels, source, source.size, args.output, args.preview)


if __name__ == "__main__":
    main()
