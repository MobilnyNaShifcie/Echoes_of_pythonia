import random
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from companions.models import PartyState
from data.class_effects import CLASS_EFFECT_DATA
from data.items import ITEM_DATA
from data.rifts import RIFT_MIN_COMPANIONS, RIFT_RANKS, RIFT_SEGMENTS, RIFT_UNIQUE_POOLS
from game.config import SAVE_SCHEMA_VERSION
from game.state import GameState
from items.factory import create_equipment_item
from items.models import EquipmentSlot
from player.classes import PlayerClass
from player.factory import create_player
from rifts.models import RiftInstance, RiftState
from systems.companions import (
    MAX_ACTIVE_COMPANIONS,
    MAX_COMPANIONS,
    candidate_willingness_score,
    dismiss_companion,
    ensure_daily_candidates,
    equip_player_item_to_companion,
    recruit_candidate,
    remove_player_item_from_companion,
    set_companion_active,
    set_party_solo,
    talk_to_candidate,
)
from systems.rift_combat import RiftBattleEngine, RiftRoundResult
from systems.rifts import (
    RiftEnemyProfile,
    can_start_rift,
    ensure_rift_state,
    resolve_rift_completion,
    start_rift_expedition,
)
from systems.save_system import load_game, save_game


class CompanionsV024Tests(unittest.TestCase):
    def _player(self, level=20, cls=PlayerClass.WARRIOR):
        player = create_player("Tester")
        player.level = level
        player.choose_class(cls)
        return player

    def test_schema_fourteen(self):
        self.assertEqual(SAVE_SCHEMA_VERSION, 15)

    def test_roster_is_three_active_plus_one_extra(self):
        self.assertEqual(MAX_ACTIVE_COMPANIONS, 3)
        self.assertEqual(MAX_COMPANIONS, 4)

    def test_candidates_persist_for_same_pythonia_day(self):
        player = self._player()
        party = PartyState()
        self.assertTrue(ensure_daily_candidates(party, player, 10, "S"))
        first = [(c.candidate_id, c.companion.level, c.companion.path_id) for c in party.candidates]
        self.assertFalse(ensure_daily_candidates(party, player, 10, "S"))
        self.assertEqual(first, [(c.candidate_id, c.companion.level, c.companion.path_id) for c in party.candidates])

    def test_candidate_levels_stay_near_player(self):
        player = self._player(level=20)
        party = PartyState()
        for day in range(10, 25):
            ensure_daily_candidates(party, player, day, "S")
            for candidate in party.candidates:
                self.assertGreaterEqual(candidate.companion.level, 14)
                self.assertLessEqual(candidate.companion.level, 28)

    def test_higher_level_is_modifier_not_hard_lock(self):
        player = self._player(level=20)
        party = PartyState()
        ensure_daily_candidates(party, player, 10, "S")
        candidate = party.candidates[0]
        candidate.companion.level = 28
        high_score = candidate_willingness_score(candidate, player, "S", 4)
        candidate.companion.level = 20
        equal_score = candidate_willingness_score(candidate, player, "S", 4)
        self.assertLess(high_score, equal_score)
        self.assertGreaterEqual(high_score, 5)

    def test_candidate_conversation_is_handwritten_and_changes_impression(self):
        player = self._player()
        party = PartyState()
        ensure_daily_candidates(party, player, 11, "S")
        candidate = party.candidates[0]
        before = candidate.impression
        text = talk_to_candidate(candidate, 1)
        self.assertTrue(candidate.talked)
        self.assertGreater(candidate.impression, before)
        self.assertNotIn("Kandydat słucha uważniej", text)
        self.assertGreater(len(text), 30)

    def test_personal_equipment_cannot_be_stolen_but_player_loan_can_return(self):
        player = self._player()
        party = PartyState()
        ensure_daily_candidates(party, player, 12, "S")
        candidate = party.candidates[0]
        candidate.recruitment_roll = 1
        success, _, _ = recruit_candidate(party, candidate, player, "S", 5)
        self.assertTrue(success)
        companion = party.companions[0]
        personal_slot = next(slot for slot in EquipmentSlot if companion.equipment.get(slot) and companion.owns_item(companion.equipment.get(slot)))
        with self.assertRaises(ValueError):
            remove_player_item_from_companion(player, companion, personal_slot)

        loan = create_equipment_item("nature_ring")
        player.inventory.add_equipment_instance(loan)
        index = next(i for i, item in enumerate(player.inventory.equipment_items) if item.instance_id == loan.instance_id)
        equip_player_item_to_companion(player, companion, index)
        self.assertEqual(companion.equipment.get(EquipmentSlot.RING).instance_id, loan.instance_id)
        returned = remove_player_item_from_companion(player, companion, EquipmentSlot.RING)
        self.assertEqual(returned.instance_id, loan.instance_id)
        self.assertTrue(any(item.instance_id == loan.instance_id for item in player.inventory.equipment_items))


    def test_party_setup_can_switch_entire_group_to_solo(self):
        player = self._player()
        party = PartyState()
        day = 30
        while len(party.companions) < 4:
            ensure_daily_candidates(party, player, day, "S")
            for candidate in list(party.candidates):
                if len(party.companions) >= 4:
                    break
                candidate.recruitment_roll = 1
                recruit_candidate(party, candidate, player, "S", 5)
            day += 1
        self.assertEqual(len(party.active_companions()), 3)
        changed = set_party_solo(party)
        self.assertEqual(changed, 3)
        self.assertEqual(party.active_companions(), [])
        self.assertTrue(all(not companion.active for companion in party.companions))

    def test_dismissal_returns_player_gear_and_keeps_companion_history(self):
        player = self._player()
        party = PartyState()
        ensure_daily_candidates(party, player, 13, "S")
        candidate = party.candidates[0]
        candidate.recruitment_roll = 1
        recruit_candidate(party, candidate, player, "S", 5)
        companion = party.companions[0]
        companion.relation = 17
        loan = create_equipment_item("nature_ring")
        player.inventory.add_equipment_instance(loan)
        idx = next(i for i, item in enumerate(player.inventory.equipment_items) if item.instance_id == loan.instance_id)
        equip_player_item_to_companion(player, companion, idx)
        dismissed = dismiss_companion(party, player, companion.companion_id, 20)
        self.assertEqual(dismissed.relation, 17)
        self.assertEqual(len(party.companions), 0)
        self.assertEqual(party.dismissed_companions[0].relation, 17)
        self.assertTrue(any(item.instance_id == loan.instance_id for item in player.inventory.equipment_items))


