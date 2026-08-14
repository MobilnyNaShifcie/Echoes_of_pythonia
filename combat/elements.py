from dataclasses import dataclass
from enum import Enum

from game.config import MAX_ELEMENTAL_RESISTANCE


class DamageType(Enum):
    PHYSICAL = ("physical", "Fizyczne")
    FIRE = ("fire", "Ogień")
    WIND = ("wind", "Wiatr")
    FROST = ("frost", "Mróz")
    EARTH = ("earth", "Ziemia")
    WATER = ("water", "Woda")

    def __init__(self, code: str, display_name: str) -> None:
        self.code = code
        self.display_name = display_name


_ELEMENTAL_TYPES = (
    DamageType.FIRE,
    DamageType.WIND,
    DamageType.FROST,
    DamageType.EARTH,
    DamageType.WATER,
)


@dataclass(frozen=True)
class ElementalResistances:
    fire: int = 0
    wind: int = 0
    frost: int = 0
    earth: int = 0
    water: int = 0

    def get(self, damage_type: DamageType) -> int:
        if damage_type is DamageType.PHYSICAL:
            return 0
        return int(getattr(self, damage_type.code))

    def as_dict(self) -> dict[str, int]:
        return {
            damage_type.display_name: self.get(damage_type)
            for damage_type in _ELEMENTAL_TYPES
        }

    def clamped(self) -> "ElementalResistances":
        def clamp(value: int) -> int:
            return max(0, min(int(value), MAX_ELEMENTAL_RESISTANCE))

        return ElementalResistances(
            fire=clamp(self.fire),
            wind=clamp(self.wind),
            frost=clamp(self.frost),
            earth=clamp(self.earth),
            water=clamp(self.water),
        )

    def add(self, other: "ElementalResistances") -> "ElementalResistances":
        return ElementalResistances(
            fire=self.fire + other.fire,
            wind=self.wind + other.wind,
            frost=self.frost + other.frost,
            earth=self.earth + other.earth,
            water=self.water + other.water,
        ).clamped()


def apply_elemental_resistance(
    damage: int,
    damage_type: DamageType,
    resistances: ElementalResistances,
) -> int:
    if damage <= 0 or damage_type is DamageType.PHYSICAL:
        return max(0, damage)

    resistance = resistances.get(damage_type)
    reduced = int(damage * (1.0 - resistance / 100.0))
    return max(1, reduced)


def damage_type_from_code(code: str | None) -> DamageType:
    if code is None:
        return DamageType.PHYSICAL

    for damage_type in DamageType:
        if damage_type.code == code:
            return damage_type

    raise ValueError(f"Nieznany typ obrażeń: {code}")
