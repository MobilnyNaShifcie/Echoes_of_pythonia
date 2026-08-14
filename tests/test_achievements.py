import unittest

from player.factory import create_player
from systems.achievements import achievements_after_victory
from world.weather import WeatherType


class AchievementTests(unittest.TestCase):
    def test_boss_victory_unlocks_title(self) -> None:
        player = create_player("Tester")
        unlocked = achievements_after_victory(
            player,
            "nature_guardian",
            WeatherType.SUNNY,
        )
        ids = {achievement.achievement_id for achievement in unlocked}
        self.assertIn("first_blood", ids)
        self.assertIn("nature_breaker", ids)
        player.achievements.equip_title("Pogromca Natury")
        self.assertEqual(player.display_name, "[Pogromca Natury] Tester")

    def test_achievement_cannot_unlock_twice(self) -> None:
        player = create_player("Tester")
        achievements_after_victory(player, "wolf", WeatherType.SUNNY)
        second = achievements_after_victory(player, "wolf", WeatherType.SUNNY)
        self.assertEqual(second, [])

    def test_aurora_victory_unlocks_aurora_title(self) -> None:
        player = create_player("Tester")
        unlocked = achievements_after_victory(player, "wolf", WeatherType.AURORA)
        self.assertIn("aurora_hunter", {item.achievement_id for item in unlocked})
