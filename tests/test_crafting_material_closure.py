import unittest

from player.factory import create_player
from systems.crafting import craft, craft_for_player, get_all_recipes, get_recipe


class CraftingMaterialClosureTests(unittest.TestCase):
    def test_hunter_provisions_uses_boar_drops(self) -> None:
        player = create_player("Tester")
        player.inventory.add("raw_boar_meat", 2)
        player.inventory.add("truffle", 1)

        craft(player.inventory, get_recipe("hunter_provisions"))

        self.assertEqual(player.inventory.count("hunter_provisions"), 1)
        self.assertEqual(player.inventory.count("raw_boar_meat"), 0)
        self.assertEqual(player.inventory.count("truffle"), 0)

    def test_executioner_axe_requires_three_boss_hearts(self) -> None:
        player = create_player("Tester")
        player.inventory.add("blackwood_heart", 3)
        player.inventory.add("hard_wood", 4)
        player.inventory.add("grinding_stone", 2)
        player.gold = 450

        craft_for_player(player, get_recipe("executioner_axe"))

        self.assertEqual(player.inventory.count("executioner_axe"), 1)
        self.assertEqual(player.inventory.count("blackwood_heart"), 0)

    def test_drowned_mother_blade_requires_three_hearts(self) -> None:
        player = create_player("Tester")
        player.inventory.add("silentwater_heart", 3)
        player.inventory.add("ancient_scale", 3)
        player.inventory.add("bone_fang", 2)
        player.gold = 750

        craft_for_player(player, get_recipe("drowned_mother_blade"))

        self.assertEqual(
            player.inventory.count("drowned_mother_blade"),
            1,
        )
        self.assertEqual(player.inventory.count("silentwater_heart"), 0)

    def test_recipe_list_is_grouped_in_region_order(self) -> None:
        recipes = get_all_recipes()
        regions = [recipe.region for recipe in recipes]

        first_forest = regions.index("Czarny Bór")
        first_marsh = regions.index("Mokradła Głuchej Wody")
        first_crypt = regions.index("Krypta Zatopionego Zakonu")
        first_borderlands = regions.index("Popielne Pogranicze")
        first_ice_coast = regions.index("Lodowe Wybrzeże")
        first_black_fleet = regions.index("Wrak Czarnej Floty")

        self.assertTrue(all(region == "Zmierzchowe Równiny" for region in regions[:first_forest]))
        self.assertTrue(all(region == "Czarny Bór" for region in regions[first_forest:first_marsh]))
        self.assertTrue(all(region == "Mokradła Głuchej Wody" for region in regions[first_marsh:first_crypt]))
        self.assertTrue(all(region == "Krypta Zatopionego Zakonu" for region in regions[first_crypt:first_borderlands]))
        self.assertTrue(all(region == "Popielne Pogranicze" for region in regions[first_borderlands:first_ice_coast]))
        self.assertTrue(all(region == "Lodowe Wybrzeże" for region in regions[first_ice_coast:first_black_fleet]))
        self.assertTrue(all(region == "Wrak Czarnej Floty" for region in regions[first_black_fleet:]))


if __name__ == "__main__":
    unittest.main()
