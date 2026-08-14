import unittest

from systems.crafting import can_craft, craft, get_recipe
from player.factory import create_player


class CraftingTests(unittest.TestCase):
    def test_can_craft_leather_hood_with_materials(self) -> None:
        player = create_player("Tester")
        player.inventory.add("weak_leather", 2)
        recipe = get_recipe("leather_hood")

        self.assertTrue(can_craft(player.inventory, recipe))

        craft(player.inventory, recipe)

        self.assertEqual(player.inventory.count("weak_leather"), 0)
        self.assertEqual(player.inventory.count("leather_hood"), 1)

    def test_missing_materials_prevent_crafting(self) -> None:
        player = create_player("Tester")
        recipe = get_recipe("stitched_armor")

        self.assertFalse(can_craft(player.inventory, recipe))

        with self.assertRaises(ValueError):
            craft(player.inventory, recipe)

    def test_sharpened_sword_requires_starter_sword_in_inventory(self) -> None:
        player = create_player("Tester")
        player.inventory.add("whetstone", 2)
        recipe = get_recipe("sharpened_sword")

        # Starter sword is equipped, not in the backpack.
        self.assertFalse(can_craft(player.inventory, recipe))

        player.unequip_to_inventory(
            next(
                slot
                for slot, item in player.equipment.slots.items()
                if item.item_id == "starter_sword"
            )
        )

        self.assertTrue(can_craft(player.inventory, recipe))

        craft(player.inventory, recipe)

        self.assertEqual(player.inventory.count("starter_sword"), 0)
        self.assertEqual(player.inventory.count("whetstone"), 0)
        self.assertEqual(player.inventory.count("sharpened_sword"), 1)

    def test_black_forest_recipe_consumes_materials(self) -> None:
        player = create_player("Tester")
        player.inventory.add("spider_silk", 4)
        player.inventory.add("venom_gland", 1)
        recipe = get_recipe("spiderweave_gloves")

        craft(player.inventory, recipe)

        self.assertEqual(player.inventory.count("spider_silk"), 0)
        self.assertEqual(player.inventory.count("venom_gland"), 0)
        self.assertEqual(
            player.inventory.count("spiderweave_gloves"),
            1,
        )
