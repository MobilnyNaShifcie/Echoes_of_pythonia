import unittest

from items.factory import create_equipment_item
from player.factory import create_player
from systems.guild_storage import (
    GUILD_STORAGE_CAPACITY_SLOTS,
    GuildStorage,
    deposit_equipment_many,
    deposit_stacks,
    withdraw_equipment_many,
    withdraw_stacks,
)
from ui.quartermaster_view import (
    parse_multi_index_selection,
    parse_stack_multi_selection,
)


class QuartermasterBulkParsingV0244Tests(unittest.TestCase):
    def test_equipment_parser_accepts_lists_and_ranges(self):
        self.assertEqual(parse_multi_index_selection("1,3,5-7", 7), [0, 2, 4, 5, 6])

    def test_equipment_parser_rejects_duplicates(self):
        with self.assertRaises(ValueError):
            parse_multi_index_selection("1,1", 3)

    def test_stack_parser_supports_whole_and_partial_stacks(self):
        player = create_player("Tester")
        player.inventory.add("weak_leather", 12)
        player.inventory.add("slime_gel", 8)
        item_ids = ["weak_leather", "slime_gel"]
        result = parse_stack_multi_selection("1,2x3", player.inventory, item_ids)
        self.assertEqual(result, {"weak_leather": 12, "slime_gel": 3})


class QuartermasterBulkTransfersV0244Tests(unittest.TestCase):
    def test_bulk_equipment_deposit_preserves_exact_instances(self):
        player = create_player("Tester")
        storage = GuildStorage()
        items = [
            create_equipment_item("nature_amulet"),
            create_equipment_item("hunter_gloves"),
            create_equipment_item("reinforced_boots"),
        ]
        items[0].upgrade_level = 4
        items[2].upgrade_level = 7
        for item in items:
            player.inventory.add_equipment_instance(item)

        moved = deposit_equipment_many(player, storage, [0, 2])
        self.assertEqual([i.instance_id for i in moved], [items[0].instance_id, items[2].instance_id])
        self.assertEqual([i.upgrade_level for i in moved], [4, 7])
        self.assertEqual(len(player.inventory.equipment_items), 1)
        self.assertEqual(len(storage.inventory.equipment_items), 2)

    def test_bulk_equipment_deposit_is_rejected_before_partial_move_when_full(self):
        player = create_player("Tester")
        storage = GuildStorage()
        first = create_equipment_item("nature_amulet")
        second = create_equipment_item("hunter_gloves")
        player.inventory.add_equipment_instance(first)
        player.inventory.add_equipment_instance(second)
        for _ in range(GUILD_STORAGE_CAPACITY_SLOTS - 1):
            storage.inventory.add_equipment_instance(create_equipment_item("nature_amulet"))

        with self.assertRaises(ValueError):
            deposit_equipment_many(player, storage, [0, 1])
        self.assertEqual(len(player.inventory.equipment_items), 2)
        self.assertEqual(storage.used_slots, GUILD_STORAGE_CAPACITY_SLOTS - 1)

    def test_bulk_equipment_withdraw_returns_selected_instances(self):
        player = create_player("Tester")
        storage = GuildStorage()
        items = [create_equipment_item("nature_amulet") for _ in range(3)]
        for item in items:
            storage.inventory.add_equipment_instance(item)
        moved = withdraw_equipment_many(player, storage, [0, 2])
        self.assertEqual([i.instance_id for i in moved], [items[0].instance_id, items[2].instance_id])
        self.assertEqual(len(storage.inventory.equipment_items), 1)
        self.assertEqual(len(player.inventory.equipment_items), 2)

    def test_bulk_stack_transfer_is_reversible(self):
        player = create_player("Tester")
        storage = GuildStorage()
        player.inventory.add("weak_leather", 20)
        player.inventory.add("slime_gel", 10)
        deposit_stacks(player, storage, {"weak_leather": 15, "slime_gel": 4})
        self.assertEqual(player.inventory.count("weak_leather"), 5)
        self.assertEqual(storage.inventory.count("weak_leather"), 15)
        withdraw_stacks(player, storage, {"weak_leather": 5, "slime_gel": 2})
        self.assertEqual(player.inventory.count("weak_leather"), 10)
        self.assertEqual(storage.inventory.count("weak_leather"), 10)


if __name__ == "__main__":
    unittest.main()
