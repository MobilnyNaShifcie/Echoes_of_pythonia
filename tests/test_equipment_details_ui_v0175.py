import io
import unittest
from contextlib import redirect_stdout

from player.factory import create_player
from ui.inventory_view import (
    show_all_equipped_details,
    show_equipped_detail_selection,
)


class EquipmentDetailsUiV0175Tests(unittest.TestCase):
    def setUp(self) -> None:
        self.player = create_player("Tester")

    def test_selection_offers_show_all_option(self) -> None:
        output = io.StringIO()
        with redirect_stdout(output):
            items = show_equipped_detail_selection(self.player)

        self.assertTrue(items)
        self.assertIn(
            "[A] Pokaż wszystkie szczegóły",
            output.getvalue(),
        )

    def test_show_all_prints_every_equipped_item(self) -> None:
        output = io.StringIO()
        with redirect_stdout(output):
            show_all_equipped_details(self.player)

        rendered = output.getvalue()
        for item in self.player.equipment.slots.values():
            if item is None:
                continue
            from items.catalog import get_item_definition
            definition = get_item_definition(item.item_id)
            self.assertIn(definition.name.upper(), rendered)

    def test_show_all_uses_single_screen_header(self) -> None:
        output = io.StringIO()
        with redirect_stdout(output):
            show_all_equipped_details(self.player)

        rendered = output.getvalue()
        self.assertEqual(
            rendered.count("Echoes of Pythonia"),
            1,
        )


if __name__ == "__main__":
    unittest.main()
