import io
import unittest

from data.items import ITEM_DATA
from data.loot_tables import LOOT_TABLES
from data.upgrades import UPGRADE_MATERIAL_PROFILE_BY_ITEM_POWER
from contextlib import redirect_stdout

from items.factory import create_equipment_item
from player.factory import create_player
from systems.blacksmith import UpgradeTarget, get_upgrade_cost, get_upgrade_plan
from ui.blacksmith_view import show_blacksmith_menu, show_upgrade_preview


class UpgradeSystemV0212Tests(unittest.TestCase):
    def test_ip_five_plus_four_requires_region_material(self) -> None:
        item = create_equipment_item("wasteland_armor")
        item.upgrade_level = 3

        cost = get_upgrade_cost(3, item)

        self.assertEqual(cost.gold, 175)
        self.assertEqual(
            cost.materials,
            {"grinding_stone": 1, "salamander_scale": 1},
        )

    def test_ip_six_plus_ten_requires_leviathan_trophy(self) -> None:
        item = create_equipment_item("north_armor")
        item.upgrade_level = 9

        cost = get_upgrade_cost(9, item)

        self.assertEqual(cost.gold, 2800)
        self.assertEqual(cost.materials["leviathan_scale"], 1)
        self.assertEqual(cost.materials["cursed_compass"], 1)

    def test_ip_seven_full_upgrade_is_not_shop_only(self) -> None:
        item = create_equipment_item("varek_sabre")
        plan = get_upgrade_plan(0, 10, item)

        self.assertEqual(plan.gold, 9450)
        self.assertEqual(plan.materials["varek_sabre_fragment"], 1)
        self.assertEqual(plan.materials["cursed_compass"], 4)
        self.assertEqual(plan.materials["black_pearl"], 12)

    def test_blacksmith_menu_shows_materials_and_stat_growth(self) -> None:
        player = create_player("Tester")
        item = create_equipment_item("wasteland_armor")
        item.upgrade_level = 3
        player.inventory.equipment_items.append(item)
        player.gold = 99999
        player.inventory.add("grinding_stone", 10)
        player.inventory.add("salamander_scale", 10)

        target = UpgradeTarget(item=item, source="Plecak")
        output = io.StringIO()
        with redirect_stdout(output):
            show_blacksmith_menu(player, [target])

        text = output.getvalue()
        self.assertIn("Gold: 99999/175 [OK]", text)
        self.assertIn("Kamień Szlifierski: 10/1 [OK]", text)
        self.assertIn("Łuska Salamandry: 10/1 [OK]", text)
        self.assertIn("Wzrost:", text)
        self.assertIn("+0..+3 wymagają podstawowych materiałów", text)

    def test_multi_upgrade_preview_shows_resulting_stats(self) -> None:
        item = create_equipment_item("grandmaster_sword")
        target = UpgradeTarget(item=item, source="Plecak")
        plan = get_upgrade_plan(0, 10, item)

        output = io.StringIO()
        with redirect_stdout(output):
            show_upgrade_preview(target, plan)

        text = output.getvalue()
        self.assertIn("+0 -> +10", text)
        self.assertIn("Po ulepszeniu: ATK 25", text)
        self.assertIn("Fragment Zatopionej Korony x1", text)

    def test_every_upgrade_profile_material_exists_and_has_drop_source(self) -> None:
        dropped = {
            str(entry["item_id"])
            for table in LOOT_TABLES.values()
            for entry in table
        }
        for profile in UPGRADE_MATERIAL_PROFILE_BY_ITEM_POWER.values():
            for item_id in profile.values():
                self.assertIn(item_id, ITEM_DATA)
                self.assertIn(item_id, dropped)

    def test_all_current_equipment_item_powers_have_upgrade_profile(self) -> None:
        from items.catalog import get_item_definition
        from items.models import ItemCategory

        item_powers = {
            get_item_definition(item_id).item_power
            for item_id, raw in ITEM_DATA.items()
            if raw["category"] == ItemCategory.EQUIPMENT.value
        }
        self.assertTrue(item_powers)
        self.assertTrue(
            item_powers.issubset(UPGRADE_MATERIAL_PROFILE_BY_ITEM_POWER)
        )


if __name__ == "__main__":
    unittest.main()
