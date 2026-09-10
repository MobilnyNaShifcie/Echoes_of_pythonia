"""Report neutral components for manual alpha QA; does not modify artwork."""
import argparse
from collections import deque
from pathlib import Path
import numpy as np
from PIL import Image, ImageDraw

parser = argparse.ArgumentParser()
parser.add_argument('images', nargs='+', type=Path)
args = parser.parse_args()
for path in args.images:
    image = Image.open(path).convert('RGB')
    image.thumbnail((512, 512), Image.Resampling.NEAREST)
    rgb = np.asarray(image).astype(np.int16)
    mask = (rgb.min(axis=2) > 205) & (np.ptp(rgb, axis=2) < 20)
    h, w = mask.shape
    # Flood each candidate component, leaving original RGB untouched.
    comps = []
    for sy, sx in zip(*np.where(mask)):
        if not mask[sy, sx]:
            continue
        todo = deque([(int(sx), int(sy))])
        mask[sy, sx] = False
        pixels = []
        edge = False
        while todo:
            x, y = todo.popleft()
            pixels.append((x, y))
            edge |= x == 0 or y == 0 or x == w-1 or y == h-1
            for nx, ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
                if 0 <= nx < w and 0 <= ny < h and mask[ny,nx]:
                    mask[ny,nx] = False
                    todo.append((nx,ny))
        if not edge and len(pixels) >= 12:
            points = np.asarray(pixels)
            center = points.mean(axis=0)
            nearest = points[np.argmin(((points-center)**2).sum(axis=1))]
            comps.append((len(pixels), tuple(np.round(nearest/[w,h],4)),
                          tuple(np.round(points.min(axis=0)/[w,h],3)),
                          tuple(np.round(points.max(axis=0)/[w,h],3))))
    print(path.stem, sorted(comps, reverse=True))
