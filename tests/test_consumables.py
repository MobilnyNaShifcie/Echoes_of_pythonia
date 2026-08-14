import random
import unittest

from combat.combat import CombatEngine
from enemies.enemy import Enemy
from items.consumables import use_consumable
from player.factory import create_player


class ConsumableTests(unittest.TestCase):
    def test_healing_potion_heals_and_is_consumed(self) -> None:
        player = create_player("Tester")
        player.inventory.add("weak_healing_potion", 2)
        player.stats.current_hp = 5

        result = use_consumable(player, "weak_healing_potion")

        self.assertEqual(result.healed_hp, 15)
        self.assertEqual(player.stats.current_hp, 20)
        self.assertEqual(
            player.inventory.count("weak_healing_potion"),
            1,
        )

    def test_healing_caps_at_max_hp(self) -> None:
        player = create_player("Tester")
        player.inventory.add("weak_healing_potion")
        player.stats.current_hp = 18

        result = use_consumable(player, "weak_healing_potion")

        self.assertEqual(result.healed_hp, 2)
        self.assertEqual(player.stats.current_hp, 20)

    def test_full_hp_does_not_consume_potion(self) -> None:
        player = create_player("Tester")
        player.inventory.add("weak_healing_potion")

        with self.assertRaises(ValueError):
            use_consumable(player, "weak_healing_potion")

        self.assertEqual(
            player.inventory.count("weak_healing_potion"),
            1,
        )

    def test_using_item_in_combat_costs_enemy_turn(self) -> None:
        player = create_player("Tester")
        player.inventory.add("weak_healing_potion")
        player.stats.current_hp = 10

        enemy = Enemy(
            enemy_id="plain",
            name="Wróg",
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

        used = use_consumable(player, "weak_healing_potion")
        report = combat.player_item_turn(
            used.healed_hp,
            "Słaba Mikstura Lecznicza",
        )

        # 10 + 10 leczenia (limit maks. HP) - (4 ATK - 2 DEF) = 18
        self.assertEqual(player.stats.current_hp, 18)
        self.assertEqual(report.player_healed, 10)
        self.assertEqual(report.enemy_damage, 2)
