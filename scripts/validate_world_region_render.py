"""Compare real Godot raster output against the authoritative picking atlas.

Run build/render_varenhold_live_validation.gd first. These checks catch GPU/CPU
UV shifts, ID filtering/gamma mistakes, and cross-module hover leaks. They do
not replace visual review of alignment to the illustrated gold boundaries.
"""
import json
from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "build/world-map-validation"


def validate():
    transform = json.loads((OUT / "transform-1920.json").read_text())
    atlas = np.asarray(Image.open(ROOT / "godot/assets/world_map/pythonia_region_atlas_v2.png"))
    ambient = np.asarray(Image.open(OUT / "ambient-1920.png")).astype(int)
    h,w = ambient.shape[:2]
    x = np.floor((np.arange(w)+.5-transform['position'][0])*2560/transform['size'][0]).astype(int)
    y = np.floor((np.arange(h)+.5-transform['position'][1])*1440/transform['size'][1]).astype(int)
    visible = atlas[np.clip(y,0,1439)[:,None],np.clip(x,0,2559)[None,:]]
    codes = {'varenhold_valley':26,'twilight_plains':51,'black_forest':102,
             'silentwater_marshes':153,'ashen_borderlands':204,'ice_coast':255}
    results = {}
    for name,code in codes.items():
        hovered = np.asarray(Image.open(OUT / (name+'-hover.png'))).astype(int)
        changed = np.max(np.abs(hovered[:,:,:3]-ambient[:,:,:3]),axis=2)>2
        inside = visible[:,:,0] == code
        # UI can intentionally occlude the map. All land in these captures lies
        # below the top labels and above the bottom controls.
        changed[:180] = False
        changed[980:] = False
        outside = int((changed & ~inside).sum())
        fill = inside & (visible[:,:,1] == 0) & (visible[:,:,2] == 0)
        fill[:180] = False
        fill[980:] = False
        coverage = float((changed & fill).sum()/max(1,fill.sum()))
        results[name] = {'changed_pixels':int(changed.sum()), 'outside_ID_pixels':outside,
                         'visible_fill_coverage':round(coverage,6)}
        print(name,results[name])
        assert outside == 0, f'{name}: highlight escapes the picked region'
        assert coverage > .99, f'{name}: highlight leaves holes inside the picked region'
    (OUT / 'gpu-mask-validation.json').write_text(json.dumps(results,indent=2),encoding='utf-8')


if __name__ == '__main__':
    validate()
