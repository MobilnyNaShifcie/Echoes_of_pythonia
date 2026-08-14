from __future__ import annotations

import hashlib
import random

from data.signature_weapons import SIGNATURE_DUNGEON_WEAPONS


def is_signature_dungeon_weapon(item_id: str) -> bool:
    return item_id in SIGNATURE_DUNGEON_WEAPONS


def signature_weapon_source_boss(item_id: str) -> str | None:
    data = SIGNATURE_DUNGEON_WEAPONS.get(item_id)
    if data is None:
        return None
    return str(data["source_boss_id"])


def average_damage_range(item_id: str) -> tuple[int, int] | None:
    data = SIGNATURE_DUNGEON_WEAPONS.get(item_id)
    if data is None:
        return None
    minimum = int(data["average_damage_min"])
    maximum = int(data["average_damage_max"])
    if minimum > maximum:
        raise ValueError(
            f"Nieprawidłowe widełki Średnich Obrażeń dla {item_id}."
        )
    return minimum, maximum


def roll_average_damage_percent(
    item_id: str,
    rng: random.Random,
) -> int | None:
    limits = average_damage_range(item_id)
    if limits is None:
        return None
    minimum, maximum = limits
    return rng.randint(minimum, maximum)


def deterministic_average_damage_percent(
    item_id: str,
    instance_id: str,
) -> int | None:
    """Stabilny roll dla instancji istniejących przed v0.18.

    Nie zmieniamy istniejących affixów Equipment 2.0. Jedynie dokładamy
    brakującą specjalną właściwość na podstawie trwałego instance_id.
    """
    if not is_signature_dungeon_weapon(item_id):
        return None
    seed_text = (
        f"EchoesOfPythonia-v0.18-average|{item_id}|{instance_id}"
    )
    digest = hashlib.sha256(seed_text.encode("utf-8")).digest()
    seed = int.from_bytes(digest[:8], "big")
    return roll_average_damage_percent(
        item_id,
        random.Random(seed),
    )


def validate_average_damage_percent(
    item_id: str,
    value: int | None,
) -> None:
    limits = average_damage_range(item_id)
    if limits is None:
        if value is not None:
            raise ValueError(
                f"Przedmiot {item_id} nie może posiadać Średnich Obrażeń."
            )
        return

    if value is None:
        raise ValueError(
            f"Broń {item_id} nie ma wylosowanych Średnich Obrażeń."
        )

    minimum, maximum = limits
    if not minimum <= value <= maximum:
        raise ValueError(
            f"Nieprawidłowe Średnie Obrażenia dla {item_id}: {value}%. "
            f"Dozwolone: {minimum}%..{maximum}%."
        )


def format_average_damage(value: int) -> str:
    return f"{value:+d}%"
