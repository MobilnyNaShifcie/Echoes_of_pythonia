from dataclasses import dataclass
from datetime import date
import hashlib
import random

from data.dungeons import DUNGEON_DATA
from data.enemies import ENEMY_DATA
from data.items import ITEM_DATA
from data.locations import LOCATION_DATA, LOCATION_ORDER
from data.loot_tables import LOOT_TABLES
from game.config import ATTRIBUTE_POINTS_PER_LEVEL
from items.catalog import get_item_definition
from player.player import Player
from quests.contracts import (
    ContractBoard,
    ContractCategory,
    ContractDefinition,
    ContractObjective,
    ContractObjectiveType,
)
from world.dungeon import create_dungeon


@dataclass(frozen=True)
class ContractProgressUpdate:
    contract_id: str
    title: str
    objective_index: int
    current: int
    required: int
    ready: bool


@dataclass(frozen=True)
class ContractClaimResult:
    contract_id: str
    title: str
    experience: int
    gold: int
    levels_gained: int
    attribute_points_gained: int
    reward_item_id: str | None
    reward_item_quantity: int


def daily_key(today: date) -> str:
    return today.isoformat()


def weekly_key(today: date) -> str:
    iso = today.isocalendar()
    return f"{iso.year}-W{iso.week:02d}"


def ensure_contract_board(
    board: ContractBoard,
    player: Player,
    *,
    today: date | None = None,
) -> list[str]:
    current = today or date.today()
    messages: list[str] = []

    day = daily_key(current)
    if not board.daily_date or day > board.daily_date:
        old_ids = {
            contract.contract_id
            for contract in board.daily_contracts
        }
        _remove_progress(board, old_ids)
        board.daily_date = day
        board.daily_contracts = generate_daily_contracts(
            player,
            day,
        )
        board.daily_claimed.clear()
        messages.append(
            f"Nowe kontrakty dzienne: {day}."
        )
    elif day == board.daily_date and not board.daily_contracts:
        board.daily_contracts = generate_daily_contracts(
            player,
            day,
        )
        messages.append(
            f"Utworzono kontrakty dzienne: {day}."
        )

    week = weekly_key(current)
    if not board.weekly_key or week > board.weekly_key:
        old_ids = (
            {board.weekly_contract.contract_id}
            if board.weekly_contract is not None
            else set()
        )
        _remove_progress(board, old_ids)
        board.weekly_key = week
        board.weekly_contract = generate_weekly_contract(
            player,
            week,
        )
        board.weekly_claimed = False
        messages.append(
            f"Nowy kontrakt tygodniowy: {week}."
        )
    elif week == board.weekly_key and board.weekly_contract is None:
        board.weekly_contract = generate_weekly_contract(
            player,
            week,
        )
        messages.append(
            f"Utworzono kontrakt tygodniowy: {week}."
        )

    return messages


