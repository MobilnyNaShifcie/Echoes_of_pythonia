import unittest

from data.enemies import ENEMY_DATA
from world.factory import create_location, create_world_locations


class WorldMapTests(unittest.TestCase):
    def test_world_has_five_playable_locations(self) -> None:
        locations = create_world_locations()

        self.assertEqual(len(locations), 5)
        self.assertEqual(locations[0].location_id, "twilight_plains")
        self.assertEqual(locations[1].location_id, "black_forest")
        self.assertEqual(locations[2].location_id, "silentwater_marshes")
        self.assertEqual(locations[3].location_id, "ashen_borderlands")
        self.assertEqual(locations[4].location_id, "ice_coast")

    def test_black_forest_recommends_level_two_to_four(self) -> None:
        location = create_location("black_forest")

        self.assertEqual(location.danger_rating, 2)
        self.assertEqual(location.recommended_level_min, 2)
        self.assertEqual(location.recommended_level_max, 4)

    def test_all_location_encounters_reference_existing_enemies(self) -> None:
        for location in create_world_locations():
            enemy_ids = (
                set(location.day_encounters)
                | set(location.night_encounters)
            )

            for enemy_id in enemy_ids:
                self.assertIn(enemy_id, ENEMY_DATA)
