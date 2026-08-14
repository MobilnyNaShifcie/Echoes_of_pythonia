import unittest

from systems.elite_system import ELITE_MISS_BONUS, elite_chance_with_streak
from world.time_system import TimePeriod
from world.weather import WeatherType


class EliteTuningV0162Tests(unittest.TestCase):
    def test_bonus_is_two_percentage_points(self) -> None:
        self.assertAlmostEqual(ELITE_MISS_BONUS, 0.02)

    def test_day_progression_matches_new_balance(self) -> None:
        self.assertAlmostEqual(elite_chance_with_streak(TimePeriod.DAY, WeatherType.SUNNY, 0), 0.10)
        self.assertAlmostEqual(elite_chance_with_streak(TimePeriod.DAY, WeatherType.SUNNY, 1), 0.12)
        self.assertAlmostEqual(elite_chance_with_streak(TimePeriod.DAY, WeatherType.SUNNY, 2), 0.14)
        self.assertAlmostEqual(elite_chance_with_streak(TimePeriod.DAY, WeatherType.SUNNY, 3), 0.16)

if __name__ == "__main__":
    unittest.main()
