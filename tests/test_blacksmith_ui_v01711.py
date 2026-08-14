import io
import unittest
from contextlib import redirect_stdout

from items.models import EquipmentSlot
from player.factory import create_player
from systems.blacksmith import get_upgrade_targets
from ui.blacksmith_view import show_blacksmith_menu


class BlacksmithUiV01711Tests(unittest.TestCase):
    def test_equipped_and_backpack_are_separate_sections(self) -> None:
        player = create_player("Tester")
        player.inventory.add("wraith_ring")
        buffer = io.StringIO()

        with redirect_stdout(buffer):
            show_blacksmith_menu(player, get_upgrade_targets(player))

        output = buffer.getvalue()
        self.assertIn("=== ZAŁOŻONE ===", output)
        self.assertIn("=== PLECAK ===", output)
        self.assertLess(
            output.index("=== ZAŁOŻONE ==="),
            output.index("=== PLECAK ==="),
        )
        self.assertNotIn("[Plecak]", output)
        self.assertNotIn("[Założone:", output)

    def test_equipped_item_keeps_short_slot_label(self) -> None:
        player = create_player("Tester")
        targets = get_upgrade_targets(player)
        weapon_index = next(
            index
            for index, target in enumerate(targets, start=1)
            if target.slot is EquipmentSlot.WEAPON
        )
        buffer = io.StringIO()

        with redirect_stdout(buffer):
            show_blacksmith_menu(player, targets)

        output = buffer.getvalue()
        self.assertIn(f"[{weapon_index}]", output)
        self.assertIn("[Broń]", output)

    def test_numbering_stays_global_across_sections(self) -> None:
        player = create_player("Tester")
        player.inventory.add("wraith_ring")
        targets = get_upgrade_targets(player)
        buffer = io.StringIO()

        with redirect_stdout(buffer):
            show_blacksmith_menu(player, targets)

        output = buffer.getvalue()
        backpack_index = next(
            index
            for index, target in enumerate(targets, start=1)
            if target.slot is None
        )
        self.assertIn(f"[{backpack_index}]", output)


if __name__ == "__main__":
    unittest.main()
