import unittest

from items.catalog import get_item_definition
from items.models import EquipmentSlot
from player.factory import create_player


class EquipmentTests(unittest.TestCase):
    def test_starting_equipment_provides_initial_stats(self) -> None:
        player = create_player("Tester")

        self.assertEqual(player.stats.attack, 3)
        self.assertEqual(player.stats.defense, 2)
        self.assertEqual(player.stats.max_hp, 20)

    def test_equipping_necklace_changes_attack(self) -> None:
        player = create_player("Tester")
        player.level = 99
        player.inventory.add("wolf_tooth_necklace")

        player.equip_from_inventory(0)

        self.assertEqual(player.stats.attack, 5)
        self.assertIsNotNone(
            player.equipment.get(EquipmentSlot.NECKLACE)
        )

    def test_swapping_chest_returns_old_item_to_inventory(self) -> None:
        player = create_player("Tester")
        player.level = 99
        player.inventory.add("nature_amulet")
        # Amulet to inny slot, więc najpierw testujemy zwykłe dołożenie.
        player.equip_from_inventory(0)

        self.assertEqual(len(player.inventory.equipment_items), 0)

        # Wkładamy drugą zbroję testowo przez katalog istniejącego itemu.
        player.inventory.add("worn_leather_armor")
        player.equip_from_inventory(0)

        chest = player.equipment.get(EquipmentSlot.CHEST)
        self.assertIsNotNone(chest)

        self.assertEqual(len(player.inventory.equipment_items), 1)
        returned = get_item_definition(
            player.inventory.equipment_items[0].item_id
        )
        self.assertEqual(returned.name, "Zużyta Skórzana Zbroja")

    def test_unequip_moves_item_to_inventory_without_duplication(self) -> None:
        player = create_player("Tester")
        initial_inventory_count = len(player.inventory.equipment_items)

        removed = player.unequip_to_inventory(EquipmentSlot.WEAPON)

        self.assertIsNotNone(removed)
        self.assertIsNone(player.equipment.get(EquipmentSlot.WEAPON))
        self.assertEqual(
            len(player.inventory.equipment_items),
            initial_inventory_count + 1,
        )
        self.assertEqual(player.stats.attack, 0)
