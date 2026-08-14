import unittest

from player.factory import create_player
from quests.models import QuestLog
from systems.quest_system import (
    accept_quest,
    get_active_quests,
    get_available_quests,
    get_ready_quests,
    objective_progress,
    record_enemy_kill,
    turn_in_quest,
)
from quests.catalog import get_quest


class QuestTests(unittest.TestCase):
    def test_kill_progress_counts_only_after_acceptance(self) -> None:
        log = QuestLog()
        self.assertEqual(record_enemy_kill(log, "forest_cultist"), [])

        accept_quest(log, "cult_beneath_roots")
        updates = record_enemy_kill(log, "forest_cultist")
        self.assertEqual(len(updates), 1)
        self.assertEqual(updates[0].current, 1)
        self.assertFalse(updates[0].ready)

    def test_kill_quest_becomes_ready(self) -> None:
        player = create_player("Tester")
        log = QuestLog()
        accept_quest(log, "cult_beneath_roots")
        for _ in range(3):
            record_enemy_kill(log, "forest_cultist")
        ready = get_ready_quests(player, log)
        self.assertEqual([q.quest_id for q in ready], ["cult_beneath_roots"])

    def test_collect_quest_uses_current_inventory(self) -> None:
        player = create_player("Tester")
        log = QuestLog()
        accept_quest(log, "black_venom")
        quest = get_quest("black_venom")
        player.inventory.add("venom_gland", 2)
        self.assertEqual(objective_progress(player, log, quest), (2, 2))

    def test_turn_in_collect_consumes_items_and_rewards_player(self) -> None:
        player = create_player("Tester")
        log = QuestLog()
        accept_quest(log, "herbs_for_mirela")
        player.inventory.add("witch_herb", 3)
        before_gold = player.gold
        result = turn_in_quest(player, log, "herbs_for_mirela")
        self.assertEqual(player.inventory.count("witch_herb"), 0)
        self.assertEqual(player.inventory.count("strong_healing_potion"), 2)
        self.assertEqual(player.gold, before_gold + 240)
        self.assertIn("herbs_for_mirela", log.completed)
        self.assertNotIn("herbs_for_mirela", log.active)
        self.assertEqual(result.experience, 180)

    def test_completed_quest_cannot_be_accepted_again(self) -> None:
        player = create_player("Tester")
        log = QuestLog()
        accept_quest(log, "mother_below")
        record_enemy_kill(log, "drowned_mother")
        turn_in_quest(player, log, "mother_below")
        with self.assertRaises(ValueError):
            accept_quest(log, "mother_below")

    def test_all_six_quests_can_be_active_at_once(self) -> None:
        log = QuestLog()
        quest_ids = [
            "black_venom",
            "cult_beneath_roots",
            "bones_of_silentwater",
            "herbs_for_mirela",
            "knights_without_graves",
            "mother_below",
        ]

        for quest_id in quest_ids:
            accept_quest(log, quest_id)

        self.assertEqual(len(log.active), 6)
        self.assertEqual(set(log.active), set(quest_ids))

    def test_turn_in_removes_quest_from_active_queries(self) -> None:
        player = create_player("Tester")
        log = QuestLog()
        accept_quest(log, "cult_beneath_roots")

        for _ in range(3):
            record_enemy_kill(log, "forest_cultist")

        turn_in_quest(player, log, "cult_beneath_roots")

        active_ids = {q.quest_id for q in get_active_quests(log)}
        available_ids = {q.quest_id for q in get_available_quests(log)}

        self.assertNotIn("cult_beneath_roots", active_ids)
        self.assertNotIn("cult_beneath_roots", available_ids)
        self.assertIn("cult_beneath_roots", log.completed)

    def test_reward_cannot_be_claimed_twice(self) -> None:
        player = create_player("Tester")
        log = QuestLog()
        accept_quest(log, "mother_below")
        record_enemy_kill(log, "drowned_mother")

        turn_in_quest(player, log, "mother_below")
        gold_after_first_turn_in = player.gold
        exp_after_first_turn_in = player.experience

        with self.assertRaises(ValueError):
            turn_in_quest(player, log, "mother_below")

        self.assertEqual(player.gold, gold_after_first_turn_in)
        self.assertEqual(player.experience, exp_after_first_turn_in)

    def test_completed_state_wins_over_stale_active_entry(self) -> None:
        log = QuestLog(
            active={"cult_beneath_roots": 3},
            completed={"cult_beneath_roots"},
        )

        active_ids = {q.quest_id for q in get_active_quests(log)}

        self.assertNotIn("cult_beneath_roots", active_ids)
        self.assertNotIn("cult_beneath_roots", log.active)

    def test_completed_quest_never_returns_to_board_or_active_list(self) -> None:
        player = create_player("Tester")
        log = QuestLog()
        accept_quest(log, "mother_below")
        record_enemy_kill(log, "drowned_mother")
        turn_in_quest(player, log, "mother_below")

        active_ids = {q.quest_id for q in get_active_quests(log)}
        available_ids = {q.quest_id for q in get_available_quests(log)}

        self.assertNotIn("mother_below", active_ids)
        self.assertNotIn("mother_below", available_ids)
        self.assertIn("mother_below", log.completed)

    def test_available_quests_exclude_active_and_completed(self) -> None:
        log = QuestLog()
        accept_quest(log, "black_venom")
        log.completed.add("cult_beneath_roots")
        ids = {q.quest_id for q in get_available_quests(log)}
        self.assertNotIn("black_venom", ids)
        self.assertNotIn("cult_beneath_roots", ids)
        self.assertIn("bones_of_silentwater", ids)
