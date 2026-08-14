import random
import unittest

from items.affixes import EquipmentQuality, affix_count_for_rarity
from items.catalog import get_item_definition
from items.loot import LootDrop, add_loot_to_inventory
from player.factory import create_player
from systems.crafting import craft_for_player, get_recipe


class EquipmentGenerationSourcesV017Tests(unittest.TestCase):
    def test_loot_generates_full_affix_count(self) -> None:
        player = create_player("Tester")
        added = add_loot_to_inventory(
            player.inventory,
            [LootDrop("executioner_axe")],
            rng=random.Random(4),
            equipment_quality=EquipmentQuality.ELITE,
        )
        item = added.equipment_items[0]
        definition = get_item_definition(item.item_id)
        self.assertEqual(
            len(item.affixes),
            affix_count_for_rarity(definition.rarity),
        )

    def test_crafting_generates_affixes_for_equipment(self) -> None:
        player = create_player("Tester")
        recipe = get_recipe("wolf_tooth_necklace")
        for item_id, quantity in recipe.ingredients.items():
            player.inventory.add(item_id, quantity)

        craft_for_player(player, recipe, random.Random(8))
        crafted = next(
            item
            for item in player.inventory.equipment_items
            if item.item_id == recipe.output_item_id
        )
        self.assertEqual(len(crafted.affixes), 2)


if __name__ == "__main__":
    unittest.main()
