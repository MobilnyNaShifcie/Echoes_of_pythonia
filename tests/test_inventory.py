import unittest

from player.inventory import Inventory


class InventoryTests(unittest.TestCase):
    def test_stackable_items_stack(self) -> None:
        inventory = Inventory()

        inventory.add("wolf_fur", 2)
        inventory.add("wolf_fur", 3)

        self.assertEqual(inventory.stacks["wolf_fur"], 5)

    def test_equipment_items_are_separate_instances(self) -> None:
        inventory = Inventory()

        inventory.add("leather_hood", 2)

        self.assertEqual(len(inventory.equipment_items), 2)
        self.assertNotEqual(
            inventory.equipment_items[0].instance_id,
            inventory.equipment_items[1].instance_id,
        )

    def test_count_works_for_stacks_and_equipment(self) -> None:
        inventory = Inventory()
        inventory.add("wolf_fur", 3)
        inventory.add("leather_hood", 2)

        self.assertEqual(inventory.count("wolf_fur"), 3)
        self.assertEqual(inventory.count("leather_hood"), 2)

    def test_remove_equipment_item_by_id(self) -> None:
        inventory = Inventory()
        inventory.add("leather_hood", 2)

        inventory.remove_item("leather_hood", 1)

        self.assertEqual(inventory.count("leather_hood"), 1)
