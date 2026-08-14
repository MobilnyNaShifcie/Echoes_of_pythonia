import io
import unittest
from contextlib import redirect_stdout

from player.factory import create_player
from ui.dungeon_view import show_dungeon_entrance
from world.dungeon import create_dungeon


class DungeonEntranceUiV0176Tests(unittest.TestCase):
    def _render(self, key_count: int) -> str:
        player = create_player("Tester")
        player.level = 17
        if key_count:
            player.inventory.add("ancient_order_key", key_count)
        dungeon = create_dungeon("sunken_order_crypt")

        output = io.StringIO()
        with redirect_stdout(output):
            show_dungeon_entrance(player, dungeon)
        return output.getvalue()

    def test_key_count_is_enough_without_ready_marker(self) -> None:
        output = self._render(2)
        self.assertIn("Starożytny Klucz Zakonu: 2/1", output)
        self.assertNotIn("[GOTOWE]", output)

    def test_missing_key_is_shown_only_as_quantity(self) -> None:
        output = self._render(0)
        self.assertIn("Starożytny Klucz Zakonu: 0/1", output)
        self.assertNotIn("[BRAK]", output)


if __name__ == "__main__":
    unittest.main()
