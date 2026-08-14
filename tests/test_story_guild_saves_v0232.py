import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from data.guild import GUILD_RANK_BY_CODE
from game.config import SAVE_SLOT_COUNT
from game.state import GameState
from player.factory import create_player
from quests.catalog import get_quest
from quests.models import QuestLog
from systems.guild_progression import GuildProgress, record_story_quest_reputation
from systems.quest_system import accept_quest, get_available_quests, turn_in_quest
from systems.save_system import (
    any_save_exists,
    get_save_summary,
    load_game,
    save_game,
    save_slot_name,
)


class StoryGuildV0232Tests(unittest.TestCase):
    def test_rank_c_is_zdobywca(self):
        self.assertEqual(GUILD_RANK_BY_CODE["C"].name, "Zdobywca")
        self.assertEqual(GUILD_RANK_BY_CODE["C"].reputation_required, 700)

    def test_act_one_has_nine_story_quests_and_700_reputation(self):
        ids = [
            "awakening_missing_recruits",
            "awakening_black_wax",
            "awakening_voice_beneath_roots",
            "awakening_beneath_still_water",
            "awakening_nameless_seal",
            "awakening_breathing_crypt",
            "awakening_ash_remembers",
            "awakening_bells_beneath_ice",
            "awakening_last_order",
        ]
        quests = [get_quest(quest_id) for quest_id in ids]
        self.assertEqual(len(quests), 9)
        self.assertEqual(sum(q.guild_reputation for q in quests), 700)
        self.assertTrue(all(q.story_arc == "Akt I — Ślady Przebudzenia" for q in quests))

    def test_story_chain_respects_level_and_previous_chapter(self):
        log = QuestLog()
        level_zero = {q.quest_id for q in get_available_quests(log, 0)}
        self.assertIn("awakening_missing_recruits", level_zero)
        self.assertNotIn("awakening_black_wax", level_zero)

        log.completed.add("awakening_missing_recruits")
        level_one = {q.quest_id for q in get_available_quests(log, 1)}
        self.assertNotIn("awakening_black_wax", level_one)
        level_two = {q.quest_id for q in get_available_quests(log, 2)}
        self.assertIn("awakening_black_wax", level_two)

    def test_story_trophy_is_examined_not_consumed(self):
        player = create_player("Tester")
        player.inventory.add("crown_fragment", 1)
        log = QuestLog(completed={
            "awakening_missing_recruits",
            "awakening_black_wax",
            "awakening_voice_beneath_roots",
            "awakening_beneath_still_water",
            "awakening_nameless_seal",
        })
        accept_quest(log, "awakening_breathing_crypt")
        result = turn_in_quest(player, log, "awakening_breathing_crypt")
        self.assertEqual(player.inventory.count("crown_fragment"), 1)
        self.assertIn("Zakon", result.completion_text)

    def test_story_reputation_uses_per_quest_value_once(self):
        progress = GuildProgress()
        quest = get_quest("awakening_last_order")
        update = record_story_quest_reputation(progress, quest.quest_id, quest.guild_reputation)
        self.assertEqual(update.amount, 130)
        self.assertIsNone(record_story_quest_reputation(progress, quest.quest_id, 130))


class FourSaveSlotsV0232Tests(unittest.TestCase):
    def test_four_slots_are_configured(self):
        self.assertEqual(SAVE_SLOT_COUNT, 4)
        self.assertEqual([save_slot_name(i) for i in range(1, 5)], [
            "save_1.json", "save_2.json", "save_3.json", "save_4.json"
        ])

    def test_slots_store_independent_characters(self):
        with tempfile.TemporaryDirectory() as temp:
            save_dir = Path(temp)
            with patch("systems.save_system.get_save_directory", return_value=save_dir):
                first = GameState(active_game=True, player=create_player("WojownikTest"))
                second = GameState(active_game=True, player=create_player("MagTest"))
                save_game(first, save_slot_name(1))
                save_game(second, save_slot_name(3))

                self.assertTrue(any_save_exists())
                self.assertEqual(load_game(save_slot_name(1)).player.name, "WojownikTest")
                self.assertEqual(load_game(save_slot_name(3)).player.name, "MagTest")
                self.assertIsNone(get_save_summary(save_slot_name(2)))
                self.assertEqual(get_save_summary(save_slot_name(3)).player_name, "MagTest")


if __name__ == "__main__":
    unittest.main()
