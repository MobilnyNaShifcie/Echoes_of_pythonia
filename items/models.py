from dataclasses import dataclass, field
from enum import Enum
from uuid import uuid4

from combat.elements import ElementalResistances
from game.config import MAX_UPGRADE_LEVEL


class ItemCategory(Enum):
    MATERIAL = "material"
    CONSUMABLE = "consumable"
    EQUIPMENT = "equipment"
    KEY = "key"
    BOOK = "book"


class ItemRarity(Enum):
    COMMON = ("common", "Zwykły")
    UNCOMMON = ("uncommon", "Niezwykły")
    RARE = ("rare", "Rzadki")
    EPIC = ("epic", "Epicki")
    LEGENDARY = ("legendary", "Legendarny")
    MYTHIC = ("mythic", "Mityczny")

    def __init__(self, code: str, display_name: str) -> None:
        self.code = code
        self.display_name = display_name


class EquipmentSlot(Enum):
    WEAPON = ("weapon", "Broń")
    HEAD = ("head", "Hełm")
    CHEST = ("chest", "Zbroja")
    HANDS = ("hands", "Rękawice")
    FEET = ("feet", "Buty")
    BELT = ("belt", "Pas")
    NECKLACE = ("necklace", "Naszyjnik")
    BRACELET = ("bracelet", "Bransoleta")
    EARRINGS = ("earrings", "Kolczyki")
    RING = ("ring", "Pierścień")
    OFF_HAND = ("off_hand", "Druga ręka")

    def __init__(self, code: str, display_name: str) -> None:
        self.code = code
        self.display_name = display_name


class EquipmentRole(Enum):
    DEFENSIVE = ("defensive", "Defensywny")
    OFFENSIVE = ("offensive", "Ofensywny")
    MIXED = ("mixed", "Mieszany")

    def __init__(self, code: str, display_name: str) -> None:
        self.code = code
        self.display_name = display_name


_DEFENSIVE_SLOTS = {
    EquipmentSlot.HEAD,
    EquipmentSlot.CHEST,
    EquipmentSlot.HANDS,
    EquipmentSlot.FEET,
}

_OFFENSIVE_SLOTS = {
    EquipmentSlot.WEAPON,
    EquipmentSlot.NECKLACE,
    EquipmentSlot.BRACELET,
    EquipmentSlot.EARRINGS,
    EquipmentSlot.RING,
}


def equipment_role_for_slot(slot: EquipmentSlot) -> EquipmentRole:
    if slot in _DEFENSIVE_SLOTS:
        return EquipmentRole.DEFENSIVE
    if slot in _OFFENSIVE_SLOTS:
        return EquipmentRole.OFFENSIVE
    if slot in {EquipmentSlot.BELT, EquipmentSlot.OFF_HAND}:
        return EquipmentRole.MIXED
    raise ValueError(f"Slot {slot} nie ma przypisanej roli wyposażenia.")


@dataclass(frozen=True)
class ItemDefinition:
    item_id: str
    name: str
    description: str
    category: ItemCategory
    rarity: ItemRarity
    stackable: bool
    slot: EquipmentSlot | None = None
    item_power: int = 0
    required_level: int = 0
    attack: int = 0
    defense: int = 0
    max_hp: int = 0
    dodge: float = 0.0
    max_mana: int = 0
    magic_power: int = 0
    heal_hp: int = 0
    heal_hp_percent: float = 0.0
    restore_mana: int = 0
    restore_mana_percent: float = 0.0
    set_id: str | None = None
    class_effect_id: str | None = None
    equipment_type: str | None = None
    required_class_code: str | None = None
    required_class_name: str | None = None
    class_bonus_class_code: str | None = None
    class_bonus_attack: int = 0
    class_bonus_defense: int = 0
    class_bonus_max_hp: int = 0
    class_bonus_max_mana: int = 0
    class_bonus_dodge: float = 0.0
    resistances: ElementalResistances = ElementalResistances()

    @property
    def is_equipment(self) -> bool:
        return self.category is ItemCategory.EQUIPMENT

    @property
    def is_consumable(self) -> bool:
        return self.category is ItemCategory.CONSUMABLE

    @property
    def is_key(self) -> bool:
        return self.category is ItemCategory.KEY

    @property
    def is_book(self) -> bool:
        return self.category is ItemCategory.BOOK

    @property
    def equipment_role(self) -> EquipmentRole | None:
        if self.slot is None:
            return None
        return equipment_role_for_slot(self.slot)


@dataclass(frozen=True)
class AffixRoll:
    affix_id: str
    tier: int
    value: float

    def __post_init__(self) -> None:
        if not 1 <= self.tier <= 5:
            raise ValueError("Tier bonusu musi mieścić się w zakresie T1-T5.")
        if self.value <= 0:
            raise ValueError("Wartość bonusu musi być dodatnia.")


@dataclass
class EquipmentItem:
    item_id: str
    upgrade_level: int = 0
    instance_id: str = ""
    item_power: int = 0
    affixes: list[AffixRoll] = field(default_factory=list)
    average_damage_percent: int | None = None

    def __post_init__(self) -> None:
        if not 0 <= self.upgrade_level <= MAX_UPGRADE_LEVEL:
            raise ValueError(
                f"Poziom ulepszenia musi mieścić się w zakresie 0-{MAX_UPGRADE_LEVEL}."
            )
        if self.item_power < 0:
            raise ValueError("Item Power nie może być ujemny.")
        if (
            self.average_damage_percent is not None
            and not -100 < self.average_damage_percent < 100
        ):
            raise ValueError(
                "Średnie Obrażenia muszą mieścić się między -99% a +99%."
            )
        if len({affix.affix_id for affix in self.affixes}) != len(self.affixes):
            raise ValueError("Ten sam bonus nie może wystąpić na przedmiocie dwa razy.")
        if not self.instance_id:
            self.instance_id = uuid4().hex
