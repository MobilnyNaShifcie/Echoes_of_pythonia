import unittest

from enemies.factory import create_enemy
from systems.elite_system import apply_elite_modifier
from systems.weather_effects import apply_weather_to_enemy
from world.weather import WeatherType


class EliteBalanceGrammarV0171Tests(unittest.TestCase):
    def test_aurora_swamp_witch_uses_feminine_elemental_name(self) -> None:
        enemy = create_enemy("swamp_witch")
        apply_weather_to_enemy(enemy, WeatherType.AURORA)
        apply_elite_modifier(enemy, "elemental", WeatherType.AURORA)

        self.assertEqual(enemy.name, "Zorzowa Bagienna Wiedźma")
        self.assertEqual(enemy.grammatical_gender, "feminine")

    def test_feminine_modifier_names_are_declined(self) -> None:
        cursed = create_enemy("swamp_witch")
        apply_elite_modifier(cursed, "cursed", WeatherType.SUNNY)
        self.assertEqual(cursed.name, "Przeklęta Bagienna Wiedźma")

        vampiric = create_enemy("swamp_witch")
        apply_elite_modifier(vampiric, "vampiric", WeatherType.SUNNY)
        self.assertEqual(vampiric.name, "Wampiryczna Bagienna Wiedźma")

        wraith = create_enemy("gallows_wraith")
        apply_elite_modifier(wraith, "elemental", WeatherType.FROST)
        self.assertEqual(wraith.name, "Mroźna Zjawa Wisielca")

    def test_masculine_names_keep_masculine_form(self) -> None:
        enemy = create_enemy("wolf")
        apply_elite_modifier(enemy, "elemental", WeatherType.AURORA)
        self.assertEqual(enemy.name, "Zorzowy Wilk")

    def test_all_elites_receive_real_baseline_power(self) -> None:
        enemy = create_enemy("wolf")
        base_hp = enemy.max_hp
        base_attack = enemy.attack
        base_defense = enemy.defense

        apply_elite_modifier(enemy, "furious", WeatherType.SUNNY)

        self.assertGreater(enemy.max_hp, base_hp)
        self.assertGreater(enemy.attack, base_attack)
        self.assertGreaterEqual(enemy.defense, base_defense)

    def test_aurora_elemental_witch_is_substantially_stronger(self) -> None:
        enemy = create_enemy("swamp_witch")
        apply_weather_to_enemy(enemy, WeatherType.AURORA)
        apply_elite_modifier(enemy, "elemental", WeatherType.AURORA)

        # v0.16.x dawało w tym przypadku 46 HP. Nowa elita ma
        # być wyraźnie mocniejszym spotkaniem, bez robienia z niej bossa.
        self.assertGreaterEqual(enemy.max_hp, 70)
        self.assertGreaterEqual(enemy.attack, 18)
        self.assertGreaterEqual(enemy.defense, 4)
        self.assertGreaterEqual(enemy.dodge, 23.0)
        self.assertEqual(enemy.elemental_resistances.frost, 50)
        self.assertEqual(enemy.special_damage_type.code, "frost")
        self.assertGreaterEqual(enemy.special_attack_bonus, 6)


if __name__ == "__main__":
    unittest.main()
