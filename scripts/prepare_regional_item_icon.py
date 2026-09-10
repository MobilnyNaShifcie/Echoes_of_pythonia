"""Authorized local background extraction; never calls a network/model service.

Keeps source illustrations intact, normalizes transparent PNGs to inventory scale,
and writes dark/light previews so alpha edges can be reviewed before integration.
"""
import argparse
import json
from pathlib import Path

import numpy as np
from PIL import Image, ImageFilter, ImageDraw


def dilate(mask, radius=2):
    return np.asarray(Image.fromarray(mask.astype(np.uint8) * 255).filter(
        ImageFilter.MaxFilter(radius * 2 + 1))) > 0


def extend_colors(rgb, known, steps=10):
    """Nearest Manhattan-neighbour colour propagation, restricted to unknowns."""
    color = rgb.astype(np.float32).copy()
    valid = known.copy()
    for _ in range(steps):
        total = np.zeros_like(color)
        count = np.zeros(valid.shape, np.float32)
        for axis, shift in ((0, 1), (0, -1), (1, 1), (1, -1)):
            neighbour = np.roll(valid, shift, axis=axis)
            samples = np.roll(color, shift, axis=axis)
            if axis == 0:
                neighbour[0 if shift == 1 else -1, :] = False
            else:
                neighbour[:, 0 if shift == 1 else -1] = False
            total += samples * neighbour[:, :, None]
            count += neighbour
        take = (~valid) & (count > 0)
        color[take] = total[take] / count[take, None]
        valid[take] = True
    return color


def cutout(source, key_shadows=False, background_seeds=()):
    image = Image.open(source).convert('RGBA')
    rgba = np.asarray(image).copy()
    if rgba[:, :, 3].min() < 250:
        return image, 'preserved_existing_alpha'
    rgb = rgba[:, :, :3].astype(np.float32)
    r, g, b = rgb.transpose(2, 0, 1)
    corners = np.concatenate([rgb[:24, :24].reshape(-1, 3),
                              rgb[-24:, -24:].reshape(-1, 3)])
    key = np.median(corners, axis=0)
    if key[0] > 210 and key[2] > 210 and key[1] < 75:
        background = (r > 220) & (b > 220) & (g < 65)
        if key_shadows:
            # Opt-in for reviewed assets whose generated backdrop has pink
            # shadows. Preserve desaturated purple leather and metal.
            background |= (np.minimum(r, b) > 90) & (g < 40) & (g < np.minimum(r, b) * .3)
        mode = 'magenta_local_cutout'
    elif key.min() > 210 and np.ptp(key) < 18:
        # Exterior-connected neutral backdrop only. Review each result on
        # light/dark surfaces: outlined pale bone/feathers stay enclosed,
        # but unoutlined white silhouettes need regeneration with chroma-key.
        background = (rgb.min(axis=2) > 205) & (np.ptp(rgb, axis=2) < 20)
        # Preserve bright reflected details INSIDE the item. Only remove the
        # neutral candidate component connected to the outside of the image.
        # fromarray can expose a read-only numpy buffer; Pillow floodfill then
        # silently returns on pixel assignment. Detach before mutating it.
        connected = Image.fromarray(background.astype(np.uint8) * 255).copy()
        ImageDraw.floodfill(connected, (0, 0), 128, thresh=0)
        # Explicitly reviewed enclosed holes only; never blanket-remove white
        # highlights or pale fur. Seeds are normalized source-image coordinates.
        for fx, fy in background_seeds:
            if not (0 <= fx < 1 and 0 <= fy < 1):
                raise ValueError('Background seed must be normalized to [0, 1)')
            point = (int(fx * image.width), int(fy * image.height))
            if connected.getpixel(point) not in (128, 255):
                raise ValueError(f'Background seed {fx, fy} is not neutral backdrop')
            ImageDraw.floodfill(connected, point, 128, thresh=0)
        background = np.asarray(connected) == 128
        mode = 'neutral_checker_exterior_only'
        if background_seeds:
            mode = 'neutral_checker_reviewed_holes'
    else:
        raise ValueError(f'Unsupported opaque backdrop {key}; review/regenerate, do not guess')
    if background.mean() < .1 or background.mean() > .97:
        raise ValueError('Unexpected foreground/background coverage')
    unknown = dilate(background, 3) & ~background
    foreground = ~dilate(background, 3)
    fg = extend_colors(rgb, foreground)
    bg = extend_colors(rgb, background)
    delta = fg - bg
    alpha = np.ones(background.shape, np.float32)
    alpha[background] = 0
    estimate = np.sum((rgb - bg) * delta, axis=2) / np.maximum(
        np.sum(delta * delta, axis=2), 1)
    alpha[unknown] = np.clip(estimate[unknown], 0, 1)
    # Unmatte boundary RGB instead of leaving pink/white pixels in the fringe.
    edge = unknown & (alpha > .01)
    clean = rgb.copy()
    clean[edge] = (rgb[edge] - bg[edge] * (1 - alpha[edge, None])) / alpha[edge, None]
    rgba[:, :, :3] = np.clip(clean, 0, 255).astype(np.uint8)
    rgba[:, :, 3] = np.rint(alpha * 255).astype(np.uint8)
    rgba[rgba[:, :, 3] <= 3] = 0
    return Image.fromarray(rgba), mode


