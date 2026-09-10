"""Contact sheets for art QA; uses generated cutouts without repainting them."""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'output/item_art'
FONT = 'C:/Windows/Fonts/segoeui.ttf'


def font(size):
    return ImageFont.truetype(FONT, size)


def fit(source, size):
    im = Image.open(source).convert('RGBA')
    bounds = im.getchannel('A').getbbox()
    if bounds:
        im = im.crop(bounds)
    im.thumbnail(size, Image.Resampling.LANCZOS)
    return im


def pilot_sheet():
    OUT.mkdir(parents=True, exist_ok=True)
    canvas = Image.new('RGB', (1600, 880), '#0b121e')
    draw = ImageDraw.Draw(canvas)
    draw.text((34, 25), 'NOWY KIERUNEK • ILUSTRACYJNE ANIME-FANTASY', font=font(30), fill='#ecd3a0')
    draw.text((34, 73), 'Postacie zostają wzorcem. Mniej szumu faktur, zachowane pochodzenie i materiały łupu.', font=font(20), fill='#a5b6ca')
    hero = fit(ROOT / 'godot/assets/combat/heroes/hunter_male.png', (390, 660))
    canvas.paste(hero, ((410-hero.width)//2, 153), hero)
    draw.text((42, 118), 'WZORZEC — POSTAĆ Z GRY', font=font(17), fill='#b2c2d7')
    pilots = [
        ('black_bear_claw', 'Czarny Pazur', 'Materiał • Niepospolity', '#4ab875'),
        ('rotting_knight_helm', 'Hełm Zgniłego Rycerza', 'Zbroja • Rzadki', '#4f96e8'),
        ('cultist_pendant', 'Wisiorek Kultysty', 'Ozdoba • Rzadki', '#4f96e8'),
    ]
    for i, (item_id, title, subtitle, color) in enumerate(pilots):
        x = 432 + i*380
        draw.rounded_rectangle((x, 142, x+354, 630), radius=12, fill='#111d2a', outline='#2a3b50', width=1)
        draw.text((x+15, 160), title, font=font(23), fill='#e8edf5')
        draw.text((x+15, 198), subtitle, font=font(18), fill=color)
        im = Image.open(ROOT / f'art_drafts/anime_style_pilot/processed/{item_id}.png').convert('RGBA')
        large = im.resize((330, 330), Image.Resampling.LANCZOS)
        canvas.paste(large, (x+12, 247), large)
        draw.text((x+16, 650), 'Rzeczywisty slot 64 px', font=font(18), fill='#a5b6ca')
        draw.rounded_rectangle((x+137, 698, x+205, 766), radius=5, fill='#101723', outline=color, width=2)
        small = im.resize((64, 64), Image.Resampling.LANCZOS)
        canvas.paste(small, (x+139, 700), small)
    draw.text((432, 815), 'Ramki jakości nakłada interfejs — nie są wmalowane w ikonę.', font=font(20), fill='#a5b6ca')
    canvas.save(OUT / 'anime_style_pilot_review.png')


def region_sheet():
    ids = [('frozen_castaway', 'Zamarznięty Rozbitek'), ('ice_bear', 'Lodowy Niedźwiedź'),
           ('snow_griffin', 'Śnieżny Gryf'), ('ice_crab', 'Lodowy Krab'),
           ('black_sea_siren', 'Syrena Czarnego Morza'), ('ghost_ship_captain', 'Widmo Kapitana'),
           ('leviathan_north', 'Lewiatan Północy')]
    canvas = Image.new('RGB', (1800, 1250), '#0b1420')
    draw = ImageDraw.Draw(canvas)
    draw.text((32, 22), 'LODOWE WYBRZEŻE • KOMPLET REGIONU 5', font=font(30), fill='#d9ebf3')
    for i, (item_id, name) in enumerate(ids):
        x, y = (i % 4)*450, 90+(i//4)*570
        draw.rounded_rectangle((x+12, y, x+438, y+545), radius=9, fill='#223446', outline='#354f67')
        im = fit(ROOT / f'godot/assets/combat/enemies/{item_id}.png', (400, 472))
        canvas.paste(im, (x+(450-im.width)//2, y+495-im.height), im)
        draw.text((x+25, y+510), name, font=font(22), fill='#e6edf1')
    for j, period in enumerate(['day', 'night']):
        im = fit(ROOT / f'godot/assets/combat/backgrounds/ice_coast_{period}.png', (424, 235))
        canvas.paste(im, (1363, 685+j*260), im)
    (ROOT / 'output/ice_coast').mkdir(parents=True, exist_ok=True)
    canvas.save(ROOT / 'output/ice_coast/art_contact_sheet.png')


if __name__ == '__main__':
    pilot_sheet()
    region_sheet()
