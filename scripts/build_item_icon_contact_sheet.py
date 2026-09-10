import argparse
import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont


ROOT = Path(__file__).resolve().parents[1]
ITEMS_BATCH_02 = (
    ("Łuk Myśliwski", "equipment/hunting_bow.png"),
    ("Kostur Adepta", "equipment/apprentice_staff.png"),
    ("Lanca Kaprysu", "equipment/caprice_lance.png"),
    ("Rękawice Myśliwego", "equipment/hunter_gloves.png"),
    ("Wzmocnione Buty", "equipment/reinforced_boots.png"),
    ("Pas Skórzany", "equipment/leather_belt.png"),
    ("Ząb Wilka", "equipment/wolf_tooth_necklace.png"),
    ("Pierścień Natury", "equipment/nature_ring.png"),
    ("Twarde Drewno", "materials/hard_wood.png"),
    ("Zwykła Esencja", "materials/common_essence.png"),
    ("Mocna Mikstura Lecznicza", "consumables/strong_healing_potion.png"),
    ("Grimuar Podwójnego Splotu", "books/path_arcana_book.png"),
)

ITEMS_BATCH_03 = (
    ("Ostrzony Miecz", "equipment/sharpened_sword.png"),
    ("Zszywana Zbroja", "equipment/stitched_armor.png"),
    ("Kołczan Tropiciela", "equipment/simple_quiver.png"),
    ("Amulet Natury", "equipment/nature_amulet.png"),
    ("Bransoleta Natury", "equipment/nature_bracelet.png"),
    ("Kolczyki Natury", "equipment/nature_earrings.png"),
    ("Słaba Skóra", "materials/weak_leather.png"),
    ("Metalowa Klamra", "materials/metal_buckle.png"),
    ("Kamień Szlifierski", "materials/grinding_stone.png"),
    ("Iskra Życia", "materials/spark_of_life.png"),
    ("Kryształ Many", "equipment/mana_crystal_artifact.png"),
    ("Prowiant Myśliwego", "consumables/hunter_provisions.png"),
)

ITEMS_BATCH_04 = (
    ("Eliksir Arcymistrza", "consumables/grandmaster_elixir.png"),
    ("Manuskrypt Szybkiego Ostrza", "books/mastery_attack_speed_book.png"),
    ("Kodeks Krytycznego Uderzenia", "books/mastery_critical_book.png"),
    ("Traktat Mistrzowskiej Regeneracji", "books/mastery_regeneration_book.png"),
    ("Stare Ubrania", "materials/old_clothes.png"),
    ("Księga Fortuny", "books/path_fortuna_book.png"),
    ("Traktat Ciężkiego Rycerza", "books/path_heavy_knight_book.png"),
    ("Kronika Widmowego Strzelca", "books/path_phantom_archer_book.png"),
    ("Surowe Mięso Dzika", "materials/raw_boar_meat.png"),
    ("Trufla", "materials/truffle.png"),
    ("Wytarte Kości Losu", "equipment/worn_fate_dice.png"),
    ("Zużyty Pasek", "materials/worn_strap.png"),
)

BATCHES = {"02": ITEMS_BATCH_02, "03": ITEMS_BATCH_03, "04": ITEMS_BATCH_04}


def load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont:
    windows_fonts = Path("C:/Windows/Fonts")
    filename = "segoeuib.ttf" if bold else "segoeui.ttf"
    return ImageFont.truetype(str(windows_fonts / filename), size)


def fit_icon(icon: Image.Image, width: int, height: int) -> Image.Image:
    icon = icon.convert("RGBA")
    alpha = icon.getchannel("A")
    bounds = alpha.point(lambda value: 255 if value > 3 else 0).getbbox()
    if bounds is None:
        raise ValueError("Icon contains no visible pixels")
    icon = icon.crop(bounds)
    scale = min(width / icon.width, height / icon.height)
    size = (max(1, round(icon.width * scale)), max(1, round(icon.height * scale)))
    return icon.resize(size, Image.Resampling.LANCZOS)


