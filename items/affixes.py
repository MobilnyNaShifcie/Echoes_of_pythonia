from __future__ import annotations

from dataclasses import dataclass
from enum import IntEnum
import hashlib
import math
import random

from combat.elements import ElementalResistances
from data.affixes import AFFIX_DATA, DEFENSIVE_AFFIX_IDS, OFFENSIVE_AFFIX_IDS
from items.catalog import get_item_definition
from items.signature_weapons import (
    deterministic_average_damage_percent,
    is_signature_dungeon_weapon,
    roll_average_damage_percent,
)
from items.models import (
    AffixRoll,
    EquipmentItem,
    EquipmentRole,
    EquipmentSlot,
    ItemDefinition,
    ItemRarity,
)


class EquipmentQuality(IntEnum):
    """Jakość źródła dropu wpływa wyłącznie na szansę tierów T1-T5."""

    NORMAL = 0
    ELITE = 1
    MINIBOSS = 2
    DUNGEON = 3
    BOSS = 4


RARITY_AFFIX_COUNT: dict[ItemRarity, int] = {
    ItemRarity.COMMON: 0,
    ItemRarity.UNCOMMON: 1,
    ItemRarity.RARE: 2,
    ItemRarity.EPIC: 3,
    ItemRarity.LEGENDARY: 4,
    # Mityczny zachowuje cztery losowe bonusy. Piąty/specjalny efekt
    # jest zarezerwowany dla późniejszego systemu unikatów.
    ItemRarity.MYTHIC: 4,
}

# Zwykły drop faworyzuje T1-T2. Lepsze źródła przesuwają rozkład w górę,
# ale nawet boss nie gwarantuje T5.
_TIER_WEIGHTS: dict[EquipmentQuality, tuple[int, int, int, int, int]] = {
    EquipmentQuality.NORMAL: (35, 30, 20, 10, 5),
    EquipmentQuality.ELITE: (25, 28, 24, 15, 8),
    EquipmentQuality.MINIBOSS: (18, 25, 27, 20, 10),
    EquipmentQuality.DUNGEON: (12, 20, 28, 25, 15),
    EquipmentQuality.BOSS: (8, 15, 25, 28, 24),
}

_TIER_FRACTIONS: dict[int, float] = {
    1: 0.20,
    2: 0.40,
    3: 0.60,
    4: 0.80,
    5: 1.00,
}

# Maksymalny (T5) płaski roll dla obecnych Item Power I-IV.
# Powyżej IP IV flat stats rosną automatycznie krzywą endgame.
_FLAT_T5_BY_POWER: dict[str, tuple[float, float, float, float]] = {
    "max_hp": (12, 18, 24, 30),
    "attack": (2, 3, 4, 5),
    "defense": (2, 2, 3, 4),
    "max_mana": (6, 8, 10, 12),
    "health_regen": (1, 1, 1, 1),
}

# Procenty rosną powoli i mają twarde limity. Dzięki temu przyszłe
# Item Power może zwiększać HP/ATK o setki lub tysiące, ale multiplikatory
# nie eksplodują.
_PERCENT_T5_BY_POWER: dict[str, tuple[float, float, float, float]] = {
    "dodge": (1.5, 2.0, 2.5, 3.0),
    "crit_chance": (2.5, 3.0, 3.5, 4.0),
    "crit_damage": (8.0, 10.0, 12.0, 15.0),
    "skill_damage": (3.0, 4.0, 5.0, 6.0),
    "armor_penetration": (2.0, 3.0, 4.0, 5.0),
    "damage_vs_elite": (5.0, 6.0, 8.0, 10.0),
    "damage_vs_boss": (5.0, 6.0, 8.0, 10.0),
    "fire_resistance": (5.0, 6.0, 7.0, 8.0),
    "wind_resistance": (5.0, 6.0, 7.0, 8.0),
    "frost_resistance": (5.0, 6.0, 7.0, 8.0),
    "earth_resistance": (5.0, 6.0, 7.0, 8.0),
    "water_resistance": (5.0, 6.0, 7.0, 8.0),
}

