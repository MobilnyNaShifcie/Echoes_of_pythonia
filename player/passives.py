from dataclasses import dataclass
from enum import Enum

from game.config import (
    BASE_CRITICAL_CHANCE,
    BASIC_PASSIVE_LEVEL,
    MAX_PASSIVE_LEVEL,
    PASSIVE_POINT_EVERY_LEVELS,
)


class PassiveType(Enum):
    ATTACK_SPEED = ("attack_speed", "Szybkość ataku")
    CRITICAL_DAMAGE = ("critical_damage", "Obrażenia krytyczne")
    HEALTH_REGEN = ("health_regen", "Regeneracja zdrowia")
    INCREASED_ATTACK = ("increased_attack", "Zwiększenie ataku")

    def __init__(self, code: str, display_name: str) -> None:
        self.code = code
        self.display_name = display_name


@dataclass
class Passives:
    attack_speed: int = 0
    critical_damage: int = 0
    health_regen: int = 0
    increased_attack: int = 0

    def get(self, passive: PassiveType) -> int:
        return int(getattr(self, passive.code))

    def increase(
        self,
        passive: PassiveType,
        amount: int = 1,
        *,
        max_level: int = BASIC_PASSIVE_LEVEL,
    ) -> None:
        if amount <= 0:
            raise ValueError("Liczba punktów musi być większa od zera.")

        current = self.get(passive)
        target_level = current + amount

        if target_level > max_level:
            raise ValueError(
                f"Ta umiejętność może mieć obecnie maksymalnie poziom "
                f"{max_level}."
            )

        setattr(self, passive.code, target_level)

    @property
    def spent_points(self) -> int:
        return sum(self.get(passive) for passive in PassiveType)

    def as_dict(self) -> dict[str, int]:
        return {
            passive.display_name: self.get(passive)
            for passive in PassiveType
        }


def total_passive_points_for_level(level: int) -> int:
    return max(0, level // PASSIVE_POINT_EVERY_LEVELS)


def available_passive_points(level: int, passives: Passives) -> int:
    return max(0, total_passive_points_for_level(level) - passives.spent_points)


def attack_speed_extra_hit_chance(passives: Passives) -> float:
    level = passives.attack_speed
    if level <= BASIC_PASSIVE_LEVEL:
        return level * 5.0
    return BASIC_PASSIVE_LEVEL * 5.0 + (level - BASIC_PASSIVE_LEVEL) * 2.0


def critical_chance(passives: Passives) -> float:
    level = passives.critical_damage
    if level <= 0:
        return 0.0
    # 1-5: 5-9%, mistrzostwo 6-10: 10-14%.
    return BASE_CRITICAL_CHANCE + level - 1


def critical_multiplier(passives: Passives) -> float:
    level = passives.critical_damage
    if level <= BASIC_PASSIVE_LEVEL:
        return 1.5 + level * 0.25
    # Po 5/5 przyrost jest łagodniejszy: x2.80 ... x3.00.
    return 2.75 + (level - BASIC_PASSIVE_LEVEL) * 0.05


def health_regeneration_per_turn(passives: Passives) -> int:
    level = passives.health_regen
    if level <= BASIC_PASSIVE_LEVEL:
        return level * 3
    return BASIC_PASSIVE_LEVEL * 3 + (level - BASIC_PASSIVE_LEVEL) * 4


def passive_attack_bonus(passives: Passives) -> int:
    level = passives.increased_attack
    if level <= BASIC_PASSIVE_LEVEL:
        return level * 2
    return BASIC_PASSIVE_LEVEL * 2 + (level - BASIC_PASSIVE_LEVEL) * 3


def passive_effect_description(passive: PassiveType, level: int) -> str:
    preview = Passives()
    setattr(preview, passive.code, level)
    if passive is PassiveType.ATTACK_SPEED:
        return f"{attack_speed_extra_hit_chance(preview):.0f}% szansy na dodatkowe uderzenie"
    if passive is PassiveType.CRITICAL_DAMAGE:
        if level == 0:
            return "odblokowuje krytyki; potem zwiększa ich szansę i obrażenia"
        return (
            f"{critical_chance(preview):.0f}% szansy na krytyk, "
            f"mnożnik x{critical_multiplier(preview):.2f}"
        )
    if passive is PassiveType.HEALTH_REGEN:
        return f"+{health_regeneration_per_turn(preview)} HP regeneracji po turze przeciwnika"
    return f"+{passive_attack_bonus(preview)} ATK"
