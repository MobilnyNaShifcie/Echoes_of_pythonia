import io
import unittest
from contextlib import redirect_stdout

from player.factory import create_player
from systems.blacksmith import get_upgrade_targets
from ui.blacksmith_view import show_blacksmith_menu


class BlacksmithUiV01710Tests(unittest.TestCase):
    def test_ready_status_uses_natural_upgrade_wording(self) -> None:
        player = create_player("Tester")
        player.gold = 100
        player.inventory.add("whetstone", 1)
        buffer = io.StringIO()

        with redirect_stdout(buffer):
            show_blacksmith_menu(player, get_upgrade_targets(player))

        output = buffer.getvalue()
        self.assertIn("[MOŻNA ULEPSZYĆ]", output)
        self.assertNotIn("[GOTOWE]", output)


if __name__ == "__main__":
    unittest.main()
