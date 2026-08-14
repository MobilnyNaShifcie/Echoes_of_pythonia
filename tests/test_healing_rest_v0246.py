import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from data.recipes import RECIPE_ORDER
from game.config import (
    CAMP_REST_HP_PERCENT,
    CAMP_REST_MANA_PERCENT,
    INN_REST_DURATION_HOURS,
)
from items.consumables import use_consumable
from player.classes import PlayerClass
from player.factory import create_player
from systems.crafting import craft_for_player, get_recipe
from systems.inn import inn_rest_cost, rest_at_camp, rest_at_inn
from systems.item_usage import audit_stackable_gameplay_uses, get_item_usage
from game.state import GameState
from systems.save_system import load_game, save_game
from world.time_system import GameClock


class HealingRestV0246Tests(unittest.TestCase):
    def test_camp_rest_is_partial(self) -> None:
        player = create_player("Tester")
        player.level = 18
        player.attributes.vitality = 60
        player.attributes.intelligence = 20
        player.recalculate_stats()
        player.stats.current_hp = 1
        player.stats.current_mana = 0

        result = rest_at_camp(player)

        self.assertEqual(result.healed_hp, round(player.stats.max_hp * CAMP_REST_HP_PERCENT))
        self.assertEqual(result.restored_mana, round(player.stats.max_mana * CAMP_REST_MANA_PERCENT))
        self.assertLess(player.stats.current_hp, player.stats.max_hp)

    def test_inn_cost_scales_with_level_and_fully_restores(self) -> None:
        player = create_player("Tester")
        player.level = 10
        player.recalculate_stats()
        cost = inn_rest_cost(player)
        player.gold = cost + 100
        player.stats.current_hp = 1
        clock = GameClock(day=5, hour=12)

        result = rest_at_inn(player, clock, last_inn_rest_day=0)

        self.assertEqual(result.gold_cost, cost)
        self.assertEqual(player.stats.current_hp, player.stats.max_hp)
        self.assertEqual(clock.hour, (12 + INN_REST_DURATION_HOURS) % 24)
        self.assertEqual(result.next_available_day, clock.day + 1)

    def test_inn_cannot_be_spammed_same_day(self) -> None:
        player = create_player("Tester")
        player.gold = 10_000
        player.stats.current_hp = 1
        clock = GameClock(day=3, hour=8)

        with self.assertRaises(ValueError):
            rest_at_inn(player, clock, last_inn_rest_day=3)

    def test_potion_upgrade_chain(self) -> None:
        player = create_player("Tester")
        player.inventory.add("weak_healing_potion", 3)
        craft_for_player(player, get_recipe("weak_to_strong_potion"))
        self.assertEqual(player.inventory.count("strong_healing_potion"), 1)

        player.inventory.add("strong_healing_potion", 2)
        player.inventory.add("mist_essence", 1)
        craft_for_player(player, get_recipe("great_healing_potion"))
        self.assertEqual(player.inventory.count("great_healing_potion"), 1)

        player.inventory.add("great_healing_potion", 1)
        player.inventory.add("spark_of_life", 1)
        craft_for_player(player, get_recipe("grandmaster_elixir"))
        self.assertEqual(player.inventory.count("grandmaster_elixir"), 1)

    def test_grandmaster_elixir_scales_with_max_stats(self) -> None:
        player = create_player("Tester")
        player.level = 18
        player.attributes.vitality = 80
        player.attributes.intelligence = 30
        player.recalculate_stats()
        player.choose_class(PlayerClass.MAGE)
        player.stats.current_hp = 1
        player.stats.current_mana = 0
        player.inventory.add("grandmaster_elixir", 1)

        result = use_consumable(player, "grandmaster_elixir")

        self.assertEqual(result.healed_hp, round(player.stats.max_hp * 0.35))
        self.assertEqual(result.restored_mana, round(player.stats.max_mana * 0.20))

    def test_rest_cooldowns_round_trip_in_save(self) -> None:
        player = create_player("Tester")
        state = GameState(
            active_game=True,
            player=player,
            camp_rest_available=False,
            last_inn_rest_day=7,
        )
        with tempfile.TemporaryDirectory() as temp:
            save_dir = Path(temp)
            save_path = save_dir / "save.json"
            with patch("systems.save_system.get_save_directory", return_value=save_dir), patch(
                "systems.save_system.get_save_path", return_value=save_path
            ):
                save_game(state)
                loaded = load_game()
        self.assertFalse(loaded.camp_rest_available)
        self.assertEqual(loaded.last_inn_rest_day, 7)

    def test_every_material_and_key_has_gameplay_use(self) -> None:
        self.assertEqual(audit_stackable_gameplay_uses(), {})

    def test_drowned_coin_usage_is_visible(self) -> None:
        usage = get_item_usage("drowned_coin")
        self.assertIn("Rękawice Topielca", usage.recipe_names)
        self.assertIn("Pancerz Zatopionego Zakonu", usage.recipe_names)
        self.assertIn("Medalion Utopionej Matki", usage.recipe_names)

    def test_instance_keys_are_documented_as_dungeon_entries(self) -> None:
        self.assertIn(
            "Krypta Zatopionego Zakonu",
            get_item_usage("ancient_order_key").dungeon_names,
        )
        self.assertIn(
            "Wrak Czarnej Floty",
            get_item_usage("black_fleet_medallion").dungeon_names,
        )

    def test_ancient_order_key_recipe_is_visible_in_recipe_order(self) -> None:
        self.assertIn("ancient_order_key", RECIPE_ORDER)


if __name__ == "__main__":
    unittest.main()
