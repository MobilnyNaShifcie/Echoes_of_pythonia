import unittest

from data.items import ITEM_DATA
from data.loot_tables import LOOT_TABLES
from data.recipes import RECIPE_DATA
from game.config import STARTING_WEAPON_ID


class MaterialCraftingIntegrityTests(unittest.TestCase):
    def setUp(self) -> None:
        self.material_ids = {
            item_id
            for item_id, data in ITEM_DATA.items()
            if data["category"] == "material"
        }
        self.recipe_ingredient_ids = {
            item_id
            for recipe in RECIPE_DATA.values()
            for item_id in recipe["ingredients"]
        }
        self.loot_item_ids = {
            entry["item_id"]
            for entries in LOOT_TABLES.values()
            for entry in entries
        }

    def test_every_material_is_used_by_at_least_one_recipe(self) -> None:
        unused = self.material_ids - self.recipe_ingredient_ids
        self.assertEqual(
            unused,
            set(),
            f"Materiały bez zastosowania: {sorted(unused)}",
        )

    def test_every_material_recipe_ingredient_has_loot_source(self) -> None:
        material_ingredients = (
            self.recipe_ingredient_ids & self.material_ids
        )
        missing = material_ingredients - self.loot_item_ids
        self.assertEqual(
            missing,
            set(),
            f"Składniki bez źródła w dropie: {sorted(missing)}",
        )

    def test_non_material_recipe_ingredients_are_deliberate(self) -> None:
        non_material = (
            self.recipe_ingredient_ids - self.material_ids
        )
        self.assertEqual(
            non_material,
            {
                STARTING_WEAPON_ID,
                "weak_healing_potion",
                "strong_healing_potion",
                "great_healing_potion",
            },
        )

    def test_every_enemy_drops_something_with_gameplay_use(self) -> None:
        for enemy_id, entries in LOOT_TABLES.items():
            useful = False

            for entry in entries:
                item_id = entry["item_id"]
                category = ITEM_DATA[item_id]["category"]

                if category != "material":
                    useful = True
                    break

                if item_id in self.recipe_ingredient_ids:
                    useful = True
                    break

            self.assertTrue(
                useful,
                f"{enemy_id} nie ma dropu z zastosowaniem.",
            )


if __name__ == "__main__":
    unittest.main()
