from dataclasses import dataclass
import math
import random

from combat.elements import (
    DamageType,
    ElementalResistances,
)
from data.elites import ELITE_COMPATIBILITY, ELITE_MODIFIERS
from enemies.enemy import Enemy
from world.time_system import TimePeriod
from world.weather import WeatherType


ELITE_MISS_BONUS = 0.02
MAX_ELITE_CHANCE = 0.95

# Każda elita otrzymuje wspólny rdzeń siły, zanim nałożymy
# jej konkretny modyfikator. To sprawia, że [ELITA] oznacza
# realnie groźniejsze spotkanie, a nie tylko inny prefiks.
ELITE_BASE_HP_MULTIPLIER = 1.40
ELITE_BASE_ATTACK_MULTIPLIER = 1.10
ELITE_BASE_DEFENSE_BONUS = 1
ELITE_BASE_DODGE_BONUS = 3.0


@dataclass(frozen=True)
class EliteRoll:
    modifier_id: str
    display_name: str


def elite_encounter_chance(
    period: TimePeriod,
    weather: WeatherType,
) -> float:
    if weather is WeatherType.AURORA:
        return 0.25
    if period is TimePeriod.NIGHT:
        return 0.15
    return 0.10


def elite_chance_with_streak(
    period: TimePeriod,
    weather: WeatherType,
    miss_count: int,
) -> float:
    """Szansa na elitę po serii zwykłych spotkań w danym regionie.

    Każde kwalifikujące się spotkanie bez elity dodaje 2 punkty
    procentowe. Szansa nigdy nie osiąga 100%.
    """
    if miss_count < 0:
        raise ValueError("Licznik spotkań bez elity nie może być ujemny.")

    base = elite_encounter_chance(period, weather)
    return min(
        MAX_ELITE_CHANCE,
        base + miss_count * ELITE_MISS_BONUS,
    )


def can_become_elite(enemy: Enemy) -> bool:
    return (
        enemy.rank == "normal"
        and enemy.enemy_id in ELITE_COMPATIBILITY
        and enemy.elite_modifier_id is None
    )


def roll_elite_modifier(
    enemy: Enemy,
    period: TimePeriod,
    weather: WeatherType,
    rng: random.Random,
    *,
    miss_count: int = 0,
) -> EliteRoll | None:
    if not can_become_elite(enemy):
        return None

    chance = elite_chance_with_streak(
        period,
        weather,
        miss_count,
    )
    if rng.random() >= chance:
        return None

    modifier_id = rng.choice(ELITE_COMPATIBILITY[enemy.enemy_id])
    return EliteRoll(
        modifier_id=modifier_id,
        display_name=str(
            ELITE_MODIFIERS[modifier_id]["display_name"]
        ),
    )


def maybe_make_elite(
    enemy: Enemy,
    period: TimePeriod,
    weather: WeatherType,
    rng: random.Random,
    *,
    miss_count: int = 0,
) -> str | None:
    rolled = roll_elite_modifier(
        enemy,
        period,
        weather,
        rng,
        miss_count=miss_count,
    )
    if rolled is None:
        return None

    apply_elite_modifier(enemy, rolled.modifier_id, weather)
    return rolled.modifier_id


def roll_elite_for_region(
    enemy: Enemy,
    period: TimePeriod,
    weather: WeatherType,
    region_id: str,
    miss_streaks: dict[str, int],
    rng: random.Random,
) -> str | None:
    """Losuje elitę i aktualizuje licznik wyłącznie danego regionu.

    Zwykłe spotkanie bez elity: +1 do licznika regionu.
    Spotkanie elity: licznik regionu wraca do 0.
    Przeciwnik niekwalifikujący się do systemu: bez zmian.
    """
    if not can_become_elite(enemy):
        return None

    miss_count = int(miss_streaks.get(region_id, 0))
    if miss_count < 0:
        raise ValueError("Licznik spotkań bez elity nie może być ujemny.")

    modifier_id = maybe_make_elite(
        enemy,
        period,
        weather,
        rng,
        miss_count=miss_count,
    )

    if modifier_id is None:
        miss_streaks[region_id] = miss_count + 1
    else:
        miss_streaks[region_id] = 0

    return modifier_id


def _adjective_form(
    enemy: Enemy,
    masculine: str,
    feminine: str,
    neuter: str,
) -> str:
    if enemy.grammatical_gender == "feminine":
        return feminine
    if enemy.grammatical_gender == "neuter":
        return neuter
    return masculine


def _modifier_prefix(enemy: Enemy, modifier_id: str) -> str:
    forms: dict[str, tuple[str, str, str]] = {
        "furious": ("Wściekły", "Wściekła", "Wściekłe"),
        "armored": ("Opancerzony", "Opancerzona", "Opancerzone"),
        "vampiric": ("Wampiryczny", "Wampiryczna", "Wampiryczne"),
        "cursed": ("Przeklęty", "Przeklęta", "Przeklęte"),
    }
    masculine, feminine, neuter = forms[modifier_id]
    return _adjective_form(enemy, masculine, feminine, neuter)


def _apply_elite_baseline(enemy: Enemy) -> None:
    enemy.max_hp = max(
        1,
        math.ceil(enemy.max_hp * ELITE_BASE_HP_MULTIPLIER),
    )
    enemy.current_hp = enemy.max_hp
    enemy.attack = max(
        1,
        math.ceil(enemy.attack * ELITE_BASE_ATTACK_MULTIPLIER),
    )
    enemy.defense += ELITE_BASE_DEFENSE_BONUS
    enemy.dodge = min(
        95.0,
        enemy.dodge + ELITE_BASE_DODGE_BONUS,
    )


