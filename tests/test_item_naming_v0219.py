import unittest

from data.items import ITEM_DATA
from data.recipes import RECIPE_DATA


class ItemNamingV0219Tests(unittest.TestCase):
    def test_black_antler_item_name_matches_bracelet_slot(self):
        item = ITEM_DATA["black_antler_charm"]
        self.assertEqual(item["name"], "Bransoleta Czarnego Jelenia")
        self.assertEqual(item["slot"], "bracelet")
        self.assertEqual(RECIPE_DATA["black_antler_charm"]["name"], item["name"])
        self.assertNotIn("rzemyku", item["description"].lower())


if __name__ == "__main__":
    unittest.main()
