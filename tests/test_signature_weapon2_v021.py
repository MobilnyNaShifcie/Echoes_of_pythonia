import random
import unittest

from data.loot_tables import LOOT_TABLES
from items.affixes import EquipmentQuality, generate_equipment_item
from items.catalog import get_item_definition
from items.models import EquipmentSlot
from items.signature_weapons import (
    average_damage_range,
    is_signature_dungeon_weapon,
    signature_weapon_source_boss,
)
from player.factory import create_player
from systems.crafting import craft_for_player, get_recipe


class SignatureWeapon2V021Tests(unittest.TestCase):
    def test_varek_sabre_is_second_signature_weapon(self) -> None:
        self.assertTrue(is_signature_dungeon_weapon("varek_sabre"))
        self.assertEqual(signature_weapon_source_boss("varek_sabre"), "admiral_varek")
        self.assertEqual(average_damage_range("varek_sabre"), (-8, 22))

    def test_varek_sabre_is_ip_seven_level_twenty_legendary(self) -> None:
        definition = get_item_definition("varek_sabre")
        self.assertEqual(definition.name, "Szabla Admirała Vareka")
        self.assertEqual(definition.item_power, 7)
        self.assertEqual(definition.required_level, 20)
        self.assertEqual(definition.rarity.display_name, "Legendarny")

    def test_each_varek_sabre_rolls_average_damage_independently(self) -> None:
        values = {
            generate_equipment_item(
                "varek_sabre",
                random.Random(seed),
                quality=EquipmentQuality.BOSS,
            ).average_damage_percent
            for seed in range(50)
        }
        self.assertTrue(all(value is not None and -8 <= value <= 22 for value in values))
        self.assertGreater(len(values), 1)

    def test_average_damage_does_not_consume_four_legendary_affixes(self) -> None:
        item = generate_equipment_item(
            "varek_sabre",
            random.Random(21),
            quality=EquipmentQuality.BOSS,
        )
        self.assertEqual(len(item.affixes), 4)
        self.assertIsNotNone(item.average_damage_percent)

    def test_varek_has_ten_percent_direct_sabre_drop(self) -> None:
        drops = {
            str(entry["item_id"]): float(entry["chance"])
            for entry in LOOT_TABLES["admiral_varek"]
        }
        self.assertEqual(drops["varek_sabre_fragment"], 1.0)
        self.assertEqual(drops["varek_sabre"], 0.10)

    def test_crafting_is_two_clear_bad_luck_protection(self) -> None:
        player = create_player("Tester")
        recipe = get_recipe("varek_sabre")
        self.assertEqual(recipe.ingredients["varek_sabre_fragment"], 2)
        for item_id, quantity in recipe.ingredients.items():
            player.inventory.add(item_id, quantity)
        player.gold = recipe.gold_cost

        craft_for_player(player, recipe, random.Random(9))

        sabres = [
            item
            for item in player.inventory.equipment_items
            if item.item_id == "varek_sabre"
        ]
        self.assertEqual(len(sabres), 1)
        self.assertIsNotNone(sabres[0].average_damage_percent)
        self.assertEqual(len(sabres[0].affixes), 4)
        self.assertEqual(player.gold, 0)

    def test_level_nineteen_cannot_equip_but_level_twenty_can(self) -> None:
        player = create_player("Tester")
        player.level = 19
        player.inventory.add_generated_equipment(
            "varek_sabre",
            random.Random(4),
            quality=EquipmentQuality.BOSS,
        )

        with self.assertRaisesRegex(ValueError, "Wymagany poziom: 20"):
            player.equip_from_inventory(0)

        self.assertEqual(len(player.inventory.equipment_items), 1)
        player.level = 20
        player.equip_from_inventory(0)
        self.assertEqual(player.equipment.slots[EquipmentSlot.WEAPON].item_id, "varek_sabre")


if __name__ == "__main__":
    unittest.main()
