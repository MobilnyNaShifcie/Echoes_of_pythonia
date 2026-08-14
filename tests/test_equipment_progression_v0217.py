import unittest

from data.loot_tables import LOOT_TABLES
from items.catalog import get_item_definition
from systems.crafting import get_recipe


class EquipmentProgressionV0217Tests(unittest.TestCase):
    def test_missing_slot_progression_items_have_expected_power_and_levels(self) -> None:
        expected = {
            "drowned_mother_medallion": ("necklace", 3, 8),
            "order_bracelet": ("bracelet", 4, 10),
            "wasteland_belt": ("belt", 5, 13),
            "captain_signet": ("bracelet", 6, 17),
        }
        for item_id, (slot, item_power, level) in expected.items():
            definition = get_item_definition(item_id)
            self.assertEqual(definition.slot.code, slot)
            self.assertEqual(definition.item_power, item_power)
            self.assertEqual(definition.required_level, level)

    def test_captain_item_is_now_karwasz_not_second_ring(self) -> None:
        captain = get_item_definition("captain_signet")
        leviathan = get_item_definition("leviathan_ring")
        self.assertEqual(captain.name, "Bransoleta Czarnej Floty")
        self.assertEqual(captain.slot.code, "bracelet")
        self.assertEqual(leviathan.slot.code, "ring")
        self.assertEqual(captain.item_power, leviathan.item_power)

    def test_new_progression_items_have_deliberate_sources(self) -> None:
        drowned_drops = {entry["item_id"] for entry in LOOT_TABLES["drowned_mother"]}
        self.assertIn("drowned_mother_medallion", drowned_drops)
        for recipe_id in ("drowned_mother_medallion", "order_bracelet", "wasteland_belt", "captain_signet"):
            self.assertEqual(get_recipe(recipe_id).output_item_id, recipe_id)


if __name__ == "__main__":
    unittest.main()
