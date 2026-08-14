from dataclasses import dataclass

from data.upgrades import (
    BASE_UPGRADE_GOLD_COSTS,
    ITEM_POWER_GOLD_MULTIPLIER,
    UPGRADE_MATERIAL_PROFILE_BY_ITEM_POWER,
)
from game.config import MAX_UPGRADE_LEVEL
from items.catalog import get_item_definition
from items.models import EquipmentItem, EquipmentSlot
from player.player import Player


@dataclass(frozen=True)
class UpgradeCost:
    gold: int
    materials: dict[str, int]


@dataclass(frozen=True)
class UpgradeTarget:
    item: EquipmentItem
    source: str
    slot: EquipmentSlot | None = None


@dataclass(frozen=True)
class UpgradePlan:
    start_level: int
    target_level: int
    gold: int
    materials: dict[str, int]

    @property
    def levels(self) -> int:
        return self.target_level - self.start_level


def _normalize_item_power(item: EquipmentItem | None) -> int:
    if item is None:
        # Zachowuje kompatybilność wywołań pomocniczych bez konkretnego itemu.
        return 1
    return max(1, int(item.item_power))


def _gold_multiplier(item_power: int) -> float:
    if item_power in ITEM_POWER_GOLD_MULTIPLIER:
        return ITEM_POWER_GOLD_MULTIPLIER[item_power]
    highest = max(ITEM_POWER_GOLD_MULTIPLIER)
    if item_power > highest:
        # Przyszłe IP rośnie przewidywalnie nawet przed dodaniem własnego profilu.
        return ITEM_POWER_GOLD_MULTIPLIER[highest] + 0.35 * (item_power - highest)
    return 1.0


def _round_gold(value: float) -> int:
    return max(25, int(round(value / 25.0)) * 25)


def _material_profile(item_power: int) -> dict[str, str]:
    if item_power in UPGRADE_MATERIAL_PROFILE_BY_ITEM_POWER:
        return UPGRADE_MATERIAL_PROFILE_BY_ITEM_POWER[item_power]
    highest = max(UPGRADE_MATERIAL_PROFILE_BY_ITEM_POWER)
    return UPGRADE_MATERIAL_PROFILE_BY_ITEM_POWER[highest]


def _add_material(materials: dict[str, int], item_id: str, quantity: int) -> None:
    if quantity <= 0:
        return
    materials[item_id] = materials.get(item_id, 0) + quantity


def get_upgrade_cost(
    current_level: int,
    item: EquipmentItem | None = None,
) -> UpgradeCost:
    """Koszt przejścia z current_level na current_level + 1.

    +0..+3 opierają się wyłącznie na materiałach dostępnych w sklepie.
    Od +4 wymagane są materiały regionu, od +8 materiały mocniejszych
    przeciwników, a +10 wymaga trofeum głównego bossa danego etapu.
    """
    if not 0 <= current_level < MAX_UPGRADE_LEVEL:
        raise ValueError("Tego poziomu nie można dalej ulepszyć.")

    item_power = _normalize_item_power(item)
    profile = _material_profile(item_power)
    materials: dict[str, int] = {}

    # Podstawowe materiały pozostają kupowalne, ale przestają wystarczać
    # do maksymalnego rozwinięcia przedmiotu.
    if current_level == 0:
        _add_material(materials, "whetstone", 1)
    elif current_level == 1:
        _add_material(materials, "whetstone", 1)
    elif current_level == 2:
        _add_material(materials, "whetstone", 2)
    elif current_level == 3:
        _add_material(materials, "grinding_stone", 1)
        _add_material(materials, profile["regional"], 1)
    elif current_level == 4:
        _add_material(materials, "grinding_stone", 1)
        _add_material(materials, profile["regional"], 2)
    elif current_level == 5:
        _add_material(materials, "grinding_stone", 2)
        _add_material(materials, profile["regional"], 2)
        _add_material(materials, "common_essence", 1)
    elif current_level == 6:
        _add_material(materials, "grinding_stone", 2)
        _add_material(materials, profile["regional"], 3)
        _add_material(materials, "common_essence", 2)
    elif current_level == 7:
        _add_material(materials, "grinding_stone", 2)
        _add_material(materials, profile["regional"], 2)
        _add_material(materials, profile["elite"], 1)
    elif current_level == 8:
        _add_material(materials, "grinding_stone", 3)
        _add_material(materials, profile["regional"], 2)
        _add_material(materials, profile["elite"], 2)
    elif current_level == 9:
        _add_material(materials, "grinding_stone", 4)
        _add_material(materials, profile["elite"], 1)
        _add_material(materials, profile["boss"], 1)

    base_gold = BASE_UPGRADE_GOLD_COSTS[current_level]
    gold = _round_gold(base_gold * _gold_multiplier(item_power))
    return UpgradeCost(gold=gold, materials=materials)


