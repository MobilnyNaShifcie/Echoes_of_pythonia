import unittest

from data.loot_tables import LOOT_TABLES
from enemies.factory import create_enemy
from items.catalog import get_item_definition
from systems.contracts import _accessible_regions, generate_weekly_contract
from player.factory import create_player
from world.factory import create_location, create_world_locations


class FifthRegionV020Tests(unittest.TestCase):
    def test_ice_coast_is_fifth_region_for_levels_fourteen_to_eighteen(self) -> None:
        locations = create_world_locations()
        self.assertEqual(locations[4].location_id, "ice_coast")
        region = create_location("ice_coast")
        self.assertEqual(region.name, "Lodowe Wybrzeże")
        self.assertEqual(region.danger_rating, 5)
        self.assertEqual(region.recommended_level_min, 14)
        self.assertEqual(region.recommended_level_max, 18)

    def test_region_uses_approved_enemy_names(self) -> None:
        expected = {
            "frozen_castaway": "Zamarznięty Rozbitek",
            "ice_bear": "Lodowy Niedźwiedź",
            "snow_griffin": "Śnieżny Gryf",
            "ice_crab": "Lodowy Krab",
            "black_sea_siren": "Syrena Czarnego Morza",
            "ghost_ship_captain": "Widmo Kapitana Statku",
            "leviathan_north": "Lewiatan Północy",
        }
        for enemy_id, name in expected.items():
            self.assertEqual(create_enemy(enemy_id).name, name)

    def test_siren_is_strongest_normal_enemy_in_region(self) -> None:
        siren = create_enemy("black_sea_siren")
        normal_ids = (
            "frozen_castaway", "ice_bear", "snow_griffin", "ice_crab"
        )
        self.assertGreater(siren.attack, max(create_enemy(e).attack for e in normal_ids))
        self.assertGreater(siren.experience_reward, max(create_enemy(e).experience_reward for e in normal_ids))

    def test_captain_is_night_miniboss_and_leviathan_is_not_random(self) -> None:
        region = create_location("ice_coast")
        encounters = set(region.day_encounters) | set(region.night_encounters)
        self.assertEqual(region.night_encounters["ghost_ship_captain"], 5)
        self.assertNotIn("leviathan_north", encounters)
        self.assertEqual(create_enemy("ghost_ship_captain").rank, "miniboss")
        self.assertEqual(create_enemy("leviathan_north").rank, "boss")

    def test_encounter_weights_are_complete(self) -> None:
        region = create_location("ice_coast")
        self.assertEqual(sum(region.day_encounters.values()), 100)
        self.assertEqual(sum(region.night_encounters.values()), 100)

    def test_region_five_equipment_is_item_power_six(self) -> None:
        expected_levels = {
            "northern_trail_boots": 15,
            "black_pearl_earrings": 16,
            "north_armor": 16,
            "snow_griffin_cloak": 16,
            "black_sea_amulet": 16,
            "captain_signet": 17,
            "leviathan_ring": 18,
        }
        for item_id, required_level in expected_levels.items():
            definition = get_item_definition(item_id)
            self.assertEqual(definition.item_power, 6)
            self.assertEqual(definition.required_level, required_level)

    def test_level_seventeen_contracts_use_ice_coast(self) -> None:
        self.assertIn("ice_coast", _accessible_regions(17))
        player = create_player("Tester")
        player.level = 17
        weekly = generate_weekly_contract(player, "2099-W01")
        self.assertEqual(weekly.objectives[0].target_id, "ice_coast")

    def test_class_items_are_not_crafting_material_noise(self) -> None:
        for enemy_id in ("ice_bear", "snow_griffin", "black_sea_siren"):
            class_drops = [
                entry for entry in LOOT_TABLES[enemy_id]
                if get_item_definition(str(entry["item_id"])).is_equipment
            ]
            self.assertEqual(len(class_drops), 1)


if __name__ == "__main__":
    unittest.main()
