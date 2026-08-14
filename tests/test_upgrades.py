import unittest

from game.config import MAX_UPGRADE_LEVEL
from items.factory import create_equipment_item
from items.upgrades import calculate_upgraded_stats
from player.factory import create_player
from systems.blacksmith import (
    can_upgrade,
    get_upgrade_cost,
    get_upgrade_plan,
    max_affordable_upgrade_levels,
    upgrade_item,
    upgrade_item_levels,
)


class UpgradeTests(unittest.TestCase):
    def test_first_three_levels_use_shop_materials_only(self) -> None:
        item = create_equipment_item("wasteland_armor")

        first = get_upgrade_cost(0, item)
        second = get_upgrade_cost(1, item)
        third = get_upgrade_cost(2, item)

        self.assertEqual(first.materials, {"whetstone": 1})
        self.assertEqual(second.materials, {"whetstone": 1})
        self.assertEqual(third.materials, {"whetstone": 2})

    def test_later_levels_require_region_elite_and_boss_materials(self) -> None:
        item = create_equipment_item("wasteland_armor")

        plus_four = get_upgrade_cost(3, item)
        plus_eight = get_upgrade_cost(7, item)
        plus_ten = get_upgrade_cost(9, item)

        self.assertEqual(
            plus_four.materials,
            {"grinding_stone": 1, "salamander_scale": 1},
        )
        self.assertIn("hearth_core", plus_eight.materials)
        self.assertIn("azhar_sigil", plus_ten.materials)

    def test_gold_cost_scales_with_item_power(self) -> None:
        ip_one = create_equipment_item("starter_sword")
        ip_seven = create_equipment_item("varek_sabre")

        self.assertEqual(get_upgrade_cost(9, ip_one).gold, 1400)
        self.assertEqual(get_upgrade_cost(9, ip_seven).gold, 3300)

    def test_legacy_low_tier_upgrade_power_is_not_nerfed(self) -> None:
        item = create_equipment_item("starter_sword")
        item.upgrade_level = 10
        self.assertEqual(calculate_upgraded_stats(item).attack, 8)

        ring = create_equipment_item("wraith_ring")
        ring.upgrade_level = 10
        self.assertEqual(calculate_upgraded_stats(ring).max_mana, 30)

    def test_high_item_power_weapon_gets_meaningful_upgrade_growth(self) -> None:
        grandmaster = create_equipment_item("grandmaster_sword")
        grandmaster.upgrade_level = 10
        self.assertEqual(calculate_upgraded_stats(grandmaster).attack, 25)

        varek = create_equipment_item("varek_sabre")
        varek.upgrade_level = 10
        self.assertEqual(calculate_upgraded_stats(varek).attack, 46)

    def test_high_item_power_armor_scales_defense_and_hp(self) -> None:
        armor = create_equipment_item("north_armor")
        armor.upgrade_level = 10
        stats = calculate_upgraded_stats(armor)

        self.assertEqual(stats.defense, 22)
        self.assertEqual(stats.max_hp, 120)

    def test_hp_mana_and_dodge_still_scale_when_present(self) -> None:
        boots = create_equipment_item("northern_trail_boots")
        boots.upgrade_level = 10
        boot_stats = calculate_upgraded_stats(boots)
        self.assertEqual(boot_stats.dodge, 12.0)

        amulet = create_equipment_item("black_sea_amulet")
        amulet.upgrade_level = 10
        amulet_stats = calculate_upgraded_stats(amulet)
        self.assertEqual(amulet_stats.max_mana, 59)

    def test_upgrade_consumes_gold_and_material(self) -> None:
        player = create_player("Tester")
        weapon = player.equipment.slots[
            next(
                slot
                for slot, item in player.equipment.slots.items()
                if item.item_id == "starter_sword"
            )
        ]
        player.gold = 100
        player.inventory.add("whetstone", 1)

        self.assertTrue(can_upgrade(player, weapon))

        upgrade_item(player, weapon)

        self.assertEqual(weapon.upgrade_level, 1)
        self.assertEqual(player.gold, 75)
        self.assertEqual(player.inventory.count("whetstone"), 0)

    def test_equipped_item_upgrade_recalculates_player_stats(self) -> None:
        player = create_player("Tester")
        weapon = next(
            item
            for item in player.equipment.slots.values()
            if item.item_id == "starter_sword"
        )
        player.gold = 500
        player.inventory.add("whetstone", 4)

        upgrade_item(player, weapon)
        self.assertEqual(player.stats.attack, 3)

        upgrade_item(player, weapon)
        self.assertEqual(weapon.upgrade_level, 2)
        self.assertEqual(player.stats.attack, 4)

    def test_cannot_upgrade_without_resources(self) -> None:
        player = create_player("Tester")
        weapon = next(iter(player.equipment.slots.values()))

        self.assertFalse(can_upgrade(player, weapon))

        with self.assertRaises(ValueError):
            upgrade_item(player, weapon)

    def test_max_level_cannot_be_upgraded(self) -> None:
        player = create_player("Tester")
        item = create_equipment_item("starter_sword")
        item.upgrade_level = MAX_UPGRADE_LEVEL
        player.gold = 99999
        player.inventory.add("grinding_stone", 99)

        self.assertFalse(can_upgrade(player, item))

        with self.assertRaises(ValueError):
            upgrade_item(player, item)

    def test_multi_upgrade_plan_sums_all_intermediate_costs(self) -> None:
        item = create_equipment_item("starter_sword")
        plan = get_upgrade_plan(0, 5, item)

        self.assertEqual(plan.start_level, 0)
        self.assertEqual(plan.target_level, 5)
        self.assertEqual(plan.gold, 400)
        self.assertEqual(
            plan.materials,
            {
                "whetstone": 4,
                "grinding_stone": 2,
                "common_essence": 3,
            },
        )

    def test_multi_upgrade_consumes_total_cost_once(self) -> None:
        player = create_player("Tester")
        item = create_equipment_item("starter_sword")
        player.inventory.equipment_items.append(item)
        player.gold = 1000
        player.inventory.add("whetstone", 4)
        player.inventory.add("grinding_stone", 2)
        player.inventory.add("common_essence", 3)

        plan = upgrade_item_levels(player, item, 5)

        self.assertEqual(item.upgrade_level, 5)
        self.assertEqual(plan.gold, 400)
        self.assertEqual(player.gold, 600)
        self.assertEqual(player.inventory.count("whetstone"), 0)
        self.assertEqual(player.inventory.count("grinding_stone"), 0)
        self.assertEqual(player.inventory.count("common_essence"), 0)

    def test_multi_upgrade_is_atomic_when_resources_are_missing(self) -> None:
        player = create_player("Tester")
        item = create_equipment_item("starter_sword")
        player.inventory.equipment_items.append(item)
        player.gold = 1000
        player.inventory.add("whetstone", 4)
        player.inventory.add("grinding_stone", 2)
        # Brak Zwykłej Esencji wymaganej od +4.

        with self.assertRaises(ValueError):
            upgrade_item_levels(player, item, 5)

        self.assertEqual(item.upgrade_level, 0)
        self.assertEqual(player.gold, 1000)
        self.assertEqual(player.inventory.count("whetstone"), 4)
        self.assertEqual(player.inventory.count("grinding_stone"), 2)

    def test_max_affordable_upgrade_levels_uses_all_materials(self) -> None:
        player = create_player("Tester")
        item = create_equipment_item("starter_sword")
        player.gold = 1000
        player.inventory.add("whetstone", 4)

        self.assertEqual(max_affordable_upgrade_levels(player, item), 3)

        player.inventory.add("grinding_stone", 1)
        player.inventory.add("common_essence", 1)
        self.assertEqual(max_affordable_upgrade_levels(player, item), 4)

    def test_max_affordable_upgrade_stops_at_level_ten(self) -> None:
        player = create_player("Tester")
        item = create_equipment_item("starter_sword")
        item.upgrade_level = 9
        player.gold = 99999
        player.inventory.add("grinding_stone", 4)
        player.inventory.add("common_essence", 1)
        player.inventory.add("spark_of_life", 1)

        self.assertEqual(max_affordable_upgrade_levels(player, item), 1)

    def test_two_copies_can_have_different_upgrade_levels(self) -> None:
        player = create_player("Tester")
        player.inventory.add("leather_hood", 2)

        first = player.inventory.equipment_items[0]
        second = player.inventory.equipment_items[1]

        first.upgrade_level = 4

        self.assertEqual(first.upgrade_level, 4)
        self.assertEqual(second.upgrade_level, 0)
        self.assertNotEqual(first.instance_id, second.instance_id)