_PERCENT_ENDGAME_CAPS: dict[str, float] = {
    "dodge": 5.0,
    "crit_chance": 10.0,
    "crit_damage": 30.0,
    "skill_damage": 12.0,
    "armor_penetration": 10.0,
    "damage_vs_elite": 20.0,
    "damage_vs_boss": 20.0,
    "fire_resistance": 15.0,
    "wind_resistance": 15.0,
    "frost_resistance": 15.0,
    "earth_resistance": 15.0,
    "water_resistance": 15.0,
}

# Przyrost T5 na każdy IP ponad IV do osiągnięcia capu.
_PERCENT_ENDGAME_STEP: dict[str, float] = {
    "dodge": 0.25,
    "crit_chance": 0.75,
    "crit_damage": 2.0,
    "skill_damage": 0.75,
    "armor_penetration": 0.625,
    "damage_vs_elite": 1.25,
    "damage_vs_boss": 1.25,
    "fire_resistance": 0.875,
    "wind_resistance": 0.875,
    "frost_resistance": 0.875,
    "earth_resistance": 0.875,
    "water_resistance": 0.875,
}

MIXED_SLOT_VALUE_MULTIPLIER = 0.75
ENDGAME_FLAT_GROWTH_PER_POWER = 1.75


@dataclass(frozen=True)
class AffixBonuses:
    attack: int = 0
    defense: int = 0
    max_hp: int = 0
    dodge: float = 0.0
    max_mana: int = 0
    health_regen: int = 0
    crit_chance: float = 0.0
    crit_damage: float = 0.0
    skill_damage: float = 0.0
    armor_penetration: float = 0.0
    damage_vs_elite: float = 0.0
    damage_vs_boss: float = 0.0
    resistances: ElementalResistances = ElementalResistances()


def affix_count_for_rarity(rarity: ItemRarity) -> int:
    return RARITY_AFFIX_COUNT[rarity]


def allowed_affix_ids(definition: ItemDefinition) -> tuple[str, ...]:
    role = definition.equipment_role
    if role is EquipmentRole.DEFENSIVE:
        return DEFENSIVE_AFFIX_IDS
    if role is EquipmentRole.OFFENSIVE:
        return OFFENSIVE_AFFIX_IDS
    if role is EquipmentRole.MIXED:
        return DEFENSIVE_AFFIX_IDS + OFFENSIVE_AFFIX_IDS
    return ()


def _flat_t5_value(affix_id: str, item_power: int) -> float:
    values = _FLAT_T5_BY_POWER[affix_id]
    if item_power <= 4:
        return values[max(1, item_power) - 1]

    # Od Item Power V zaczyna się krzywa przygotowana pod przyszły endgame.
    # Przykładowo HP T5 przy IP XII przekracza ~2500, podczas gdy procenty
    # nadal zatrzymują się na bezpiecznych capach.
    return values[-1] * (
        ENDGAME_FLAT_GROWTH_PER_POWER ** (item_power - 4)
    )


def _percent_t5_value(affix_id: str, item_power: int) -> float:
    values = _PERCENT_T5_BY_POWER[affix_id]
    if item_power <= 4:
        return values[max(1, item_power) - 1]

    value = values[-1] + _PERCENT_ENDGAME_STEP[affix_id] * (
        item_power - 4
    )
    return min(value, _PERCENT_ENDGAME_CAPS[affix_id])


def max_affix_value(affix_id: str, item_power: int) -> float:
    if item_power <= 0:
        raise ValueError("Item Power wyposażenia musi być dodatni.")
    if affix_id in _FLAT_T5_BY_POWER:
        return _flat_t5_value(affix_id, item_power)
    if affix_id in _PERCENT_T5_BY_POWER:
        return _percent_t5_value(affix_id, item_power)
    raise KeyError(f"Nieznany bonus wyposażenia: {affix_id}")


