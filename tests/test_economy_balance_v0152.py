import unittest

from data.dungeons import DUNGEON_DATA
from data.enemies import ENEMY_DATA
from data.economy import MERCHANT_STOCK
from data.recipes import RECIPE_DATA
from items.consumables import use_consumable
from player.classes import PlayerClass
from player.factory import create_player
from systems.blacksmith import get_upgrade_cost


class EconomyBalanceV0152Tests(unittest.TestCase):
    def test_early_game_gold_was_not_nerfed(self) -> None:
        self.assertEqual(
            (
                ENEMY_DATA["wild_dog"]["gold_min"],
                ENEMY_DATA["wild_dog"]["gold_max"],
            ),
            (5, 5),
        )
        self.assertEqual(
            (
                ENEMY_DATA["forest_cultist"]["gold_min"],
                ENEMY_DATA["forest_cultist"]["gold_max"],
            ),
            (28, 40),
        )

    def test_late_boss_gold_is_rebalanced(self) -> None:
        self.assertEqual(
            (
                ENEMY_DATA["drowned_mother"]["gold_min"],
                ENEMY_DATA["drowned_mother"]["gold_max"],
            ),
            (300, 450),
        )
        self.assertEqual(
            (
                ENEMY_DATA["order_grandmaster"]["gold_min"],
                ENEMY_DATA["order_grandmaster"]["gold_max"],
            ),
            (450, 650),
        )

    def test_expected_full_crypt_gold_is_in_target_band(self) -> None:
        dungeon = DUNGEON_DATA["sunken_order_crypt"]

        def average(enemy_id: str) -> float:
            enemy = ENEMY_DATA[enemy_id]
            return (
                float(enemy["gold_min"])
                + float(enemy["gold_max"])
            ) / 2.0

        def pool_average(pool: tuple[str, ...]) -> float:
            return sum(average(enemy_id) for enemy_id in pool) / len(pool)

        common = (
            pool_average(dungeon["room_one_enemies"])
            + pool_average(dungeon["room_two_enemies"])
            + pool_average(dungeon["room_three_enemies"])
            + average(dungeon["mandatory_elite_enemy"])
            + average(dungeon["boss_enemy"])
        )

        iron_total = common + average(dungeon["iron_path_enemy"])
        flooded_total = (
            common
            + float(dungeon["flooded_ambush_chance"])
            * average(dungeon["flooded_ambush_enemy"])
        )

        self.assertGreaterEqual(flooded_total, 1100)
        self.assertLessEqual(flooded_total, 1200)
        self.assertGreaterEqual(iron_total, 1200)
        self.assertLessEqual(iron_total, 1300)

    def test_ip_one_full_upgrade_gold_cost_remains_4025(self) -> None:
        total = sum(
            get_upgrade_cost(level).gold
            for level in range(10)
        )
        self.assertEqual(total, 4025)

    def test_high_end_crafting_has_gold_costs(self) -> None:
        self.assertEqual(
            RECIPE_DATA["executioner_axe"]["gold_cost"],
            450,
        )
        self.assertEqual(
            RECIPE_DATA["drowned_mother_blade"]["gold_cost"],
            750,
        )
        self.assertEqual(
            RECIPE_DATA["grandmaster_sword"]["gold_cost"],
            1200,
        )
        self.assertEqual(
            RECIPE_DATA["abyss_ring"]["gold_cost"],
            800,
        )
        self.assertEqual(
            int(RECIPE_DATA["leather_hood"].get("gold_cost", 0)),
            0,
        )

    def test_grandmaster_elixir_costs_2500(self) -> None:
        stock = {
            str(entry["item_id"]): int(entry["buy_price"])
            for entry in MERCHANT_STOCK
        }
        self.assertEqual(stock["grandmaster_elixir"], 2500)

    def test_grandmaster_elixir_restores_hp_and_mana(self) -> None:
        player = create_player("Tester")
        player.level = 12
        player.attributes.vitality = 10
        player.recalculate_stats()
        player.choose_class(PlayerClass.MAGE)
        player.stats.current_hp = player.stats.max_hp - 60
        player.stats.current_mana = max(0, player.stats.max_mana - 20)
        player.inventory.add("grandmaster_elixir", 1)

        hp_before = player.stats.current_hp
        mana_before = player.stats.current_mana

        result = use_consumable(player, "grandmaster_elixir")

        expected_hp = min(60, round(player.stats.max_hp * 0.35))
        expected_mana = min(20, round(player.stats.max_mana * 0.20))
        self.assertEqual(result.healed_hp, expected_hp)
        self.assertEqual(result.restored_mana, expected_mana)
        self.assertEqual(player.stats.current_hp, hp_before + expected_hp)
        self.assertEqual(player.stats.current_mana, mana_before + expected_mana)
        self.assertEqual(
            player.inventory.count("grandmaster_elixir"),
            0,
        )

    def test_grandmaster_elixir_is_not_wasted_at_full_resources(self) -> None:
        player = create_player("Tester")
        player.level = 12
        player.choose_class(PlayerClass.MAGE)
        player.inventory.add("grandmaster_elixir", 1)

        with self.assertRaises(ValueError):
            use_consumable(player, "grandmaster_elixir")

        self.assertEqual(
            player.inventory.count("grandmaster_elixir"),
            1,
        )


if __name__ == "__main__":
    unittest.main()
