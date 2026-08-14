from dataclasses import dataclass
from enum import Enum

from game.config import (
    DEXTERITY_DODGE_PER_POINT,
    ENDURANCE_POINTS_PER_DEFENSE,
    INTELLIGENCE_MANA_PER_POINT,
    STRENGTH_ATTACK_PER_POINT,
    VITALITY_HP_PER_POINT,
)


class AttributeType(Enum):
    STRENGTH = ("strength", "Siła")
    VITALITY = ("vitality", "Witalność")
    INTELLIGENCE = ("intelligence", "Inteligencja")
    DEXTERITY = ("dexterity", "Zręczność")
    ENDURANCE = ("endurance", "Wytrzymałość")
    LUCK = ("luck", "Szczęście")

    def __init__(self, code: str, display_name: str) -> None:
        self.code = code
        self.display_name = display_name


@dataclass
class Attributes:
    """Podstawowe atrybuty rozwijane przez gracza."""

    strength: int = 0
    vitality: int = 0
    intelligence: int = 0
    dexterity: int = 0
    endurance: int = 0
    luck: int = 0

    def get(self, attribute: AttributeType) -> int:
        return int(getattr(self, attribute.code))

    def increase(self, attribute: AttributeType, amount: int = 1) -> None:
        if amount <= 0:
            raise ValueError("Wzrost atrybutu musi być dodatni.")

        current = self.get(attribute)
        setattr(self, attribute.code, current + amount)

    def as_dict(self) -> dict[str, int]:
        return {
            attribute.display_name: self.get(attribute)
            for attribute in AttributeType
        }


@dataclass(frozen=True)
class AttributeBonuses:
    attack: int = 0
    max_hp: int = 0
    max_mana: int = 0
    dodge: float = 0.0
    defense: int = 0


def calculate_attribute_bonuses(
    attributes: Attributes,
) -> AttributeBonuses:
    """Przelicza atrybuty na statystyki używane przez bohatera."""
    return AttributeBonuses(
        attack=attributes.strength * STRENGTH_ATTACK_PER_POINT,
        max_hp=attributes.vitality * VITALITY_HP_PER_POINT,
        max_mana=(
            attributes.intelligence * INTELLIGENCE_MANA_PER_POINT
        ),
        dodge=attributes.dexterity * DEXTERITY_DODGE_PER_POINT,
        defense=(
            attributes.endurance // ENDURANCE_POINTS_PER_DEFENSE
        ),
    )


def attribute_effect_description(attribute: AttributeType) -> str:
    if attribute is AttributeType.STRENGTH:
        return f"+{STRENGTH_ATTACK_PER_POINT} ATK i +0.5 kg udźwigu za punkt"

    if attribute is AttributeType.VITALITY:
        return f"+{VITALITY_HP_PER_POINT} maks. HP za punkt"

    if attribute is AttributeType.INTELLIGENCE:
        return f"+{INTELLIGENCE_MANA_PER_POINT} maks. Many za punkt"

    if attribute is AttributeType.LUCK:
        return "wzmacnia Kości Losu i Żetony Losu Pierrota"

    if attribute is AttributeType.DEXTERITY:
        return f"+{DEXTERITY_DODGE_PER_POINT:.1f}% Uniku za punkt"

    return (
        f"+1 DEF za każde {ENDURANCE_POINTS_PER_DEFENSE} punkty; "
        "+1.5 kg udźwigu za punkt"
    )
