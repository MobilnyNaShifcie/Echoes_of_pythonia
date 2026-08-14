import unittest

from player.factory import create_player
from systems.economy import (
    get_equipment_sell_price,
    get_stack_sell_price,
    sell_equipment_items,
    sell_stack_items,
)
from ui.merchant_view import (
    parse_equipment_sale_selection,
    parse_stack_sale_selection,
)


class BulkSaleTests(unittest.TestCase):
    def test_can_sell_multiple_stack_types_and_quantities(self) -> None:
        player = create_player("Tester")
        player.inventory.add("wolf_fur", 5)
        player.inventory.add("slime_gel", 4)

        expected = (
            get_stack_sell_price("wolf_fur") * 3
            + get_stack_sell_price("slime_gel") * 2
        )

        sold, total = sell_stack_items(
            player,
            {
                "wolf_fur": 3,
                "slime_gel": 2,
            },
        )

        self.assertEqual(total, expected)
        self.assertEqual(len(sold), 2)
        self.assertEqual(player.inventory.count("wolf_fur"), 2)
        self.assertEqual(player.inventory.count("slime_gel"), 2)
        self.assertEqual(player.gold, expected)

    def test_stack_batch_is_atomic_when_quantity_is_invalid(self) -> None:
        player = create_player("Tester")
        player.inventory.add("wolf_fur", 2)
        player.inventory.add("slime_gel", 2)

        with self.assertRaises(ValueError):
            sell_stack_items(
                player,
                {
                    "wolf_fur": 1,
                    "slime_gel": 99,
                },
            )

        self.assertEqual(player.inventory.count("wolf_fur"), 2)
        self.assertEqual(player.inventory.count("slime_gel"), 2)
        self.assertEqual(player.gold, 0)

    def test_stack_selection_supports_quantity_and_max(self) -> None:
        player = create_player("Tester")
        player.inventory.add("wolf_fur", 7)
        player.inventory.add("slime_gel", 4)
        item_ids = ["wolf_fur", "slime_gel"]

        sales = parse_stack_sale_selection(
            "1x3, 2xMAX",
            player,
            item_ids,
        )

        self.assertEqual(
            sales,
            {
                "wolf_fur": 3,
                "slime_gel": 4,
            },
        )

    def test_stack_selection_rejects_more_than_owned(self) -> None:
        player = create_player("Tester")
        player.inventory.add("wolf_fur", 2)

        with self.assertRaises(ValueError):
            parse_stack_sale_selection(
                "1x3",
                player,
                ["wolf_fur"],
            )

    def test_can_sell_multiple_equipment_instances(self) -> None:
        player = create_player("Tester")
        player.inventory.add("leather_hood", 3)

        first = player.inventory.equipment_items[0]
        third = player.inventory.equipment_items[2]
        expected = (
            get_equipment_sell_price(first)
            + get_equipment_sell_price(third)
        )

        sold, total = sell_equipment_items(player, [0, 2])

        self.assertEqual(total, expected)
        self.assertEqual(len(sold), 2)
        self.assertEqual(len(player.inventory.equipment_items), 1)
        self.assertEqual(player.gold, expected)

    def test_equipment_selection_supports_ranges(self) -> None:
        indexes = parse_equipment_sale_selection("1,3,5-7", 7)
        self.assertEqual(indexes, [0, 2, 4, 5, 6])

    def test_equipment_selection_rejects_duplicates(self) -> None:
        with self.assertRaises(ValueError):
            parse_equipment_sale_selection("1,1", 3)

    def test_equipment_batch_is_atomic_with_bad_index(self) -> None:
        player = create_player("Tester")
        player.inventory.add("leather_hood", 2)

        with self.assertRaises(IndexError):
            sell_equipment_items(player, [0, 5])

        self.assertEqual(len(player.inventory.equipment_items), 2)
        self.assertEqual(player.gold, 0)


if __name__ == "__main__":
    unittest.main()
