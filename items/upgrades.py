from dataclasses import dataclass

from data.upgrades import UPGRADE_SCALING_PROGRESS, UPGRADE_STAT_MAX_BONUS
from game.config import MAX_UPGRADE_LEVEL
from items.catalog import get_item_definition
from items.models import EquipmentItem


@dataclass(frozen=True)
class UpgradedItemStats:
    attack: int = 0
    defense: int = 0
    max_hp: int = 0
    dodge: float = 0.0
    max_mana: int = 0
    magic_power: int = 0


def _scaled_integer_bonus(
    base_value: int,
    level: int,
    stat_name: str,
    legacy_bonus: int,
) -> int:
    if base_value <= 0:
        return 0
    progress = UPGRADE_SCALING_PROGRESS[level]
    scaled = int(round(base_value * UPGRADE_STAT_MAX_BONUS[stat_name] * progress))
    # Nigdy nie osłabiamy przedmiotu względem systemu sprzed v0.21.2.
    return max(legacy_bonus, scaled)


def _scaled_dodge_bonus(base_value: float, level: int) -> float:
    if base_value <= 0:
        return 0.0
    progress = UPGRADE_SCALING_PROGRESS[level]
    scaled = base_value * UPGRADE_STAT_MAX_BONUS["dodge"] * progress
    legacy = level * 0.5
    return max(legacy, scaled)


def calculate_upgraded_stats(item: EquipmentItem) -> UpgradedItemStats:
    """Zwraca finalne bazowe statystyki instancji wyposażenia.

    Upgrade System 2.0 skaluje przyrost z bazową siłą przedmiotu. Dzięki temu
    ulepszanie wysokiego Item Power jest wyraźnie bardziej odczuwalne niż
    dawny, stały bonus. Stare wartości pozostają minimalnym progiem, więc
    żaden istniejący przedmiot nie traci statystyk po aktualizacji.
    """
    definition = get_item_definition(item.item_id)
    level = item.upgrade_level

    attack_bonus = _scaled_integer_bonus(
        definition.attack,
        level,
        "attack",
        level // 2,
    )
    defense_bonus = _scaled_integer_bonus(
        definition.defense,
        level,
        "defense",
        level // 3,
    )
    hp_bonus = _scaled_integer_bonus(
        definition.max_hp,
        level,
        "max_hp",
        level * 2,
    )
    mana_bonus = _scaled_integer_bonus(
        definition.max_mana,
        level,
        "max_mana",
        level * 2,
    )
    dodge_bonus = _scaled_dodge_bonus(definition.dodge, level)
    magic_power_bonus = _scaled_integer_bonus(
        definition.magic_power, level, "attack", level // 2
    )

    return UpgradedItemStats(
        attack=definition.attack + attack_bonus,
        defense=definition.defense + defense_bonus,
        max_hp=definition.max_hp + hp_bonus,
        dodge=definition.dodge + dodge_bonus,
        max_mana=definition.max_mana + mana_bonus,
        magic_power=definition.magic_power + magic_power_bonus,
    )


def format_upgrade_name(item: EquipmentItem) -> str:
    definition = get_item_definition(item.item_id)
    return f"{definition.name} +{item.upgrade_level}"


def is_max_upgrade(item: EquipmentItem) -> bool:
    return item.upgrade_level >= MAX_UPGRADE_LEVEL
