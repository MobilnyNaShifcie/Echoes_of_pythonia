"""Regression checks for chroma-key QA, including legitimate mage crystals."""
import unittest
import numpy as np
from verify_anime_item_batch import strong_key_mask


class KeyDetectionTests(unittest.TestCase):
    def test_opaque_pink_key_and_dark_residue_are_rejected(self):
        pixels = np.array([[[255, 0, 255, 255], [185, 20, 190, 128]]], dtype=np.uint8)
        self.assertTrue(strong_key_mask(pixels).all())

    def test_blue_violet_crystals_and_white_reflections_are_preserved(self):
        pixels = np.array([[[195, 38, 238, 255], [173, 25, 221, 255],
                            [255, 255, 255, 255]]], dtype=np.uint8)
        self.assertFalse(strong_key_mask(pixels).any())

    def test_transparent_rgb_is_not_visible_key_residue(self):
        pixels = np.array([[[255, 0, 255, 0], [255, 0, 255, 32]]], dtype=np.uint8)
        self.assertFalse(strong_key_mask(pixels).any())


if __name__ == "__main__":
    unittest.main()
