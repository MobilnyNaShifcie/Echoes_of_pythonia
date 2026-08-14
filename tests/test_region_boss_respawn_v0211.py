import io
import json
from pathlib import Path
import tempfile
import unittest
from contextlib import redirect_stdout
from unittest.mock import patch

from combat.combat import CombatResult
from game.application import Game
from game.config import REGION_BOSS_RESPAWN_EXPEDITIONS, SAVE_SCHEMA_VERSION
from game.state import GameState
from player.factory import create_player
from systems.region_boss_respawn import (
    boss_is_available,
    record_region_expedition,
    respawn_remaining,
    start_boss_respawn,
)
from systems.save_system import load_game, save_game
from ui.world_view import show_location_menu
from world.factory import create_location
from world.time_system import GameClock


class RegionBossRespawnSystemV0211Tests(unittest.TestCase):
    def test_victory_starts_six_expedition_respawn(self) -> None:
        respawns: dict[str, int] = {}
        start_boss_respawn(respawns, "azhar")
        self.assertEqual(
            respawn_remaining(respawns, "azhar"),
            REGION_BOSS_RESPAWN_EXPEDITIONS,
        )
        self.assertFalse(boss_is_available(respawns, "azhar"))

    def test_only_expeditions_in_boss_region_reduce_respawn(self) -> None:
        respawns = {"azhar": 6}
        record_region_expedition(respawns, "ice_coast")
        self.assertEqual(respawns["azhar"], 6)
        record_region_expedition(respawns, "ashen_borderlands")
        self.assertEqual(respawns["azhar"], 5)

    def test_boss_returns_after_exactly_six_expeditions(self) -> None:
        respawns = {"leviathan_north": 6}
        for expected in (5, 4, 3, 2, 1):
            remaining = record_region_expedition(respawns, "ice_coast")
            self.assertEqual(remaining, expected)
            self.assertFalse(boss_is_available(respawns, "leviathan_north"))

        remaining = record_region_expedition(respawns, "ice_coast")
        self.assertEqual(remaining, 0)
        self.assertTrue(boss_is_available(respawns, "leviathan_north"))
        self.assertNotIn("leviathan_north", respawns)

    def test_location_ui_shows_respawn_counter(self) -> None:
        player = create_player("Tester")
        player.level = 17
        output = io.StringIO()
        with redirect_stdout(output):
            show_location_menu(
                player,
                create_location("ashen_borderlands"),
                GameClock(),
                {"azhar": 3},
            )
        self.assertIn(
            "Azhar, Władca Pustkowi [Odrodzenie: 3 wyprawy]",
            output.getvalue(),
        )


class RegionBossRespawnApplicationV0211Tests(unittest.TestCase):
    def setUp(self) -> None:
        self.game = Game()
        self.game.state.player = create_player("Tester")
        self.game.state.active_game = True

    def test_azhar_victory_starts_respawn(self) -> None:
        location = create_location("ashen_borderlands")
        with (
            patch("builtins.input", return_value="1"),
            patch.object(self.game, "_ensure_repeatable_contracts"),
            patch.object(
                self.game,
                "play_combat",
                return_value=CombatResult.VICTORY,
            ),
            patch.object(self.game, "_advance_world_time"),
            patch("game.application.clear_screen"),
            patch("game.application.show_region_boss_challenge"),
        ):
            self.game.run_azhar_challenge(location)

        self.assertEqual(
            self.game.state.region_boss_respawns["azhar"],
            REGION_BOSS_RESPAWN_EXPEDITIONS,
        )

    def test_defeat_does_not_start_respawn(self) -> None:
        location = create_location("ashen_borderlands")
        with (
            patch("builtins.input", return_value="1"),
            patch.object(self.game, "_ensure_repeatable_contracts"),
            patch.object(
                self.game,
                "play_combat",
                return_value=CombatResult.DEFEAT,
            ),
            patch.object(self.game, "_advance_world_time"),
            patch("game.application.clear_screen"),
            patch("game.application.show_region_boss_challenge"),
        ):
            self.game.run_azhar_challenge(location)

        self.assertNotIn("azhar", self.game.state.region_boss_respawns)

    def test_active_respawn_blocks_immediate_rematch(self) -> None:
        location = create_location("ashen_borderlands")
        self.game.state.region_boss_respawns["azhar"] = 4
        with (
            patch.object(self.game, "play_combat") as play_combat,
            patch("game.application.clear_screen"),
            patch("game.application.show_region_boss_respawn") as show_respawn,
            patch("game.application.pause"),
        ):
            self.game.run_azhar_challenge(location)

        play_combat.assert_not_called()
        show_respawn.assert_called_once_with(
            "Azhar, Władca Pustkowi",
            "Popielne Pogranicze",
            4,
        )


class RegionBossRespawnSaveV0211Tests(unittest.TestCase):
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

    def test_respawn_counters_survive_save_and_load(self) -> None:
        state = GameState(active_game=True, player=create_player("Tester"))
        state.region_boss_respawns = {
            "azhar": 3,
            "leviathan_north": 6,
        }
        save_game(state)
        loaded = load_game()
        self.assertEqual(
            loaded.region_boss_respawns,
            state.region_boss_respawns,
        )

    def test_schema_nine_migrates_with_bosses_available(self) -> None:
        state = GameState(active_game=True, player=create_player("Tester"))
        path = save_game(state)
        payload = json.loads(path.read_text(encoding="utf-8"))
        payload["schema_version"] = 9
        payload.pop("region_boss_respawns", None)
        path.write_text(json.dumps(payload), encoding="utf-8")

        loaded = load_game()

        self.assertEqual(SAVE_SCHEMA_VERSION, 15)
        self.assertEqual(loaded.region_boss_respawns, {})


if __name__ == "__main__":
    unittest.main()
