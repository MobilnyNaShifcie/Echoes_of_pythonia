from datetime import date
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from game.state import GameState
from player.factory import create_player
from systems.contracts import ensure_contract_board
from systems.save_system import load_game, save_game


class SaveV016Tests(unittest.TestCase):
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

    def test_contract_board_and_elite_discoveries_survive_save(self) -> None:
        player = create_player("Tester")
        player.level = 12
        state = GameState(
            active_game=True,
            player=player,
        )
        ensure_contract_board(
            state.contract_board,
            player,
            today=date(2026, 8, 9),
        )

        first = state.contract_board.daily_contracts[0]
        state.contract_board.progress[first.contract_id] = {
            "0": 2,
        }
        state.elite_discoveries = {
            "furious",
            "armored",
        }

        save_game(state)
        loaded = load_game()

        self.assertEqual(
            loaded.contract_board.daily_date,
            "2026-08-09",
        )
        self.assertEqual(
            loaded.contract_board.daily_contracts,
            state.contract_board.daily_contracts,
        )
        self.assertEqual(
            loaded.contract_board.progress,
            state.contract_board.progress,
        )
        self.assertEqual(
            loaded.elite_discoveries,
            {"furious", "armored"},
        )

    def test_schema_five_migrates_with_empty_repeatables(self) -> None:
        state = GameState(
            active_game=True,
            player=create_player("Tester"),
        )
        path = save_game(state)

        payload = json.loads(path.read_text(encoding="utf-8"))
        payload["schema_version"] = 5
        payload.pop("contracts", None)
        payload.pop("elite_discoveries", None)
        path.write_text(
            json.dumps(payload),
            encoding="utf-8",
        )

        loaded = load_game()

        self.assertEqual(
            loaded.contract_board.daily_contracts,
            [],
        )
        self.assertIsNone(
            loaded.contract_board.weekly_contract
        )
        self.assertEqual(loaded.elite_discoveries, set())


if __name__ == "__main__":
    unittest.main()
