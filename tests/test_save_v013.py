import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from game.adventure_log import AdventureLog
from game.state import GameState
from player.passives import PassiveType
from player.factory import create_player
from systems.achievements import achievements_after_victory
from systems.save_system import load_game, save_game
from world.time_system import GameClock
from world.weather import WeatherState, WeatherType


class SaveV013Tests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.patch = patch(
            "systems.save_system.get_save_directory",
            return_value=Path(self.temp.name),
        )
        self.patch.start()

    def tearDown(self) -> None:
        self.patch.stop()
        self.temp.cleanup()

    def test_new_systems_survive_save_and_load(self) -> None:
        player = create_player("Tester")
        player.level = 2
        player.spend_passive_point(PassiveType.INCREASED_ATTACK)
        achievements_after_victory(player, "wolf", WeatherType.AURORA)
        player.achievements.equip_title("Dziecko Zorzy")
        state = GameState(
            active_game=True,
            player=player,
            world_clock=GameClock(day=9, hour=22),
            weather=WeatherState(WeatherType.AURORA, 3),
            adventure_log=AdventureLog(entries=["Testowy wpis"]),
        )
        save_game(state)
        loaded = load_game()
        self.assertEqual(loaded.player.passives.increased_attack, 1)
        self.assertIn("aurora_hunter", loaded.player.achievements.unlocked)
        self.assertEqual(loaded.player.achievements.equipped_title, "Dziecko Zorzy")
        self.assertEqual(loaded.weather.current, WeatherType.AURORA)
        self.assertEqual(loaded.weather.remaining_hours, 3)
        self.assertEqual(loaded.adventure_log.entries, ["Testowy wpis"])

    def test_schema_three_save_migrates_with_safe_defaults(self) -> None:
        player = create_player("Tester")
        path = save_game(GameState(active_game=True, player=player))
        payload = json.loads(path.read_text(encoding="utf-8"))
        payload["schema_version"] = 3
        payload["player"].pop("passives", None)
        payload["player"].pop("achievements", None)
        payload["world"].pop("weather", None)
        payload["world"].pop("weather_remaining_hours", None)
        payload.pop("adventure_log", None)
        path.write_text(json.dumps(payload), encoding="utf-8")
        loaded = load_game()
        self.assertEqual(loaded.player.passives.spent_points, 0)
        self.assertEqual(loaded.player.achievements.equipped_title, "Wędrowiec")
        self.assertEqual(loaded.weather.current, WeatherType.SUNNY)
        self.assertEqual(loaded.adventure_log.entries, [])
