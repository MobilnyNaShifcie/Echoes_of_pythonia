import unittest

from combat.combat import TurnReport
from combat.region_bosses import AzharCombatEngine, HearthDevourerCombatEngine
from enemies.factory import create_enemy
from player.factory import create_player


class RegionBossesV019Tests(unittest.TestCase):
    def test_enemy_factory_loads_region_elemental_resistances(self) -> None:
        salamander = create_enemy("red_salamander")
        golem = create_enemy("sand_golem")
        azhar = create_enemy("azhar")
        self.assertEqual(salamander.elemental_resistances.fire, 40)
        self.assertEqual(golem.elemental_resistances.earth, 35)
        self.assertEqual(azhar.elemental_resistances.wind, 25)
        self.assertEqual(azhar.status_resistance, 0.40)

    def test_azhar_phase_two_is_sandstorm(self) -> None:
        player = create_player("Tester")
        enemy = create_enemy("azhar")
        engine = AzharCombatEngine(player, enemy)
        enemy.current_hp = int(enemy.max_hp * 0.60)
        report = TurnReport()
        base_attack = enemy.attack
        base_dodge = enemy.dodge

        engine._update_phase(report)

        self.assertEqual(engine.phase, 2)
        self.assertEqual(enemy.attack, base_attack + 2)
        self.assertEqual(enemy.dodge, base_dodge + 10.0)
        self.assertTrue(any("Burza Piaskowa" in note for note in report.boss_notes))

    def test_azhar_phase_three_trades_defense_for_attack(self) -> None:
        player = create_player("Tester")
        enemy = create_enemy("azhar")
        engine = AzharCombatEngine(player, enemy)
        enemy.current_hp = int(enemy.max_hp * 0.25)
        report = TurnReport()
        base_attack = enemy.attack
        base_defense = enemy.defense

        engine._update_phase(report)

        self.assertEqual(engine.phase, 3)
        self.assertEqual(enemy.attack, base_attack + 8)
        self.assertEqual(enemy.defense, base_defense - 4)
        self.assertEqual(len(report.boss_notes), 2)

    def test_hearth_devourer_heat_and_frenzy_are_bounded(self) -> None:
        player = create_player("Tester")
        player.stats.max_hp = 999
        player.stats.current_hp = 999
        player.stats.defense = 100
        enemy = create_enemy("hearth_devourer")
        engine = HearthDevourerCombatEngine(player, enemy)
        enemy.attacks_made = 3
        enemy.current_hp = int(enemy.max_hp * 0.30)
        report = TurnReport()
        base_attack = enemy.attack
        base_defense = enemy.defense

        engine._enemy_turn(report, defending=True)

        self.assertEqual(engine.heat_stacks, 1)
        self.assertTrue(engine.frenzy_triggered)
        self.assertEqual(enemy.attack, base_attack + 6)
        self.assertEqual(enemy.defense, base_defense - 2)
        self.assertTrue(any("Rozżarzenie" in note for note in report.boss_notes))
        self.assertTrue(any("SZAŁ PALENISKA" in note for note in report.boss_notes))


if __name__ == "__main__":
    unittest.main()
