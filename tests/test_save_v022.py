import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from game.config import SAVE_SCHEMA_VERSION
from game.state import GameState
from player.factory import create_player
from player.passives import PassiveType
from systems.black_market import BlackMarketOffer, BlackMarketState
from systems.guild_progression import GuildProgress
from systems.save_system import load_game, save_game


class SaveV022Tests(unittest.TestCase):
    def test_schema_is_twelve(self):
        self.assertEqual(SAVE_SCHEMA_VERSION, 15)

    def test_new_guild_market_and_mastery_state_round_trip(self):
        player = create_player("Tester")
        player.level = 20
        player.passive_masteries.add(PassiveType.HEALTH_REGEN.code)
        player.passives.health_regen = 7
        state = GameState(
            active_game=True,
            player=player,
            guild_progress=GuildProgress(850, {"dungeon:black_fleet_wreck", "quest:a"}),
            black_market=BlackMarketState(
                unlocked=True,
                rotation_key="123",
                offers=[BlackMarketOffer("123:0", "mastery_strength_book", 1, 40000)],
                purchased_offer_ids={"123:x"},
                buy_negotiated_prices={"123:0": 36000},
                sale_negotiated_prices={"mastery_strength_book": 18500},
            ),
        )
        with tempfile.TemporaryDirectory() as temp:
            save_dir = Path(temp)
            with patch("systems.save_system.get_save_directory", return_value=save_dir), patch(
                "systems.save_system.get_save_path", return_value=save_dir / "save.json"
            ):
                save_game(state)
                loaded = load_game()
        self.assertEqual(loaded.guild_progress.reputation, 850)
        self.assertTrue(loaded.black_market.unlocked)
        self.assertEqual(loaded.black_market.offers[0].item_id, "mastery_strength_book")
        self.assertIn("health_regen", loaded.player.passive_masteries)
        self.assertEqual(loaded.player.passives.health_regen, 7)

    def test_schema_eleven_migration_removes_old_easy_guild_veteran_and_rebuilds_reputation(self):
        player = create_player("Tester")
        state = GameState(active_game=True, player=player)
        with tempfile.TemporaryDirectory() as temp:
            save_dir = Path(temp)
            path = save_dir / "save.json"
            with patch("systems.save_system.get_save_directory", return_value=save_dir), patch(
                "systems.save_system.get_save_path", return_value=path
            ):
                save_game(state)
                payload = json.loads(path.read_text(encoding="utf-8"))
                payload["schema_version"] = 11
                payload.pop("guild", None)
                payload.pop("black_market", None)
                payload["player"].pop("passive_masteries", None)
                payload["player"]["achievements"] = {
                    "unlocked": ["guild_veteran"],
                    "equipped_title": "Weteran Gildii",
                }
                payload["quests"] = {
                    "active": {},
                    "completed": [
                        "black_venom", "cult_beneath_roots", "bones_of_silentwater",
                        "herbs_for_mirela", "knights_without_graves", "mother_below", "seal_of_drowned",
                    ],
                }
                payload["player"]["inventory"]["stacks"]["varek_sabre_fragment"] = 1
                path.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
                loaded = load_game()
        self.assertNotIn("guild_veteran", loaded.player.achievements.unlocked)
        self.assertEqual(loaded.player.achievements.equipped_title, "Wędrowiec")
        # 7 quests * 50 + Black Fleet 250 = 600; rank D, not instant Veteran/Legend.
        self.assertEqual(loaded.guild_progress.reputation, 600)
        self.assertIn("dungeon:black_fleet_wreck", loaded.guild_progress.milestones)


if __name__ == "__main__":
    unittest.main()
