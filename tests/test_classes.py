import unittest

from player.classes import PlayerClass
from player.factory import create_player


class PlayerClassTests(unittest.TestCase):
    def test_class_is_locked_before_level_five(self) -> None:
        player = create_player("Tester")
        player.level = 4

        with self.assertRaises(ValueError):
            player.choose_class(PlayerClass.WARRIOR)

        self.assertEqual(player.character_class, PlayerClass.NONE)

    def test_level_five_can_choose_class(self) -> None:
        player = create_player("Tester")
        player.level = 5

        player.choose_class(PlayerClass.WARRIOR)

        self.assertEqual(player.character_class, PlayerClass.WARRIOR)
        self.assertEqual(player.stats.max_mana, 12)
        self.assertEqual(player.stats.current_mana, 12)

    def test_class_choice_is_permanent(self) -> None:
        player = create_player("Tester")
        player.level = 5
        player.choose_class(PlayerClass.HUNTER)

        with self.assertRaises(ValueError):
            player.choose_class(PlayerClass.MAGE)

        self.assertEqual(player.character_class, PlayerClass.HUNTER)

    def test_class_base_mana_adds_to_intelligence_mana(self) -> None:
        player = create_player("Tester")
        player.level = 5
        player.attributes.intelligence = 3
        player.recalculate_stats()

        player.choose_class(PlayerClass.MAGE)

        self.assertEqual(player.stats.max_mana, 52)
        self.assertEqual(player.stats.current_mana, 52)


if __name__ == "__main__":
    unittest.main()