class RiftsV024Tests(unittest.TestCase):
    def _player(self, level=20):
        player = create_player("Rifter")
        player.level = level
        player.choose_class(PlayerClass.WARRIOR)
        return player

    def _rift(self, rank="B", expires=10):
        return RiftInstance("r1", rank, "blood_moon", "Pęknięcie", (), 1, expires, 123, RIFT_SEGMENTS[rank], "boss", "Władca")

    def test_rift_ranks_and_lengths_are_f_to_s_and_epic(self):
        self.assertEqual(RIFT_RANKS, ("F", "E", "D", "C", "B", "A", "S"))
        self.assertEqual(RIFT_SEGMENTS["F"], 12)
        self.assertEqual(RIFT_SEGMENTS["S"], 24)
        self.assertTrue(all(RIFT_SEGMENTS[a] < RIFT_SEGMENTS[b] for a, b in zip(RIFT_RANKS, RIFT_RANKS[1:])))

    def test_rifts_require_a_real_party(self):
        for rank in RIFT_RANKS:
            required = RIFT_MIN_COMPANIONS[rank]
            ok, _ = can_start_rift(self._rift(rank), required - 1, "S")
            self.assertFalse(ok)
            ok, _ = can_start_rift(self._rift(rank), required, "S")
            self.assertTrue(ok)

    def test_active_expedition_protects_rift_from_other_teams(self):
        player = self._player()
        state = RiftState(active_rift=self._rift("C", expires=2), next_spawn_day=99)
        start_rift_expedition(state, 1, ("a", "b", "c"))
        notice = ensure_rift_state(state, player, 20, "S")
        self.assertIsNone(notice)
        self.assertIsNotNone(state.active_rift)
        self.assertIsNotNone(state.expedition)

    def test_ignored_rift_is_closed_by_other_searchers(self):
        player = self._player()
        state = RiftState(active_rift=self._rift("C", expires=2), next_spawn_day=99)
        notice = ensure_rift_state(state, player, 3, "S")
        self.assertIsNone(state.active_rift)
        self.assertIsNotNone(notice)
        self.assertIn("zamknęła", notice)

    def test_main_boss_completion_closes_rift_once(self):
        player = self._player()
        state = RiftState(active_rift=self._rift("C", expires=10), next_spawn_day=99)
        start_rift_expedition(state, 2, ("a", "b", "c"))
        reward = resolve_rift_completion(state, player, random.Random(1))
        self.assertGreater(reward.gold, 0)
        self.assertEqual(state.completed_total, 1)
        self.assertIsNone(state.active_rift)
        self.assertIsNone(state.expedition)
        with self.assertRaises(ValueError):
            resolve_rift_completion(state, player, random.Random(1))

    def test_only_high_rift_bosses_can_prepare_lethal_execution(self):
        player = self._player()
        companion_party = PartyState()
        ensure_daily_candidates(companion_party, player, 15, "S")
        candidate = companion_party.candidates[0]
        candidate.recruitment_roll = 1
        recruit_candidate(companion_party, candidate, player, "S", 10)
        companion = companion_party.companions[0]

        for rank, lethal in (("E", False), ("B", True)):
            enemy = RiftEnemyProfile("e", "Boss", 1000, 9999, 0, boss=True)
            engine = RiftBattleEngine(player, [companion], enemy, self._rift(rank), random.Random(1))
            fighter = engine.companion_fighters[0]
            fighter.combatant.stats.current_hp = 0
            result = RiftRoundResult()
            engine._down_fighter(fighter, result)
            self.assertEqual(fighter.lethal_downed, lethal)
            self.assertTrue(any("POWALONY" in line for line in result.lines))
            if lethal:
                self.assertTrue(any("EGZEKUCJ" in line for line in result.lines))

    def test_rift_uniques_are_four_per_class_and_not_crafting_placeholders(self):
        self.assertEqual({key: len(value) for key, value in RIFT_UNIQUE_POOLS.items()}, {
            "warrior": 4, "hunter": 4, "mage": 4, "pierrot": 4,
        })
        for pool in RIFT_UNIQUE_POOLS.values():
            for item_id in pool:
                self.assertIn(item_id, ITEM_DATA)
                effect_id = ITEM_DATA[item_id].get("class_effect_id")
                self.assertIn(effect_id, CLASS_EFFECT_DATA)
        self.assertNotIn("rift_shard", ITEM_DATA)
        self.assertNotIn("anomaly_core", ITEM_DATA)


