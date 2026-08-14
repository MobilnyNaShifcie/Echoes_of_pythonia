import unittest

from game.config import ATTRIBUTE_POINTS_PER_LEVEL
from player.factory import create_player


class ProgressionTests(unittest.TestCase):
    def test_remaining_exp_at_start(self) -> None:
        player = create_player("Tester")
        self.assertEqual(player.experience_remaining_to_next_level(), 50)

    def test_remaining_exp_after_gain(self) -> None:
        player = create_player("Tester")
        player.gain_experience(14)
        self.assertEqual(player.experience_remaining_to_next_level(), 36)

    def test_level_up_grants_attribute_points(self) -> None:
        player = create_player("Tester")

        levels_gained = player.gain_experience(50)

        self.assertEqual(levels_gained, 1)
        self.assertEqual(player.level, 1)
        self.assertEqual(
            player.unspent_attribute_points,
            ATTRIBUTE_POINTS_PER_LEVEL,
        )
