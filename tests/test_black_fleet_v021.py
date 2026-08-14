import io
import random
import unittest
from contextlib import redirect_stdout

from combat.combat import TurnReport
from combat.dungeon_boss import AdmiralVarekCombatEngine
from data.enemies import ENEMY_DATA
from data.loot_tables import LOOT_TABLES
from enemies.factory import create_enemy
from player.factory import create_player
from systems.crafting import can_craft_for_player, craft_for_player, get_recipe
from ui.dungeon_view import show_dungeon_entrance
from world.dungeon import (
    can_enter_dungeon,
    consume_dungeon_entry,
    create_dungeon,
    roll_dungeon_chest,
    use_medical_cabin,
)


class HighRandom(random.Random):
    def random(self) -> float:
        return 0.99


class BlackFleetV021Tests(unittest.TestCase):
    def test_black_fleet_definition_uses_approved_names(self) -> None:
        dungeon = create_dungeon("black_fleet_wreck")
        self.assertEqual(dungeon.name, "Wrak Czarnej Floty")
        self.assertEqual(dungeon.recommended_level_min, 16)
        self.assertEqual(dungeon.recommended_level_max, 20)
        self.assertEqual(dungeon.entry_item_id, "black_fleet_medallion")
        self.assertEqual(dungeon.mandatory_elite_enemy, "black_fleet_first_officer")
        self.assertEqual(dungeon.boss_enemy, "admiral_varek")

        expected_names = {
            "Przeklęty Marynarz",
            "Topielec Czarnej Floty",
            "Przeklęty Kanonier",
            "Widmowy Strzelec",
            "Bosman Czarnej Floty",
            "Pierwszy Oficer Czarnej Floty",
            "Admirał Varek",
        }
        actual_names = {
            ENEMY_DATA[enemy_id]["name"]
            for enemy_id in (
                "cursed_sailor",
                "black_fleet_drowned",
                "cursed_gunner",
                "spectral_marksman",
                "black_fleet_boatswain",
                "black_fleet_first_officer",
                "admiral_varek",
            )
        }
        self.assertEqual(actual_names, expected_names)

    def test_ghost_ship_captain_guarantees_medallion(self) -> None:
        entries = {
            str(entry["item_id"]): float(entry["chance"])
            for entry in LOOT_TABLES["ghost_ship_captain"]
        }
        self.assertEqual(entries["black_fleet_medallion"], 1.0)

    def test_medallion_recipe_is_alternative_entry_source(self) -> None:
        player = create_player("Tester")
        recipe = get_recipe("black_fleet_medallion")
        for item_id, quantity in recipe.ingredients.items():
            player.inventory.add(item_id, quantity)
        player.gold = recipe.gold_cost

        self.assertTrue(can_craft_for_player(player, recipe))
        craft_for_player(player, recipe)
        self.assertEqual(player.inventory.count("black_fleet_medallion"), 1)
        self.assertEqual(player.gold, 0)

    def test_black_fleet_entry_consumes_one_medallion(self) -> None:
        player = create_player("Tester")
        dungeon = create_dungeon("black_fleet_wreck")
        player.inventory.add("black_fleet_medallion", 2)

        self.assertTrue(can_enter_dungeon(player.inventory, dungeon))
        consume_dungeon_entry(player.inventory, dungeon)
        self.assertEqual(player.inventory.count("black_fleet_medallion"), 1)

    def test_entrance_shows_black_fleet_sources_not_crypt_sources(self) -> None:
        player = create_player("Tester")
        dungeon = create_dungeon("black_fleet_wreck")
        out = io.StringIO()
        with redirect_stdout(out):
            show_dungeon_entrance(player, dungeon)
        text = out.getvalue()
        self.assertIn("Widmo Kapitana Statku lub crafting", text)
        self.assertNotIn("Matka Głuchej Wody", text)

    def test_treasury_has_guaranteed_black_fleet_loot(self) -> None:
        player = create_player("Tester")
        dungeon = create_dungeon("black_fleet_wreck")
        drops = roll_dungeon_chest(dungeon, player.inventory, random.Random(1))
        drop_ids = {drop.item_id for drop in drops}
        self.assertIn("cursed_compass", drop_ids)
        self.assertIn("black_pearl", drop_ids)

    def test_medical_cabin_restores_thirty_percent(self) -> None:
        player = create_player("Tester")
        player.stats.max_hp = 100
        player.stats.current_hp = 10
        player.stats.max_mana = 100
        player.stats.current_mana = 10

        healed, restored = use_medical_cabin(player)

        self.assertEqual(healed, 30)
        self.assertEqual(restored, 30)
        self.assertEqual(player.stats.current_hp, 40)
        self.assertEqual(player.stats.current_mana, 40)

    def test_first_officer_and_varek_have_expected_ranks(self) -> None:
        officer = create_enemy("black_fleet_first_officer")
        varek = create_enemy("admiral_varek")
        self.assertEqual(officer.rank, "miniboss")
        self.assertEqual(varek.rank, "boss")
        self.assertGreater(varek.max_hp, officer.max_hp)
        self.assertGreaterEqual(varek.max_hp, 4000)

    def test_varek_phase_two_telegraphs_cannon_salvo(self) -> None:
        player = create_player("Tester")
        player.stats.max_hp = 9999
        player.stats.current_hp = 9999
        enemy = create_enemy("admiral_varek")
        engine = AdmiralVarekCombatEngine(player, enemy, HighRandom())
        enemy.current_hp = int(enemy.max_hp * 0.60)
        report = TurnReport()

        engine._update_phase(report)
        self.assertEqual(engine.phase, 2)

        # Po dwóch normalnych turach salwa ma być zapowiedziana i
        # komunikat ma pozostać widoczny przed następną akcją gracza.
        engine.player_defend()
        report = engine.player_defend()
        self.assertTrue(engine.cannon_pending)
        self.assertTrue(any("przygotowują salwę" in note for note in report.boss_notes))
        self.assertTrue(any("Salwa Armatnia" in line for line in engine.status_lines()))

    def test_defend_reduces_telegraphed_cannon_salvo(self) -> None:
        def make_engine():
            player = create_player("Tester")
            player.stats.max_hp = 9999
            player.stats.current_hp = 9999
            enemy = create_enemy("admiral_varek")
            engine = AdmiralVarekCombatEngine(player, enemy, HighRandom())
            engine.phase = 2
            engine.cannon_pending = True
            return engine

        attacking = make_engine()
        attack_report = attacking.player_attack()

        defending = make_engine()
        defend_report = defending.player_defend()

        self.assertEqual(attack_report.enemy_special_name, "Salwa Armatnia")
        self.assertEqual(defend_report.enemy_special_name, "Salwa Armatnia")
        self.assertGreater(attack_report.enemy_damage, defend_report.enemy_damage)
        self.assertFalse(attacking.cannon_pending)
        self.assertFalse(defending.cannon_pending)

    def test_varek_phase_three_ends_cannon_cycle_and_trades_def_for_attack(self) -> None:
        player = create_player("Tester")
        enemy = create_enemy("admiral_varek")
        engine = AdmiralVarekCombatEngine(player, enemy, HighRandom())
        base_attack = enemy.attack
        base_defense = enemy.defense
        engine.phase = 2
        engine.cannon_pending = True
        enemy.current_hp = int(enemy.max_hp * 0.25)
        report = TurnReport()

        engine._update_phase(report)

        self.assertEqual(engine.phase, 3)
        self.assertFalse(engine.cannon_pending)
        self.assertEqual(enemy.attack, base_attack + 10)
        self.assertEqual(enemy.defense, base_defense - 8)
        self.assertTrue(any("Ostatni Rozkaz" in note for note in report.boss_notes))


if __name__ == "__main__":
    unittest.main()
