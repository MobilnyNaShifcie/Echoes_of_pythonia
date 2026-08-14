import unittest

from game.config import INN_REST_DURATION_HOURS
from player.factory import create_player
from systems.inn import inn_rest_cost, rest_at_inn
from world.time_system import GameClock


class InnTests(unittest.TestCase):
    def test_inn_restores_player_and_advances_time(self) -> None:
        player = create_player("Tester")
        cost = inn_rest_cost(player)
        player.gold = cost + 50
        player.stats.current_hp = 5
        clock = GameClock(day=1, hour=20)
        result = rest_at_inn(player, clock)
        self.assertEqual(player.gold, 50)
        self.assertEqual(result.gold_cost, cost)
        self.assertEqual(player.stats.current_hp, player.stats.max_hp)
        self.assertEqual(clock.hour, (20 + INN_REST_DURATION_HOURS) % 24)
        self.assertEqual(clock.day, 2)
        self.assertEqual(result.next_available_day, 3)

    def test_full_health_prevents_unnecessary_paid_rest(self) -> None:
        player = create_player("Tester")
        player.gold = 100
        clock = GameClock()
        with self.assertRaises(ValueError):
            rest_at_inn(player, clock)
        self.assertEqual(player.gold, 100)


if __name__ == "__main__":
    unittest.main()
