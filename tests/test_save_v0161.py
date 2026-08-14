import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from game.state import GameState
from player.factory import create_player
from systems.save_system import load_game, save_game


class SaveV0161Tests(unittest.TestCase):
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

    def test_region_elite_streaks_survive_save_and_load(self) -> None:
        state = GameState(
            active_game=True,
            player=create_player("Tester"),
        )
        state.elite_miss_streaks = {
            "twilight_plains": 3,
            "black_forest": 7,
            "silentwater_marshes": 1,
        }

        save_game(state)
        loaded = load_game()

        self.assertEqual(
            loaded.elite_miss_streaks,
            state.elite_miss_streaks,
        )

    def test_schema_six_migrates_with_empty_streaks(self) -> None:
        state = GameState(
            active_game=True,
            player=create_player("Tester"),
        )
        path = save_game(state)

        payload = json.loads(path.read_text(encoding="utf-8"))
        payload["schema_version"] = 6
        payload.pop("elite_miss_streaks", None)
        path.write_text(
            json.dumps(payload),
            encoding="utf-8",
        )

        loaded = load_game()

        self.assertEqual(loaded.elite_miss_streaks, {})

    def test_negative_streak_is_rejected(self) -> None:
        state = GameState(
            active_game=True,
            player=create_player("Tester"),
        )
        path = save_game(state)

        payload = json.loads(path.read_text(encoding="utf-8"))
        payload["elite_miss_streaks"] = {
            "twilight_plains": -1,
        }
        path.write_text(
            json.dumps(payload),
            encoding="utf-8",
        )

        with self.assertRaises(Exception):
            load_game()


if __name__ == "__main__":
    unittest.main()
