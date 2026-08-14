import unittest

from combat.combat import CombatEngine
from data.recipes import RECIPE_DATA
from enemies.factory import create_enemy
from items.class_effects import get_class_effect, has_active_class_effect
from items.factory import create_equipment_item
from items.loot import roll_loot
from player.classes import PlayerClass
from player.factory import create_player


class HighRollRng:
    def random(self):
        return 0.99


class SequenceRng:
    def __init__(self, values):
        self.values = iter(values)

    def random(self):
        return next(self.values)


class ClassItemsV020Tests(unittest.TestCase):
    def _player_with_item(self, player_class, item_id):
        player = create_player("Tester")
        player.level = 18
        player.character_class = player_class
        player.inventory.add_equipment_instance(create_equipment_item(item_id))
        player.equip_from_inventory(len(player.inventory.equipment_items) - 1)
        player.recalculate_stats()
        return player

    def test_three_class_items_have_expected_class_effects(self) -> None:
        expected = {
            "north_armor": ("warrior_retribution", "warrior"),
            "snow_griffin_cloak": ("hunter_predatory_instinct", "hunter"),
            "black_sea_amulet": ("mage_mana_tide", "mage"),
        }
        from items.catalog import get_item_definition
        for item_id, (effect_id, class_code) in expected.items():
            definition = get_item_definition(item_id)
            self.assertEqual(definition.class_effect_id, effect_id)
            self.assertEqual(get_class_effect(effect_id).player_class_code, class_code)

    def test_class_items_are_drop_only(self) -> None:
        outputs = {str(data["output_item_id"]) for data in RECIPE_DATA.values()}
        self.assertNotIn("north_armor", outputs)
        self.assertNotIn("snow_griffin_cloak", outputs)
        self.assertNotIn("black_sea_amulet", outputs)

    def test_elite_bear_has_higher_class_item_drop_chance(self) -> None:
        normal = roll_loot("ice_bear", SequenceRng([0.99, 0.05]), elite=False)
        elite = roll_loot("ice_bear", SequenceRng([0.99, 0.05]), elite=True)
        self.assertNotIn("north_armor", [drop.item_id for drop in normal])
        self.assertIn("north_armor", [drop.item_id for drop in elite])

    def test_effect_is_inactive_for_wrong_class_but_item_can_still_be_equipped(self) -> None:
        player = self._player_with_item(PlayerClass.MAGE, "north_armor")
        self.assertFalse(has_active_class_effect(player, "warrior_retribution"))
        self.assertIsNotNone(player.equipment.slots)

    def test_warrior_retribution_scales_next_basic_attack_from_defense(self) -> None:
        player = self._player_with_item(PlayerClass.WARRIOR, "north_armor")
        player.stats.current_hp = player.stats.max_hp
        enemy = create_enemy("sand_golem")
        enemy.defense = 0
        enemy.dodge = 0.0
        engine = CombatEngine(player, enemy, HighRollRng())

        engine.player_defend()
        before = enemy.current_hp
        report = engine.player_attack()
        dealt = before - enemy.current_hp

        self.assertGreater(dealt, player.stats.attack)
        self.assertTrue(any("ODWET" in note for note in report.class_effect_notes))

    def test_hunter_dodge_prepares_predatory_instinct(self) -> None:
        player = self._player_with_item(PlayerClass.HUNTER, "snow_griffin_cloak")
        player.stats.current_hp = player.stats.max_hp
        player.stats.dodge = 100.0
        enemy = create_enemy("sand_golem")
        enemy.defense = 0
        enemy.dodge = 0.0
        engine = CombatEngine(player, enemy, HighRollRng())

        defend_report = engine.player_defend()
        self.assertTrue(defend_report.player_dodged)
        player.stats.dodge = 0.0
        attack_report = engine.player_attack()
        self.assertTrue(any("DRAPIEŻNY ODRUCH" in note for note in attack_report.class_effect_notes))

    def test_mage_mana_tide_refunds_five_after_twenty_mana_spent(self) -> None:
        player = self._player_with_item(PlayerClass.MAGE, "black_sea_amulet")
        # v0.23: zaklęcia Maga wymagają kostura. Stare przedmioty klasowe
        # pozostają kompatybilne, ale aktywne skille korzystają już z tożsamości broni.
        player.inventory.add_equipment_instance(create_equipment_item("apprentice_staff"))
        player.equip_from_inventory(len(player.inventory.equipment_items) - 1)
        player.stats.current_mana = player.stats.max_mana
        start_mana = player.stats.current_mana
        player.stats.max_hp = 999
        player.stats.current_hp = 999
        player.stats.defense = 100
        enemy = create_enemy("trial_wraith")
        enemy.max_hp = 999
        enemy.current_hp = 999
        enemy.attack = 0
        enemy.defense = 0
        enemy.dodge = 0.0
        engine = CombatEngine(player, enemy, HighRollRng())

        reports = [engine.player_use_skill("fire_bolt") for _ in range(4)]
        self.assertEqual(player.stats.current_mana, start_mana - 19)
        self.assertTrue(any("PRZYPŁYW MANY" in note for r in reports for note in r.class_effect_notes))


if __name__ == "__main__":
    unittest.main()