def get_upgrade_plan(
    current_level: int,
    levels: int,
    item: EquipmentItem | None = None,
) -> UpgradePlan:
    """Zwraca łączny koszt kilku kolejnych ulepszeń bez modyfikacji stanu."""
    if not 0 <= current_level <= MAX_UPGRADE_LEVEL:
        raise ValueError("Nieprawidłowy poziom ulepszenia.")
    if levels <= 0:
        raise ValueError("Liczba poziomów musi być dodatnia.")
    if current_level + levels > MAX_UPGRADE_LEVEL:
        raise ValueError(
            f"Przedmiot można ulepszyć maksymalnie do +{MAX_UPGRADE_LEVEL}."
        )

    gold = 0
    materials: dict[str, int] = {}
    for level in range(current_level, current_level + levels):
        cost = get_upgrade_cost(level, item)
        gold += cost.gold
        for item_id, quantity in cost.materials.items():
            materials[item_id] = materials.get(item_id, 0) + quantity

    return UpgradePlan(
        start_level=current_level,
        target_level=current_level + levels,
        gold=gold,
        materials=materials,
    )


def can_afford_upgrade_plan(player: Player, plan: UpgradePlan) -> bool:
    if player.gold < plan.gold:
        return False
    return all(
        player.inventory.has(item_id, quantity)
        for item_id, quantity in plan.materials.items()
    )


def max_affordable_upgrade_levels(
    player: Player,
    item: EquipmentItem,
) -> int:
    """Maksymalna liczba kolejnych poziomów możliwa teraz do wykonania."""
    remaining = MAX_UPGRADE_LEVEL - item.upgrade_level
    affordable = 0

    for levels in range(1, remaining + 1):
        plan = get_upgrade_plan(item.upgrade_level, levels, item)
        if not can_afford_upgrade_plan(player, plan):
            break
        affordable = levels

    return affordable


def upgrade_item_levels(
    player: Player,
    item: EquipmentItem,
    levels: int,
) -> UpgradePlan:
    """Ulepsza przedmiot o kilka poziomów w jednej atomowej operacji."""
    if item.upgrade_level >= MAX_UPGRADE_LEVEL:
        raise ValueError("Przedmiot osiągnął już poziom +10.")

    plan = get_upgrade_plan(item.upgrade_level, levels, item)

    if player.gold < plan.gold:
        raise ValueError(
            f"Brakuje golda. Potrzeba {plan.gold}, masz {player.gold}."
        )

    for item_id, quantity in plan.materials.items():
        if not player.inventory.has(item_id, quantity):
            material_name = get_item_definition(item_id).name
            owned = player.inventory.count(item_id)
            raise ValueError(
                f"Brakuje materiału: {material_name} "
                f"{owned}/{quantity}."
            )

    # Dopiero po pełnej walidacji pobieramy cały koszt.
    for item_id, quantity in plan.materials.items():
        player.inventory.remove_item(item_id, quantity)
    player.gold -= plan.gold
    item.upgrade_level = plan.target_level
    player.recalculate_stats()
    return plan


def get_upgrade_targets(player: Player) -> list[UpgradeTarget]:
    targets: list[UpgradeTarget] = []

    for slot, item in player.equipment.slots.items():
        targets.append(
            UpgradeTarget(
                item=item,
                source="Założone",
                slot=slot,
            )
        )

    for item in player.inventory.equipment_items:
        targets.append(
            UpgradeTarget(
                item=item,
                source="Plecak",
                slot=None,
            )
        )

    return targets


def can_upgrade(player: Player, item: EquipmentItem) -> bool:
    if item.upgrade_level >= MAX_UPGRADE_LEVEL:
        return False
    plan = get_upgrade_plan(item.upgrade_level, 1, item)
    return can_afford_upgrade_plan(player, plan)


def upgrade_item(player: Player, item: EquipmentItem) -> None:
    """Kompatybilny wrapper: ulepsza przedmiot o dokładnie jeden poziom."""
    upgrade_item_levels(player, item, 1)
