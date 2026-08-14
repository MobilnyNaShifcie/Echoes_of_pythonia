import io
import unittest
from contextlib import redirect_stdout
from unittest.mock import patch

from player.factory import create_player
from quests.models import QuestLog
from systems.quest_system import (
    accept_quest,
    get_available_quests,
    record_enemy_kill,
    turn_in_quest,
)
from ui.guild_view import show_quest_board


class GuildBoardTests(unittest.TestCase):
    def _render_board(self, player, log) -> str:
        output = io.StringIO()
        quests = get_available_quests(log)

        with patch("ui.guild_view.print_header"), redirect_stdout(output):
            show_quest_board(player, quests)

        return output.getvalue()

    def test_active_quest_disappears_from_board(self) -> None:
        player = create_player("Tester")
        log = QuestLog()
        accept_quest(log, "black_venom")

        text = self._render_board(player, log)

        self.assertNotIn("Czarny jad", text)
        self.assertIn("Kult pod korzeniami", text)

    def test_completed_quest_disappears_from_board_permanently(self) -> None:
        player = create_player("Tester")
        log = QuestLog()
        accept_quest(log, "mother_below")
        record_enemy_kill(log, "drowned_mother")
        turn_in_quest(player, log, "mother_below")

        text = self._render_board(player, log)

        self.assertNotIn("Matka z głębin", text)
        self.assertIn("mother_below", log.completed)

    def test_board_numbers_current_visible_quests_sequentially(self) -> None:
        player = create_player("Tester")
        log = QuestLog()
        accept_quest(log, "black_venom")
        accept_quest(log, "cult_beneath_roots")
        accept_quest(log, "bones_of_silentwater")

        text = self._render_board(player, log)

        self.assertIn("[1] Ziele z czarnej wody", text)
        self.assertIn("[2] Rycerze bez grobów", text)
        self.assertIn("[3] Matka z głębin", text)
        self.assertIn("[4] Pieczęć Zatopionych", text)
        self.assertIn("[5] Ci, którzy nie wrócili", text)
        self.assertNotIn("[6]", text)


if __name__ == "__main__":
    unittest.main()