def despill_combat_edges(illustration):
    """Remove residual key-colour fringe only along the transparent silhouette.

    Region 5 has no magenta materials; keep interior colours, pale fur and
    actual cyan highlights intact. This is local key cleanup, not repainting.
    """
    pixels = np.asarray(illustration).copy()
    rgb = pixels[:, :, :3].astype(np.int16)
    edge = dilate(pixels[:, :, 3] < 16, 10) & (pixels[:, :, 3] > 0)
    excess = np.minimum(rgb[:, :, 0], rgb[:, :, 2]) - rgb[:, :, 1]
    correction = np.where(edge & (excess > 14), excess - 4, 0)
    rgb[:, :, 0] -= correction
    rgb[:, :, 2] -= correction
    pixels[:, :, :3] = np.clip(rgb, 0, 255).astype(np.uint8)
    pixels[pixels[:, :, 3] <= 3] = 0
    return Image.fromarray(pixels)


def prepare_combat(source, destination, preview_dir):
    """Keep native illustration detail/aspect; remove key and unused padding only."""
    illustration, mode = cutout(source)
    if mode == 'magenta_local_cutout':
        illustration = despill_combat_edges(illustration)
    bounds = illustration.getchannel('A').point(lambda v: 255 if v > 3 else 0).getbbox()
    if bounds is None:
        raise ValueError('Empty enemy cutout')
    subject = illustration.crop(bounds)
    padding = 12
    result = Image.new('RGBA', (subject.width + padding * 2, subject.height + padding * 2))
    result.alpha_composite(subject, (padding, padding))
    destination.parent.mkdir(parents=True, exist_ok=True)
    result.save(destination)
    preview_dir.mkdir(parents=True, exist_ok=True)
    thumb = result.copy()
    thumb.thumbnail((600, 760), Image.Resampling.LANCZOS)
    preview = Image.new('RGB', (1200, 800), '#172635')
    preview.paste(Image.new('RGB', (600, 800), '#dde5e9'), (600, 0))
    for x in (0, 600):
        preview.paste(thumb, (x + (600-thumb.width)//2, 800-thumb.height), thumb)
    preview.save(preview_dir / (destination.stem + '_alpha_review.png'))
    report = dict(source=str(source), output=str(destination), method=mode,
                  dimensions=list(result.size), alpha_bounds=list(result.getbbox()))
    print(json.dumps(report, ensure_ascii=False))
    return report


def prepare(source, destination, preview_dir, size=512, key_shadows=False, neutral_edges=False,
            background_seeds=()):
    icon, mode = cutout(source, key_shadows=key_shadows, background_seeds=background_seeds)
    if neutral_edges and mode == 'magenta_local_cutout':
        icon = despill_combat_edges(icon)
    bounds = icon.getchannel('A').point(lambda v: 255 if v > 3 else 0).getbbox()
    if bounds is None:
        raise ValueError('Empty cutout')
    cropped = icon.crop(bounds)
    scale = size * .84 / max(cropped.size)
    cropped = cropped.resize(tuple(max(1, round(v * scale)) for v in cropped.size),
                             Image.Resampling.LANCZOS)
    result = Image.new('RGBA', (size, size))
    result.alpha_composite(cropped, ((size-cropped.width)//2, (size-cropped.height)//2))
    pixels = np.asarray(result).copy()
    pixels[pixels[:, :, 3] <= 3] = 0
    result = Image.fromarray(pixels)
    destination.parent.mkdir(parents=True, exist_ok=True)
    result.save(destination)
    preview_dir.mkdir(parents=True, exist_ok=True)
    preview = Image.new('RGB', (size*2, size), '#090f18')
    preview.paste(Image.new('RGB', (size, size), '#e5e3dc'), (size, 0))
    preview.paste(result, (0, 0), result)
    preview.paste(result, (size, 0), result)
    preview.save(preview_dir / (destination.stem + '_alpha_review.png'))
    report = dict(source=str(source), output=str(destination), method=mode,
                  dimensions=list(result.size), alpha_bounds=list(result.getbbox()),
                  transparent_fraction=float((pixels[:, :, 3] == 0).mean()))
    print(json.dumps(report, ensure_ascii=False))
    return report


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('source', type=Path)
    parser.add_argument('destination', type=Path)
    parser.add_argument('--previews', type=Path, default=Path('output/item_art/alpha_reviews'))
    parser.add_argument('--combat', action='store_true', help='Native-resolution enemy cutout')
    parser.add_argument('--key-shadows', action='store_true', help='Reviewed saturated backdrop shadows only')
    parser.add_argument('--neutral-edges', action='store_true', help='Despill reviewed non-magenta item edges')
    parser.add_argument('--background-seed', type=float, nargs=2, action='append', default=[],
                        help='Reviewed neutral hole, normalized source X Y; repeat for separate holes')
    args = parser.parse_args()
    if args.combat:
        prepare_combat(args.source, args.destination, args.previews)
    else:
        prepare(args.source, args.destination, args.previews,
                key_shadows=args.key_shadows, neutral_edges=args.neutral_edges,
                background_seeds=args.background_seed)
