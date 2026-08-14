import json
from pathlib import Path
import random
import tempfile
import unittest
from unittest.mock import patch

from game.state import GameState
from items.affixes import EquipmentQuality, generate_equipment_item
from player.factory import create_player
from systems.save_system import load_game, save_game


class SaveV018Tests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.patch = patch(
            "systems.save_system.get_save_directory",
            return_value=Path(self.temp.name),
        )
        self.patch.start()

    def tearDown(self) -> None:
        self.patch.stop()
        self.temp.cleanup()

    def test_average_damage_survives_save_and_load(self) -> None:
        player = create_player("Tester")
        item = generate_equipment_item(
            "grandmaster_sword",
            random.Random(18),
            quality=EquipmentQuality.BOSS,
        )
        player.inventory.add_equipment_instance(item)
        state = GameState(active_game=True, player=player)

        save_game(state)
        loaded = load_game()
        loaded_item = loaded.player.inventory.equipment_items[0]

        self.assertEqual(
            loaded_item.average_damage_percent,
            item.average_damage_percent,
        )
        self.assertEqual(loaded_item.affixes, item.affixes)

    def test_schema_eight_backfills_average_damage_without_rerolling_affixes(self) -> None:
        player = create_player("Tester")
        item = generate_equipment_item(
            "grandmaster_sword",
            random.Random(777),
            quality=EquipmentQuality.BOSS,
        )
        player.inventory.add_equipment_instance(item)
        state = GameState(active_game=True, player=player)
        path = save_game(state)

        payload = json.loads(path.read_text(encoding="utf-8"))
        payload["schema_version"] = 8
        raw_item = payload["player"]["inventory"]["equipment_items"][0]
        old_affixes = list(raw_item["affixes"])
        raw_item.pop("average_damage_percent", None)
        path.write_text(json.dumps(payload), encoding="utf-8")

        first = load_game().player.inventory.equipment_items[0]
        second = load_game().player.inventory.equipment_items[0]

        self.assertIsNotNone(first.average_damage_percent)
        self.assertEqual(
            first.average_damage_percent,
            second.average_damage_percent,
        )
        self.assertEqual(
            [
                {"affix_id": a.affix_id, "tier": a.tier, "value": a.value}
                for a in first.affixes
            ],
            old_affixes,
        )


if __name__ == "__main__":
    unittest.main()
