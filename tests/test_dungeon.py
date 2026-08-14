import random
import unittest

from combat.combat import CombatResult, TurnReport
from combat.dungeon_boss import GrandMasterCombatEngine
from data.dungeons import DUNGEON_DATA
from data.enemies import ENEMY_DATA
from data.items import ITEM_DATA
from data.loot_tables import LOOT_TABLES
from data.recipes import RECIPE_DATA
from enemies.factory import create_enemy
from items.catalog import get_item_definition
from player.classes import PlayerClass
from player.factory import create_player
from world.dungeon import (
    capture_dungeon_loot_snapshot,
    create_dungeon,
    discard_unsecured_dungeon_loot,
    dungeon_loot_since_snapshot,
    roll_dungeon_chest,
    use_dungeon_shrine,
)


class AlwaysLowRandom(random.Random):
    def random(self) -> float:
        return 0.0


class DungeonTests(unittest.TestCase):
    def test_dungeon_references_existing_enemies_and_items(self) -> None:
        dungeon = create_dungeon("sunken_order_crypt")
        enemy_ids = (
            *dungeon.room_one_enemies,
            *dungeon.room_two_enemies,
            *dungeon.room_three_enemies,
            dungeon.iron_path_enemy,
            dungeon.flooded_ambush_enemy,
            dungeon.mandatory_elite_enemy,
            dungeon.boss_enemy,
        )
        for enemy_id in enemy_ids:
            self.assertIn(enemy_id, ENEMY_DATA)

        for entry in dungeon.flooded_chest_loot:
            self.assertIn(entry["item_id"], ITEM_DATA)

    def test_all_new_dungeon_materials_have_recipes_and_loot_sources(self) -> None:
        materials = {
            "order_seal",
            "grandmaster_chain",
            "crown_fragment",
        }
        ingredients = {
            item_id
            for recipe in RECIPE_DATA.values()
            for item_id in recipe["ingredients"]
        }
        loot = {
            entry["item_id"]
            for entries in LOOT_TABLES.values()
            for entry in entries
        }
        self.assertTrue(materials <= ingredients)
        self.assertTrue(materials <= loot)

    def test_dungeon_rewards_are_epic_equipment(self) -> None:
        for item_id in (
            "grandmaster_sword",
            "sunken_order_cloak",
            "abyss_ring",
        ):
            definition = get_item_definition(item_id)
            self.assertTrue(definition.is_equipment)
            self.assertEqual(definition.rarity.code, "epic")

    def test_snapshot_reports_only_new_loot(self) -> None:
        player = create_player("Tester")
        player.inventory.add("drowned_coin", 2)
        snapshot = capture_dungeon_loot_snapshot(player.inventory)

        player.inventory.add("drowned_coin", 3)
        player.inventory.add("order_seal", 2)
        player.inventory.add("grandmaster_sword", 1)

        changes = {
            change.item_id: change.quantity
            for change in dungeon_loot_since_snapshot(
                player.inventory, snapshot
            )
        }
        self.assertEqual(changes["drowned_coin"], 3)
        self.assertEqual(changes["order_seal"], 2)
        self.assertEqual(changes["grandmaster_sword"], 1)

    def test_defeat_removes_only_unsecured_new_loot(self) -> None:
        player = create_player("Tester")
        player.inventory.add("drowned_coin", 5)
        player.inventory.add("sunken_knight_armor", 1)
        old_equipment_id = player.inventory.equipment_items[-1].instance_id
        snapshot = capture_dungeon_loot_snapshot(player.inventory)

        player.inventory.add("drowned_coin", 2)
        player.inventory.add("order_seal", 3)
        player.inventory.add("grandmaster_sword", 1)

        lost = discard_unsecured_dungeon_loot(
            player.inventory, snapshot
        )
        lost_map = {change.item_id: change.quantity for change in lost}

        self.assertEqual(player.inventory.count("drowned_coin"), 5)
        self.assertEqual(player.inventory.count("order_seal"), 0)
        self.assertEqual(player.inventory.count("grandmaster_sword"), 0)
        self.assertEqual(
            player.inventory.equipment_items[0].instance_id,
            old_equipment_id,
        )
        self.assertEqual(lost_map["drowned_coin"], 2)
        self.assertEqual(lost_map["order_seal"], 3)
        self.assertEqual(lost_map["grandmaster_sword"], 1)

    def test_consumed_dungeon_loot_is_not_removed_twice(self) -> None:
        player = create_player("Tester")
        player.inventory.add("strong_healing_potion", 2)
        snapshot = capture_dungeon_loot_snapshot(player.inventory)
        player.inventory.add("strong_healing_potion", 1)
        player.inventory.remove_stack("strong_healing_potion", 2)

        discard_unsecured_dungeon_loot(player.inventory, snapshot)

        self.assertEqual(
            player.inventory.count("strong_healing_potion"),
            1,
        )

    def test_flooded_chest_adds_guaranteed_loot(self) -> None:
        player = create_player("Tester")
        dungeon = create_dungeon("sunken_order_crypt")
        drops = roll_dungeon_chest(
            dungeon,
            player.inventory,
            AlwaysLowRandom(),
        )
        drop_ids = {drop.item_id for drop in drops}
        self.assertIn("order_seal", drop_ids)
        self.assertIn("drowned_coin", drop_ids)
        self.assertIn("strong_healing_potion", drop_ids)
        self.assertEqual(player.inventory.count("order_seal"), 1)
        self.assertEqual(player.inventory.count("drowned_coin"), 2)

    def test_shrine_restores_quarter_without_overhealing(self) -> None:
        player = create_player("Tester")
        player.level = 5
        player.choose_class(PlayerClass.MAGE)
        player.stats.current_hp = 1
        player.stats.current_mana = 1

        healed, mana = use_dungeon_shrine(player)

        self.assertGreater(healed, 0)
        self.assertGreater(mana, 0)
        self.assertLessEqual(player.stats.current_hp, player.stats.max_hp)
        self.assertLessEqual(
            player.stats.current_mana,
            player.stats.max_mana,
        )

    def test_grandmaster_phase_two_changes_attack_and_defense(self) -> None:
        player = create_player("Tester")
        player.stats.max_hp = 1000
        player.stats.current_hp = 1000
        enemy = create_enemy("order_grandmaster")
        engine = GrandMasterCombatEngine(
            player, enemy, random.Random(1)
        )
        enemy.current_hp = int(enemy.max_hp * 0.60)
        report = TurnReport()

        engine._update_phase(report)

        self.assertEqual(engine.phase, 2)
        self.assertEqual(enemy.attack, 21)
        self.assertEqual(enemy.defense, 6)
        self.assertTrue(report.boss_notes)

    def test_grandmaster_phase_three_applies_water_aura(self) -> None:
        player = create_player("Tester")
        player.stats.max_hp = 1000
        player.stats.current_hp = 1000
        enemy = create_enemy("order_grandmaster")
        engine = GrandMasterCombatEngine(
            player, enemy, random.Random(7)
        )
        enemy.current_hp = int(enemy.max_hp * 0.25)

        report = engine.player_defend()

        self.assertEqual(engine.phase, 3)
        self.assertGreater(report.boss_aura_damage, 0)
        self.assertEqual(engine.result, CombatResult.ONGOING)


if __name__ == "__main__":
    unittest.main()
