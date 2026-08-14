from dataclasses import dataclass, field
from enum import Enum
from typing import Any


class ContractCategory(Enum):
    DAILY = "daily"
    WEEKLY = "weekly"


class ContractObjectiveType(Enum):
    KILL_ENEMY = "kill_enemy"
    KILL_REGION = "kill_region"
    COLLECT = "collect"
    KILL_ELITE = "kill_elite"
    KILL_ELITE_REGION = "kill_elite_region"
    KILL_MINIBOSS = "kill_miniboss"
    COMPLETE_DUNGEON = "complete_dungeon"


@dataclass(frozen=True)
class ContractObjective:
    objective_type: ContractObjectiveType
    target_id: str | None
    required_count: int
    consume_items: bool = False


@dataclass(frozen=True)
class ContractDefinition:
    contract_id: str
    category: ContractCategory
    period_key: str
    title: str
    description: str
    recommended_level: int
    objectives: tuple[ContractObjective, ...]
    reward_exp: int
    reward_gold: int
    reward_item_id: str | None = None
    reward_item_quantity: int = 0


@dataclass
class ContractBoard:
    daily_date: str = ""
    daily_contracts: list[ContractDefinition] = field(default_factory=list)
    daily_claimed: set[str] = field(default_factory=set)

    weekly_key: str = ""
    weekly_contract: ContractDefinition | None = None
    weekly_claimed: bool = False

    # contract_id -> objective_index_as_string -> progress
    progress: dict[str, dict[str, int]] = field(default_factory=dict)


def objective_to_dict(
    objective: ContractObjective,
) -> dict[str, Any]:
    return {
        "objective_type": objective.objective_type.value,
        "target_id": objective.target_id,
        "required_count": objective.required_count,
        "consume_items": objective.consume_items,
    }


def objective_from_dict(
    data: dict[str, Any],
) -> ContractObjective:
    return ContractObjective(
        objective_type=ContractObjectiveType(
            str(data["objective_type"])
        ),
        target_id=(
            None
            if data.get("target_id") is None
            else str(data["target_id"])
        ),
        required_count=int(data["required_count"]),
        consume_items=bool(data.get("consume_items", False)),
    )


def contract_to_dict(
    contract: ContractDefinition,
) -> dict[str, Any]:
    return {
        "contract_id": contract.contract_id,
        "category": contract.category.value,
        "period_key": contract.period_key,
        "title": contract.title,
        "description": contract.description,
        "recommended_level": contract.recommended_level,
        "objectives": [
            objective_to_dict(objective)
            for objective in contract.objectives
        ],
        "reward_exp": contract.reward_exp,
        "reward_gold": contract.reward_gold,
        "reward_item_id": contract.reward_item_id,
        "reward_item_quantity": contract.reward_item_quantity,
    }


def contract_from_dict(
    data: dict[str, Any],
) -> ContractDefinition:
    return ContractDefinition(
        contract_id=str(data["contract_id"]),
        category=ContractCategory(str(data["category"])),
        period_key=str(data["period_key"]),
        title=str(data["title"]),
        description=str(data["description"]),
        recommended_level=int(data["recommended_level"]),
        objectives=tuple(
            objective_from_dict(dict(objective))
            for objective in list(data["objectives"])
        ),
        reward_exp=int(data["reward_exp"]),
        reward_gold=int(data["reward_gold"]),
        reward_item_id=(
            None
            if data.get("reward_item_id") is None
            else str(data["reward_item_id"])
        ),
        reward_item_quantity=int(
            data.get("reward_item_quantity", 0)
        ),
    )