def apply_elite_modifier(
    enemy: Enemy,
    modifier_id: str,
    weather: WeatherType,
) -> None:
    if modifier_id not in ELITE_MODIFIERS:
        raise KeyError(f"Nieznany modyfikator elity: {modifier_id}")
    if not can_become_elite(enemy):
        raise ValueError(
            f"{enemy.name} nie może otrzymać modyfikatora elity."
        )
    if modifier_id not in ELITE_COMPATIBILITY[enemy.enemy_id]:
        raise ValueError(
            f"Modyfikator {modifier_id} nie pasuje do {enemy.name}."
        )

    _apply_elite_baseline(enemy)

    if modifier_id == "furious":
        enemy.max_hp = max(1, math.ceil(enemy.max_hp * 1.10))
        enemy.current_hp = enemy.max_hp
        enemy.attack = max(1, math.ceil(enemy.attack * 1.30))
        enemy.defense = max(0, enemy.defense - 1)
        prefix = _modifier_prefix(enemy, modifier_id)
        note = "elitarna baza + HP +10%, ATK +30%, DEF -1"

    elif modifier_id == "armored":
        enemy.max_hp = max(1, math.ceil(enemy.max_hp * 1.35))
        enemy.current_hp = enemy.max_hp
        enemy.defense = max(
            enemy.defense + 2,
            math.ceil(enemy.defense * 1.50),
        )
        prefix = _modifier_prefix(enemy, modifier_id)
        note = "elitarna baza + HP +35%, mocno zwiększony DEF"

    elif modifier_id == "vampiric":
        enemy.max_hp = max(1, math.ceil(enemy.max_hp * 1.25))
        enemy.current_hp = enemy.max_hp
        enemy.life_steal_percent = 40.0
        prefix = _modifier_prefix(enemy, modifier_id)
        note = "elitarna baza + HP +25%, odzyskuje 40% zadanych obrażeń"

    elif modifier_id == "cursed":
        enemy.max_hp = max(1, math.ceil(enemy.max_hp * 1.20))
        enemy.current_hp = enemy.max_hp
        enemy.special_chance = min(
            1.0,
            max(0.30, enemy.special_chance + 0.20),
        )
        enemy.special_attack_bonus += 2
        if enemy.special_name is None:
            enemy.special_name = "Uderzenie Klątwy"
        enemy.status_resistance = 0.50
        prefix = _modifier_prefix(enemy, modifier_id)
        note = (
            "elitarna baza + HP +20%, znacznie silniejsze ataki "
            "specjalne, 50% odporności na negatywne efekty"
        )

    elif modifier_id == "elemental":
        enemy.max_hp = max(1, math.ceil(enemy.max_hp * 1.30))
        enemy.current_hp = enemy.max_hp
        enemy.attack = max(1, math.ceil(enemy.attack * 1.15))
        enemy.special_attack_bonus += 2
        damage_type, forms = _element_for_weather(weather)
        prefix = _adjective_form(enemy, *forms)
        enemy.basic_damage_type = damage_type
        enemy.special_damage_type = damage_type
        enemy.elemental_resistances = _single_resistance(
            damage_type,
            50,
        )
        note = (
            f"elitarna baza + HP +30%, mocniejszy ATK, "
            f"obrażenia: {damage_type.display_name}, "
            f"odporność {damage_type.display_name}: 50%"
        )

    else:
        raise RuntimeError("Nieobsługiwany typ elity.")

    # Wspólny bonus nagród dla wszystkich elit.
    enemy.experience_reward = max(
        1,
        int(round(enemy.experience_reward * 1.50)),
    )
    enemy.gold_min = max(
        0,
        int(round(enemy.gold_min * 1.25)),
    )
    enemy.gold_max = max(
        enemy.gold_min,
        int(round(enemy.gold_max * 1.25)),
    )
    enemy.loot_chance_multiplier = 1.20
    enemy.rank = "elite"
    enemy.elite_modifier_id = modifier_id
    enemy.name = f"{prefix} {enemy.name}"
    enemy.elite_note = note


def _element_for_weather(
    weather: WeatherType,
) -> tuple[DamageType, tuple[str, str, str]]:
    if weather is WeatherType.STORM:
        return DamageType.WIND, ("Burzowy", "Burzowa", "Burzowe")
    if weather is WeatherType.WIND:
        return DamageType.WIND, ("Wichrowy", "Wichrowa", "Wichrowe")
    if weather is WeatherType.FROST:
        return DamageType.FROST, ("Mroźny", "Mroźna", "Mroźne")
    if weather is WeatherType.AURORA:
        return DamageType.FROST, ("Zorzowy", "Zorzowa", "Zorzowe")
    return DamageType.FIRE, ("Rozżarzony", "Rozżarzona", "Rozżarzone")


def _single_resistance(
    damage_type: DamageType,
    value: int,
) -> ElementalResistances:
    values = {
        "fire": 0,
        "wind": 0,
        "frost": 0,
        "earth": 0,
        "water": 0,
    }
    if damage_type is not DamageType.PHYSICAL:
        values[damage_type.code] = value
    return ElementalResistances(**values)
