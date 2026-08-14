import unittest

from data.loot_tables import LOOT_TABLES
from items.affixes import EquipmentQuality
from systems.crafting import get_recipe


class Region4LootCraftingV019Tests(unittest.TestCase):
    def test_life_spark_and_common_essence_return_in_region_four_crafting(self) -> None:
        region_recipes = [
            get_recipe("wasteland_armor"),
            get_recipe("sun_talisman"),
            get_recipe("hearth_gauntlets"),
            get_recipe("azhar_crown"),
            get_recipe("azhar_ring"),
        ]
        ingredients = {
            item_id
            for recipe in region_recipes
            for item_id in recipe.ingredients
        }
        self.assertIn("spark_of_life", ingredients)
        self.assertIn("common_essence", ingredients)

    def test_miniboss_and_boss_have_guaranteed_crafting_materials(self) -> None:
        hearth = {entry["item_id"]: entry["chance"] for entry in LOOT_TABLES["hearth_devourer"]}
        azhar = {entry["item_id"]: entry["chance"] for entry in LOOT_TABLES["azhar"]}
        self.assertEqual(hearth["hearth_core"], 1.0)
        self.assertEqual(azhar["azhar_sigil"], 1.0)

    def test_miniboss_and_boss_bad_luck_recipes_preserve_source_quality(self) -> None:
        self.assertEqual(
            get_recipe("hearth_gauntlets").equipment_quality,
            EquipmentQuality.MINIBOSS,
        )
        for recipe_id in ("azhar_blade", "azhar_crown", "azhar_ring"):
            self.assertEqual(
                get_recipe(recipe_id).equipment_quality,
                EquipmentQuality.BOSS,
            )

    def test_azhar_recipes_require_repeated_boss_kills(self) -> None:
        for recipe_id in ("azhar_blade", "azhar_crown", "azhar_ring"):
            self.assertEqual(get_recipe(recipe_id).ingredients["azhar_sigil"], 6)


if __name__ == "__main__":
    unittest.main()
