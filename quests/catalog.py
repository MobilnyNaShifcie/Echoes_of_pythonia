from data.quests import QUEST_DATA, QUEST_ORDER
from quests.models import QuestDefinition, QuestObjectiveType


_OBJECTIVE_BY_CODE = {
    objective.value: objective
    for objective in QuestObjectiveType
}


def get_quest(quest_id: str) -> QuestDefinition:
    if quest_id not in QUEST_DATA:
        raise KeyError(f"Nieznane zadanie: {quest_id}")

    data = QUEST_DATA[quest_id]
    return QuestDefinition(
        quest_id=quest_id,
        title=str(data["title"]),
        description=str(data["description"]),
        recommended_level=int(data["recommended_level"]),
        objective_type=_OBJECTIVE_BY_CODE[str(data["objective_type"])],
        target_id=str(data["target_id"]),
        required_count=int(data["required_count"]),
        reward_exp=int(data["reward_exp"]),
        reward_gold=int(data["reward_gold"]),
        reward_item_id=(
            None if data.get("reward_item_id") is None
            else str(data["reward_item_id"])
        ),
        reward_item_quantity=int(data.get("reward_item_quantity", 1)),
        guild_reputation=int(data.get("guild_reputation", 50)),
        unlock_level=int(data.get("unlock_level", data["recommended_level"])),
        prerequisite_quest_id=(
            None if data.get("prerequisite_quest_id") is None
            else str(data["prerequisite_quest_id"])
        ),
        story_arc=(None if data.get("story_arc") is None else str(data["story_arc"])),
        chapter=(None if data.get("chapter") is None else str(data["chapter"])),
        completion_text=(
            None if data.get("completion_text") is None
            else str(data["completion_text"])
        ),
        consume_objective_items=bool(data.get("consume_objective_items", True)),
    )


def get_all_quests() -> list[QuestDefinition]:
    return [get_quest(quest_id) for quest_id in QUEST_ORDER]


def quest_exists(quest_id: str) -> bool:
    return quest_id in QUEST_DATA
