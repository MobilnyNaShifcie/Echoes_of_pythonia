from dataclasses import dataclass
from enum import Enum

from game.config import STARTING_DAY, STARTING_HOUR


class TimePeriod(Enum):
    DAY = "day"
    NIGHT = "night"

    @property
    def display_name(self) -> str:
        if self is TimePeriod.DAY:
            return "DZIEŃ"
        return "NOC"


@dataclass
class GameClock:
    """Prosty zegar świata sterowany akcjami gracza.

    Jedna wyprawa przesuwa czas o godzinę. Dzięki temu dzień i noc
    są częścią decyzji gracza, a nie wymagają czekania w czasie realnym.
    """

    day: int = STARTING_DAY
    hour: int = STARTING_HOUR

    @property
    def period(self) -> TimePeriod:
        if 6 <= self.hour < 18:
            return TimePeriod.DAY
        return TimePeriod.NIGHT

    def advance(self, hours: int = 1) -> None:
        if hours < 0:
            raise ValueError("Nie można cofać czasu przez advance().")

        total_hours = self.hour + hours
        passed_days, self.hour = divmod(total_hours, 24)
        self.day += passed_days

    def formatted_time(self) -> str:
        return f"Dzień {self.day} | {self.hour:02d}:00"
