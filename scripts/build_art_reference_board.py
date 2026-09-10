"""Read-only reference overview; source artwork is never modified."""
import argparse
import math
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    parser.add_argument("images", nargs="+", type=Path)
    args = parser.parse_args()
    cols, w, h = 4, 420, 440
    board = Image.new("RGB", (cols*w, math.ceil(len(args.images)/cols)*h), "#162330")
    draw = ImageDraw.Draw(board)
    font = ImageFont.truetype("C:/Windows/Fonts/segoeui.ttf", 20)
    for i, path in enumerate(args.images):
        art = Image.open(path).convert("RGBA")
        bounds = art.getchannel("A").getbbox()
        if bounds:
            art = art.crop(bounds)
        art.thumbnail((w-26, h-55), Image.Resampling.LANCZOS)
        x, y = (i%cols)*w, (i//cols)*h
        board.paste(art, (x+(w-art.width)//2, y+8+(h-55-art.height)//2), art)
        draw.text((x+10, y+h-35), path.stem, font=font, fill="#e6e9ee")
    args.output.parent.mkdir(parents=True, exist_ok=True)
    board.save(args.output)
    print(args.output)
if __name__ == "__main__":
    main()

