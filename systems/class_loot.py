import random

from data.class_loot import (
    CLASS_GEAR_POOL,
    CLASS_WEAPON_POOLS,
    CLASS_WEAPON_REGION_BY_ENEMY,
    LATE_GAME_GEAR_ENEMIES,
)


def roll_class_gear_drop(
    enemy_id: str,
    rank: str,
    *,
    elite: bool,
    rng: random.Random,
) -> str | None:
    """Rzadki build-defining OFF-HAND z szerokiej puli późnych regionów."""
    if enemy_id not in LATE_GAME_GEAR_ENEMIES:
        return None
    if rank == "boss":
        chance = 0.04
    elif rank == "miniboss":
        chance = 0.03
    elif elite:
        chance = 0.02
    else:
        chance = 0.005
    if rng.random() >= chance:
        return None
    return rng.choice(CLASS_GEAR_POOL)


def roll_class_weapon_drop(
    enemy_id: str,
    rank: str,
    *,
    elite: bool,
    rng: random.Random,
) -> str | None:
    """Losuje broń klasową z puli całego regionu, nie z jednego potwora.

    Broń jest celowo dostępniejsza niż wyjątkowy sprzęt klasowy: ma stanowić
    normalną progresję Łowcy/Maga/Pierrota, a nie wielotygodniowy chase drop.
    Rodzaj broni nadal jest losowy, więc świat nie dopasowuje lootu do klasy.
    """
    region = CLASS_WEAPON_REGION_BY_ENEMY.get(enemy_id)
    if region is None:
        return None
    if rank == "boss":
        chance = 0.20
    elif rank == "miniboss":
        chance = 0.14
    elif elite:
        chance = 0.10
    else:
        chance = 0.04
    if rng.random() >= chance:
        return None
    return rng.choice(CLASS_WEAPON_POOLS[region])
