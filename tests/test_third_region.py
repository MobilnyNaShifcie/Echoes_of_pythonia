import unittest

from data.enemies import ENEMY_DATA
from items.catalog import item_exists
from systems.crafting import get_all_recipes
from world.factory import create_location, create_world_locations


class ThirdRegionTests(unittest.TestCase):
    def test_silentwater_remains_third_region(self) -> None:
        locations = create_world_locations()
        self.assertGreaterEqual(len(locations), 3)
        self.assertEqual(locations[2].location_id, "silentwater_marshes")

    def test_silentwater_balance_band(self) -> None:
        location = create_location("silentwater_marshes")
        self.assertEqual(location.danger_rating, 3)
        self.assertEqual(location.recommended_level_min, 5)
        self.assertEqual(location.recommended_level_max, 8)
        self.assertIn("drowned_mother", location.night_encounters)

    def test_all_silentwater_enemies_exist(self) -> None:
        location = create_location("silentwater_marshes")
        for enemy_id in set(location.day_encounters) | set(location.night_encounters):
            self.assertIn(enemy_id, ENEMY_DATA)

    def test_new_crafting_outputs_exist(self) -> None:
        recipe_ids = {recipe.recipe_id for recipe in get_all_recipes()}
        for recipe_id in {"mirewalker_boots", "witchbone_ring", "scale_belt", "strong_healing_potion"}:
            self.assertIn(recipe_id, recipe_ids)
        for item_id in {"mirewalker_boots", "witchbone_ring", "scale_belt", "strong_healing_potion"}:
            self.assertTrue(item_exists(item_id))
