import io
import unittest
from contextlib import redirect_stdout

from player.factory import create_player
from systems.crafting import get_all_recipes
from ui.crafting_view import show_crafting_menu


class CraftingUiV0178Tests(unittest.TestCase):
    def test_unavailable_recipe_uses_descriptive_resource_status(self) -> None:
        player = create_player("Tester")
        recipes = get_all_recipes()

        buffer = io.StringIO()
        with redirect_stdout(buffer):
            show_crafting_menu(player, recipes)

        output = buffer.getvalue()
        self.assertIn("[BRAK WYMAGANYCH ZASOBÓW]", output)
        self.assertNotIn("] [BRAKI]", output)


if __name__ == "__main__":
    unittest.main()
