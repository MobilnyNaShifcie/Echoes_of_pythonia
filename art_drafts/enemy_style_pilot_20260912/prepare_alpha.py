"""Owner-authorized local extraction of this reviewed pilot only; no network.

Run from any directory. Original and production PNGs are never overwritten.
The neutral ranges are sampled from these two specific printed backdrops,
NOT defaults for future enemies. Core RGB is preserved; only the matte edge
is unmatted. Uses the existing project extraction helpers and pixel gate.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
from pathlib import Path
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(ROOT / "scripts"))
sys.path.insert(0, str(ROOT / "tools"))
from prepare_regional_item_icon import dilate, extend_colors
from echoes_autopilot_desktop.art_policy import inspect_enemy_png

PROFILES = {
    "wolf": {
        "source": "wolf_style_v2_alpha_attempt.png",
        "sha256": "f0514d63391568a6bf0332bfe81bb7160bf6a6a9e68efa75584b846e66cf89e6",
        "minimum": 175,
        "spread": 14,
        # Tiny enclosed background triangle below the mane, checked at 200%.
        "holes": [(434, 829)],
    },
    "ice_crab": {
        "source": "ice_crab_left_v2.png",
        "sha256": "71ac35ed950b2b2fd36e3f7168be1ed8a1ebafd3b7371a100a829a1aa0acb738",
        "minimum": 95,
        "spread": 14,
        # Visually checked checkerboard enclosed by the overlapping claws.
        "holes": [(330, 585), (1210, 550)],
    },
}


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def connected_background(rgb, minimum, spread, holes=()):
    candidate = (rgb.min(axis=2) >= minimum) & (np.ptp(rgb, axis=2) <= spread)
    # Padding connects ALL exterior components, not just the top-left corner.
    mask = Image.fromarray(np.pad(candidate, 1, constant_values=True).astype(np.uint8) * 255).copy()
    ImageDraw.floodfill(mask, (0, 0), 128, thresh=0)
    for x, y in holes:
        if not (0 <= x < rgb.shape[1] and 0 <= y < rgb.shape[0]):
            raise ValueError("Reviewed hole seed is outside the source")
        if mask.getpixel((x + 1, y + 1)) not in (128, 255):
            raise ValueError("Reviewed hole seed is not neutral backdrop")
        ImageDraw.floodfill(mask, (x + 1, y + 1), 128, thresh=0)
    return np.asarray(mask)[1:-1, 1:-1] == 128


def extract(image, minimum, spread, holes=()):
    if image.mode != "RGB":
        raise ValueError("This pilot extractor expects its original RGB source")
    rgb = np.asarray(image).astype(np.float32)
    background = connected_background(rgb, minimum, spread, holes)
    if not .1 < background.mean() < .95:
        raise ValueError("Unexpected background coverage; inspect before continuing")
    edge = dilate(background, 2) & ~background
    core = ~(background | edge)
    fg = extend_colors(rgb, core, steps=12)
    bg = extend_colors(rgb, background, steps=6)
    delta = fg - bg
    estimate = np.sum((rgb - bg) * delta, axis=2) / np.maximum(np.sum(delta * delta, axis=2), 1)
    alpha = np.ones(background.shape, np.float32)
    alpha[background] = 0
    # A dark ink contour can be darker than BOTH the nearby bright ice and
    # grey backdrop. It is NOT a partially transparent blend: clamping its
    # negative projection to zero would eat the outline. Unmatte only samples
    # that actually fit the local foreground/background mixture.
    reconstructed = bg + estimate[:, :, None] * delta
    residual = np.max(np.abs(reconstructed - rgb), axis=2)
    blend = edge & (estimate > .01) & (estimate < 1) & (residual < 9)
    alpha[blend] = estimate[blend]
    clean = rgb.copy()
    partial = edge & (alpha > .01)
    clean[partial] = (rgb[partial] - bg[partial] * (1 - alpha[partial, None])) / alpha[partial, None]
    rgba = np.dstack((np.clip(clean, 0, 255), np.rint(alpha * 255))).astype(np.uint8)
    rgba[rgba[:, :, 3] <= 3] = 0
    assert np.array_equal(rgba[core, :3], rgb[core].astype(np.uint8)), "Interior repainting is forbidden"
    return Image.fromarray(rgba), {
        "background_fraction": float(background.mean()),
        "unchanged_core_rgb_pixels": int(core.sum()),
        "matte_edge_band_pixels": int(edge.sum()),
    }


def padded(image, margin=.07):
    bbox = image.getchannel("A").getbbox()
    if bbox is None:
        raise ValueError("Empty silhouette")
    subject = image.crop(bbox)
    # Padding only: no resampling, distortion, or artificial upscaling.
    px = math.ceil(subject.width * margin / (1 - 2 * margin))
    py = math.ceil(subject.height * margin / (1 - 2 * margin))
    result = Image.new("RGBA", (subject.width + 2 * px, subject.height + 2 * py))
    result.paste(subject, (px, py))
    return result, {"source_alpha_bounds": list(bbox), "padding_xy": [px, py], "resampled": False}


def font(size=22):
    path = Path("C:/Windows/Fonts/segoeui.ttf")
    return ImageFont.truetype(str(path), size) if path.exists() else ImageFont.load_default()


def reviews(assets, qa):
    width, height = 800, 620
    sheet = Image.new("RGB", (width * 2, height * len(assets)))
    draw = ImageDraw.Draw(sheet)
    for row, (name, art) in enumerate(assets.items()):
        thumb = art.copy()
        thumb.thumbnail((width - 50, height - 65), Image.Resampling.LANCZOS)
        for col, color in enumerate(("#142333", "#ede7dd")):
            x, y = col * width, row * height
            draw.rectangle((x, y, x + width, y + height), fill=color)
            sheet.paste(thumb, (x + (width - thumb.width) // 2, y + 45 + (height - 65 - thumb.height) // 2), thumb)
            draw.text((x + 25, y + 14), name + " / " + ("dark" if col == 0 else "light"),
                      fill="#d8e4ef" if col == 0 else "#243746", font=font())
    sheet.save(qa / "alpha_review_dark_light.png")


def detail_review(name, unframed, qa):
    # Native source coordinates. Do not sharpen previews or hide alpha defects.
    crops = {
        "wolf": [(140, 600, 440, 850), (700, 120, 1000, 370), (505, 895, 805, 1145)],
        "ice_crab": [(175, 430, 475, 680), (710, 585, 1010, 835), (1090, 430, 1390, 680)],
    }[name]
    board = Image.new("RGB", (1800, 1060))
    draw = ImageDraw.Draw(board)
    for col, box in enumerate(crops):
        art = unframed.crop(box).resize((600, 500), Image.Resampling.NEAREST)
        for row, color in enumerate(("#080d16", "#f3efe8")):
            x, y = col * 600, row * 530
            draw.rectangle((x, y, x + 600, y + 530), fill=color)
            board.paste(art, (x, y + 30), art)
            draw.text((x + 10, y + 3), name + " / 200% / " + str(box),
                      font=font(17), fill="#b0b0b0" if row == 0 else "#303030")
    board.save(qa / (name + "_edge_details_200pct.png"))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, default=HERE / "processed")
    args = parser.parse_args()
    output = args.output.resolve()
    if not output.is_relative_to(HERE) or output == HERE:
        raise ValueError("Outputs must stay in a subdirectory of this draft")
    qa = output / "qa"
    qa.mkdir(parents=True, exist_ok=True)
    reports, assets = [], {}
    for name, profile in PROFILES.items():
        source = HERE / profile["source"]
        if sha(source) != profile["sha256"]:
            raise ValueError("Source changed; thresholds and reviewed holes must be checked again")
        production = ROOT / "godot/assets/combat/enemies" / (name + ".png")
        before = sha(production)
        with Image.open(source) as image:
            cutout, extraction = extract(image, profile["minimum"], profile["spread"], profile["holes"])
        cutout.save(qa / (name + "_unframed.png"))
        detail_review(name, cutout, qa)
        # Diagnostic only: opaque neutral pixels may be valid pale highlights
        # OR an unreviewed enclosed checker hole. Never erase them globally.
        px = np.asarray(cutout).astype(np.float32)
        neutral = (px[:, :, 3] > 0) & (px[:, :, :3].min(axis=2) >= profile["minimum"]) & (np.ptp(px[:, :, :3], axis=2) <= profile["spread"])
        diagnostic = Image.new('RGB', cutout.size, '#142333')
        diagnostic.paste(cutout, (0, 0), cutout)
        marked = np.asarray(diagnostic).copy()
        marked[dilate(neutral, 3)] = [255, 0, 255]
        Image.fromarray(marked).save(qa / (name + '_remaining_neutrals_diagnostic.png'))
        result, framing = padded(cutout)
        target = output / (name + "_rgba.png")
        result.save(target)
        gate = inspect_enemy_png(target)
        pixels = np.asarray(result)
        hidden_rgb_clean = bool(np.all(pixels[pixels[:, :, 3] == 0, :3] == 0))
        assert gate["status"] == "PASS", gate
        assert hidden_rgb_clean
        assert sha(production) == before
        reports.append({
            "enemy": name, "source": str(source.relative_to(ROOT)), "source_sha256": sha(source),
            "output": str(target.relative_to(ROOT)), "method": "reviewed_neutral_connectivity_and_local_edge_unmatting",
            "profile": profile, "extraction": extraction, "framing": framing,
            "pixel_gate": gate, "transparent_rgb_zero": hidden_rgb_clean,
            "production_sha256_unchanged": before,
        })
        assets[name] = result
    reviews(assets, qa)
    report = {
        "status": "DRAFT — alpha processing only, pending visual and owner review",
        "authorization": "User explicitly approved local Python background extraction; 2026-09-12",
        "network_or_paid_services": False, "production_changed": False,
        "limitations": "Pixel gate does not prove anatomy, rigging readiness, style or in-game placement.",
        "assets": reports,
    }
    (qa / "alpha_report.json").write_text(json.dumps(report, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
