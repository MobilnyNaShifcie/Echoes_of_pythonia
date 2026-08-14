from data.dungeons import DUNGEON_DATA
from data.enemies import ENEMY_DATA
from data.locations import LOCATION_DATA
from items.catalog import get_item_definition
from player.player import Player
from quests.contracts import (
    ContractBoard,
    ContractDefinition,
    ContractObjective,
    ContractObjectiveType,
)
from systems.contracts import (
    ContractClaimResult,
    contract_is_ready,
    objective_progress,
)
from ui.console import print_header


def objective_text(
    objective: ContractObjective,
) -> str:
    count = objective.required_count

    if objective.objective_type is ContractObjectiveType.KILL_ENEMY:
        enemy = str(ENEMY_DATA[str(objective.target_id)]["name"])
        return f"Pokonaj: {enemy} x{count}"

    if objective.objective_type is ContractObjectiveType.KILL_REGION:
        region = str(
            LOCATION_DATA[str(objective.target_id)]["name"]
        )
        return f"Wygraj walki w regionie {region}: x{count}"

    if objective.objective_type is ContractObjectiveType.COLLECT:
        item = get_item_definition(str(objective.target_id))
        return f"Dostarcz: {item.name} x{count}"

    if objective.objective_type is ContractObjectiveType.KILL_ELITE:
        return f"Pokonaj elitarne warianty przeciwników: x{count}"

    if (
        objective.objective_type
        is ContractObjectiveType.KILL_ELITE_REGION
    ):
        region = str(
            LOCATION_DATA[str(objective.target_id)]["name"]
        )
        return f"Pokonaj elity w regionie {region}: x{count}"

    if objective.objective_type is ContractObjectiveType.KILL_MINIBOSS:
        enemy = str(ENEMY_DATA[str(objective.target_id)]["name"])
        return f"Pokonaj minibossa: {enemy} x{count}"

    if (
        objective.objective_type
        is ContractObjectiveType.COMPLETE_DUNGEON
    ):
        dungeon = DUNGEON_DATA[str(objective.target_id)]
        return f"Ukończ: {dungeon['name']} x{count}"

    return "Nieznany cel"


def reward_text(contract: ContractDefinition) -> str:
    text = f"{contract.reward_exp} EXP | {contract.reward_gold} Gold"
    if contract.reward_item_id is not None:
        item = get_item_definition(contract.reward_item_id)
        text += (
            f" | {item.name} x"
            f"{contract.reward_item_quantity}"
        )
    return text


def show_daily_contracts(
    player: Player,
    board: ContractBoard,
) -> list[ContractDefinition]:
    print_header()
    print()
    print("KONTRAKTY DZIENNE")
    print("-" * 58)
    print(f"Zestaw: {board.daily_date}")
    print("Reset: następny lokalny dzień kalendarzowy.")
    print()

    for index, contract in enumerate(
        board.daily_contracts,
        start=1,
    ):
        claimed = contract.contract_id in board.daily_claimed
        ready = contract_is_ready(player, board, contract)
        status = (
            "ODEBRANE"
            if claimed
            else "GOTOWE"
            if ready
            else "W TOKU"
        )

        print(f"[{index}] {contract.title} [{status}]")
        print(f"    {contract.description}")

        for objective_index, objective in enumerate(
            contract.objectives
        ):
            current, required = objective_progress(
                player,
                board,
                contract,
                objective_index,
            )
            print(
                f"    - {objective_text(objective)} "
                f"({current}/{required})"
            )

        print(f"    Nagroda: {reward_text(contract)}")
        print()

    print(
        "Wpisz numer kontraktu [GOTOWE], aby odebrać nagrodę."
    )
    print("[0] Powrót")
    return list(board.daily_contracts)


def show_weekly_contract(
    player: Player,
    board: ContractBoard,
) -> ContractDefinition | None:
    print_header()
    print()
    print("KONTRAKT TYGODNIOWY")
    print("-" * 58)
    print(f"Tydzień: {board.weekly_key}")
    print("Reset: wraz z nowym tygodniem ISO (poniedziałek).")
    print()

    contract = board.weekly_contract
    if contract is None:
        print("Brak kontraktu tygodniowego.")
        print()
        print("[0] Powrót")
        return None

    ready = contract_is_ready(player, board, contract)
    status = (
        "ODEBRANE"
        if board.weekly_claimed
        else "GOTOWE"
        if ready
        else "W TOKU"
    )

    print(f"{contract.title} [{status}]")
    print(contract.description)
    print()

    for index, objective in enumerate(contract.objectives):
        current, required = objective_progress(
            player,
            board,
            contract,
            index,
        )
        print(
            f"- {objective_text(objective)} "
            f"({current}/{required})"
        )

    print()
    print(f"Nagroda: {reward_text(contract)}")
    print()

    if ready:
        print("[1] Odbierz nagrodę")
    print("[0] Powrót")
    return contract


def show_contract_claim(
    result: ContractClaimResult,
) -> None:
    print_header()
    print()
    print("KONTRAKT UKOŃCZONY")
    print("-" * 58)
    print(result.title)
    print(f"+ {result.experience} EXP")
    print(f"+ {result.gold} Gold")

    if result.reward_item_id is not None:
        item = get_item_definition(result.reward_item_id)
        print(
            f"+ {item.name} x{result.reward_item_quantity}"
        )

    if result.levels_gained > 0:
        print(f"AWANS! Poziomy: +{result.levels_gained}")
        print(
            f"Punkty atrybutów: "
            f"+{result.attribute_points_gained}"
        )