def generate_daily_contracts(
    player: Player,
    period_key: str,
) -> list[ContractDefinition]:
    rng = _period_rng(player, period_key, "daily")
    regions = _accessible_regions(player.level)

    # 1. Polowanie na konkretny typ przeciwnika.
    hunt_region = rng.choice(regions)
    hunt_enemy = rng.choice(_normal_enemies(hunt_region))
    danger = int(LOCATION_DATA[hunt_region]["danger_rating"])
    hunt_count = 3 + danger + rng.randint(0, 2)
    hunt_name = str(ENEMY_DATA[hunt_enemy]["name"])
    hunt_title = rng.choice((
        f"Polowanie: {hunt_name}",
        f"Problem z: {hunt_name}",
        f"List gończy: {hunt_name}",
        f"Uszczuplić stado: {hunt_name}",
    ))

    hunt = ContractDefinition(
        contract_id=f"daily-{period_key}-hunt",
        category=ContractCategory.DAILY,
        period_key=period_key,
        title=hunt_title,
        description=(
            "Gildia płaci za ograniczenie liczby zagrożeń "
            "na szlakach."
        ),
        recommended_level=int(
            LOCATION_DATA[hunt_region]["recommended_level_min"]
        ),
        objectives=(
            ContractObjective(
                ContractObjectiveType.KILL_ENEMY,
                hunt_enemy,
                hunt_count,
            ),
        ),
        reward_exp=100 + danger * 70 + hunt_count * 10,
        reward_gold=55 + danger * 35,
    )

    # 2. Dostawa materiałów.
    supply_region = rng.choice(regions)
    material_id = rng.choice(
        _common_materials_for_region(supply_region)
    )
    supply_danger = int(
        LOCATION_DATA[supply_region]["danger_rating"]
    )
    quantity = 2 + min(2, supply_danger - 1) + rng.randint(0, 1)
    material_name = get_item_definition(material_id).name
    supply_title = rng.choice((
        f"Zamówienie: {material_name}",
        f"Braki w magazynie: {material_name}",
        f"Dostawa dla rzemieślników",
        f"Potrzebne materiały: {material_name}",
    ))

    supply = ContractDefinition(
        contract_id=f"daily-{period_key}-supply",
        category=ContractCategory.DAILY,
        period_key=period_key,
        title=supply_title,
        description=(
            "Gildia skupuje materiały potrzebne miejscowym "
            "rzemieślnikom i alchemikom."
        ),
        recommended_level=int(
            LOCATION_DATA[supply_region]["recommended_level_min"]
        ),
        objectives=(
            ContractObjective(
                ContractObjectiveType.COLLECT,
                material_id,
                quantity,
                consume_items=True,
            ),
        ),
        reward_exp=120 + supply_danger * 65,
        reward_gold=70 + supply_danger * 30,
    )

    # 3. Elita albo patrol dla bardzo początkującej postaci.
    elite_region = rng.choice(regions)
    elite_danger = int(
        LOCATION_DATA[elite_region]["danger_rating"]
    )

    if player.level >= 2:
        elite_count = 1 if elite_danger == 1 else 2
        elite = ContractDefinition(
            contract_id=f"daily-{period_key}-elite",
            category=ContractCategory.DAILY,
            period_key=period_key,
            title=rng.choice((
                "Elitarne zagrożenie",
                "Niebezpieczny okaz",
                "Łowca elit",
                "Ponadprzeciętny przeciwnik",
            )),
            description=(
                "Gildia szuka kogoś, kto poradzi sobie "
                "z wyjątkowo silnymi przeciwnikami."
            ),
            recommended_level=max(
                2,
                int(
                    LOCATION_DATA[elite_region][
                        "recommended_level_min"
                    ]
                ),
            ),
            objectives=(
                ContractObjective(
                    ContractObjectiveType.KILL_ELITE_REGION,
                    elite_region,
                    elite_count,
                ),
            ),
            reward_exp=240 + elite_danger * 90,
            reward_gold=100 + elite_danger * 45,
            reward_item_id="strong_healing_potion",
            reward_item_quantity=1,
        )
    else:
        patrol_count = 5
        elite = ContractDefinition(
            contract_id=f"daily-{period_key}-patrol",
            category=ContractCategory.DAILY,
            period_key=period_key,
            title="Pierwszy patrol",
            description=(
                "Przejdź się po okolicy i oczyść najbliższe szlaki."
            ),
            recommended_level=0,
            objectives=(
                ContractObjective(
                    ContractObjectiveType.KILL_REGION,
                    elite_region,
                    patrol_count,
                ),
            ),
            reward_exp=160,
            reward_gold=80,
        )

    return [hunt, supply, elite]


def generate_weekly_contract(
    player: Player,
    period_key: str,
) -> ContractDefinition:
    rng = _period_rng(player, period_key, "weekly")
    region = _accessible_regions(player.level)[-1]
    data = LOCATION_DATA[region]
    danger = int(data["danger_rating"])
    region_name = str(data["name"])

    objectives: list[ContractObjective] = [
        ContractObjective(
            ContractObjectiveType.KILL_REGION,
            region,
            8 + danger * 2,
        ),
        ContractObjective(
            ContractObjectiveType.KILL_ELITE,
            None,
            min(3, 1 + danger),
        ),
    ]

    if player.level >= 7:
        dungeon_id = (
            "black_fleet_wreck"
            if player.level >= 16
            else "sunken_order_crypt"
        )
        dungeon_name = str(DUNGEON_DATA[dungeon_id]["name"])
        objectives.append(
            ContractObjective(
                ContractObjectiveType.COMPLETE_DUNGEON,
                dungeon_id,
                1,
            )
        )
        title = rng.choice((
            f"Tydzień w regionie: {region_name}",
            "Próba Gildii",
            f"Szlaki i {dungeon_name}",
        ))
        description = (
            "Długi kontrakt dla doświadczonego poszukiwacza. "
            f"Gildia oczekuje działań w aktualnym regionie oraz ukończenia: {dungeon_name}."
        )
        reward_item_id = "grandmaster_elixir"
        reward_item_quantity = 1
    else:
        minibosses = _minibosses_for_region(region)
        if minibosses:
            objectives.append(
                ContractObjective(
                    ContractObjectiveType.KILL_MINIBOSS,
                    rng.choice(minibosses),
                    1,
                )
            )
        title = rng.choice((
            f"Tydzień w regionie: {region_name}",
            "Kontrakt tygodniowy",
            "Duże zlecenie Gildii",
        ))
        description = (
            "Tygodniowe zlecenie łączące kilka celów "
            "w jednym regionie."
        )
        reward_item_id = "strong_healing_potion"
        reward_item_quantity = 2

    return ContractDefinition(
        contract_id=f"weekly-{period_key}",
        category=ContractCategory.WEEKLY,
        period_key=period_key,
        title=title,
        description=description,
        recommended_level=int(data["recommended_level_min"]),
        objectives=tuple(objectives),
        reward_exp=850 + danger * 170,
        reward_gold=450 + danger * 110,
        reward_item_id=reward_item_id,
        reward_item_quantity=reward_item_quantity,
    )


