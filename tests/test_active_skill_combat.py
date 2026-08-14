import random
import unittest

from combat.combat import CombatEngine, CombatResult
from enemies.enemy import Enemy
from player.classes import PlayerClass
from player.factory import create_player


def make_enemy(
    *,
    hp: int = 100,
    attack: int = 5,
    defense: int = 2,
    dodge: float = 0.0,
) -> Enemy:
    return Enemy(
        enemy_id="skill_dummy",
        name="Manekin",
        max_hp=hp,
        current_hp=hp,
        attack=attack,
        defense=defense,
        dodge=dodge,
        experience_reward=0,
        gold_min=0,
        gold_max=0,
    )


class ActiveSkillCombatTests(unittest.TestCase):
    def test_power_slash_spends_mana_and_deals_damage(self) -> None:
        player = create_player("Tester")
        player.level = 5
        player.choose_class(PlayerClass.WARRIOR)
        enemy = make_enemy()
        combat = CombatEngine(player, enemy, random.Random(1))

        mana_before = player.stats.current_mana
        report = combat.player_use_skill("power_slash")

        self.assertEqual(
            player.stats.current_mana,
            mana_before - 6,
        )
        self.assertGreater(report.player_damage, 0)
        self.assertEqual(report.skill_name, "Potężne Cięcie")

    def test_locked_skill_cannot_be_used(self) -> None:
        player = create_player("Tester")
        player.level = 5
        player.choose_class(PlayerClass.WARRIOR)
        enemy = make_enemy()
        combat = CombatEngine(player, enemy, random.Random(1))

        mana_before = player.stats.current_mana

        with self.assertRaises(ValueError):
            combat.player_use_skill("armor_break")

        self.assertEqual(player.stats.current_mana, mana_before)
        self.assertEqual(enemy.current_hp, enemy.max_hp)

    def test_wrong_class_skill_cannot_be_used(self) -> None:
        player = create_player("Tester")
        player.level = 12
        player.choose_class(PlayerClass.WARRIOR)
        enemy = make_enemy()
        combat = CombatEngine(player, enemy, random.Random(1))

        with self.assertRaises(ValueError):
            combat.player_use_skill("fire_bolt")

    def test_insufficient_mana_does_not_consume_turn(self) -> None:
        player = create_player("Tester")
        player.level = 5
        player.choose_class(PlayerClass.WARRIOR)
        player.stats.current_mana = 0
        enemy = make_enemy()
        combat = CombatEngine(player, enemy, random.Random(1))
        hp_before = player.stats.current_hp

        with self.assertRaises(ValueError):
            combat.player_use_skill("power_slash")

        self.assertEqual(player.stats.current_hp, hp_before)
        self.assertEqual(enemy.attacks_made, 0)
        self.assertEqual(combat.result, CombatResult.ONGOING)

    def test_armor_break_improves_following_attack(self) -> None:
        player = create_player("Tester")
        player.level = 7
        player.attributes.strength = 5
        player.recalculate_stats()
        player.choose_class(PlayerClass.WARRIOR)
        enemy = make_enemy(hp=200, attack=0, defense=8)
        combat = CombatEngine(player, enemy, random.Random(4))

        combat.player_use_skill("armor_break")
        before = enemy.current_hp
        report = combat.player_attack()

        damage_with_break = before - enemy.current_hp

        comparison_player = create_player("Tester")
        comparison_player.level = 7
        comparison_player.attributes.strength = 5
        comparison_player.recalculate_stats()
        comparison_player.choose_class(PlayerClass.WARRIOR)
        comparison_enemy = make_enemy(
            hp=200,
            attack=0,
            defense=8,
        )
        comparison = CombatEngine(
            comparison_player,
            comparison_enemy,
            random.Random(4),
        )
        comparison_before = comparison_enemy.current_hp
        comparison.player_attack()
        normal_damage = comparison_before - comparison_enemy.current_hp

        self.assertGreater(damage_with_break, normal_damage)
        self.assertGreater(report.player_damage, 0)

    def test_hunter_precise_shot_ignores_enemy_dodge(self) -> None:
        player = create_player("Tester")
        player.level = 5
        player.choose_class(PlayerClass.HUNTER)
        enemy = make_enemy(dodge=100.0)
        combat = CombatEngine(player, enemy, random.Random(1))

        report = combat.player_use_skill("precise_shot")

        self.assertFalse(report.enemy_dodged)
        self.assertGreater(report.player_damage, 0)

    def test_bleed_deals_damage_after_enemy_turn(self) -> None:
        player = create_player("Tester")
        player.level = 7
        player.choose_class(PlayerClass.HUNTER)
        enemy = make_enemy(hp=100, attack=0)
        combat = CombatEngine(player, enemy, random.Random(2))

        report = combat.player_use_skill("bleeding_shot")

        self.assertEqual(report.enemy_bleed_damage, 2)
        self.assertEqual(combat.effects.bleed_turns_remaining, 2)

    def test_warrior_guard_reduces_enemy_damage(self) -> None:
        player = create_player("Tester")
        player.level = 9
        player.choose_class(PlayerClass.WARRIOR)
        enemy = make_enemy(hp=100, attack=10, defense=0)
        combat = CombatEngine(player, enemy, random.Random(3))

        hp_before = player.stats.current_hp
        report = combat.player_use_skill("defensive_stance")
        guarded_damage = hp_before - player.stats.current_hp

        comparison_player = create_player("Tester")
        comparison_enemy = make_enemy(
            hp=100,
            attack=10,
            defense=0,
        )
        comparison = CombatEngine(
            comparison_player,
            comparison_enemy,
            random.Random(3),
        )
        comparison_before = comparison_player.stats.current_hp
        comparison.player_attack()
        normal_damage = (
            comparison_before
            - comparison_player.stats.current_hp
        )

        self.assertLess(guarded_damage, normal_damage)
        self.assertEqual(report.skill_name, "Postawa Obronna")

    def test_mage_damage_scales_with_intelligence(self) -> None:
        low = create_player("Low")
        low.level = 5
        low.choose_class(PlayerClass.MAGE)
        low_enemy = make_enemy(hp=200, defense=4)
        low_combat = CombatEngine(low, low_enemy, random.Random(1))
        low_report = low_combat.player_use_skill("fire_bolt")

        high = create_player("High")
        high.level = 5
        high.attributes.intelligence = 5
        high.recalculate_stats()
        high.choose_class(PlayerClass.MAGE)
        high_enemy = make_enemy(hp=200, defense=4)
        high_combat = CombatEngine(high, high_enemy, random.Random(1))
        high_report = high_combat.player_use_skill("fire_bolt")

        self.assertGreater(
            high_report.player_damage,
            low_report.player_damage,
        )


if __name__ == "__main__":
    unittest.main()
