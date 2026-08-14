import io
import unittest
from contextlib import redirect_stdout

from combat.combat import TurnReport
from enemies.factory import create_enemy
from player.factory import create_player
from ui.combat_view import show_turn_report


class CombatUiV0177Tests(unittest.TestCase):
    def test_critical_hit_uses_natural_damage_message(self) -> None:
        player = create_player("Tester")
        enemy = create_enemy("drowned_acolyte")
        report = TurnReport(player_damage=6, player_critical=True)

        output = io.StringIO()
        with redirect_stdout(output):
            show_turn_report(player, enemy, report)

        text = output.getvalue()
        self.assertIn("otrzymuje 6 obrażeń krytycznych!", text)
        self.assertNotIn("[KRYTYK!]", text)

    def test_regular_hit_keeps_regular_message(self) -> None:
        player = create_player("Tester")
        enemy = create_enemy("drowned_acolyte")
        report = TurnReport(player_damage=6, player_critical=False)

        output = io.StringIO()
        with redirect_stdout(output):
            show_turn_report(player, enemy, report)

        text = output.getvalue()
        self.assertIn("otrzymuje 6 obrażeń.", text)
        self.assertNotIn("krytycznych", text)

    def test_extra_critical_hit_uses_same_style(self) -> None:
        player = create_player("Tester")
        enemy = create_enemy("drowned_acolyte")
        report = TurnReport(
            extra_player_damage=9,
            extra_player_critical=True,
        )

        output = io.StringIO()
        with redirect_stdout(output):
            show_turn_report(player, enemy, report)

        text = output.getvalue()
        self.assertIn(
            "Dodatkowy atak zadaje 9 obrażeń krytycznych!",
            text,
        )
        self.assertNotIn("[KRYTYK!]", text)


if __name__ == "__main__":
    unittest.main()