def active_contracts(
    board: ContractBoard,
) -> list[ContractDefinition]:
    contracts = [
        contract
        for contract in board.daily_contracts
        if contract.contract_id not in board.daily_claimed
    ]
    if (
        board.weekly_contract is not None
        and not board.weekly_claimed
    ):
        contracts.append(board.weekly_contract)
    return contracts


def objective_progress(
    player: Player,
    board: ContractBoard,
    contract: ContractDefinition,
    objective_index: int,
) -> tuple[int, int]:
    objective = contract.objectives[objective_index]

    if objective.objective_type is ContractObjectiveType.COLLECT:
        current = player.inventory.count(
            str(objective.target_id)
        )
    else:
        current = board.progress.get(
            contract.contract_id,
            {},
        ).get(str(objective_index), 0)

    return (
        min(current, objective.required_count),
        objective.required_count,
    )


def contract_is_ready(
    player: Player,
    board: ContractBoard,
    contract: ContractDefinition,
) -> bool:
    if contract.category is ContractCategory.DAILY:
        if contract.contract_id in board.daily_claimed:
            return False
    elif board.weekly_claimed:
        return False

    return all(
        objective_progress(player, board, contract, index)[0]
        >= objective.required_count
        for index, objective in enumerate(contract.objectives)
    )


def record_contract_victory(
    player: Player,
    board: ContractBoard,
    *,
    enemy_id: str,
    region_id: str,
    is_miniboss: bool,
    elite_modifier_id: str | None,
) -> list[ContractProgressUpdate]:
    updates: list[ContractProgressUpdate] = []

    for contract in active_contracts(board):
        for index, objective in enumerate(contract.objectives):
            matches = False

            if objective.objective_type is ContractObjectiveType.KILL_ENEMY:
                matches = objective.target_id == enemy_id

            elif objective.objective_type is ContractObjectiveType.KILL_REGION:
                matches = objective.target_id == region_id

            elif objective.objective_type is ContractObjectiveType.KILL_ELITE:
                matches = elite_modifier_id is not None

            elif (
                objective.objective_type
                is ContractObjectiveType.KILL_ELITE_REGION
            ):
                matches = (
                    elite_modifier_id is not None
                    and objective.target_id == region_id
                )

            elif objective.objective_type is ContractObjectiveType.KILL_MINIBOSS:
                matches = (
                    is_miniboss
                    and objective.target_id == enemy_id
                )

            if not matches:
                continue

            update = _increment(
                player,
                board,
                contract,
                index,
                1,
            )
            if update is not None:
                updates.append(update)

    return updates


def record_dungeon_completion(
    player: Player,
    board: ContractBoard,
    dungeon_id: str,
) -> list[ContractProgressUpdate]:
    updates: list[ContractProgressUpdate] = []

    for contract in active_contracts(board):
        for index, objective in enumerate(contract.objectives):
            if (
                objective.objective_type
                is ContractObjectiveType.COMPLETE_DUNGEON
                and objective.target_id == dungeon_id
            ):
                update = _increment(
                    player,
                    board,
                    contract,
                    index,
                    1,
                )
                if update is not None:
                    updates.append(update)

    return updates


