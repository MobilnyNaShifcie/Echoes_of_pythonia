"""Synthetic regressions for this opt-in draft extraction, no production files."""
import unittest

import numpy as np
from PIL import Image, ImageDraw

from prepare_alpha import connected_background, extract, padded


class PilotAlphaTests(unittest.TestCase):
    def sample(self):
        y, x = np.indices((120, 160))
        grey = np.where(((x // 8 + y // 8) % 2) == 0, 140, 200).astype(np.uint8)
        image = Image.fromarray(np.repeat(grey[:, :, None], 3, axis=2))
        draw = ImageDraw.Draw(image)
        draw.rectangle((30, 25, 130, 100), fill=(10, 20, 35))
        draw.rectangle((32, 27, 128, 98), fill=(150, 220, 250))
        draw.rectangle((50, 45, 70, 65), fill=(242, 242, 242))
        draw.rectangle((90, 45, 110, 65), fill=(160, 160, 160))
        return image

    def test_only_exterior_and_explicit_hole_removed(self):
        image = self.sample()
        result, _ = extract(image, 95, 14, holes=[(100, 55)])
        self.assertEqual(result.getpixel((0, 0)), (0, 0, 0, 0))
        self.assertEqual(result.getpixel((100, 55)), (0, 0, 0, 0))
        self.assertEqual(result.getpixel((60, 55)), (242, 242, 242, 255))
        self.assertEqual(result.getpixel((80, 75)), (150, 220, 250, 255))

    def test_dark_ink_edge_not_misinterpreted_as_alpha(self):
        result, _ = extract(self.sample(), 95, 14)
        self.assertEqual(result.getpixel((30, 60)), (10, 20, 35, 255))
        self.assertEqual(result.getpixel((80, 25)), (10, 20, 35, 255))

    def test_invalid_seed_rejected(self):
        rgb = np.asarray(self.sample()).astype(np.float32)
        with self.assertRaises(ValueError):
            connected_background(rgb, 95, 14, holes=[(80, 75)])
        with self.assertRaises(ValueError):
            connected_background(rgb, 95, 14, holes=[(-1, 0)])

    def test_padding_preserves_pixels_and_aspect(self):
        art, _ = extract(self.sample(), 95, 14)
        result, report = padded(art)
        bounds = result.getchannel('A').getbbox()
        self.assertEqual(result.crop(bounds).tobytes(), art.crop(art.getchannel('A').getbbox()).tobytes())
        self.assertFalse(report['resampled'])
        self.assertGreaterEqual(bounds[0] / result.width, .07)
        self.assertGreaterEqual(bounds[1] / result.height, .07)
        self.assertEqual(bounds[0], result.width - bounds[2])
        self.assertEqual(bounds[1], result.height - bounds[3])

    def test_existing_rgba_is_not_rekeyed(self):
        with self.assertRaises(ValueError):
            extract(self.sample().convert('RGBA'), 95, 14)


if __name__ == '__main__':
    unittest.main()
