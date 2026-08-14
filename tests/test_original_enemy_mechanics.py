import random
import unittest

from combat.combat import CombatEngine
from enemies.factory import create_enemy
from player.factory import create_player


class ZeroRandom(random.Random):
    def random(self) -> float:
        return 0.0


class OriginalEnemyMechanicsTests(unittest.TestCase):
    def test_wild_dog_can_attack_twice(self) -> None:
        player = create_player("Tester")
        dog = create_enemy("wild_dog")
        report = CombatEngine(player, dog, ZeroRandom()).player_defend()
        self.assertGreater(report.enemy_extra_damage, 0)

    def test_boar_charge_only_buffs_first_attack(self) -> None:
        player = create_player("Tester")
        player.stats.max_hp = 100
        player.stats.current_hp = 100
        boar = create_enemy("boar")
        combat = CombatEngine(player, boar, random.Random(20))
        first = combat.player_defend().enemy_damage
        second = combat.player_defend().enemy_damage
        self.assertGreater(first, second)

    def test_scarecrow_reduces_physical_damage_by_one(self) -> None:
        player = create_player("Tester")
        player.stats.attack = 5
        scarecrow = create_enemy("cursed_scarecrow")
        report = CombatEngine(player, scarecrow, random.Random(20)).player_attack()
        # 5 ATK - 2 DEF = 3, następnie odporność fizyczna -1 => 2.
        self.assertEqual(report.player_damage, 2)

    def test_plains_spirit_has_twenty_five_percent_dodge(self) -> None:
        self.assertEqual(create_enemy("plains_spirit").dodge, 25.0)
