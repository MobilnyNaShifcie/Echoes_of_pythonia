from contextlib import redirect_stdout
from io import StringIO
import random
import unittest

from items.affixes import EquipmentQuality, generate_equipment_item
from player.factory import create_player
from ui.inventory_view import show_equipment_details, show_equippable_inventory


class ItemProgressionUiV018Tests(unittest.TestCase):
    def test_detail_shows_required_level_and_average_damage(self) -> None:
        item = generate_equipment_item(
            "grandmaster_sword",
            random.Random(4),
            quality=EquipmentQuality.BOSS,
        )
        output = StringIO()
        with redirect_stdout(output):
            show_equipment_details(item)
        text = output.getvalue()

        self.assertIn("Wymagany poziom: 10", text)
        self.assertIn("ŚREDNIE OBRAŻENIA", text)

    def test_equip_list_shows_required_level(self) -> None:
        player = create_player("Tester")
        player.inventory.add_generated_equipment(
            "grandmaster_sword",
            random.Random(5),
            quality=EquipmentQuality.BOSS,
        )
        output = StringIO()
        with redirect_stdout(output):
            show_equippable_inventory(player)

        self.assertIn("Wym. poz. 10", output.getvalue())


if __name__ == "__main__":
    unittest.main()
