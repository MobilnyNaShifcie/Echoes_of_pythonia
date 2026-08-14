import random
import unittest

from world.exploration import explore_location
from world.location import Location
from world.time_system import TimePeriod


class ExplorationTests(unittest.TestCase):
    def _make_location(
        self,
        encounter_chance: float,
        day_encounters: dict[str, int],
        night_encounters: dict[str, int],
    ) -> Location:
        return Location(
            location_id="test",
            name="Test",
            description="",
            danger_rating=1,
            recommended_level_min=0,
            recommended_level_max=1,
            encounter_chance=encounter_chance,
            day_encounters=day_encounters,
            night_encounters=night_encounters,
            quiet_events=("Cisza.",),
        )

    def test_single_enemy_table_returns_that_enemy(self) -> None:
        location = self._make_location(
            encounter_chance=1.0,
            day_encounters={"wolf": 1},
            night_encounters={"plains_spirit": 1},
        )

        result = explore_location(
            location,
            TimePeriod.DAY,
            random.Random(1),
        )

        self.assertTrue(result.has_encounter)
        self.assertEqual(result.enemy_id, "wolf")

    def test_zero_encounter_chance_returns_quiet_event(self) -> None:
        location = self._make_location(
            encounter_chance=0.0,
            day_encounters={"wolf": 1},
            night_encounters={"wolf": 1},
        )

        result = explore_location(
            location,
            TimePeriod.DAY,
            random.Random(1),
        )

        self.assertFalse(result.has_encounter)
        self.assertEqual(result.message, "Cisza.")


if __name__ == "__main__":
    unittest.main()
