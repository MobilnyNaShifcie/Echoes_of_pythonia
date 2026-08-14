from data.passive_specializations import PASSIVE_SPECIALIZATIONS, SPECIALIZATIONS_BY_PASSIVE
from player.passives import PassiveType


def can_choose_passive_specialization(player, passive: PassiveType) -> bool:
    return (
        player.passives.get(passive) >= 10
        and passive.code in player.passive_masteries
        and passive.code not in player.passive_specializations
    )


def choose_passive_specialization(player, passive: PassiveType, specialization_id: str) -> None:
    if not can_choose_passive_specialization(player, passive):
        raise ValueError("Ta pasywka nie jest gotowa do wyboru specjalizacji.")
    if specialization_id not in SPECIALIZATIONS_BY_PASSIVE[passive.code]:
        raise ValueError("Nieprawidłowa specjalizacja tej pasywki.")
    player.passive_specializations[passive.code] = specialization_id
    player.recalculate_stats()


def specialization_for(player, passive_code: str) -> str | None:
    return player.passive_specializations.get(passive_code)


def specialization_name(player, passive_code: str) -> str | None:
    spec_id = specialization_for(player, passive_code)
    if spec_id is None:
        return None
    return PASSIVE_SPECIALIZATIONS[spec_id].name
