import unittest

from combat.damage import apply_defend_reduction, calculate_damage


class DamageTests(unittest.TestCase):
    def test_attack_above_defense(self) -> None:
        self.assertEqual(calculate_damage(7, 2), 5)

    def test_successful_attack_has_minimum_one_damage(self) -> None:
        self.assertEqual(calculate_damage(0, 10), 1)

    def test_defend_can_block_one_damage(self) -> None:
        self.assertEqual(apply_defend_reduction(1), 0)


if __name__ == "__main__":
    unittest.main()
