"""Authorized local alpha preparation and QA; generated source art is never changed."""
from pathlib import Path
import json
import sys
from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "scripts"))
from prepare_regional_item_icon import prepare_combat, cutout

HERE = Path(__file__).resolve().parent
ENEMIES = ["drowned_acolyte", "drowned_priestess", "iron_gate_guardian",
           "crypt_warden", "sunken_knight_anime", "order_grandmaster"]
ROOMS = ["seal_corridor", "drowned_gallery", "sunken_chapel",
         "chain_hall", "grandmaster_gate"]

# Individually inspected holes, not cloth, skin or metal highlights.
REVIEWED_HOLES = {
    "drowned_acolyte": [(0.8592, 0.5879), (0.7449, 0.8379), (0.261, 0.5703)],
    "drowned_priestess": [(0.2845, 0.6602), (0.2258, 0.375),
        (0.2199, 0.123), (0.217, 0.0879), (0.1935, 0.0703),
        (0.2023, 0.1445), (0.1261, 0.0938), (0.132, 0.1289),
        (0.1525, 0.1484), (0.1437, 0.0742)],
    "iron_gate_guardian": [(0.305, 0.4414)],
    "crypt_warden": [(0.8211, 0.5098), (0.6833, 0.3711), (0.2082, 0.4512),
        (0.3021, 0.4023), (0.9032, 0.5371), (0.9032, 0.4453),
        (0.1437, 0.4219), (0.9062, 0.3965), (0.9032, 0.4902),
        (0.1466, 0.3281), (0.1554, 0.2871), (0.7126, 0.4668),
        (0.1466, 0.375), (0.7977, 0.4141), (0.7713, 0.4473)],
    "order_grandmaster": [(0.7335, 0.2676), (0.4756, 0.7812), (0.255, 0.75)],
}


def main():
    reports = []
    for name in ENEMIES:
        source = HERE / "raw" / (name + ".png")
        if source.exists():
            (HERE / "qa").mkdir(exist_ok=True)
            art, method = cutout(source, background_seeds=REVIEWED_HOLES.get(name, []))
            intermediate = HERE / "qa" / (name + "_alpha_source.png")
            art.save(intermediate)
            report = prepare_combat(intermediate, HERE / "processed" / (name + ".png"),
                                    HERE / "qa")
            report.update(source=str(source), method=method,
                          reviewed_holes=REVIEWED_HOLES.get(name, []))
            reports.append(report)
    (HERE / "qa").mkdir(exist_ok=True)
    (HERE / "qa" / "alpha_report.json").write_text(
        json.dumps(reports, indent=2), encoding="utf-8")
    sheet = Image.new("RGB", (1800, 1200), "#182635")
    draw = ImageDraw.Draw(sheet)
    for index, name in enumerate(ENEMIES):
        path = HERE / "processed" / (name + ".png")
        if not path.exists():
            continue
        actor = Image.open(path).convert("RGBA")
        actor.thumbnail((550, 535), Image.Resampling.LANCZOS)
        x, y = (index % 3) * 600, (index // 3) * 600
        sheet.paste(actor, (x + (600 - actor.width)//2, y + 565 - actor.height), actor)
        draw.text((x + 20, y + 578), name, fill="#eeeeee")
    sheet.save(HERE / "qa" / "enemy_contact_sheet.png")
    rooms = [("sunken_vestibule", ROOT / "art_drafts/dungeon_crypt_pilot_01/sunken_vestibule_v2.png")]
    rooms += [(name, HERE / "raw" / (name + ".png")) for name in ROOMS]
    board = Image.new("RGB", (1500, 640), "#182635")
    draw = ImageDraw.Draw(board)
    for index, (name, path) in enumerate(rooms):
        if not path.exists():
            continue
        art = Image.open(path).convert("RGB")
        art.thumbnail((490, 280), Image.Resampling.LANCZOS)
        x, y = (index % 3) * 500, (index // 3) * 320
        board.paste(art, (x, y))
        draw.text((x + 10, y + 287), name, fill="#eeeeee")
    board.save(HERE / "qa" / "room_contact_sheet.png")


if __name__ == "__main__":
    main()