def claim_contract(
    player: Player,
    board: ContractBoard,
    contract_id: str,
) -> ContractClaimResult:
    contract = _find_contract(board, contract_id)

    if contract.category is ContractCategory.DAILY:
        if contract.contract_id in board.daily_claimed:
            raise ValueError("Nagroda za ten kontrakt została już odebrana.")
    elif board.weekly_claimed:
        raise ValueError("Nagroda tygodniowa została już odebrana.")

    if not contract_is_ready(player, board, contract):
        raise ValueError("Warunki kontraktu nie zostały jeszcze spełnione.")

    # Najpierw pełna walidacja dostaw, dopiero potem zmiana stanu.
    deliveries: list[tuple[str, int]] = []
    for objective in contract.objectives:
        if (
            objective.objective_type is ContractObjectiveType.COLLECT
            and objective.consume_items
        ):
            item_id = str(objective.target_id)
            if not player.inventory.has(
                item_id,
                objective.required_count,
            ):
                raise ValueError(
                    "Brakuje materiałów wymaganych do oddania kontraktu."
                )
            deliveries.append(
                (item_id, objective.required_count)
            )

    for item_id, quantity in deliveries:
        player.inventory.remove_item(item_id, quantity)

    levels_gained = player.gain_experience(contract.reward_exp)
    player.add_gold(contract.reward_gold)

    if contract.reward_item_id is not None:
        get_item_definition(contract.reward_item_id)
        player.inventory.add(
            contract.reward_item_id,
            contract.reward_item_quantity,
        )

    if contract.category is ContractCategory.DAILY:
        board.daily_claimed.add(contract.contract_id)
    else:
        board.weekly_claimed = True

    return ContractClaimResult(
        contract_id=contract.contract_id,
        title=contract.title,
        experience=contract.reward_exp,
        gold=contract.reward_gold,
        levels_gained=levels_gained,
        attribute_points_gained=(
            levels_gained * ATTRIBUTE_POINTS_PER_LEVEL
        ),
        reward_item_id=contract.reward_item_id,
        reward_item_quantity=contract.reward_item_quantity,
    )


def _increment(
    player: Player,
    board: ContractBoard,
    contract: ContractDefinition,
    objective_index: int,
    amount: int,
) -> ContractProgressUpdate | None:
    objective = contract.objectives[objective_index]
    contract_progress = board.progress.setdefault(
        contract.contract_id,
        {},
    )
    key = str(objective_index)
    old = int(contract_progress.get(key, 0))
    new = min(
        objective.required_count,
        old + max(0, amount),
    )
    contract_progress[key] = new

    if new == old:
        return None

    return ContractProgressUpdate(
        contract_id=contract.contract_id,
        title=contract.title,
        objective_index=objective_index,
        current=new,
        required=objective.required_count,
        ready=contract_is_ready(player, board, contract),
    )


def _find_contract(
    board: ContractBoard,
    contract_id: str,
) -> ContractDefinition:
    for contract in board.daily_contracts:
        if contract.contract_id == contract_id:
            return contract
    if (
        board.weekly_contract is not None
        and board.weekly_contract.contract_id == contract_id
    ):
        return board.weekly_contract
    raise KeyError(f"Nieznany kontrakt: {contract_id}")


def _remove_progress(
    board: ContractBoard,
    contract_ids: set[str],
) -> None:
    for contract_id in contract_ids:
        board.progress.pop(contract_id, None)


def _period_rng(
    player: Player,
    period_key: str,
    category: str,
) -> random.Random:
    source = (
        f"EchoesOfPythonia|{player.name}|"
        f"{category}|{period_key}"
    )
    digest = hashlib.sha256(
        source.encode("utf-8")
    ).digest()
    seed = int.from_bytes(digest[:8], "big")
    return random.Random(seed)


def _accessible_regions(level: int) -> list[str]:
    regions = [
        location_id
        for location_id in LOCATION_ORDER
        if level
        >= int(
            LOCATION_DATA[location_id]["recommended_level_min"]
        )
    ]
    return regions or [LOCATION_ORDER[0]]


def _region_enemy_ids(region_id: str) -> set[str]:
    data = LOCATION_DATA[region_id]
    return (
        set(dict(data["day_encounters"]).keys())
        | set(dict(data["night_encounters"]).keys())
    )


def _normal_enemies(region_id: str) -> list[str]:
    enemies = [
        enemy_id
        for enemy_id in sorted(_region_enemy_ids(region_id))
        if str(ENEMY_DATA[enemy_id].get("rank", "normal"))
        == "normal"
    ]
    if not enemies:
        raise RuntimeError(
            f"Brak zwykłych przeciwników w regionie {region_id}."
        )
    return enemies


def _minibosses_for_region(region_id: str) -> list[str]:
    return [
        enemy_id
        for enemy_id in sorted(_region_enemy_ids(region_id))
        if str(ENEMY_DATA[enemy_id].get("rank", "normal"))
        == "miniboss"
    ]


def _common_materials_for_region(
    region_id: str,
) -> list[str]:
    materials: set[str] = set()

    for enemy_id in _normal_enemies(region_id):
        for entry in LOOT_TABLES.get(enemy_id, ()):
            if float(entry["chance"]) < 0.20:
                continue
            item_id = str(entry["item_id"])
            item = ITEM_DATA[item_id]
            if item["category"] == "material":
                materials.add(item_id)

    if not materials:
        raise RuntimeError(
            f"Brak materiałów kontraktowych w regionie {region_id}."
        )
    return sorted(materials)
