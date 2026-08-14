import random
import unittest
from unittest.mock import patch

from enemies.factory import create_enemy
from systems.weather_effects import (
    apply_weather_to_enemy,
    drop_chance_multiplier,
    reward_multiplier,
    roll_weather_boss_weapon,
)
from world.weather import (
    WEATHER_WEIGHTS,
    WeatherState,
    WeatherType,
    advance_weather,
)


class ZeroRandom(random.Random):
    def random(self) -> float:
        return 0.0


class WeatherTests(unittest.TestCase):
    def test_weather_weights_match_original_notes(self) -> None:
        weights = {weather: weight for weather, weight in WEATHER_WEIGHTS}
        self.assertEqual(weights[WeatherType.SUNNY], 30)
        self.assertEqual(weights[WeatherType.STORM], 20)
        self.assertEqual(weights[WeatherType.FROST], 20)
        self.assertEqual(weights[WeatherType.WIND], 20)
        self.assertEqual(weights[WeatherType.AURORA], 10)
        self.assertEqual(sum(weights.values()), 100)

    def test_weather_changes_after_six_world_hours(self) -> None:
        state = WeatherState(current=WeatherType.SUNNY, remaining_hours=6)
        with patch("world.weather.roll_weather", return_value=WeatherType.STORM):
            changes = advance_weather(state, 6, random.Random(1))
        self.assertEqual(state.current, WeatherType.STORM)
        self.assertEqual(state.remaining_hours, 6)
        self.assertEqual(changes, [(WeatherType.SUNNY, WeatherType.STORM)])

    def test_aurora_strengthens_normal_enemy_and_rewards(self) -> None:
        enemy = create_enemy("wolf")
        apply_weather_to_enemy(enemy, WeatherType.AURORA)
        self.assertGreater(enemy.max_hp, 9)
        self.assertEqual(enemy.attack, 5)
        self.assertEqual(enemy.defense, 2)
        self.assertEqual(reward_multiplier(WeatherType.AURORA), 1.5)
        self.assertEqual(drop_chance_multiplier(WeatherType.AURORA), 1.5)

    def test_storm_strengthens_miniboss_and_can_drop_weather_weapon(self) -> None:
        enemy = create_enemy("nature_guardian")
        apply_weather_to_enemy(enemy, WeatherType.STORM)
        self.assertGreater(enemy.max_hp, 24)
        self.assertEqual(enemy.attack, 8)
        drops = roll_weather_boss_weapon(enemy, WeatherType.STORM, ZeroRandom())
        self.assertEqual(len(drops), 1)
        self.assertEqual(drops[0].item_id, "stormroot_blade")

    def test_sunny_has_no_weather_boss_weapon(self) -> None:
        enemy = create_enemy("nature_guardian")
        self.assertEqual(
            roll_weather_boss_weapon(enemy, WeatherType.SUNNY, ZeroRandom()),
            [],
        )
