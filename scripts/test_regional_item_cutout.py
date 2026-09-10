"""Small deterministic tests for the authorized local alpha preparation."""
import tempfile
import unittest
from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw
from prepare_regional_item_icon import cutout, prepare, despill_combat_edges


class CutoutTests(unittest.TestCase):
    def test_shadow_key_removes_saturated_pink_but_keeps_purple_leather(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'gloves.png'
            source = Image.new('RGB', (128, 128), (255, 0, 255))
            draw = ImageDraw.Draw(source)
            draw.rectangle((25, 25, 106, 106), fill=(170, 0, 170))
            draw.rectangle((30, 30, 96, 96), fill=(100, 65, 110))
            source.save(path)
            result, _ = cutout(path, key_shadows=True)
            self.assertEqual(result.getpixel((103, 70))[3], 0)
            self.assertEqual(result.getpixel((64, 64)), (100, 65, 110, 255))

    def test_white_checker_extraction_keeps_internal_specular_highlight(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'claw.png'
            source = Image.new('RGB', (128, 128), (244, 244, 244))
            draw = ImageDraw.Draw(source)
            draw.rectangle((32, 32, 96, 96), fill=(60, 50, 40))
            draw.rectangle((52, 52, 72, 72), fill=(244, 244, 244))
            source.save(path)
            result, _ = cutout(path)
            self.assertEqual(result.getpixel((0, 0))[3], 0)
            self.assertEqual(result.getpixel((62, 62))[3], 255)

    def test_chroma_removes_ring_hole_without_erasing_grey_material(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'ring.png'
            source = Image.new('RGB', (128, 128), (255, 0, 255))
            draw = ImageDraw.Draw(source)
            draw.ellipse((20, 20, 108, 108), fill=(230, 230, 230))
            draw.ellipse((44, 44, 84, 84), fill=(255, 0, 255))
            source.save(path)
            result, _ = cutout(path)
            self.assertEqual(result.getpixel((64, 64))[3], 0)
            self.assertEqual(result.getpixel((32, 64))[3], 255)
            output = Path(folder) / 'out.png'
            prepare(path, output, Path(folder) / 'preview')
            pixels = np.asarray(Image.open(output))
            self.assertEqual(pixels.shape, (512, 512, 4))
            self.assertTrue(np.all(pixels[pixels[:, :, 3] == 0] == 0))

    def test_reviewed_neutral_hole_is_removed_but_other_highlight_stays(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'chain.png'
            source = Image.new('RGB', (128, 128), (244, 244, 244))
            draw = ImageDraw.Draw(source)
            draw.rectangle((25, 25, 103, 103), fill=(50, 60, 75))
            draw.rectangle((36, 40, 59, 80), fill=(244, 244, 244))
            draw.rectangle((72, 40, 90, 80), fill=(244, 244, 244))
            source.save(path)
            result, mode = cutout(path, background_seeds=[(.37, .47)])
            self.assertEqual(mode, 'neutral_checker_reviewed_holes')
            self.assertEqual(result.getpixel((47, 60))[3], 0)
            self.assertEqual(result.getpixel((81, 60))[3], 255)
            with self.assertRaises(ValueError):
                cutout(path, background_seeds=[(.23, .23)])

    def test_existing_alpha_is_preserved(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'rgba.png'
            source = Image.new('RGBA', (128, 128))
            source.putpixel((64, 64), (120, 80, 20, 128))
            source.save(path)
            result, mode = cutout(path)
            self.assertEqual(mode, 'preserved_existing_alpha')
            self.assertEqual(result.getpixel((64, 64)), (120, 80, 20, 128))

    def test_combat_despill_is_local_and_keeps_white_fur(self):
        source = Image.new('RGBA', (128, 128))
        draw = ImageDraw.Draw(source)
        draw.rectangle((20, 20, 108, 108), fill=(60, 40, 90, 255))
        draw.rectangle((20, 20, 24, 108), fill=(130, 40, 150, 170))
        draw.rectangle((99, 20, 108, 108), fill=(245, 245, 250, 255))
        result = despill_combat_edges(source)
        self.assertEqual(result.getpixel((64, 64)), (60, 40, 90, 255))
        self.assertEqual(result.getpixel((105, 60)), (245, 245, 250, 255))
        self.assertEqual(result.getpixel((22, 64)), (44, 40, 64, 170))
        self.assertEqual(result.getpixel((0, 0)), (0, 0, 0, 0))


if __name__ == '__main__':
    unittest.main()
