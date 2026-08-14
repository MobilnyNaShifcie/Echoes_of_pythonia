from __future__ import annotations

from dataclasses import dataclass

from items.catalog import get_item_definition
from items.models import EquipmentSlot, ItemCategory, EquipmentItem
from player.inventory import Inventory


BASE_CARRY_CAPACITY_KG = 50.0
STRENGTH_CARRY_KG_PER_POINT = 0.5
ENDURANCE_CARRY_KG_PER_POINT = 1.5

# Poziom 0 oznacza brak ulepszenia. Każdy kolejny poziom zastępuje
# poprzedni bonus, zamiast dodawać go ponownie.
CARRY_UPGRADE_BONUSES_KG: tuple[float, ...] = (0.0, 10.0, 20.0, 35.0)
CARRY_UPGRADE_COSTS_GOLD: tuple[int, ...] = (0, 8_000, 18_000, 35_000)
CARRY_UPGRADE_REQUIRED_RANKS: tuple[str, ...] = ("F", "E", "D", "C")
CARRY_UPGRADE_NAMES: tuple[str, ...] = (
    "Brak ulepszenia",
    "Plecak Poszukiwacza I",
    "Plecak Poszukiwacza II",
    "Plecak Poszukiwacza III",
)

_EQUIPMENT_SLOT_WEIGHT_KG: dict[EquipmentSlot, float] = {
    EquipmentSlot.WEAPON: 3.5,
    EquipmentSlot.HEAD: 2.0,
    EquipmentSlot.CHEST: 6.0,
    EquipmentSlot.HANDS: 1.0,
    EquipmentSlot.FEET: 1.5,
    EquipmentSlot.BELT: 0.5,
    EquipmentSlot.NECKLACE: 0.2,
    EquipmentSlot.BRACELET: 0.2,
    EquipmentSlot.EARRINGS: 0.1,
    EquipmentSlot.RING: 0.1,
    EquipmentSlot.OFF_HAND: 2.0,
}

_EQUIPMENT_TYPE_WEIGHT_KG: dict[str, float] = {
    "sword": 3.5,
    "bow": 2.5,
    "staff": 3.0,
    "fate_lance": 4.0,
    "shield": 4.0,
    "quiver": 1.0,
    "artifact": 1.0,
    "fate_dice": 0.5,
    "fate_cards": 0.4,
}

_STACK_UNIT_WEIGHT_KG: dict[ItemCategory, float] = {
    ItemCategory.MATERIAL: 0.05,
    ItemCategory.CONSUMABLE: 0.30,
    ItemCategory.KEY: 0.20,
    ItemCategory.BOOK: 0.50,
}


@dataclass(frozen=True)
class CarryStatus:
    code: str
    display_name: str
    current_kg: float
    capacity_kg: float

    @property
    def ratio(self) -> float:
        if self.capacity_kg <= 0:
            return 0.0
        return self.current_kg / self.capacity_kg

    @property
    def overloaded(self) -> bool:
        return self.current_kg > self.capacity_kg + 1e-9


def item_unit_weight(item_id: str) -> float:
    definition = get_item_definition(item_id)
    if definition.is_equipment:
        if definition.equipment_type in _EQUIPMENT_TYPE_WEIGHT_KG:
            return _EQUIPMENT_TYPE_WEIGHT_KG[str(definition.equipment_type)]
        if definition.slot is None:
            return 1.0
        return _EQUIPMENT_SLOT_WEIGHT_KG[definition.slot]
    return _STACK_UNIT_WEIGHT_KG.get(definition.category, 0.0)


def stack_weight(item_id: str, quantity: int) -> float:
    """Łączna waga wskazanej liczby sztuk przedmiotu stackowalnego."""
    if quantity <= 0:
        return 0.0
    return round(item_unit_weight(item_id) * quantity, 2)


def equipment_weight(item: EquipmentItem) -> float:
    return item_unit_weight(item.item_id)


def inventory_weight(inventory: Inventory) -> float:
    total = 0.0
    for item_id, quantity in inventory.stacks.items():
        total += stack_weight(item_id, quantity)
    for item in inventory.equipment_items:
        total += equipment_weight(item)
    return round(total, 2)


def carry_capacity(player) -> float:
    upgrade_level = max(0, min(int(player.carry_upgrade_level), len(CARRY_UPGRADE_BONUSES_KG) - 1))
    return round(
        BASE_CARRY_CAPACITY_KG
        + player.attributes.strength * STRENGTH_CARRY_KG_PER_POINT
        + player.attributes.endurance * ENDURANCE_CARRY_KG_PER_POINT
        + CARRY_UPGRADE_BONUSES_KG[upgrade_level],
        2,
    )


def carry_status(player) -> CarryStatus:
    current = inventory_weight(player.inventory)
    capacity = carry_capacity(player)
    ratio = 0.0 if capacity <= 0 else current / capacity
    if current > capacity + 1e-9:
        code, name = "overloaded", "Przeciążony"
    elif ratio >= 0.75:
        code, name = "burdened", "Obciążony"
    else:
        code, name = "free", "Swobodny"
    return CarryStatus(code, name, current, capacity)


def next_carry_upgrade(player) -> tuple[int, str, float, int, str] | None:
    next_level = int(player.carry_upgrade_level) + 1
    if next_level >= len(CARRY_UPGRADE_BONUSES_KG):
        return None
    return (
        next_level,
        CARRY_UPGRADE_NAMES[next_level],
        CARRY_UPGRADE_BONUSES_KG[next_level],
        CARRY_UPGRADE_COSTS_GOLD[next_level],
        CARRY_UPGRADE_REQUIRED_RANKS[next_level],
    )
