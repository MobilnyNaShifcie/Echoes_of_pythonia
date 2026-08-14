import unittest

from player.attributes import AttributeType
from player.factory import create_player


class AttributeTests(unittest.TestCase):
    def test_strength_increases_attack(self) -> None:
        player = create_player("Tester")
        player.unspent_attribute_points = 1

        player.spend_attribute_point(AttributeType.STRENGTH)

        self.assertEqual(player.attributes.strength, 1)
        self.assertEqual(player.stats.attack, 4)
        self.assertEqual(player.unspent_attribute_points, 0)

    def test_vitality_increases_max_hp_without_healing(self) -> None:
        player = create_player("Tester")
        player.stats.current_hp = 10
        player.unspent_attribute_points = 1

        player.spend_attribute_point(AttributeType.VITALITY)

        self.assertEqual(player.stats.max_hp, 25)
        self.assertEqual(player.stats.current_hp, 10)

    def test_intelligence_increases_max_mana(self) -> None:
        player = create_player("Tester")
        player.unspent_attribute_points = 2

        player.spend_attribute_point(AttributeType.INTELLIGENCE)
        player.spend_attribute_point(AttributeType.INTELLIGENCE)

        self.assertEqual(player.stats.max_mana, 10)
        self.assertEqual(player.stats.current_mana, 0)

    def test_dexterity_increases_dodge(self) -> None:
        player = create_player("Tester")
        player.unspent_attribute_points = 2

        player.spend_attribute_point(AttributeType.DEXTERITY)
        player.spend_attribute_point(AttributeType.DEXTERITY)

        self.assertEqual(player.stats.dodge, 3.0)

    def test_endurance_gives_one_defense_every_two_points(self) -> None:
        player = create_player("Tester")
        player.unspent_attribute_points = 2

        player.spend_attribute_point(AttributeType.ENDURANCE)
        self.assertEqual(player.stats.defense, 2)

        player.spend_attribute_point(AttributeType.ENDURANCE)
        self.assertEqual(player.stats.defense, 3)

    def test_cannot_spend_without_free_points(self) -> None:
        player = create_player("Tester")

        with self.assertRaises(ValueError):
            player.spend_attribute_point(AttributeType.STRENGTH)

    def test_can_spend_multiple_attribute_points_at_once(self) -> None:
        player = create_player("Tester")
        player.unspent_attribute_points = 5

        player.spend_attribute_points(AttributeType.STRENGTH, 3)

        self.assertEqual(player.attributes.strength, 3)
        self.assertEqual(player.unspent_attribute_points, 2)
        self.assertEqual(player.stats.attack, 6)

    def test_bulk_attribute_spend_is_atomic_when_amount_is_too_high(self) -> None:
        player = create_player("Tester")
        player.unspent_attribute_points = 2

        with self.assertRaises(ValueError):
            player.spend_attribute_points(AttributeType.VITALITY, 3)

        self.assertEqual(player.attributes.vitality, 0)
        self.assertEqual(player.unspent_attribute_points, 2)
        self.assertEqual(player.stats.max_hp, 20)
