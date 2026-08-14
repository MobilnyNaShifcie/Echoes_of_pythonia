import random
import unittest

from enemies.factory import create_enemy


class EnemyRewardTests(unittest.TestCase):
    def test_fixed_gold_reward_is_exact(self) -> None:
        enemy = create_enemy("wild_dog")
        reward = enemy.roll_gold_reward(random.Random(1))

        self.assertEqual(reward, 5)

    def test_miniboss_reward_stays_inside_range(self) -> None:
        enemy = create_enemy("nature_guardian")
        rng = random.Random(7)

        for _ in range(20):
            reward = enemy.roll_gold_reward(rng)
            self.assertGreaterEqual(reward, 100)
            self.assertLessEqual(reward, 180)
