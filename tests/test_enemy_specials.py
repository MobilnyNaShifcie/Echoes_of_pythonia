import random
import unittest

from combat.combat import CombatEngine
from enemies.enemy import Enemy
from player.factory import create_player


class EnemySpecialTests(unittest.TestCase):
    def test_guaranteed_special_attack_adds_bonus_damage(self) -> None:
        player = create_player("Tester")
        enemy = Enemy(
            enemy_id="test_special",
            name="Testowy Wróg",
            max_hp=10,
            current_hp=10,
            attack=4,
            defense=0,
            dodge=0.0,
            experience_reward=0,
            gold_min=0,
            gold_max=0,
            special_name="Mocny Cios",
            special_chance=1.0,
            special_attack_bonus=3,
        )
        combat = CombatEngine(player, enemy, random.Random(1))

        report = combat.player_defend()

        self.assertEqual(report.enemy_special_name, "Mocny Cios")
        # (4 + 3 - 2 DEF) = 5, obrona dzieli całkowicie przez 2 -> 2
        self.assertEqual(report.enemy_damage, 2)

    def test_enemy_without_special_keeps_report_empty(self) -> None:
        player = create_player("Tester")
        enemy = Enemy(
            enemy_id="plain",
            name="Zwykły Wróg",
            max_hp=10,
            current_hp=10,
            attack=4,
            defense=0,
            dodge=0.0,
            experience_reward=0,
            gold_min=0,
            gold_max=0,
        )
        combat = CombatEngine(player, enemy, random.Random(1))

        report = combat.player_defend()

        self.assertIsNone(report.enemy_special_name)
