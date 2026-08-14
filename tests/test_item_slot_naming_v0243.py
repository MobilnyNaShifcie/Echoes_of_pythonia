import unittest

from data.items import ITEM_DATA
from data.recipes import RECIPE_DATA


class ItemSlotNamingV0243Tests(unittest.TestCase):
    def test_captain_item_is_a_bracelet_in_name_and_slot(self):
        item = ITEM_DATA["captain_signet"]
        self.assertEqual(item["name"], "Bransoleta Czarnej Floty")
        self.assertEqual(item["slot"], "bracelet")
        self.assertEqual(RECIPE_DATA["captain_signet"]["name"], item["name"])

    def test_storm_archive_item_reads_as_neck_wear(self):
        item = ITEM_DATA["storm_archive_relic"]
        self.assertEqual(item["name"], "Medalion Burzowego Archiwum")
        self.assertEqual(item["slot"], "necklace")

    def test_obvious_equipment_names_match_their_slots(self):
        expected_prefix_slots = {
            "Rękawice": "hands",
            "Karwasz": "hands",
            "Karwasze": "hands",
            "Bransoleta": "bracelet",
            "Kolczyki": "earrings",
            "Pierścień": "ring",
            "Buty": "feet",
            "Hełm": "head",
            "Pas ": "belt",
            "Tarcza": "off_hand",
            "Kołczan": "off_hand",
            "Miecz": "weapon",
            "Topór": "weapon",
            "Ostrze": "weapon",
            "Szabla": "weapon",
            "Łuk": "weapon",
            "Kostur": "weapon",
            "Lanca": "weapon",
        }
        failures = []
        for item_id, item in ITEM_DATA.items():
            if item.get("category") != "equipment":
                continue
            name = str(item.get("name", ""))
            slot = item.get("slot")
            for prefix, expected_slot in expected_prefix_slots.items():
                if name.startswith(prefix) and slot != expected_slot:
                    failures.append(f"{item_id}: {name!r} -> {slot!r}, expected {expected_slot!r}")
        self.assertEqual(failures, [], "\n".join(failures))


if __name__ == "__main__":
    unittest.main()
