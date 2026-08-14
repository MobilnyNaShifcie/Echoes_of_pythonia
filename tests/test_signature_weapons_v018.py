import random
import unittest

from combat.combat import CombatEngine
from data.loot_tables import LOOT_TABLES
from enemies.enemy import Enemy
from items.affixes import EquipmentQuality, generate_equipment_item
from items.catalog import get_item_definition
from items.models import EquipmentItem, EquipmentSlot
from items.signature_weapons import (
    average_damage_range,
    is_signature_dungeon_weapon,
    validate_average_damage_percent,
)
from player.factory import create_player
from systems.crafting import craft_for_player, get_recipe


class NoCritRng:
    def random(self) -> float:
        return 0.99


class SignatureWeaponV018Tests(unittest.TestCase):
    def _training_enemy(self) -> Enemy:
        return Enemy(
            enemy_id="training_target",
            name="Cel treningowy",
            max_hp=9999,
            current_hp=9999,
            attack=0,
            defense=0,
            dodge=0.0,
            experience_reward=0,
            gold_min=0,
            gold_max=0,
        )

    def test_only_grandmaster_sword_is_signature_weapon_for_now(self) -> None:
        self.assertTrue(is_signature_dungeon_weapon("grandmaster_sword"))
        self.assertFalse(is_signature_dungeon_weapon("executioner_axe"))
        self.assertFalse(is_signature_dungeon_weapon("drowned_mother_blade"))

    def test_grandmaster_average_damage_range_is_minus_five_to_fifteen(self) -> None:
        self.assertEqual(average_damage_range("grandmaster_sword"), (-5, 15))

        rolls = {
            generate_equipment_item(
                "grandmaster_sword",
                random.Random(seed),
                quality=EquipmentQuality.BOSS,
            ).average_damage_percent
            for seed in range(100)
        }
        self.assertTrue(all(-5 <= int(value) <= 15 for value in rolls))
        self.assertTrue(any(int(value) < 0 for value in rolls))
        self.assertTrue(any(int(value) >= 10 for value in rolls))

    def test_non_signature_weapon_never_rolls_average_damage(self) -> None:
        item = generate_equipment_item(
            "executioner_axe",
            random.Random(7),
            quality=EquipmentQuality.BOSS,
        )
        self.assertIsNone(item.average_damage_percent)

    def test_grandmaster_boss_has_direct_signature_weapon_drop(self) -> None:
        entries = {
            str(entry["item_id"]): float(entry["chance"])
            for entry in LOOT_TABLES["order_grandmaster"]
        }
        self.assertIn("grandmaster_sword", entries)
        self.assertAlmostEqual(entries["grandmaster_sword"], 0.12)

    def test_crafted_signature_weapon_uses_boss_generation_quality(self) -> None:
        recipe = get_recipe("grandmaster_sword")
        player = create_player("Tester")
        player.gold = recipe.gold_cost
        for item_id, quantity in recipe.ingredients.items():
            player.inventory.add(item_id, quantity)

        expected = generate_equipment_item(
            "grandmaster_sword",
            random.Random(8123),
            quality=EquipmentQuality.BOSS,
        )
        craft_for_player(player, recipe, random.Random(8123))
        actual = player.inventory.equipment_items[-1]

        self.assertEqual(actual.affixes, expected.affixes)
        self.assertEqual(
            actual.average_damage_percent,
            expected.average_damage_percent,
        )

    def test_positive_average_damage_increases_basic_attack(self) -> None:
        base_player = create_player("Base")
        base_player.level = 10
        boosted_player = create_player("Boosted")
        boosted_player.level = 10

        for player, average in ((base_player, None), (boosted_player, 15)):
            item = EquipmentItem(
                item_id="grandmaster_sword",
                item_power=4,
                average_damage_percent=average,
            )
            player.equipment.slots[EquipmentSlot.WEAPON] = item
            player.recalculate_stats()

        base_report = CombatEngine(
            base_player,
            self._training_enemy(),
            NoCritRng(),
        ).player_attack()
        boosted_report = CombatEngine(
            boosted_player,
            self._training_enemy(),
            NoCritRng(),
        ).player_attack()

        self.assertGreater(boosted_report.player_damage, base_report.player_damage)
        self.assertEqual(base_report.player_damage, 13)
        self.assertEqual(boosted_report.player_damage, 15)

    def test_negative_average_damage_reduces_basic_attack(self) -> None:
        player = create_player("Tester")
        player.level = 10
        player.equipment.slots[EquipmentSlot.WEAPON] = EquipmentItem(
            item_id="grandmaster_sword",
            item_power=4,
            average_damage_percent=-5,
        )
        player.recalculate_stats()

        report = CombatEngine(
            player,
            self._training_enemy(),
            NoCritRng(),
        ).player_attack()

        self.assertEqual(report.player_damage, 12)

    def test_average_damage_does_not_modify_skill_damage(self) -> None:
        player = create_player("Tester")
        player.level = 10
        player.equipment.slots[EquipmentSlot.WEAPON] = EquipmentItem(
            item_id="grandmaster_sword",
            item_power=4,
            average_damage_percent=15,
        )
        player.recalculate_stats()
        engine = CombatEngine(player, self._training_enemy(), NoCritRng())

        damage, dodged, critical = engine._resolve_player_hit(
            power=player.stats.attack,
            multiplier=1.0,
            guaranteed_hit=True,
            magical=False,
            damage_type=engine.enemy.basic_damage_type,
            is_skill=True,
        )

        self.assertFalse(dodged)
        self.assertFalse(critical)
        self.assertEqual(damage, 13)

    def test_average_damage_validation_rejects_it_on_normal_weapon(self) -> None:
        with self.assertRaises(ValueError):
            validate_average_damage_percent("executioner_axe", 10)


if __name__ == "__main__":
    unittest.main()
