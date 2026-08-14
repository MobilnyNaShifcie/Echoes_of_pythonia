import random
import unittest

from data.items import ITEM_DATA
from data.loot_tables import LOOT_TABLES
from enemies.factory import create_enemy
from items.affixes import generate_equipment_item
from items.catalog import get_item_definition
from items.signature_weapons import is_signature_dungeon_weapon
from systems.contracts import _accessible_regions, generate_weekly_contract
from world.factory import create_location, create_world_locations
from player.factory import create_player


class FourthRegionV019Tests(unittest.TestCase):
    def test_region_is_fourth_and_targets_level_ten_to_fourteen(self) -> None:
        locations = create_world_locations()
        self.assertEqual(locations[3].location_id, "ashen_borderlands")

        region = create_location("ashen_borderlands")
        self.assertEqual(region.name, "Popielne Pogranicze")
        self.assertEqual(region.danger_rating, 4)
        self.assertEqual(region.recommended_level_min, 10)
        self.assertEqual(region.recommended_level_max, 14)

    def test_region_uses_approved_enemy_names(self) -> None:
        expected = {
            "sand_golem": "Piaskowy Golem",
            "desert_harpy": "Pustynna Harpia",
            "desert_wanderer": "Pustynny Wędrowiec",
            "boneburner": "Kościopal",
            "red_salamander": "Czerwona Salamandra",
            "hearth_devourer": "Pożeracz Palenisk",
            "azhar": "Azhar, Władca Pustkowi",
        }
        for enemy_id, name in expected.items():
            self.assertEqual(create_enemy(enemy_id).name, name)

    def test_azhar_is_not_a_random_encounter(self) -> None:
        region = create_location("ashen_borderlands")
        random_encounters = set(region.day_encounters) | set(region.night_encounters)
        self.assertNotIn("azhar", random_encounters)
        self.assertEqual(region.night_encounters["hearth_devourer"], 10)

    def test_encounter_weights_form_complete_day_and_night_tables(self) -> None:
        region = create_location("ashen_borderlands")
        self.assertEqual(sum(region.day_encounters.values()), 100)
        self.assertEqual(sum(region.night_encounters.values()), 100)

    def test_region_has_the_planned_hp_scale(self) -> None:
        self.assertGreaterEqual(create_enemy("desert_harpy").max_hp, 180)
        self.assertGreaterEqual(create_enemy("sand_golem").max_hp, 400)
        self.assertGreaterEqual(create_enemy("hearth_devourer").max_hp, 950)
        self.assertGreaterEqual(create_enemy("azhar").max_hp, 1700)
        self.assertLessEqual(create_enemy("azhar").max_hp, 2000)

    def test_normal_region_loot_is_material_focused(self) -> None:
        normal_ids = {
            "desert_wanderer",
            "desert_harpy",
            "red_salamander",
            "boneburner",
            "sand_golem",
        }
        for enemy_id in normal_ids:
            for entry in LOOT_TABLES[enemy_id]:
                self.assertEqual(
                    ITEM_DATA[str(entry["item_id"])]["category"],
                    "material",
                )

    def test_region_four_equipment_is_item_power_five(self) -> None:
        expected_levels = {
            "wasteland_armor": 11,
            "sun_talisman": 12,
            "hearth_gauntlets": 13,
            "azhar_blade": 14,
            "azhar_crown": 14,
            "azhar_ring": 14,
        }
        for item_id, required_level in expected_levels.items():
            definition = get_item_definition(item_id)
            self.assertEqual(definition.item_power, 5)
            self.assertEqual(definition.required_level, required_level)

    def test_azhar_blade_is_not_a_signature_average_damage_weapon(self) -> None:
        self.assertFalse(is_signature_dungeon_weapon("azhar_blade"))
        item = generate_equipment_item("azhar_blade", random.Random(19))
        self.assertIsNone(item.average_damage_percent)

    def test_high_level_contracts_can_use_region_four(self) -> None:
        self.assertIn("ashen_borderlands", _accessible_regions(17))
        player = create_player("Tester")
        player.level = 17
        contract = generate_weekly_contract(player, "2099-W01")
        self.assertEqual(contract.objectives[0].target_id, "ice_coast")


if __name__ == "__main__":
    unittest.main()
