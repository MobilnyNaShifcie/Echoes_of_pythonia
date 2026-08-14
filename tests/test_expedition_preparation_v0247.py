import unittest

from companions.models import COMPANION_TACTICS, PartyState
from game.config import SAVE_SCHEMA_VERSION
from game.state import GameState
from player.classes import PlayerClass
from player.factory import create_player
from systems.companions import (
    ensure_daily_candidates,
    recruit_candidate,
    set_companion_tactic,
    set_party_solo,
)
from systems.expedition_preparation import (
    PRESET_NAMES,
    ExpeditionPreparationState,
    apply_preset,
    clear_preset,
    healing_supply_ids,
    save_preset,
)
from systems.guild_storage import GuildStorage
from systems.save_system import _normalize_payload, _state_from_payload, _state_to_dict
from ui.expedition_prep_view import preparation_warnings


class ExpeditionPreparationV0247Tests(unittest.TestCase):
    def _player(self, level=20):
        player = create_player("PrepTester")
        player.level = level
        player.choose_class(PlayerClass.WARRIOR)
        return player

    def _party_with_companions(self, player, count=2):
        party = PartyState()
        day = 10
        while len(party.companions) < count:
            ensure_daily_candidates(party, player, day, "S")
            for candidate in list(party.candidates):
                if len(party.companions) >= count:
                    break
                candidate.recruitment_roll = 1
                recruit_candidate(party, candidate, player, "S", 5)
            day += 1
        return party

    def test_v0247_uses_schema_fifteen(self):
        self.assertEqual(SAVE_SCHEMA_VERSION, 15)

    def test_four_named_presets_exist(self):
        self.assertEqual(PRESET_NAMES, {
            "solo": "SOLO",
            "boss": "BOSS",
            "dungeon": "DUNGEON",
            "rift": "SZCZELINA",
        })

    def test_preset_saves_current_party_and_target_supply_counts(self):
        player = self._player()
        party = self._party_with_companions(player, 2)
        prep = ExpeditionPreparationState()
        preset = save_preset(prep, "boss", party, {"strong_healing_potion": 5})
        self.assertTrue(preset.configured)
        self.assertEqual(len(preset.active_companion_ids), 2)
        self.assertEqual(preset.supplies["strong_healing_potion"], 5)

    def test_solo_preset_never_saves_active_companions(self):
        player = self._player()
        party = self._party_with_companions(player, 2)
        prep = ExpeditionPreparationState()
        preset = save_preset(prep, "solo", party, {"weak_healing_potion": 2})
        self.assertEqual(preset.active_companion_ids, [])

    def test_apply_preset_restocks_only_missing_quantity(self):
        player = self._player()
        party = PartyState()
        storage = GuildStorage()
        prep = ExpeditionPreparationState()
        player.inventory.add("strong_healing_potion", 2)
        storage.inventory.add("strong_healing_potion", 10)
        save_preset(prep, "boss", party, {"strong_healing_potion": 5})
        result = apply_preset(prep, "boss", player, party, storage)
        self.assertEqual(player.inventory.count("strong_healing_potion"), 5)
        self.assertEqual(storage.inventory.count("strong_healing_potion"), 7)
        self.assertEqual(result.withdrawn, {"strong_healing_potion": 3})

    def test_apply_preset_reports_shortage_without_inventing_items(self):
        player = self._player()
        party = PartyState()
        storage = GuildStorage()
        prep = ExpeditionPreparationState()
        storage.inventory.add("great_healing_potion", 1)
        save_preset(prep, "dungeon", party, {"great_healing_potion": 4})
        result = apply_preset(prep, "dungeon", player, party, storage)
        self.assertEqual(player.inventory.count("great_healing_potion"), 1)
        self.assertEqual(result.missing, {"great_healing_potion": 3})

    def test_preset_will_not_overload_player_during_preparation(self):
        player = create_player("Heavy")
        party = PartyState()
        storage = GuildStorage()
        prep = ExpeditionPreparationState()
        player.inventory.add("wolf_fur", 1000)  # 50 kg przy bazowym udźwigu 50 kg
        storage.inventory.add("weak_healing_potion", 1)
        save_preset(prep, "solo", party, {"weak_healing_potion": 1})
        with self.assertRaises(ValueError):
            apply_preset(prep, "solo", player, party, storage)
        self.assertEqual(storage.inventory.count("weak_healing_potion"), 1)
        self.assertEqual(player.inventory.count("weak_healing_potion"), 0)

    def test_companion_tactic_can_be_changed_and_rejects_unknown_values(self):
        player = self._player()
        party = self._party_with_companions(player, 1)
        companion = party.companions[0]
        set_companion_tactic(party, companion.companion_id, "aggressive")
        self.assertEqual(companion.tactic, "aggressive")
        self.assertEqual(COMPANION_TACTICS[companion.tactic], "Agresywna")
        with self.assertRaises(ValueError):
            set_companion_tactic(party, companion.companion_id, "berserk")

    def test_preparation_and_tactics_round_trip_in_save_payload(self):
        player = self._player()
        state = GameState(active_game=True, player=player)
        state.party = self._party_with_companions(player, 1)
        companion = state.party.companions[0]
        set_companion_tactic(state.party, companion.companion_id, "cautious")
        state.expedition_preparation.selected_location_id = "ice_coast"
        save_preset(state.expedition_preparation, "rift", state.party, {"great_healing_potion": 3})
        payload = _state_to_dict(state)
        restored = _state_from_payload(payload)
        self.assertEqual(restored.party.companions[0].tactic, "cautious")
        self.assertEqual(restored.expedition_preparation.selected_location_id, "ice_coast")
        self.assertEqual(restored.expedition_preparation.presets["rift"].supplies["great_healing_potion"], 3)

    def test_schema_fourteen_migrates_with_balanced_tactics_and_empty_presets(self):
        player = self._player()
        state = GameState(active_game=True, player=player)
        state.party = self._party_with_companions(player, 1)
        payload = _state_to_dict(state)
        payload["schema_version"] = 14
        payload.pop("expedition_preparation", None)
        for raw in payload["party"]["companions"]:
            raw.pop("tactic", None)
        migrated = _normalize_payload(payload)
        restored = _state_from_payload(migrated)
        self.assertEqual(migrated["schema_version"], 15)
        self.assertEqual(restored.party.companions[0].tactic, "balanced")
        self.assertEqual(restored.expedition_preparation.selected_location_id, "")
        self.assertTrue(all(not preset.configured for preset in restored.expedition_preparation.presets.values()))

    def test_healing_supply_catalog_combines_backpack_and_storage(self):
        player = self._player()
        storage = GuildStorage()
        player.inventory.add("weak_healing_potion", 1)
        storage.inventory.add("great_healing_potion", 2)
        ids = healing_supply_ids(player, storage)
        self.assertIn("weak_healing_potion", ids)
        self.assertIn("great_healing_potion", ids)

    def test_preparation_warns_about_low_hp_and_missing_healing(self):
        player = self._player()
        player.stats.current_hp = 1
        warnings = preparation_warnings(player, PartyState())
        self.assertTrue(any("Niskie HP" in text for text in warnings))
        self.assertTrue(any("Brak mikstur" in text for text in warnings))

    def test_clear_preset_resets_configuration(self):
        prep = ExpeditionPreparationState()
        save_preset(prep, "solo", PartyState(), {"weak_healing_potion": 1})
        clear_preset(prep, "solo")
        self.assertFalse(prep.presets["solo"].configured)
        self.assertEqual(prep.presets["solo"].supplies, {})


if __name__ == "__main__":
    unittest.main()
