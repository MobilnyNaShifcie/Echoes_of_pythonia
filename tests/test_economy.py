import unittest

from player.factory import create_player
from systems.economy import (
    buy_item,
    get_equipment_sell_price,
    get_merchant_stock,
    sell_equipment_item,
    sell_stack_item,
)


class EconomyTests(unittest.TestCase):
    def test_buying_item_spends_gold(self) -> None:
        player = create_player("Tester")
        player.gold = 100
        potion = next(e for e in get_merchant_stock() if e.item_id == "weak_healing_potion")
        buy_item(player, potion)
        self.assertEqual(player.gold, 75)
        self.assertEqual(player.inventory.count("weak_healing_potion"), 1)

    def test_cannot_buy_without_gold(self) -> None:
        player = create_player("Tester")
        potion = next(e for e in get_merchant_stock() if e.item_id == "weak_healing_potion")
        with self.assertRaises(ValueError):
            buy_item(player, potion)

    def test_selling_stack_adds_gold_and_removes_one(self) -> None:
        player = create_player("Tester")
        player.inventory.add("wolf_fur", 2)
        price = sell_stack_item(player, "wolf_fur")
        self.assertEqual(player.gold, price)
        self.assertEqual(player.inventory.count("wolf_fur"), 1)

    def test_upgraded_equipment_is_worth_more(self) -> None:
        player = create_player("Tester")
        player.inventory.add("leather_hood", 2)
        first, second = player.inventory.equipment_items
        second.upgrade_level = 5
        self.assertGreater(get_equipment_sell_price(second), get_equipment_sell_price(first))

    def test_buy_craft_sell_does_not_create_infinite_gold(self) -> None:
        from systems.crafting import craft, get_recipe

        player = create_player("Tester")
        player.gold = 100
        leather = next(e for e in get_merchant_stock() if e.item_id == "weak_leather")
        buy_item(player, leather)
        buy_item(player, leather)
        gold_after_buying = player.gold
        craft(player.inventory, get_recipe("leather_hood"))
        _, sell_price = sell_equipment_item(player, 0)
        self.assertLessEqual(gold_after_buying + sell_price, 100)

    def test_selling_equipment_only_uses_backpack(self) -> None:
        player = create_player("Tester")
        player.inventory.add("leather_hood")
        sold, price = sell_equipment_item(player, 0)
        self.assertEqual(sold.item_id, "leather_hood")
        self.assertEqual(player.inventory.count("leather_hood"), 0)
        self.assertEqual(player.gold, price)
