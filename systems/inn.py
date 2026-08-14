from dataclasses import dataclass

from game.config import (
    CAMP_REST_HP_PERCENT,
    CAMP_REST_MANA_PERCENT,
    INN_REST_BASE_COST,
    INN_REST_DURATION_HOURS,
    INN_REST_LEVEL_COST,
)
from player.player import Player
from world.time_system import GameClock


@dataclass(frozen=True)
class RestResult:
    healed_hp: int
    restored_mana: int


@dataclass(frozen=True)
class InnRestResult(RestResult):
    gold_cost: int
    next_available_day: int


def inn_rest_cost(player: Player) -> int:
    """Cena noclegu rośnie z poziomem, ale pozostaje dostępna na starcie."""
    return INN_REST_BASE_COST + max(0, int(player.level)) * INN_REST_LEVEL_COST


def rest_at_camp(player: Player) -> RestResult:
    """Darmowy odpoczynek polowy: częściowa regeneracja bez pełnego resetu."""
    if not player.stats.needs_restoration:
        raise ValueError("Nie potrzebujesz teraz odpoczynku.")

    hp_amount = max(1, round(player.stats.max_hp * CAMP_REST_HP_PERCENT))
    mana_amount = (
        max(1, round(player.stats.max_mana * CAMP_REST_MANA_PERCENT))
        if player.stats.max_mana > 0
        else 0
    )
    return RestResult(
        healed_hp=player.stats.heal(hp_amount),
        restored_mana=player.stats.restore_mana(mana_amount),
    )


def rest_at_inn(
    player: Player,
    clock: GameClock,
    *,
    last_inn_rest_day: int = 0,
) -> InnRestResult:
    """Pełny nocleg w karczmie, maksymalnie raz na dzień Pythonii."""
    if not player.stats.needs_restoration:
        raise ValueError("Nie potrzebujesz teraz noclegu.")

    if last_inn_rest_day >= clock.day:
        raise ValueError(
            f"Pokój był już dziś używany. Pełny nocleg będzie dostępny od Dnia {clock.day + 1}."
        )

    cost = inn_rest_cost(player)
    if player.gold < cost:
        raise ValueError(f"Nocleg kosztuje {cost} Gold. Masz {player.gold}.")

    missing_hp = max(0, player.stats.max_hp - player.stats.current_hp)
    missing_mana = max(0, player.stats.max_mana - player.stats.current_mana)
    player.gold -= cost
    player.stats.restore_full()
    clock.advance(INN_REST_DURATION_HOURS)

    # Blokada obejmuje także dzień, na który przesunął nas sam nocleg.
    next_available_day = clock.day + 1
    return InnRestResult(
        healed_hp=missing_hp,
        restored_mana=missing_mana,
        gold_cost=cost,
        next_available_day=next_available_day,
    )
