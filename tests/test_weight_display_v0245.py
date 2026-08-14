import io
import unittest
from contextlib import redirect_stdout

from player.factory import create_player
from systems.carry_weight import stack_weight
from systems.guild_storage import GuildStorage
from ui.inventory_view import show_inventory
from ui.quartermaster_view import show_storage, show_stack_selection


class WeightDisplayV0245Tests(unittest.TestCase):
    def test_stack_weight_returns_total_weight(self):
        self.assertEqual(stack_weight("weak_leather", 100), 5.0)
        self.assertEqual(stack_weight("weak_leather", 0), 0.0)

    def test_inventory_displays_total_weight_for_each_stack(self):
        player = create_player("Tester")
        player.inventory.add("weak_leather", 100)
        buffer = io.StringIO()
        with redirect_stdout(buffer):
            show_inventory(player)
        output = buffer.getvalue()
        self.assertIn("Słaba Skóra x100", output)
        self.assertIn("Waga: 5.0 kg", output)

    def test_quartermaster_storage_displays_total_stack_weight(self):
        player = create_player("Tester")
        storage = GuildStorage()
        storage.inventory.add("weak_leather", 100)
        buffer = io.StringIO()
        with redirect_stdout(buffer):
            show_storage(player, storage)
        output = buffer.getvalue()
        self.assertIn("Słaba Skóra x100 | Waga: 5.0 kg", output)

    def test_quartermaster_selection_displays_total_and_unit_weight(self):
        player = create_player("Tester")
        player.inventory.add("weak_leather", 100)
        buffer = io.StringIO()
        with redirect_stdout(buffer):
            show_stack_selection(player.inventory, "TEST")
        output = buffer.getvalue()
        self.assertIn("Waga: 5.0 kg (0.05 kg/szt.)", output)


if __name__ == "__main__":
    unittest.main()
