import io
import random
import unittest
from contextlib import redirect_stdout

from data.books import MASTERY_BOOK_IDS
from items.catalog import get_item_definition
from player.factory import create_player
from player.passives import (
    PassiveType,
    attack_speed_extra_hit_chance,
    critical_chance,
    critical_multiplier,
    health_regeneration_per_turn,
    passive_attack_bonus,
)
from systems.mastery_books import read_mastery_book, roll_mastery_book_drop
from ui.skills_view import show_active_skills


class SequenceRandom:
    def __init__(self, rolls, choice_index=0):
        self.rolls = iter(rolls)
        self.choice_index = choice_index
    def random(self):
        return next(self.rolls)
    def choice(self, seq):
        return seq[self.choice_index]


class MasteryBooksV022Tests(unittest.TestCase):
    def test_book_drop_is_random_from_common_pool_not_bound_to_boss(self):
        first = roll_mastery_book_drop("admiral_varek", SequenceRandom([0.0], 0))
        second = roll_mastery_book_drop("admiral_varek", SequenceRandom([0.0], 2))
        self.assertEqual(first, MASTERY_BOOK_IDS[0])
        self.assertEqual(second, MASTERY_BOOK_IDS[2])
        self.assertNotEqual(first, second)

    def test_overworld_miniboss_does_not_drop_mastery_books(self):
        self.assertIsNone(roll_mastery_book_drop("hearth_devourer", SequenceRandom([0.0], 0)))
        self.assertIsNone(roll_mastery_book_drop("ghost_ship_captain", SequenceRandom([0.0], 0)))

    def test_regional_boss_dungeon_miniboss_and_dungeon_boss_have_increasing_chances(self):
        # 1.5% fails regional 1%, succeeds dungeon miniboss 2% and dungeon boss 4%.
        self.assertIsNone(roll_mastery_book_drop("azhar", SequenceRandom([0.015], 0)))
        self.assertIsNotNone(roll_mastery_book_drop("black_fleet_first_officer", SequenceRandom([0.015], 0)))
        self.assertIsNotNone(roll_mastery_book_drop("admiral_varek", SequenceRandom([0.015], 0)))

    def test_reading_book_unlocks_only_matching_mastery_and_consumes_book(self):
        player = create_player("Tester")
        item_id = "mastery_regeneration_book"
        player.inventory.add(item_id)
        result = read_mastery_book(player, item_id)
        self.assertEqual(result.passive, PassiveType.HEALTH_REGEN)
        self.assertIn("health_regen", player.passive_masteries)
        self.assertEqual(player.inventory.count(item_id), 0)
        with self.assertRaises(ValueError):
            player.inventory.add(item_id)
            read_mastery_book(player, item_id)

    def test_without_book_passive_cap_stays_five(self):
        player = create_player("Tester")
        player.level = 30
        player.spend_passive_points(PassiveType.HEALTH_REGEN, 5)
        with self.assertRaises(ValueError):
            player.spend_passive_points(PassiveType.HEALTH_REGEN, 1)

    def test_mastery_allows_levels_six_to_ten(self):
        player = create_player("Tester")
        player.level = 40
        player.inventory.add("mastery_regeneration_book")
        read_mastery_book(player, "mastery_regeneration_book")
        player.spend_passive_points(PassiveType.HEALTH_REGEN, 10)
        self.assertEqual(player.passives.health_regen, 10)
        self.assertEqual(health_regeneration_per_turn(player.passives), 35)

    def test_mastery_level_ten_values_match_balance_plan(self):
        from player.passives import Passives
        passives = Passives(attack_speed=10, critical_damage=10, health_regen=10, increased_attack=10)
        self.assertEqual(attack_speed_extra_hit_chance(passives), 35.0)
        self.assertEqual(critical_chance(passives), 14.0)
        self.assertAlmostEqual(critical_multiplier(passives), 3.0)
        self.assertEqual(health_regeneration_per_turn(passives), 35)
        self.assertEqual(passive_attack_bonus(passives), 25)

    def test_skill_screen_is_available_outside_combat_and_lists_masteries(self):
        player = create_player("Tester")
        player.level = 20
        from player.classes import PlayerClass
        player.choose_class(PlayerClass.WARRIOR)
        output = io.StringIO()
        with redirect_stdout(output):
            show_active_skills(player)
        text = output.getvalue()
        self.assertIn("UMIEJĘTNOŚCI BOHATERA", text)
        self.assertIn("Potężne Cięcie", text)
        self.assertIn("MISTRZOSTWA PASYWNE", text)
        self.assertIn("Traktat Mistrzowskiej Regeneracji", text)


if __name__ == "__main__":
    unittest.main()
