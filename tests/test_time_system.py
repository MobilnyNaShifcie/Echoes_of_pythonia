import unittest

from world.time_system import GameClock, TimePeriod


class GameClockTests(unittest.TestCase):
    def test_day_changes_to_night_at_18(self) -> None:
        clock = GameClock(day=1, hour=17)

        self.assertEqual(clock.period, TimePeriod.DAY)
        clock.advance(1)

        self.assertEqual(clock.hour, 18)
        self.assertEqual(clock.period, TimePeriod.NIGHT)

    def test_night_changes_to_day_at_6(self) -> None:
        clock = GameClock(day=2, hour=5)

        self.assertEqual(clock.period, TimePeriod.NIGHT)
        clock.advance(1)

        self.assertEqual(clock.hour, 6)
        self.assertEqual(clock.period, TimePeriod.DAY)

    def test_midnight_advances_day_number(self) -> None:
        clock = GameClock(day=3, hour=23)
        clock.advance(1)

        self.assertEqual(clock.day, 4)
        self.assertEqual(clock.hour, 0)
