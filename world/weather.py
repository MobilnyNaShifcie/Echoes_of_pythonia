from dataclasses import dataclass
from enum import Enum
import random

from game.config import WEATHER_DURATION_HOURS


class WeatherType(Enum):
    SUNNY = ("sunny", "SŁONECZNIE")
    STORM = ("storm", "BURZA")
    FROST = ("frost", "MRÓZ")
    WIND = ("wind", "WICHURA")
    AURORA = ("aurora", "ZORZA POLARNA")

    def __init__(self, code: str, display_name: str) -> None:
        self.code = code
        self.display_name = display_name


WEATHER_WEIGHTS: tuple[tuple[WeatherType, int], ...] = (
    (WeatherType.SUNNY, 30),
    (WeatherType.STORM, 20),
    (WeatherType.FROST, 20),
    (WeatherType.WIND, 20),
    (WeatherType.AURORA, 10),
)


@dataclass
class WeatherState:
    current: WeatherType = WeatherType.SUNNY
    remaining_hours: int = WEATHER_DURATION_HOURS


def roll_weather(rng: random.Random) -> WeatherType:
    weathers = [weather for weather, _ in WEATHER_WEIGHTS]
    weights = [weight for _, weight in WEATHER_WEIGHTS]
    return rng.choices(weathers, weights=weights, k=1)[0]


def create_initial_weather(rng: random.Random) -> WeatherState:
    return WeatherState(
        current=roll_weather(rng),
        remaining_hours=WEATHER_DURATION_HOURS,
    )


def advance_weather(
    state: WeatherState,
    hours: int,
    rng: random.Random,
) -> list[tuple[WeatherType, WeatherType]]:
    if hours < 0:
        raise ValueError("Nie można cofać czasu pogody.")

    changes: list[tuple[WeatherType, WeatherType]] = []
    remaining = hours

    while remaining > 0:
        if remaining < state.remaining_hours:
            state.remaining_hours -= remaining
            break

        remaining -= state.remaining_hours
        old = state.current
        state.current = roll_weather(rng)
        state.remaining_hours = WEATHER_DURATION_HOURS
        changes.append((old, state.current))

    return changes


def weather_from_code(code: str) -> WeatherType:
    for weather in WeatherType:
        if weather.code == code:
            return weather
    raise ValueError(f"Nieznana pogoda: {code}")
