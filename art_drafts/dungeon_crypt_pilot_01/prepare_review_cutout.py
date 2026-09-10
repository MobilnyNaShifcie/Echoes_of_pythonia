"""Reproducible, previously authorized alpha extraction; no art repainting."""
from pathlib import Path
import sys
from PIL import Image

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
sys.path.insert(0, str(ROOT / 'scripts'))
from prepare_regional_item_icon import cutout, prepare_combat

source = HERE / 'order_grandmaster_source.png'
with Image.open(source) as image:
    width, height = image.size
# Three visually checked tears in the cloak still contained the fake checkerboard.
reviewed_holes = [(279 / width, 1143 / height),
                  (310 / width, 1178 / height),
                  (985 / width, 1074 / height)]
art, mode = cutout(source, background_seeds=reviewed_holes)
intermediate = HERE / 'qa' / 'order_grandmaster_alpha_source.png'
intermediate.parent.mkdir(parents=True, exist_ok=True)
art.save(intermediate)
print(mode)
prepare_combat(intermediate, HERE / 'order_grandmaster.png', HERE / 'qa')