def affix_value_for_tier(
    affix_id: str,
    item_power: int,
    tier: int,
    slot: EquipmentSlot,
) -> float:
    if tier not in _TIER_FRACTIONS:
        raise ValueError("Tier bonusu musi mieścić się w zakresie T1-T5.")

    value = max_affix_value(affix_id, item_power) * _TIER_FRACTIONS[tier]
    if slot is EquipmentSlot.BELT:
        value *= MIXED_SLOT_VALUE_MULTIPLIER

    kind = str(AFFIX_DATA[affix_id]["kind"])
    if kind in {"flat_int", "percent_int"}:
        return float(max(1, int(round(value))))

    # Procenty przechowujemy z dokładnością do 0.1 p.p.
    return max(0.1, round(value, 1))


def roll_affix_tier(
    rng: random.Random,
    quality: EquipmentQuality,
) -> int:
    weights = _TIER_WEIGHTS[EquipmentQuality(quality)]
    return int(rng.choices((1, 2, 3, 4, 5), weights=weights, k=1)[0])


def roll_affixes(
    definition: ItemDefinition,
    rng: random.Random,
    quality: EquipmentQuality = EquipmentQuality.NORMAL,
) -> list[AffixRoll]:
    if not definition.is_equipment or definition.slot is None:
        return []

    count = affix_count_for_rarity(definition.rarity)
    if count <= 0:
        return []

    pool = list(allowed_affix_ids(definition))
    if count > len(pool):
        raise RuntimeError(
            f"Za mała pula bonusów dla slotu {definition.slot.code}."
        )

    selected = rng.sample(pool, count)
    affixes: list[AffixRoll] = []
    for affix_id in selected:
        tier = roll_affix_tier(rng, quality)
        affixes.append(
            AffixRoll(
                affix_id=affix_id,
                tier=tier,
                value=affix_value_for_tier(
                    affix_id,
                    definition.item_power,
                    tier,
                    definition.slot,
                ),
            )
        )
    return affixes


def generate_equipment_item(
    item_id: str,
    rng: random.Random | None = None,
    *,
    quality: EquipmentQuality = EquipmentQuality.NORMAL,
    upgrade_level: int = 0,
    instance_id: str = "",
) -> EquipmentItem:
    definition = get_item_definition(item_id)
    if not definition.is_equipment:
        raise ValueError(f"Przedmiot {item_id} nie jest wyposażeniem.")
    if definition.item_power <= 0:
        raise ValueError(f"Wyposażenie {item_id} nie ma Item Power.")

    actual_rng = rng or random.Random()
    return EquipmentItem(
        item_id=item_id,
        upgrade_level=upgrade_level,
        instance_id=instance_id,
        item_power=definition.item_power,
        affixes=roll_affixes(definition, actual_rng, quality),
        average_damage_percent=roll_average_damage_percent(
            item_id,
            actual_rng,
        ),
    )


def backfill_legacy_equipment_item(
    item_id: str,
    upgrade_level: int,
    instance_id: str,
) -> EquipmentItem:
    """Jednorazowo odtwarza stabilny roll dla save'ów sprzed v0.17.

    Seed bazuje na niezmiennym instance_id, więc przed pierwszym zapisem v0.17
    wynik nie zmienia się po ponownym wczytaniu gry.
    """
    seed_text = f"EchoesOfPythonia-v0.17|{item_id}|{instance_id}"
    digest = hashlib.sha256(seed_text.encode("utf-8")).digest()
    seed = int.from_bytes(digest[:8], "big")
    return generate_equipment_item(
        item_id,
        random.Random(seed),
        quality=EquipmentQuality.NORMAL,
        upgrade_level=upgrade_level,
        instance_id=instance_id,
    )


def ensure_equipment_generation(item: EquipmentItem) -> EquipmentItem:
    definition = get_item_definition(item.item_id)
    required = affix_count_for_rarity(definition.rarity)
    generated_core = (
        item.item_power == definition.item_power
        and len(item.affixes) == required
    )

    if not generated_core:
        generated = backfill_legacy_equipment_item(
            item.item_id,
            item.upgrade_level,
            item.instance_id,
        )
        item.item_power = generated.item_power
        item.affixes = generated.affixes

    if (
        is_signature_dungeon_weapon(item.item_id)
        and item.average_damage_percent is None
    ):
        item.average_damage_percent = deterministic_average_damage_percent(
            item.item_id,
            item.instance_id,
        )

    return item


