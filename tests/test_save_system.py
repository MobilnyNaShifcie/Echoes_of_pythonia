import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from game.config import SAVE_SCHEMA_VERSION
from game.state import GameState
from items.models import EquipmentSlot
from player.factory import create_player
from systems.quest_system import accept_quest, record_enemy_kill, turn_in_quest
from systems.save_system import (
    SaveGameError,
    get_save_summary,
    load_game,
    migrate_legacy_save_if_needed,
    save_game,
)
from world.time_system import GameClock


class SaveSystemTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temp = tempfile.TemporaryDirectory()
        self.base = Path(self.temp.name)
        self.user_dir = self.base / "user_data"
        self.project = self.base / "echoes_of_pythonia_v0.11.0"
        self.project.mkdir()
        self.patch_user = patch(
            "systems.save_system.get_user_data_directory",
            return_value=self.user_dir,
        )
        self.patch_root = patch(
            "systems.save_system.get_project_root",
            return_value=self.project,
        )
        self.patch_user.start()
        self.patch_root.start()

    def tearDown(self) -> None:
        self.patch_root.stop()
        self.patch_user.stop()
        self.temp.cleanup()

    def _state(self) -> GameState:
        player = create_player("Kamil")
        player.gold = 777
        player.inventory.add("wolf_fur", 5)
        player.inventory.add("executioner_axe")
        player.inventory.equipment_items[0].upgrade_level = 6
        weapon = player.equipment.get(EquipmentSlot.WEAPON)
        weapon.upgrade_level = 4
        player.recalculate_stats()
        player.stats.current_hp = 17
        state = GameState(
            running=True,
            active_game=True,
            player=player,
            current_location_id="black_forest",
            current_city_id="varenhold",
            world_clock=GameClock(day=4, hour=21),
        )
        accept_quest(state.quest_log, "cult_beneath_roots")
        record_enemy_kill(state.quest_log, "forest_cultist")
        return state

    def test_save_is_outside_project_folder(self) -> None:
        path = save_game(self._state())
        self.assertTrue(path.is_relative_to(self.user_dir))
        self.assertFalse(path.is_relative_to(self.project))

    def test_save_and_load_preserve_city_and_progress(self) -> None:
        save_game(self._state())
        loaded = load_game()
        self.assertEqual(loaded.player.name, "Kamil")
        self.assertEqual(loaded.player.gold, 777)
        self.assertEqual(loaded.current_city_id, "varenhold")
        self.assertEqual(loaded.current_location_id, "black_forest")
        self.assertEqual(loaded.world_clock.day, 4)
        self.assertEqual(loaded.world_clock.hour, 21)
        self.assertEqual(loaded.player.stats.current_hp, 17)
        self.assertEqual(loaded.player.inventory.equipment_items[0].upgrade_level, 6)
        self.assertEqual(loaded.player.equipment.get(EquipmentSlot.WEAPON).upgrade_level, 4)

    def test_summary_contains_city(self) -> None:
        save_game(self._state())
        summary = get_save_summary()
        self.assertEqual(summary.city_name, "Varenhold")
        self.assertEqual(summary.location_name, "Czarny Bór")

    def test_schema_one_save_is_migrated_to_city_schema(self) -> None:
        path = save_game(self._state())
        payload = json.loads(path.read_text(encoding="utf-8"))
        payload["schema_version"] = 1
        payload["world"].pop("current_city_id")
        path.write_text(json.dumps(payload), encoding="utf-8")
        loaded = load_game()
        self.assertEqual(loaded.current_city_id, "varenhold")

    def test_legacy_project_save_is_imported_to_user_data(self) -> None:
        # Utwórz save, następnie przesuń go do starego folderu projektu.
        current = save_game(self._state())
        legacy_dir = self.project / "saves"
        legacy_dir.mkdir()
        legacy = legacy_dir / "save_1.json"
        legacy.write_bytes(current.read_bytes())
        current.unlink()

        source = migrate_legacy_save_if_needed()
        self.assertEqual(source, legacy)
        self.assertTrue((self.user_dir / "saves" / "save_1.json").is_file())
        self.assertEqual(load_game().player.gold, 777)

    def test_sibling_v010_save_can_be_auto_imported(self) -> None:
        current = save_game(self._state())
        sibling = self.base / "echoes_of_pythonia_v0.10.0" / "saves"
        sibling.mkdir(parents=True)
        legacy = sibling / "save_1.json"
        legacy.write_bytes(current.read_bytes())
        current.unlink()

        source = migrate_legacy_save_if_needed()
        self.assertEqual(source, legacy)
        self.assertEqual(load_game().player.name, "Kamil")


    def test_save_and_load_preserve_quest_progress(self) -> None:
        save_game(self._state())
        loaded = load_game()
        self.assertEqual(loaded.quest_log.active["cult_beneath_roots"], 1)

    def test_completed_quest_stays_completed_after_save_and_load(self) -> None:
        state = self._state()
        for _ in range(2):
            record_enemy_kill(state.quest_log, "forest_cultist")

        turn_in_quest(
            state.player,
            state.quest_log,
            "cult_beneath_roots",
        )
        save_game(state)
        loaded = load_game()

        self.assertNotIn("cult_beneath_roots", loaded.quest_log.active)
        self.assertIn("cult_beneath_roots", loaded.quest_log.completed)

    def test_loader_repairs_completed_quest_left_in_active(self) -> None:
        path = save_game(self._state())
        payload = json.loads(path.read_text(encoding="utf-8"))
        payload["quests"]["active"]["cult_beneath_roots"] = 3
        payload["quests"]["completed"] = ["cult_beneath_roots"]
        path.write_text(json.dumps(payload), encoding="utf-8")

        loaded = load_game()

        self.assertNotIn("cult_beneath_roots", loaded.quest_log.active)
        self.assertIn("cult_beneath_roots", loaded.quest_log.completed)

    def test_schema_two_save_gets_empty_quest_log(self) -> None:
        path = save_game(self._state())
        payload = json.loads(path.read_text(encoding="utf-8"))
        payload["schema_version"] = 2
        payload.pop("quests", None)
        path.write_text(json.dumps(payload), encoding="utf-8")
        loaded = load_game()
        self.assertEqual(loaded.quest_log.active, {})
        self.assertEqual(loaded.quest_log.completed, set())

    def test_corrupted_json_is_rejected(self) -> None:
        path = self.user_dir / "saves" / "save_1.json"
        path.parent.mkdir(parents=True)
        path.write_text("{broken", encoding="utf-8")
        with self.assertRaises(SaveGameError):
            load_game()

    def test_unknown_schema_is_rejected(self) -> None:
        path = save_game(self._state())
        payload = json.loads(path.read_text(encoding="utf-8"))
        payload["schema_version"] = SAVE_SCHEMA_VERSION + 100
        path.write_text(json.dumps(payload), encoding="utf-8")
        with self.assertRaises(SaveGameError):
            load_game()
