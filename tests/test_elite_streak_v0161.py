import unittest

from data.elites import ELITE_COMPATIBILITY
from data.enemies import ENEMY_DATA
from data.locations import LOCATION_DATA, LOCATION_ORDER
from enemies.factory import create_enemy
from systems.elite_system import (
    MAX_ELITE_CHANCE,
    elite_chance_with_streak,
    roll_elite_for_region,
)
from world.time_system import TimePeriod
from world.weather import WeatherType


class SequenceRng:
    def __init__(self, values: list[float]) -> None:
        self.values = list(values)

    def random(self) -> float:
        if not self.values:
            raise AssertionError("Brak kolejnej wartości RNG.")
        return self.values.pop(0)

    def choice(self, values):
        return values[0]


class EliteStreakV0161Tests(unittest.TestCase):
    def test_chance_increases_by_two_percentage_points(self) -> None:
        expected = [
            0.10,
            0.12,
            0.14,
            0.16,
            0.18,
        ]
        actual = [
            elite_chance_with_streak(
                TimePeriod.DAY,
                WeatherType.SUNNY,
                misses,
            )
            for misses in range(5)
        ]

        for result, target in zip(actual, expected):
            self.assertAlmostEqual(result, target)

    def test_night_and_aurora_keep_their_higher_base(self) -> None:
        self.assertAlmostEqual(
            elite_chance_with_streak(
                TimePeriod.NIGHT,
                WeatherType.SUNNY,
                3,
            ),
            0.21,
        )
        self.assertAlmostEqual(
            elite_chance_with_streak(
                TimePeriod.DAY,
                WeatherType.AURORA,
                3,
            ),
            0.31,
        )

    def test_chance_never_reaches_one_hundred_percent(self) -> None:
        for period, weather in (
            (TimePeriod.DAY, WeatherType.SUNNY),
            (TimePeriod.NIGHT, WeatherType.SUNNY),
            (TimePeriod.DAY, WeatherType.AURORA),
        ):
            chance = elite_chance_with_streak(
                period,
                weather,
                10_000,
            )
            self.assertEqual(chance, MAX_ELITE_CHANCE)
            self.assertLess(chance, 1.0)

    def test_failed_roll_increments_only_current_region(self) -> None:
        streaks = {
            "twilight_plains": 2,
            "black_forest": 4,
            "silentwater_marshes": 1,
        }
        enemy = create_enemy("wolf")

        result = roll_elite_for_region(
            enemy,
            TimePeriod.DAY,
            WeatherType.SUNNY,
            "twilight_plains",
            streaks,
            SequenceRng([0.99]),
        )

        self.assertIsNone(result)
        self.assertEqual(streaks["twilight_plains"], 3)
        self.assertEqual(streaks["black_forest"], 4)
        self.assertEqual(streaks["silentwater_marshes"], 1)

    def test_elite_roll_resets_only_current_region(self) -> None:
        streaks = {
            "twilight_plains": 5,
            "black_forest": 3,
            "silentwater_marshes": 7,
        }
        enemy = create_enemy("wolf")

        result = roll_elite_for_region(
            enemy,
            TimePeriod.DAY,
            WeatherType.SUNNY,
            "twilight_plains",
            streaks,
            SequenceRng([0.0]),
        )

        self.assertIsNotNone(result)
        self.assertEqual(streaks["twilight_plains"], 0)
        self.assertEqual(streaks["black_forest"], 3)
        self.assertEqual(streaks["silentwater_marshes"], 7)

    def test_high_streak_is_still_not_guaranteed(self) -> None:
        streaks = {"silentwater_marshes": 100}
        enemy = create_enemy("bone_crocodile")

        result = roll_elite_for_region(
            enemy,
            TimePeriod.DAY,
            WeatherType.SUNNY,
            "silentwater_marshes",
            streaks,
            SequenceRng([0.97]),
        )

        self.assertIsNone(result)
        self.assertEqual(streaks["silentwater_marshes"], 101)

    def test_miniboss_does_not_change_region_counter(self) -> None:
        streaks = {"silentwater_marshes": 6}
        enemy = create_enemy("drowned_mother")

        result = roll_elite_for_region(
            enemy,
            TimePeriod.NIGHT,
            WeatherType.AURORA,
            "silentwater_marshes",
            streaks,
            SequenceRng([]),
        )

        self.assertIsNone(result)
        self.assertEqual(streaks["silentwater_marshes"], 6)

    def test_every_normal_overworld_enemy_is_elite_compatible(self) -> None:
        missing: set[str] = set()

        for location_id in LOCATION_ORDER:
            location = LOCATION_DATA[location_id]
            enemy_ids = (
                set(location["day_encounters"])
                | set(location["night_encounters"])
            )
            for enemy_id in enemy_ids:
                rank = str(
                    ENEMY_DATA[enemy_id].get("rank", "normal")
                )
                if (
                    rank == "normal"
                    and enemy_id not in ELITE_COMPATIBILITY
                ):
                    missing.add(enemy_id)

        self.assertEqual(
            missing,
            set(),
            f"Zwykli przeciwnicy bez wariantu elity: {sorted(missing)}",
        )


if __name__ == "__main__":
    unittest.main()
