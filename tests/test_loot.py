import random
import unittest

from data.loot_tables import LOOT_TABLES
from items.catalog import item_exists
from items.loot import roll_loot


class LootTests(unittest.TestCase):
    def test_all_loot_entries_reference_existing_items(self) -> None:
        for entries in LOOT_TABLES.values():
            for entry in entries:
                self.assertTrue(item_exists(str(entry["item_id"])))
                chance = float(entry["chance"])
                self.assertGreaterEqual(chance, 0.0)
                self.assertLessEqual(chance, 1.0)

    def test_boar_always_drops_raw_meat(self) -> None:
        for seed in range(20):
            drops = roll_loot("boar", random.Random(seed))
            item_ids = {drop.item_id for drop in drops}
            self.assertIn("raw_boar_meat", item_ids)

    def test_unknown_enemy_has_empty_loot_table(self) -> None:
        drops = roll_loot("enemy_that_does_not_exist", random.Random(1))
        self.assertEqual(drops, [])
