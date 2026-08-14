import random
import unittest

from data.affixes import AFFIX_DATA
from data.items import ITEM_DATA
from items.affixes import (
    EquipmentQuality,
    affix_count_for_rarity,
    affix_value_for_tier,
    allowed_affix_ids,
    calculate_affix_bonuses,
    generate_equipment_item,
    max_affix_value,
)
from items.catalog import get_item_definition
from items.models import (
    AffixRoll,
    EquipmentItem,
    EquipmentRole,
    EquipmentSlot,
    ItemRarity,
)
from player.factory import create_player


class EquipmentV017Tests(unittest.TestCase):
    def test_rarity_controls_exact_affix_count(self) -> None:
        expected = {
            ItemRarity.COMMON: 0,
            ItemRarity.UNCOMMON: 1,
            ItemRarity.RARE: 2,
            ItemRarity.EPIC: 3,
            ItemRarity.LEGENDARY: 4,
            ItemRarity.MYTHIC: 4,
        }
        for rarity, count in expected.items():
            self.assertEqual(affix_count_for_rarity(rarity), count)

    def test_every_equipment_has_item_power(self) -> None:
        missing = []
        for item_id, raw in ITEM_DATA.items():
            if raw.get("category") != "equipment":
                continue
            if get_item_definition(item_id).item_power <= 0:
                missing.append(item_id)
        self.assertEqual(missing, [])

    def test_base_stats_follow_slot_roles(self) -> None:
        invalid = []
        for item_id, raw in ITEM_DATA.items():
            if raw.get("category") != "equipment":
                continue
            definition = get_item_definition(item_id)
            role = definition.equipment_role
            resistance_total = sum(definition.resistances.as_dict().values())

            if role is EquipmentRole.DEFENSIVE:
                if definition.attack or definition.max_mana:
                    invalid.append(item_id)
            elif role is EquipmentRole.OFFENSIVE:
                if (
                    definition.defense
                    or definition.max_hp
                    or definition.dodge
                    or resistance_total
                ):
                    invalid.append(item_id)

        self.assertEqual(invalid, [])

    def test_defensive_slots_only_roll_defensive_affixes(self) -> None:
        boots = get_item_definition("mirewalker_boots")
        self.assertEqual(boots.equipment_role, EquipmentRole.DEFENSIVE)
        for affix_id in allowed_affix_ids(boots):
            self.assertEqual(AFFIX_DATA[affix_id]["role"], "defensive")

    def test_offensive_slots_only_roll_offensive_affixes(self) -> None:
        ring = get_item_definition("abyss_ring")
        self.assertEqual(ring.equipment_role, EquipmentRole.OFFENSIVE)
        for affix_id in allowed_affix_ids(ring):
            self.assertEqual(AFFIX_DATA[affix_id]["role"], "offensive")

    def test_belt_can_roll_both_pools(self) -> None:
        belt = get_item_definition("scale_belt")
        roles = {
            str(AFFIX_DATA[affix_id]["role"])
            for affix_id in allowed_affix_ids(belt)
        }
        self.assertEqual(roles, {"offensive", "defensive"})

    def test_belt_rolls_are_weaker_than_specialized_slots(self) -> None:
        belt_attack = affix_value_for_tier(
            "attack", 4, 5, EquipmentSlot.BELT
        )
        weapon_attack = affix_value_for_tier(
            "attack", 4, 5, EquipmentSlot.WEAPON
        )
        self.assertLess(belt_attack, weapon_attack)

        belt_hp = affix_value_for_tier(
            "max_hp", 4, 5, EquipmentSlot.BELT
        )
        chest_hp = affix_value_for_tier(
            "max_hp", 4, 5, EquipmentSlot.CHEST
        )
        self.assertLess(belt_hp, chest_hp)

    def test_generated_item_has_unique_affixes(self) -> None:
        item = generate_equipment_item(
            "aurora_tide_blade",
            random.Random(7),
        )
        self.assertEqual(len(item.affixes), 4)
        self.assertEqual(
            len({affix.affix_id for affix in item.affixes}),
            4,
        )

    def test_tier_five_is_five_times_tier_one_for_future_hp(self) -> None:
        t1 = affix_value_for_tier(
            "max_hp", 12, 1, EquipmentSlot.CHEST
        )
        t5 = affix_value_for_tier(
            "max_hp", 12, 5, EquipmentSlot.CHEST
        )
        self.assertGreater(t5, 2000)
        self.assertAlmostEqual(t5 / t1, 5.0, places=2)

    def test_flat_stats_can_scale_to_future_endgame(self) -> None:
        self.assertGreater(max_affix_value("max_hp", 12), 2000)
        self.assertGreater(max_affix_value("attack", 12), 300)

    def test_percent_stats_have_hard_endgame_caps(self) -> None:
        self.assertEqual(max_affix_value("crit_chance", 999), 10.0)
        self.assertEqual(max_affix_value("crit_damage", 999), 30.0)
        self.assertEqual(max_affix_value("skill_damage", 999), 12.0)
        self.assertEqual(max_affix_value("armor_penetration", 999), 10.0)
        self.assertEqual(max_affix_value("water_resistance", 999), 15.0)
        self.assertEqual(max_affix_value("damage_vs_boss", 999), 20.0)

    def test_affix_flat_stats_modify_real_player_stats(self) -> None:
        definition = get_item_definition("executioner_axe")
        attack_value = affix_value_for_tier(
            "attack",
            definition.item_power,
            5,
            definition.slot,
        )
        item = EquipmentItem(
            item_id="executioner_axe",
            item_power=definition.item_power,
            affixes=[AffixRoll("attack", 5, attack_value)],
        )
        bonuses = calculate_affix_bonuses(item)
        self.assertGreater(bonuses.attack, 0)

    def test_better_sources_shift_tier_average_up(self) -> None:
        normal_rng = random.Random(12345)
        boss_rng = random.Random(12345)
        normal_tiers = []
        boss_tiers = []
        for _ in range(300):
            normal = generate_equipment_item(
                "executioner_axe",
                normal_rng,
                quality=EquipmentQuality.NORMAL,
            )
            boss = generate_equipment_item(
                "executioner_axe",
                boss_rng,
                quality=EquipmentQuality.BOSS,
            )
            normal_tiers.extend(affix.tier for affix in normal.affixes)
            boss_tiers.extend(affix.tier for affix in boss.affixes)
        self.assertGreater(
            sum(boss_tiers) / len(boss_tiers),
            sum(normal_tiers) / len(normal_tiers),
        )


if __name__ == "__main__":
    unittest.main()
