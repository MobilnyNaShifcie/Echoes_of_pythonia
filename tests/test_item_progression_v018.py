import unittest

from data.equipment_requirements import EQUIPMENT_REQUIRED_LEVEL
from data.items import ITEM_DATA
from items.catalog import get_item_definition
from items.models import EquipmentItem
from player.factory import create_player


class ItemProgressionV018Tests(unittest.TestCase):
    def test_every_equipment_has_required_level(self) -> None:
        equipment_ids = {
            item_id
            for item_id, data in ITEM_DATA.items()
            if data.get("category") == "equipment"
        }
        self.assertEqual(set(EQUIPMENT_REQUIRED_LEVEL), equipment_ids)
        self.assertTrue(
            all(level >= 0 for level in EQUIPMENT_REQUIRED_LEVEL.values())
        )

    def test_current_progression_bands_are_ordered(self) -> None:
        self.assertEqual(get_item_definition("starter_sword").required_level, 0)
        self.assertEqual(get_item_definition("nature_amulet").required_level, 3)
        self.assertEqual(get_item_definition("executioner_axe").required_level, 5)
        self.assertEqual(get_item_definition("drowned_mother_blade").required_level, 8)
        self.assertEqual(get_item_definition("grandmaster_sword").required_level, 10)

    def test_too_low_level_cannot_equip_and_item_stays_in_backpack(self) -> None:
        player = create_player("Tester")
        player.level = 9
        player.inventory.add_equipment_instance(
            EquipmentItem(
                item_id="grandmaster_sword",
                item_power=4,
            )
        )

        with self.assertRaisesRegex(ValueError, "Wymagany poziom: 10"):
            player.equip_from_inventory(0)

        self.assertEqual(len(player.inventory.equipment_items), 1)
        self.assertEqual(
            player.inventory.equipment_items[0].item_id,
            "grandmaster_sword",
        )

    def test_exact_required_level_can_equip(self) -> None:
        player = create_player("Tester")
        player.level = 10
        player.inventory.add_equipment_instance(
            EquipmentItem(
                item_id="grandmaster_sword",
                item_power=4,
            )
        )

        equipped = player.equip_from_inventory(0)

        self.assertEqual(equipped.item_id, "grandmaster_sword")


if __name__ == "__main__":
    unittest.main()
