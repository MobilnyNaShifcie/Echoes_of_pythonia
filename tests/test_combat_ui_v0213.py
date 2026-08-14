import io
import unittest
from contextlib import redirect_stdout

from combat.combat import TurnReport
from enemies.factory import create_enemy
from player.factory import create_player
from ui.combat_view import show_turn_report


class CombatUiV0213Tests(unittest.TestCase):
    def setUp(self) -> None:
        self.player = create_player("Tester")
        self.enemy = create_enemy("drowned_acolyte")

    def _render(self, report: TurnReport) -> str:
        output = io.StringIO()
        with redirect_stdout(output):
            show_turn_report(self.player, self.enemy, report)
        return output.getvalue()

    def test_skill_hit_shows_total_damage_summary(self) -> None:
        text = self._render(
            TurnReport(skill_name="Potężne Cięcie", skill_mana_cost=6, player_damage=37)
        )
        self.assertIn("Łączne obrażenia umiejętności: 37.", text)

    def test_missed_skill_shows_zero_damage_summary(self) -> None:
        text = self._render(
            TurnReport(skill_name="Potężne Cięcie", skill_mana_cost=6, enemy_dodged=True)
        )
        self.assertIn("Łączne obrażenia umiejętności: 0 (unik).", text)

    def test_multi_hit_skill_sums_both_hits(self) -> None:
        text = self._render(
            TurnReport(
                skill_name="Podwójny Strzał",
                skill_mana_cost=10,
                player_damage=21,
                extra_player_damage=18,
            )
        )
        self.assertIn("Łączne obrażenia umiejętności: 39.", text)

    def test_non_offensive_skill_does_not_show_zero_damage(self) -> None:
        text = self._render(
            TurnReport(skill_name="Postawa Obronna", skill_mana_cost=7)
        )
        self.assertNotIn("Łączne obrażenia umiejętności", text)


if __name__ == "__main__":
    unittest.main()
