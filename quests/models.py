from dataclasses import dataclass, field
from enum import Enum


class QuestObjectiveType(Enum):
    KILL = "kill"
    COLLECT = "collect"


@dataclass(frozen=True)
class QuestDefinition:
    quest_id: str
    title: str
    description: str
    recommended_level: int
    objective_type: QuestObjectiveType
    target_id: str
    required_count: int
    reward_exp: int
    reward_gold: int
    reward_item_id: str | None = None
    reward_item_quantity: int = 1
    guild_reputation: int = 50
    unlock_level: int = 0
    prerequisite_quest_id: str | None = None
    story_arc: str | None = None
    chapter: str | None = None
    completion_text: str | None = None
    consume_objective_items: bool = True


@dataclass
class QuestLog:
    """Stan zadań należący do konkretnego zapisu gry."""

    active: dict[str, int] = field(default_factory=dict)
    completed: set[str] = field(default_factory=set)
