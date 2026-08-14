from __future__ import annotations

from game.config import REGION_BOSS_RESPAWN_EXPEDITIONS


REGION_BOSS_BY_LOCATION: dict[str, str] = {
    "ashen_borderlands": "azhar",
    "ice_coast": "leviathan_north",
}

REGION_BOSS_NAMES: dict[str, str] = {
    "azhar": "Azhar, Władca Pustkowi",
    "leviathan_north": "Lewiatan Północy",
}


def boss_id_for_location(location_id: str) -> str | None:
    return REGION_BOSS_BY_LOCATION.get(location_id)


def respawn_remaining(respawns: dict[str, int], boss_id: str) -> int:
    return max(0, int(respawns.get(boss_id, 0)))


def boss_is_available(respawns: dict[str, int], boss_id: str) -> bool:
    return respawn_remaining(respawns, boss_id) == 0


def start_boss_respawn(respawns: dict[str, int], boss_id: str) -> int:
    if boss_id not in REGION_BOSS_NAMES:
        raise KeyError(f"Nieznany boss regionu: {boss_id}")
    respawns[boss_id] = REGION_BOSS_RESPAWN_EXPEDITIONS
    return REGION_BOSS_RESPAWN_EXPEDITIONS


def record_region_expedition(respawns: dict[str, int], location_id: str) -> int | None:
    """Zmniejsza licznik odrodzenia bossa przypisanego do danego regionu.

    Liczy się każda normalna wyprawa uruchomiona z menu regionu, niezależnie
    od tego, czy zakończyła się spokojnym wydarzeniem, zwycięstwem, ucieczką
    albo porażką. Odpoczynek i wejścia do dungeonów nie skracają odrodzenia.
    """
    boss_id = boss_id_for_location(location_id)
    if boss_id is None:
        return None

    remaining = respawn_remaining(respawns, boss_id)
    if remaining <= 0:
        return 0

    remaining -= 1
    if remaining <= 0:
        respawns.pop(boss_id, None)
        return 0

    respawns[boss_id] = remaining
    return remaining
