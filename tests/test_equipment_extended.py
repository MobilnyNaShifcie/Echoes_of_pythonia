import unittest

from player.factory import create_player


class ExtendedEquipmentTests(unittest.TestCase):
    def test_dodge_equipment_adds_to_attribute_dodge(self) -> None:
        player = create_player("Tester")
        player.level = 99
        player.inventory.add("spiderstep_boots")
        player.equip_from_inventory(0)

        self.assertEqual(player.stats.dodge, 3.0)

    def test_mana_equipment_increases_max_mana_without_refill(self) -> None:
        player = create_player("Tester")
        player.level = 99
        player.inventory.add("cultist_pendant")
        player.equip_from_inventory(0)

        self.assertEqual(player.stats.max_mana, 10)
        self.assertEqual(player.stats.current_mana, 0)

    def test_executioner_axe_replaces_starting_weapon(self) -> None:
        player = create_player("Tester")
        player.level = 99
        player.inventory.add("executioner_axe")
        player.equip_from_inventory(0)

        self.assertEqual(player.stats.attack, 7)
        self.assertEqual(len(player.inventory.equipment_items), 1)
        self.assertEqual(
            player.inventory.equipment_items[0].item_id,
            "starter_sword",
        )

    def test_upgraded_equipment_keeps_level_after_swap(self) -> None:
        player = create_player("Tester")
        player.level = 99
        player.inventory.add("executioner_axe")
        axe = player.inventory.equipment_items[0]
        axe.upgrade_level = 6

        player.equip_from_inventory(0)

        equipped_axe = next(
            item
            for item in player.equipment.slots.values()
            if item.item_id == "executioner_axe"
        )
        self.assertEqual(equipped_axe.upgrade_level, 6)

        old_sword = player.inventory.equipment_items[0]
        self.assertEqual(old_sword.item_id, "starter_sword")
        self.assertEqual(old_sword.upgrade_level, 0)