def main(batch: str) -> None:
    columns, rows = 4, 3
    tile_width, tile_height = 390, 430
    margin, gap = 34, 18
    title_height = 90
    sheet_width = margin * 2 + columns * tile_width + (columns - 1) * gap
    sheet_height = margin * 2 + title_height + rows * tile_height + (rows - 1) * gap

    sheet = Image.new("RGBA", (sheet_width, sheet_height), (4, 9, 15, 255))
    draw = ImageDraw.Draw(sheet)
    title_font = load_font(34, bold=True)
    label_font = load_font(23, bold=True)
    meta_font = load_font(16)

    draw.text((margin, margin - 4), "ECHOES OF PYTHONIA — IKONY PRZEDMIOTÓW", font=title_font, fill=(223, 180, 76, 255))
    draw.text((margin, margin + 44), f"Seria próbna {batch} • 12 przedmiotów • przezroczyste tło", font=meta_font, fill=(140, 160, 183, 255))

    assets_root = ROOT / "godot" / "assets" / "items"
    for index, (label, relative_path) in enumerate(BATCHES[batch]):
        column = index % columns
        row = index // columns
        x = margin + column * (tile_width + gap)
        y = margin + title_height + row * (tile_height + gap)
        panel = (x, y, x + tile_width, y + tile_height)
        draw.rounded_rectangle(panel, radius=12, fill=(7, 14, 23, 255), outline=(121, 86, 31, 255), width=2)
        draw.rounded_rectangle((x + 14, y + 14, x + tile_width - 14, y + 338), radius=8, fill=(2, 7, 12, 255), outline=(48, 64, 81, 255), width=1)

        icon = fit_icon(Image.open(assets_root / relative_path), tile_width - 58, 288)
        icon_x = x + (tile_width - icon.width) // 2
        icon_y = y + 30 + (280 - icon.height) // 2
        sheet.alpha_composite(icon, (icon_x, icon_y))

        text_box = draw.textbbox((0, 0), label, font=label_font)
        text_width = text_box[2] - text_box[0]
        if text_width > tile_width - 28:
            font = load_font(19, bold=True)
            text_box = draw.textbbox((0, 0), label, font=font)
            text_width = text_box[2] - text_box[0]
        else:
            font = label_font
        draw.text((x + (tile_width - text_width) // 2, y + 358), label, font=font, fill=(229, 232, 237, 255))
        draw.text((x + 18, y + 400), f"{index + 1:02d}", font=meta_font, fill=(223, 180, 76, 255))

    output = ROOT / "docs" / "previews" / f"item_icons_batch_{batch}.png"
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.convert("RGB").save(output, quality=94)
    print(output)


def regional_sheet(manifest_path: Path, output: Path) -> None:
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    entries = manifest["items"]
    columns, cell_w, cell_h, margin, gap = 5, 284, 312, 24, 12
    width = margin * 2 + columns * cell_w + (columns - 1) * gap
    height = 104 + margin * 2 + math.ceil(len(entries) / columns) * (cell_h + gap)
    sheet = Image.new("RGB", (width, height), "#070d15")
    draw = ImageDraw.Draw(sheet)
    draw.text((margin, 20), f"ECHOES OF PYTHONIA — PRZEDMIOTY / PARTIA {manifest['batch']:02d}",
              font=load_font(28, True), fill="#e1b954")
    draw.text((margin, 63), f"{len(entries)} ikon 2D • ramka = jakość • mały podgląd = 64 px",
              font=load_font(18), fill="#a8b7c7")
    for index, entry in enumerate(entries):
        x = margin + (index % columns) * (cell_w + gap)
        y = 108 + (index // columns) * (cell_h + gap)
        color = "#" + entry["rarity_color"].lstrip("#")
        draw.rounded_rectangle((x, y, x + cell_w, y + cell_h), 7,
                               fill="#0c1420", outline=color, width=2)
        path = ROOT / entry["target"]
        if not path.exists():
            path = manifest_path.parent / "processed" / (entry["id"] + ".png")
        if path.exists():
            icon = Image.open(path).convert("RGBA")
            large = icon.resize((224, 224), Image.Resampling.LANCZOS)
            sheet.paste(large, (x + 30, y + 8), large)
            small = icon.resize((64, 64), Image.Resampling.LANCZOS)
            sheet.paste(small, (x + cell_w - 77, y + 198), small)
        else:
            draw.text((x + 24, y + 92), "W PRZYGOTOWANIU", font=load_font(16), fill="#a8b7c7")
        name_font = load_font(18, True)
        if draw.textlength(entry["name"], font=name_font) > cell_w - 24:
            name_font = load_font(15, True)
        draw.text((x + 12, y + 266), entry["name"], font=name_font, fill="#e6e9ef")
        draw.text((x + 12, y + 290), f"{index+1:02d} · {entry['rarity_label']}",
                  font=load_font(14), fill=color)
    output.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(output)
    print(output)


if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--batch", choices=sorted(BATCHES), default="02")
    parser.add_argument("--manifest", type=Path)
    parser.add_argument("--output", type=Path, default=ROOT / "docs/previews/regional_items_batch_01.png")
    args = parser.parse_args()
    if args.manifest:
        regional_sheet(args.manifest, args.output)
    else:
        main(args.batch)
