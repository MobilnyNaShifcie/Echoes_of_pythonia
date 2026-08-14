import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from game.state import GameState
from player.classes import PlayerClass
from player.factory import create_player
from systems.save_system import load_game, save_game


class SaveV014Tests(unittest.TestCase):
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

    def test_class_survives_save_and_load(self) -> None:
        player = create_player("Tester")
        player.level = 7
        player.choose_class(PlayerClass.MAGE)
        player.stats.current_mana = 11

        save_game(GameState(active_game=True, player=player))
        loaded = load_game()

        self.assertEqual(
            loaded.player.character_class,
            PlayerClass.MAGE,
        )
        self.assertEqual(loaded.player.stats.current_mana, 11)

    def test_schema_four_save_migrates_as_unclassed(self) -> None:
        player = create_player("Tester")
        player.level = 6
        path = save_game(GameState(active_game=True, player=player))

        payload = json.loads(path.read_text(encoding="utf-8"))
        payload["schema_version"] = 4
        payload["player"].pop("character_class", None)
        path.write_text(json.dumps(payload), encoding="utf-8")

        loaded = load_game()

        self.assertEqual(
            loaded.player.character_class,
            PlayerClass.NONE,
        )
        self.assertTrue(loaded.player.can_choose_class)


if __name__ == "__main__":
    unittest.main()
