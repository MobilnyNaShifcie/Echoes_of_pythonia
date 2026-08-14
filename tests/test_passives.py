import random
import unittest

from combat.combat import CombatEngine
from enemies.enemy import Enemy
from player.passives import (
    PassiveType,
    attack_speed_extra_hit_chance,
    critical_chance,
    critical_multiplier,
    health_regeneration_per_turn,
    passive_attack_bonus,
)
from player.factory import create_player


class ZeroRandom(random.Random):
    def random(self) -> float:
        return 0.0


class PassiveTests(unittest.TestCase):
    def test_level_six_has_three_passive_points(self) -> None:
        player = create_player("Tester")
        player.level = 6
        self.assertEqual(player.available_passive_points, 3)

    def test_increased_attack_changes_real_attack(self) -> None:
        player = create_player("Tester")
        player.level = 2
        player.spend_passive_point(PassiveType.INCREASED_ATTACK)
        self.assertEqual(player.stats.attack, 5)

    def test_attack_speed_can_trigger_second_strike(self) -> None:
        player = create_player("Tester")
        player.level = 2
        player.spend_passive_point(PassiveType.ATTACK_SPEED)
        enemy = Enemy(
            enemy_id="dummy", name="Manekin", max_hp=20, current_hp=20,
            attack=1, defense=0, dodge=0.0, experience_reward=0,
            gold_min=0, gold_max=0,
        )
        combat = CombatEngine(player, enemy, ZeroRandom())
        report = combat.player_attack()
        self.assertGreater(report.player_damage, 0)
        self.assertGreater(report.extra_player_damage, 0)

    def test_critical_damage_passive_enables_critical_hit(self) -> None:
        player = create_player("Tester")
        player.level = 2
        player.spend_passive_point(PassiveType.CRITICAL_DAMAGE)
        enemy = Enemy(
            enemy_id="dummy", name="Manekin", max_hp=30, current_hp=30,
            attack=1, defense=0, dodge=0.0, experience_reward=0,
            gold_min=0, gold_max=0,
        )
        report = CombatEngine(player, enemy, ZeroRandom()).player_attack()
        self.assertTrue(report.player_critical)
        self.assertGreater(report.player_damage, 3)

    def test_health_regeneration_heals_after_enemy_turn(self) -> None:
        player = create_player("Tester")
        player.level = 2
        player.spend_passive_point(PassiveType.HEALTH_REGEN)
        player.stats.current_hp = 10
        enemy = Enemy(
            enemy_id="dummy", name="Manekin", max_hp=30, current_hp=30,
            attack=2, defense=0, dodge=0.0, experience_reward=0,
            gold_min=0, gold_max=0,
        )
        report = CombatEngine(player, enemy, random.Random(10)).player_defend()
        self.assertEqual(report.player_regenerated, 3)

    def test_can_spend_multiple_passive_points_at_once(self) -> None:
        player = create_player("Tester")
        player.level = 6

        player.spend_passive_points(PassiveType.INCREASED_ATTACK, 3)

        self.assertEqual(player.passives.increased_attack, 3)
        self.assertEqual(player.available_passive_points, 0)
        self.assertEqual(player.stats.attack, 9)

    def test_current_five_level_passives_have_meaningful_max_values(self) -> None:
        from player.passives import Passives

        passives = Passives(
            attack_speed=5,
            critical_damage=5,
            health_regen=5,
            increased_attack=5,
        )

        self.assertEqual(attack_speed_extra_hit_chance(passives), 25.0)
        self.assertEqual(critical_chance(passives), 9.0)
        self.assertAlmostEqual(critical_multiplier(passives), 2.75)
        self.assertEqual(health_regeneration_per_turn(passives), 15)
        self.assertEqual(passive_attack_bonus(passives), 10)

    def test_bulk_passive_spend_cannot_exceed_max_level(self) -> None:
        player = create_player("Tester")
        player.level = 20
        player.passives.increased_attack = 4
        player.recalculate_stats()

        with self.assertRaises(ValueError):
            player.spend_passive_points(PassiveType.INCREASED_ATTACK, 2)

        self.assertEqual(player.passives.increased_attack, 4)
        self.assertEqual(player.stats.attack, 11)
