import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from data.loot_tables import LOOT_TABLES
from game.state import GameState
from items.catalog import get_item_definition
from items.models import ItemCategory
from player.factory import create_player
from quests.models import QuestLog
from systems.crafting import (
    can_craft_for_player,
    craft,
    craft_for_player,
    get_recipe,
)
from systems.quest_system import (
    accept_quest,
    record_enemy_kill,
    turn_in_quest,
)
from systems.save_system import load_game, save_game
from ui.merchant_view import get_sellable_stacks
from world.dungeon import (
    can_enter_dungeon,
    consume_dungeon_entry,
    create_dungeon,
)


class DungeonAccessTests(unittest.TestCase):
    def test_crypt_requires_ancient_order_key(self) -> None:
        player = create_player("Tester")
        dungeon = create_dungeon("sunken_order_crypt")

        self.assertEqual(dungeon.entry_item_id, "ancient_order_key")
        self.assertEqual(dungeon.entry_item_quantity, 1)
        self.assertFalse(can_enter_dungeon(player.inventory, dungeon))

        player.inventory.add("ancient_order_key", 1)

        self.assertTrue(can_enter_dungeon(player.inventory, dungeon))

    def test_entering_crypt_consumes_exactly_one_key(self) -> None:
        player = create_player("Tester")
        dungeon = create_dungeon("sunken_order_crypt")
        player.inventory.add("ancient_order_key", 2)

        consume_dungeon_entry(player.inventory, dungeon)

        self.assertEqual(
            player.inventory.count("ancient_order_key"),
            1,
        )

    def test_failed_entry_does_not_mutate_inventory(self) -> None:
        player = create_player("Tester")
        dungeon = create_dungeon("sunken_order_crypt")

        with self.assertRaises(ValueError):
            consume_dungeon_entry(player.inventory, dungeon)

        self.assertEqual(
            player.inventory.count("ancient_order_key"),
            0,
        )

    def test_mother_guarantees_key_drop(self) -> None:
        entries = LOOT_TABLES["drowned_mother"]
        key_entries = [
            entry
            for entry in entries
            if entry["item_id"] == "ancient_order_key"
        ]

        self.assertEqual(len(key_entries), 1)
        self.assertEqual(float(key_entries[0]["chance"]), 1.0)

    def test_key_has_dedicated_non_sellable_category(self) -> None:
        player = create_player("Tester")
        player.inventory.add("ancient_order_key", 1)

        definition = get_item_definition("ancient_order_key")

        self.assertIs(definition.category, ItemCategory.KEY)
        self.assertNotIn(
            "ancient_order_key",
            get_sellable_stacks(player),
        )

    def test_key_recipe_costs_materials_and_300_gold(self) -> None:
        player = create_player("Tester")
        player.gold = 500
        player.inventory.add("silentwater_heart", 1)
        player.inventory.add("sunken_plate", 2)
        player.inventory.add("mist_essence", 2)
        recipe = get_recipe("ancient_order_key")

        self.assertEqual(recipe.gold_cost, 300)
        self.assertTrue(can_craft_for_player(player, recipe))

        craft_for_player(player, recipe)

        self.assertEqual(player.gold, 200)
        self.assertEqual(player.inventory.count("silentwater_heart"), 0)
        self.assertEqual(player.inventory.count("sunken_plate"), 0)
        self.assertEqual(player.inventory.count("mist_essence"), 0)
        self.assertEqual(player.inventory.count("ancient_order_key"), 1)

    def test_key_recipe_is_atomic_when_gold_is_missing(self) -> None:
        player = create_player("Tester")
        player.gold = 299
        player.inventory.add("silentwater_heart", 1)
        player.inventory.add("sunken_plate", 2)
        player.inventory.add("mist_essence", 2)
        recipe = get_recipe("ancient_order_key")

        self.assertFalse(can_craft_for_player(player, recipe))

        with self.assertRaises(ValueError):
            craft_for_player(player, recipe)

        self.assertEqual(player.gold, 299)
        self.assertEqual(player.inventory.count("silentwater_heart"), 1)
        self.assertEqual(player.inventory.count("sunken_plate"), 2)
        self.assertEqual(player.inventory.count("mist_essence"), 2)
        self.assertEqual(player.inventory.count("ancient_order_key"), 0)

    def test_inventory_only_craft_cannot_bypass_gold_cost(self) -> None:
        player = create_player("Tester")
        player.inventory.add("silentwater_heart", 1)
        player.inventory.add("sunken_plate", 2)
        player.inventory.add("mist_essence", 2)

        with self.assertRaises(ValueError):
            craft(player.inventory, get_recipe("ancient_order_key"))

        self.assertEqual(player.inventory.count("ancient_order_key"), 0)

    def test_guild_contract_rewards_one_key(self) -> None:
        player = create_player("Tester")
        log = QuestLog()
        accept_quest(log, "seal_of_drowned")

        for _ in range(3):
            record_enemy_kill(log, "sunken_knight")

        result = turn_in_quest(
            player,
            log,
            "seal_of_drowned",
        )

        self.assertEqual(result.reward_item_id, "ancient_order_key")
        self.assertEqual(result.reward_item_quantity, 1)
        self.assertEqual(player.inventory.count("ancient_order_key"), 1)

    def test_key_survives_normal_save_and_load(self) -> None:
        player = create_player("Tester")
        player.inventory.add("ancient_order_key", 2)

        with tempfile.TemporaryDirectory() as temp:
            with patch(
                "systems.save_system.get_save_directory",
                return_value=Path(temp),
            ):
                save_game(
                    GameState(active_game=True, player=player)
                )
                loaded = load_game()

        self.assertEqual(
            loaded.player.inventory.count("ancient_order_key"),
            2,
        )


if __name__ == "__main__":
    unittest.main()
