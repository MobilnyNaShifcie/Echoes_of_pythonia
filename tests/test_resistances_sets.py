import unittest

from combat.elements import DamageType, ElementalResistances, apply_elemental_resistance
from player.factory import create_player


class ResistanceAndSetTests(unittest.TestCase):
    def test_water_resistance_reduces_elemental_damage(self) -> None:
        resistances = ElementalResistances(water=20)
        self.assertEqual(
            apply_elemental_resistance(10, DamageType.WATER, resistances),
            8,
        )

    def test_resistance_is_capped_at_seventy_five_percent(self) -> None:
        resistances = ElementalResistances(water=999).clamped()
        self.assertEqual(resistances.water, 75)

    def test_equipment_can_grant_resistance(self) -> None:
        player = create_player("Tester")
        player.level = 99
        player.inventory.add("drowned_mother_crown")
        player.equip_from_inventory(0)
        self.assertEqual(player.stats.resistances.water, 15)

    def test_full_nature_set_activates_bonus(self) -> None:
        player = create_player("Tester")
        player.level = 99
        for item_id in (
            "nature_amulet",
            "nature_ring",
            "nature_bracelet",
            "nature_earrings",
        ):
            player.inventory.add(item_id)
            player.equip_from_inventory(len(player.inventory.equipment_items) - 1)

        bonuses = player.equipment.total_bonuses()
        self.assertIn("Zestaw Natury", bonuses.active_set_names)
        self.assertEqual(player.stats.resistances.earth, 15)
        self.assertEqual(player.stats.attack, 10)

    def test_incomplete_nature_set_has_no_set_bonus(self) -> None:
        player = create_player("Tester")
        player.level = 99
        for item_id in ("nature_amulet", "nature_ring", "nature_bracelet"):
            player.inventory.add(item_id)
            player.equip_from_inventory(len(player.inventory.equipment_items) - 1)
        self.assertNotIn("Zestaw Natury", player.equipment.total_bonuses().active_set_names)