class SaveV024Tests(unittest.TestCase):
    def test_party_and_rift_state_round_trip(self):
        player = create_player("SaveParty")
        player.level = 20
        player.choose_class(PlayerClass.WARRIOR)
        state = GameState(active_game=True, player=player)
        ensure_daily_candidates(state.party, player, 25, "S")
        candidate = state.party.candidates[0]
        candidate.recruitment_roll = 1
        recruit_candidate(state.party, candidate, player, "S", 3)
        state.party.companions[0].relation = 12
        state.rifts.active_rift = RiftInstance("save-rift", "D", "blood_moon", "Pęknięcie", ("hungry",), 25, 28, 99, 16, "boss", "Władca")
        start_rift_expedition(state.rifts, 25, (state.party.companions[0].companion_id,))

        with tempfile.TemporaryDirectory() as temp:
            save_dir = Path(temp)
            with patch("systems.save_system.get_save_directory", return_value=save_dir), patch(
                "systems.save_system.get_save_path", return_value=save_dir / "save.json"
            ):
                save_game(state)
                loaded = load_game()
        self.assertEqual(loaded.party.companions[0].name, state.party.companions[0].name)
        self.assertEqual(loaded.party.companions[0].relation, 12)
        self.assertEqual(loaded.rifts.active_rift.rift_id, "save-rift")
        self.assertIsNotNone(loaded.rifts.expedition)

    def test_schema_thirteen_migrates_with_empty_party_and_rifts(self):
        import json
        player = create_player("LegacyV0232")
        state = GameState(active_game=True, player=player)
        with tempfile.TemporaryDirectory() as temp:
            save_dir = Path(temp)
            path = save_dir / "save.json"
            with patch("systems.save_system.get_save_directory", return_value=save_dir), patch(
                "systems.save_system.get_save_path", return_value=path
            ):
                save_game(state)
                payload = json.loads(path.read_text(encoding="utf-8"))
                payload["schema_version"] = 13
                payload.pop("party", None)
                payload.pop("rifts", None)
                path.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
                loaded = load_game()
        self.assertEqual(loaded.party.companions, [])
        self.assertIsNone(loaded.rifts.active_rift)
        self.assertIsNone(loaded.rifts.expedition)


if __name__ == "__main__":
    unittest.main()
