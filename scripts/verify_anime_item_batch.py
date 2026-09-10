"""Verify an integrated icon batch and record reproducible source/output hashes."""
import argparse
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]


def digest(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def strong_key_mask(pixels):
    """Detect pink key residue without rejecting genuine blue-violet crystals."""
    rgb = pixels[:, :, :3].astype(np.int16)
    r, g, b = rgb.transpose(2, 0, 1)
    return ((r > 170) & (b > 170) & (g < 40) & (np.abs(r - b) < 30)
            & (pixels[:, :, 3] > 32))


def main(batch=1):
    manifest = ROOT / f"art_drafts/anime_style_batch_{batch:02d}/review_manifest.json"
    data = json.loads(manifest.read_text(encoding="utf-8"))
    entries = data["items"]
    expected = data.get("expected_count", 30)
    assert isinstance(expected, int) and expected > 0
    assert len(entries) == expected, (len(entries), expected)
    assert len({entry["id"] for entry in entries}) == expected, "Duplicate item IDs"
    reports, hashes = [], set()
    for entry in entries:
        item_id = entry["id"]
        raw = manifest.parent / "raw" / (item_id + ".png")
        processed = manifest.parent / "processed" / (item_id + ".png")
        target = ROOT / entry["target"]
        assert raw.is_file() and processed.is_file() and target.is_file(), item_id
        image = Image.open(target)
        assert image.mode == "RGBA" and image.size == (512, 512), item_id
        pixels = np.asarray(image)
        alpha = pixels[:, :, 3]
        assert (alpha[:35] == 0).all() and (alpha[-35:] == 0).all(), item_id
        assert (alpha[:, :35] == 0).all() and (alpha[:, -35:] == 0).all(), item_id
        assert (pixels[alpha == 0] == 0).all(), item_id
        strong_key = strong_key_mask(pixels)
        assert int(strong_key.sum()) < 10, (item_id, "remaining key pixels", int(strong_key.sum()))
        output_hash = digest(target)
        assert output_hash == digest(processed), item_id
        assert output_hash not in hashes, ("duplicate icon", item_id)
        hashes.add(output_hash)
        reports.append(dict(id=item_id, target=entry["target"], raw_sha256=digest(raw),
                            output_sha256=output_hash, dimensions=list(image.size),
                            alpha_bounds=list(image.getbbox()),
                            strong_key_pixels=int(strong_key.sum()),
                            reviewed_edge_cleanup=entry.get("neutral_edges", False) or item_id in (
                                "spiderweave_gloves", "blackwood_longbow", "executioner_mask"),
                            reviewed_shadow_key=entry.get("key_shadows", False) or item_id in (
                                "spiderweave_gloves", "blackwood_longbow", "executioner_mask",
                                "spider_silk", "blackwood_mail", "blackwood_staff", "corrupted_hide",
                                "rotting_knight_helm", "swamp_reed", "venom_gland")))
    output = ROOT / f"output/item_art/anime_batch_{batch:02d}_asset_validation.json"
    output.write_text(json.dumps(dict(count=len(reports), passed=True, assets=reports),
                                 indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"ANIME BATCH ART QA: {len(reports)}/{expected} RGBA icons, unique artwork, transparent margins, matching imports")


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--batch", type=int, default=1)
    main(parser.parse_args().batch)
