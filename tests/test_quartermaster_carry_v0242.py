import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from game.application import Game
from game.state import GameState
from items.factory import create_equipment_item
from player.factory import create_player
from systems.carry_weight import (
    carry_capacity,
    carry_status,
    inventory_weight,
    next_carry_upgrade,
)
from systems.guild_storage import (
    GUILD_STORAGE_CAPACITY_SLOTS,
    GuildStorage,
    deposit_equipment,
    deposit_stack,
    withdraw_equipment,
    withdraw_stack,
)
from systems.save_system import load_game, save_game
from world.factory import create_location


class CarryWeightV0242Tests(unittest.TestCase):
    def test_equipped_starting_gear_does_not_fill_backpack_capacity(self):
        player = create_player("Tester")
        self.assertEqual(inventory_weight(player.inventory), 0.0)
        self.assertEqual(carry_capacity(player), 50.0)
        self.assertEqual(carry_status(player).display_name, "Swobodny")

    def test_strength_and_endurance_raise_capacity(self):
        player = create_player("Tester")
        player.attributes.strength = 10
        player.attributes.endurance = 10
        self.assertEqual(carry_capacity(player), 70.0)

    def test_material_stacks_have_soft_weight_and_status_thresholds(self):
        player = create_player("Tester")
        player.inventory.add("weak_leather", 800)  # 40 kg
        self.assertEqual(inventory_weight(player.inventory), 40.0)
        self.assertEqual(carry_status(player).display_name, "Obciążony")

        player.inventory.add("weak_leather", 300)  # razem 55 kg
        self.assertTrue(carry_status(player).overloaded)
        self.assertEqual(carry_status(player).display_name, "Przeciążony")

    def test_overload_never_blocks_receiving_loot(self):
        player = create_player("Tester")
        player.inventory.add("weak_leather", 2_000)
        before = player.inventory.count("weak_leather")
        player.inventory.add("weak_leather", 25)
        self.assertEqual(player.inventory.count("weak_leather"), before + 25)
        self.assertTrue(carry_status(player).overloaded)

    def test_overload_blocks_only_start_of_normal_expedition(self):
        game = Game()
        game.state = GameState(active_game=True, player=create_player("Tester"))
        game.state.player.inventory.add("weak_leather", 2_000)
        location = create_location("twilight_plains")
        with patch("game.application.explore_location") as explore, patch(
            "game.application.clear_screen"
        ), patch("game.application.pause"):
            game.run_expedition(location)
        explore.assert_not_called()

    def test_carry_upgrades_are_progressive(self):
        player = create_player("Tester")
        level, name, bonus, cost, rank = next_carry_upgrade(player)
        self.assertEqual((level, bonus, cost, rank), (1, 10.0, 8_000, "E"))
        self.assertIn("Plecak Poszukiwacza", name)
        player.carry_upgrade_level = 3
        self.assertEqual(carry_capacity(player), 85.0)
        self.assertIsNone(next_carry_upgrade(player))


class GuildStorageV0242Tests(unittest.TestCase):
    def test_stack_transfer_is_reversible(self):
        player = create_player("Tester")
        storage = GuildStorage()
        player.inventory.add("weak_leather", 12)

        deposit_stack(player, storage, "weak_leather", 7)
        self.assertEqual(player.inventory.count("weak_leather"), 5)
        self.assertEqual(storage.inventory.count("weak_leather"), 7)

        withdraw_stack(player, storage, "weak_leather", 2)
        self.assertEqual(player.inventory.count("weak_leather"), 7)
        self.assertEqual(storage.inventory.count("weak_leather"), 5)

    def test_equipment_transfer_preserves_exact_instance(self):
        player = create_player("Tester")
        storage = GuildStorage()
        item = create_equipment_item("nature_amulet")
        item.upgrade_level = 7
        player.inventory.add_equipment_instance(item)

        stored = deposit_equipment(player, storage, 0)
        self.assertEqual(stored.instance_id, item.instance_id)
        self.assertEqual(stored.upgrade_level, 7)
        self.assertFalse(player.inventory.equipment_items)

        returned = withdraw_equipment(player, storage, 0)
        self.assertEqual(returned.instance_id, item.instance_id)
        self.assertEqual(returned.upgrade_level, 7)
        self.assertEqual(player.inventory.equipment_items[0].instance_id, item.instance_id)

    def test_storage_has_large_two_hundred_slot_limit(self):
        storage = GuildStorage()
        for _ in range(GUILD_STORAGE_CAPACITY_SLOTS):
            storage.inventory.add_equipment_instance(
                create_equipment_item("nature_amulet")
            )
        self.assertEqual(storage.used_slots, 200)
        self.assertEqual(storage.free_slots, 0)
        self.assertFalse(storage.can_accept_equipment())

    def test_existing_stack_can_still_grow_when_all_slots_are_used(self):
        storage = GuildStorage()
        storage.inventory.add("weak_leather", 1)
        for _ in range(GUILD_STORAGE_CAPACITY_SLOTS - 1):
            storage.inventory.add_equipment_instance(
                create_equipment_item("nature_amulet")
            )
        self.assertEqual(storage.used_slots, 200)
        self.assertTrue(storage.can_accept_stack("weak_leather"))
        self.assertFalse(storage.can_accept_stack("slime_gel"))


class QuartermasterSaveV0242Tests(unittest.TestCase):
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

    def test_storage_and_bag_upgrade_survive_save_roundtrip(self):
        player = create_player("Tester")
        player.carry_upgrade_level = 2
        state = GameState(active_game=True, player=player)
        state.guild_storage.inventory.add("weak_leather", 31)
        item = create_equipment_item("nature_amulet")
        item.upgrade_level = 4
        state.guild_storage.inventory.add_equipment_instance(item)

        save_game(state)
        loaded = load_game()

        self.assertEqual(loaded.player.carry_upgrade_level, 2)
        self.assertEqual(loaded.guild_storage.inventory.count("weak_leather"), 31)
        self.assertEqual(
            loaded.guild_storage.inventory.equipment_items[0].instance_id,
            item.instance_id,
        )
        self.assertEqual(
            loaded.guild_storage.inventory.equipment_items[0].upgrade_level,
            4,
        )

    def test_old_schema_fourteen_save_without_new_fields_loads_safely(self):
        player = create_player("Tester")
        path = save_game(GameState(active_game=True, player=player))
        payload = json.loads(path.read_text(encoding="utf-8"))
        self.assertEqual(payload["schema_version"], 15)
        payload.pop("guild_storage", None)
        payload["player"].pop("carry_upgrade_level", None)
        path.write_text(json.dumps(payload), encoding="utf-8")

        loaded = load_game()
        self.assertEqual(loaded.player.carry_upgrade_level, 0)
        self.assertTrue(loaded.guild_storage.inventory.is_empty())


if __name__ == "__main__":
    unittest.main()
