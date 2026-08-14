import random
import unittest

from combat.combat import CombatEngine
from combat.elements import DamageType
from enemies.factory import create_enemy
from player.classes import PlayerClass
from player.factory import create_player
from systems.elite_system import (
    apply_elite_modifier,
    elite_encounter_chance,
    maybe_make_elite,
)
from world.time_system import TimePeriod
from world.weather import WeatherType


class FixedRng:
    def random(self) -> float:
        return 0.0

    def choice(self, values):
        return values[0]


class EliteTests(unittest.TestCase):
    def test_elite_chances_match_design(self) -> None:
        self.assertEqual(
            elite_encounter_chance(
                TimePeriod.DAY,
                WeatherType.SUNNY,
            ),
            0.10,
        )
        self.assertEqual(
            elite_encounter_chance(
                TimePeriod.NIGHT,
                WeatherType.SUNNY,
            ),
            0.15,
        )
        self.assertEqual(
            elite_encounter_chance(
                TimePeriod.DAY,
                WeatherType.AURORA,
            ),
            0.25,
        )

    def test_normal_enemy_can_roll_compatible_elite(self) -> None:
        enemy = create_enemy("wolf")
        modifier = maybe_make_elite(
            enemy,
            TimePeriod.DAY,
            WeatherType.SUNNY,
            FixedRng(),
        )

        self.assertEqual(modifier, "furious")
        self.assertEqual(enemy.rank, "elite")
        self.assertEqual(enemy.elite_modifier_id, "furious")
        self.assertIn("Wściekły", enemy.name)

    def test_miniboss_never_becomes_random_elite(self) -> None:
        enemy = create_enemy("nature_guardian")

        modifier = maybe_make_elite(
            enemy,
            TimePeriod.NIGHT,
            WeatherType.AURORA,
            FixedRng(),
        )

        self.assertIsNone(modifier)
        self.assertEqual(enemy.rank, "miniboss")

    def test_incompatible_modifier_is_rejected(self) -> None:
        enemy = create_enemy("slime")
        with self.assertRaises(ValueError):
            apply_elite_modifier(
                enemy,
                "vampiric",
                WeatherType.SUNNY,
            )

    def test_elite_rewards_are_increased(self) -> None:
        enemy = create_enemy("corrupted_bear")
        old_exp = enemy.experience_reward
        old_gold = enemy.gold_max

        apply_elite_modifier(
            enemy,
            "armored",
            WeatherType.SUNNY,
        )

        self.assertEqual(
            enemy.experience_reward,
            round(old_exp * 1.5),
        )
        self.assertEqual(
            enemy.gold_max,
            round(old_gold * 1.25),
        )
        self.assertEqual(enemy.loot_chance_multiplier, 1.20)

    def test_elemental_elite_uses_weather_element(self) -> None:
        enemy = create_enemy("wolf")

        apply_elite_modifier(
            enemy,
            "elemental",
            WeatherType.FROST,
        )

        self.assertEqual(
            enemy.basic_damage_type,
            DamageType.FROST,
        )
        self.assertEqual(
            enemy.elemental_resistances.frost,
            50,
        )
        self.assertIn("Mroźny", enemy.name)

    def test_vampiric_elite_heals_from_damage_dealt(self) -> None:
        player = create_player("Tester")
        player.attributes.vitality = 10
        player.recalculate_stats()

        enemy = create_enemy("corrupted_bear")
        apply_elite_modifier(
            enemy,
            "vampiric",
            WeatherType.SUNNY,
        )
        enemy.current_hp -= 10

        combat = CombatEngine(
            player,
            enemy,
            random.Random(4),
        )
        before = enemy.current_hp
        report = combat.player_attack()

        self.assertGreater(report.enemy_healed, 0)
        self.assertGreater(
            enemy.current_hp,
            before - report.player_damage,
        )

    def test_cursed_elite_can_resist_bleed(self) -> None:
        player = create_player("Tester")
        player.level = 12
        player.choose_class(PlayerClass.WARRIOR)

        enemy = create_enemy("rotting_knight")
        apply_elite_modifier(
            enemy,
            "cursed",
            WeatherType.SUNNY,
        )

        combat = CombatEngine(
            player,
            enemy,
            FixedRng(),
        )
        report = combat.player_use_skill("blood_strike")

        self.assertFalse(combat.effects.bleed_active)
        self.assertTrue(
            any(
                "odpiera negatywny efekt" in note
                for note in report.skill_notes
            )
        )


if __name__ == "__main__":
    unittest.main()
