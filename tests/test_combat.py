import random
import unittest

from combat.combat import CombatEngine, CombatResult
from enemies.factory import create_enemy
from player.factory import create_player


class CombatTests(unittest.TestCase):
    def test_trial_wraith_can_be_defeated(self) -> None:
        player = create_player("Tester")
        enemy = create_enemy("trial_wraith")
        combat = CombatEngine(player, enemy, random.Random(1))

        while combat.result is CombatResult.ONGOING:
            combat.player_attack()

        self.assertEqual(combat.result, CombatResult.VICTORY)
        self.assertFalse(enemy.is_alive)
        self.assertTrue(player.stats.is_alive)

    def test_defend_reduces_trial_wraith_damage_to_zero(self) -> None:
        player = create_player("Tester")
        enemy = create_enemy("trial_wraith")
        combat = CombatEngine(player, enemy, random.Random(1))

        report = combat.player_defend()

        self.assertEqual(report.enemy_damage, 0)
        self.assertEqual(player.stats.current_hp, player.stats.max_hp)

    def test_successful_flee_ends_combat(self) -> None:
        player = create_player("Tester")
        enemy = create_enemy("trial_wraith")
        combat = CombatEngine(player, enemy, random.Random(1))

        combat.player_flee()

        self.assertEqual(combat.result, CombatResult.FLED)


if __name__ == "__main__":
    unittest.main()