def validate_affix_roll(
    definition: ItemDefinition,
    affix: AffixRoll,
) -> None:
    if affix.affix_id not in AFFIX_DATA:
        raise ValueError(f"Nieznany bonus: {affix.affix_id}")
    if affix.affix_id not in allowed_affix_ids(definition):
        raise ValueError(
            f"Bonus {affix.affix_id} nie pasuje do slotu {definition.slot}."
        )
    expected = affix_value_for_tier(
        affix.affix_id,
        definition.item_power,
        affix.tier,
        definition.slot,
    )
    if not math.isclose(affix.value, expected, abs_tol=0.001):
        raise ValueError(
            f"Nieprawidłowa wartość bonusu {affix.affix_id}: "
            f"{affix.value}, oczekiwano {expected}."
        )


def calculate_affix_bonuses(item: EquipmentItem) -> AffixBonuses:
    attack = defense = max_hp = max_mana = health_regen = 0
    dodge = crit_chance = crit_damage = skill_damage = 0.0
    armor_penetration = damage_vs_elite = damage_vs_boss = 0.0
    resistance_values = {
        "fire": 0,
        "wind": 0,
        "frost": 0,
        "earth": 0,
        "water": 0,
    }

    for affix in item.affixes:
        value = affix.value
        if affix.affix_id == "attack":
            attack += int(round(value))
        elif affix.affix_id == "defense":
            defense += int(round(value))
        elif affix.affix_id == "max_hp":
            max_hp += int(round(value))
        elif affix.affix_id == "max_mana":
            max_mana += int(round(value))
        elif affix.affix_id == "health_regen":
            health_regen += int(round(value))
        elif affix.affix_id == "dodge":
            dodge += value
        elif affix.affix_id == "crit_chance":
            crit_chance += value
        elif affix.affix_id == "crit_damage":
            crit_damage += value
        elif affix.affix_id == "skill_damage":
            skill_damage += value
        elif affix.affix_id == "armor_penetration":
            armor_penetration += value
        elif affix.affix_id == "damage_vs_elite":
            damage_vs_elite += value
        elif affix.affix_id == "damage_vs_boss":
            damage_vs_boss += value
        elif affix.affix_id.endswith("_resistance"):
            element = affix.affix_id.removesuffix("_resistance")
            resistance_values[element] += int(round(value))

    return AffixBonuses(
        attack=attack,
        defense=defense,
        max_hp=max_hp,
        dodge=round(dodge, 1),
        max_mana=max_mana,
        health_regen=health_regen,
        crit_chance=round(crit_chance, 1),
        crit_damage=round(crit_damage, 1),
        skill_damage=round(skill_damage, 1),
        armor_penetration=round(armor_penetration, 1),
        damage_vs_elite=round(damage_vs_elite, 1),
        damage_vs_boss=round(damage_vs_boss, 1),
        resistances=ElementalResistances(**resistance_values),
    )


def format_affix_value(affix: AffixRoll) -> str:
    data = AFFIX_DATA[affix.affix_id]
    kind = str(data["kind"])
    if kind == "flat_int":
        return f"+{int(round(affix.value))}"
    if kind == "percent_int":
        return f"+{int(round(affix.value))}%"
    return f"+{affix.value:.1f}%"


def item_power_display(item_power: int) -> str:
    roman = {
        1: "I",
        2: "II",
        3: "III",
        4: "IV",
        5: "V",
        6: "VI",
        7: "VII",
        8: "VIII",
        9: "IX",
        10: "X",
        11: "XI",
        12: "XII",
    }
    return roman.get(item_power, str(item_power))


def equipment_quality_for_enemy(
    *,
    rank: str,
    elite_modifier_id: str | None = None,
    in_dungeon: bool = False,
) -> EquipmentQuality:
    if rank == "boss":
        return EquipmentQuality.BOSS
    if in_dungeon:
        return EquipmentQuality.DUNGEON
    if elite_modifier_id is not None or rank == "elite":
        return EquipmentQuality.ELITE
    if rank == "miniboss":
        return EquipmentQuality.MINIBOSS
    return EquipmentQuality.NORMAL
