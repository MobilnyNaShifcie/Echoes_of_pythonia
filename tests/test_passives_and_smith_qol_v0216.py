import io
import unittest
from contextlib import redirect_stdout

from items.factory import create_equipment_item
from player.factory import create_player
from player.passives import PassiveType, passive_effect_description
from systems.blacksmith import UpgradeTarget
from ui.blacksmith_view import show_blacksmith_menu


class PassivesAndSmithQolV0216Tests(unittest.TestCase):
    def test_passive_descriptions_show_rebalanced_values(self) -> None:
        self.assertEqual(
            passive_effect_description(PassiveType.ATTACK_SPEED, 5),
            "25% szansy na dodatkowe uderzenie",
        )
        self.assertEqual(
            passive_effect_description(PassiveType.HEALTH_REGEN, 5),
            "+15 HP regeneracji po turze przeciwnika",
        )
        self.assertEqual(
            passive_effect_description(PassiveType.INCREASED_ATTACK, 5),
            "+10 ATK",
        )
        self.assertIn(
            "9% szansy na krytyk, mnożnik x2.75",
            passive_effect_description(PassiveType.CRITICAL_DAMAGE, 5),
        )

    def test_blacksmith_shows_owned_required_and_missing_status(self) -> None:
        player = create_player("Tester")
        item = create_equipment_item("azhar_ring")
        item.upgrade_level = 8
        player.inventory.equipment_items.append(item)
        player.gold = 1000
        player.inventory.add("grinding_stone", 3)
        player.inventory.add("salamander_scale", 1)
        player.inventory.add("hearth_core", 1)

        target = UpgradeTarget(item=item, source="Plecak")
        output = io.StringIO()
        with redirect_stdout(output):
            show_blacksmith_menu(player, [target])

        text = output.getvalue()
        self.assertIn("Gold: 1000/1625 [BRAK]", text)
        self.assertIn("Kamień Szlifierski: 3/3 [OK]", text)
        self.assertIn("Łuska Salamandry: 1/2 [BRAK]", text)
        self.assertIn("Rdzeń Paleniska: 1/2 [BRAK]", text)


if __name__ == "__main__":
    unittest.main()
