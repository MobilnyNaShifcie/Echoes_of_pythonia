import unittest

from game.config import PREVIOUS_SAVE_SCHEMA_VERSION, SAVE_SCHEMA_VERSION
from systems.save_system import _normalize_payload


class SaveV0217Tests(unittest.TestCase):
    def test_old_equipped_captain_signet_moves_from_ring_to_bracelet(self) -> None:
        item = {"item_id": "captain_signet", "upgrade_level": 7, "instance_id": "captain-1", "item_power": 6, "affixes": [], "average_damage_percent": None}
        payload = {
            "schema_version": PREVIOUS_SAVE_SCHEMA_VERSION,
            "player": {
                "name": "Tester",
                "level": 17,
                "experience": 0,
                "gold": 0,
                "rubies": 0,
                "unspent_attribute_points": 0,
                "attributes": {"strength": 0, "vitality": 0, "intelligence": 0, "dexterity": 0, "endurance": 0},
                "inventory": {"stacks": {}, "equipment_items": []},
                "equipment": {"ring": item},
            },
            "world": {"current_location_id": "ice_coast", "day": 1, "hour": 8},
        }
        normalized = _normalize_payload(payload)
        equipment = normalized["player"]["equipment"]
        self.assertNotIn("ring", equipment)
        self.assertEqual(equipment["bracelet"]["item_id"], "captain_signet")
        self.assertEqual(normalized["schema_version"], SAVE_SCHEMA_VERSION)

    def test_old_captain_signet_goes_to_inventory_when_bracelet_is_occupied(self) -> None:
        captain = {"item_id": "captain_signet", "upgrade_level": 3, "instance_id": "captain-2", "item_power": 6, "affixes": [], "average_damage_percent": None}
        bracelet = {"item_id": "black_antler_charm", "upgrade_level": 0, "instance_id": "bracelet-1", "item_power": 2, "affixes": [], "average_damage_percent": None}
        payload = {
            "schema_version": PREVIOUS_SAVE_SCHEMA_VERSION,
            "player": {
                "name": "Tester", "level": 17, "experience": 0, "gold": 0, "rubies": 0, "unspent_attribute_points": 0,
                "attributes": {"strength": 0, "vitality": 0, "intelligence": 0, "dexterity": 0, "endurance": 0},
                "inventory": {"stacks": {}, "equipment_items": []},
                "equipment": {"ring": captain, "bracelet": bracelet},
            },
            "world": {"current_location_id": "ice_coast", "day": 1, "hour": 8},
        }
        normalized = _normalize_payload(payload)
        equipment = normalized["player"]["equipment"]
        inventory = normalized["player"]["inventory"]["equipment_items"]
        self.assertEqual(equipment["bracelet"]["item_id"], "black_antler_charm")
        self.assertNotIn("ring", equipment)
        self.assertEqual(inventory[-1]["item_id"], "captain_signet")


if __name__ == "__main__":
    unittest.main()
