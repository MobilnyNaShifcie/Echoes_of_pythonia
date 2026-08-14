import unittest

from combat.combat import TurnReport
from combat.region_bosses import LeviathanNorthCombatEngine
from enemies.factory import create_enemy
from player.factory import create_player


class LeviathanV020Tests(unittest.TestCase):
    def test_leviathan_has_planned_region_boss_scale(self) -> None:
        boss = create_enemy("leviathan_north")
        self.assertGreaterEqual(boss.max_hp, 2500)
        self.assertLessEqual(boss.max_hp, 3500)
        self.assertEqual(boss.elemental_resistances.water, 60)
        self.assertEqual(boss.elemental_resistances.frost, 55)

    def test_phase_two_hardens_leviathan(self) -> None:
        player = create_player("Tester")
        enemy = create_enemy("leviathan_north")
        engine = LeviathanNorthCombatEngine(player, enemy)
        enemy.current_hp = int(enemy.max_hp * 0.60)
        base_attack = enemy.attack
        base_defense = enemy.defense
        report = TurnReport()
        engine._update_phase(report)
        self.assertEqual(engine.phase, 2)
        self.assertEqual(enemy.attack, base_attack + 4)
        self.assertEqual(enemy.defense, base_defense + 4)
        self.assertTrue(any("Wzburzone Morze" in note for note in report.boss_notes))

    def test_phase_three_trades_defense_for_attack(self) -> None:
        player = create_player("Tester")
        enemy = create_enemy("leviathan_north")
        engine = LeviathanNorthCombatEngine(player, enemy)
        enemy.current_hp = int(enemy.max_hp * 0.25)
        base_attack = enemy.attack
        base_defense = enemy.defense
        report = TurnReport()
        engine._update_phase(report)
        self.assertEqual(engine.phase, 3)
        self.assertEqual(enemy.attack, base_attack + 14)
        self.assertEqual(enemy.defense, base_defense - 4)
        self.assertEqual(len(report.boss_notes), 2)


if __name__ == "__main__":
    unittest.main()
