import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from game.state import GameState
from items.affixes import affix_count_for_rarity
from items.catalog import get_item_definition
from player.factory import create_player
from systems.save_system import load_game, save_game


class SaveV017Tests(unittest.TestCase):
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

    def test_affixes_and_item_power_survive_save(self) -> None:
        player = create_player("Tester")
        player.inventory.add_generated_equipment(
            "executioner_axe",
            __import__("random").Random(7),
        )
        original = player.inventory.equipment_items[0]
        state = GameState(active_game=True, player=player)

        save_game(state)
        loaded = load_game()
        restored = loaded.player.inventory.equipment_items[0]

        self.assertEqual(restored.item_power, original.item_power)
        self.assertEqual(restored.affixes, original.affixes)
        self.assertEqual(restored.instance_id, original.instance_id)

    def test_schema_seven_backfills_existing_equipment_once(self) -> None:
        player = create_player("Tester")
        player.inventory.add("executioner_axe")
        state = GameState(active_game=True, player=player)
        path = save_game(state)

        payload = json.loads(path.read_text(encoding="utf-8"))
        payload["schema_version"] = 7

        def strip_v017_fields(raw_item: dict) -> None:
            raw_item.pop("item_power", None)
            raw_item.pop("affixes", None)

        for raw_item in payload["player"]["inventory"]["equipment_items"]:
            strip_v017_fields(raw_item)
        for raw_item in payload["player"]["equipment"].values():
            strip_v017_fields(raw_item)

        path.write_text(json.dumps(payload), encoding="utf-8")

        first = load_game()
        second = load_game()
        first_item = first.player.inventory.equipment_items[0]
        second_item = second.player.inventory.equipment_items[0]
        definition = get_item_definition(first_item.item_id)

        self.assertEqual(first_item.affixes, second_item.affixes)
        self.assertEqual(first_item.item_power, definition.item_power)
        self.assertEqual(
            len(first_item.affixes),
            affix_count_for_rarity(definition.rarity),
        )

    def test_save_normalizes_plain_legacy_instance(self) -> None:
        player = create_player("Tester")
        player.inventory.add("drowned_mother_blade")
        item = player.inventory.equipment_items[0]
        self.assertEqual(item.affixes, [])

        state = GameState(active_game=True, player=player)
        save_game(state)

        self.assertEqual(len(item.affixes), 3)
        loaded = load_game()
        self.assertEqual(
            loaded.player.inventory.equipment_items[0].affixes,
            item.affixes,
        )


if __name__ == "__main__":
    unittest.main()
