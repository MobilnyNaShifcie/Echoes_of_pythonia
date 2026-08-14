import unittest

from player.factory import create_player
from systems.economy import buy_item, get_merchant_stock, max_affordable_quantity


class BulkPurchaseTests(unittest.TestCase):
    def test_can_buy_multiple_items_at_once(self) -> None:
        player = create_player("Tester")
        player.gold = 200
        entry = get_merchant_stock()[0]
        spent = buy_item(player, entry, 5)
        self.assertEqual(spent, entry.buy_price * 5)
        self.assertEqual(player.inventory.count(entry.item_id), 5)
        self.assertEqual(player.gold, 200 - spent)

    def test_max_affordable_quantity(self) -> None:
        player = create_player("Tester")
        player.gold = 124
        entry = get_merchant_stock()[0]
        self.assertEqual(max_affordable_quantity(player, entry), 4)

    def test_bulk_purchase_rejects_unaffordable_total(self) -> None:
        player = create_player("Tester")
        player.gold = 100
        entry = get_merchant_stock()[0]
        with self.assertRaises(ValueError):
            buy_item(player, entry, 5)
