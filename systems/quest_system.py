from dataclasses import dataclass

from game.config import ATTRIBUTE_POINTS_PER_LEVEL
from items.catalog import get_item_definition
from player.player import Player
from quests.catalog import get_all_quests, get_quest
from quests.models import QuestDefinition, QuestLog, QuestObjectiveType


@dataclass(frozen=True)
class QuestProgressUpdate:
    quest_id: str
    title: str
    current: int
    required: int
    ready: bool


@dataclass(frozen=True)
class QuestTurnInResult:
    quest_id: str
    title: str
    experience: int
    gold: int
    levels_gained: int
    attribute_points_gained: int
    reward_item_id: str | None = None
    reward_item_quantity: int = 0
    completion_text: str | None = None


def get_available_quests(
    log: QuestLog,
    player_level: int | None = None,
) -> list[QuestDefinition]:
    normalize_quest_log(log)
    available: list[QuestDefinition] = []
    for quest in get_all_quests():
        if quest.quest_id in log.active or quest.quest_id in log.completed:
            continue
        if player_level is not None and player_level < quest.unlock_level:
            continue
        if (
            quest.prerequisite_quest_id is not None
            and quest.prerequisite_quest_id not in log.completed
        ):
            continue
        available.append(quest)
    return available


def normalize_quest_log(log: QuestLog) -> None:
    """Ukończone zadanie zawsze ma pierwszeństwo nad stanem aktywnym.

    Funkcja jest celowo idempotentna i naprawia także ewentualny stary
    niespójny stan, w którym quest znalazł się jednocześnie w obu zbiorach.
    """
    for quest_id in tuple(log.completed):
        log.active.pop(quest_id, None)


def get_active_quests(log: QuestLog) -> list[QuestDefinition]:
    normalize_quest_log(log)
    return [
        quest for quest in get_all_quests()
        if quest.quest_id in log.active
        and quest.quest_id not in log.completed
    ]


def accept_quest(log: QuestLog, quest_id: str) -> None:
    normalize_quest_log(log)
    quest = get_quest(quest_id)

    if quest.quest_id in log.completed:
        raise ValueError("To zadanie zostało już ukończone.")
    if quest.quest_id in log.active:
        raise ValueError("To zadanie jest już aktywne.")
    if (
        quest.prerequisite_quest_id is not None
        and quest.prerequisite_quest_id not in log.completed
    ):
        prerequisite = get_quest(quest.prerequisite_quest_id)
        raise ValueError(
            f"Najpierw ukończ zadanie: {prerequisite.title}."
        )

    log.active[quest.quest_id] = 0


def objective_progress(
    player: Player,
    log: QuestLog,
    quest: QuestDefinition,
) -> tuple[int, int]:
    if quest.quest_id not in log.active:
        return 0, quest.required_count

    if quest.objective_type is QuestObjectiveType.KILL:
        current = log.active.get(quest.quest_id, 0)
    else:
        current = player.inventory.count(quest.target_id)

    return min(current, quest.required_count), quest.required_count


def is_ready_to_turn_in(
    player: Player,
    log: QuestLog,
    quest: QuestDefinition,
) -> bool:
    normalize_quest_log(log)
    if quest.quest_id in log.completed:
        return False
    current, required = objective_progress(player, log, quest)
    return quest.quest_id in log.active and current >= required


def get_ready_quests(player: Player, log: QuestLog) -> list[QuestDefinition]:
    return [
        quest for quest in get_active_quests(log)
        if is_ready_to_turn_in(player, log, quest)
    ]


def record_enemy_kill(log: QuestLog, enemy_id: str) -> list[QuestProgressUpdate]:
    updates: list[QuestProgressUpdate] = []

    for quest in get_active_quests(log):
        if quest.objective_type is not QuestObjectiveType.KILL:
            continue
        if quest.target_id != enemy_id:
            continue

        old = log.active.get(quest.quest_id, 0)
        new = min(old + 1, quest.required_count)
        log.active[quest.quest_id] = new

        if new != old:
            updates.append(
                QuestProgressUpdate(
                    quest_id=quest.quest_id,
                    title=quest.title,
                    current=new,
                    required=quest.required_count,
                    ready=new >= quest.required_count,
                )
            )

    return updates


def turn_in_quest(
    player: Player,
    log: QuestLog,
    quest_id: str,
) -> QuestTurnInResult:
    normalize_quest_log(log)
    quest = get_quest(quest_id)

    if quest.quest_id in log.completed:
        raise ValueError("To zadanie zostało już ukończone.")
    if quest.quest_id not in log.active:
        raise ValueError("To zadanie nie jest aktywne.")
    if not is_ready_to_turn_in(player, log, quest):
        raise ValueError("Warunki zadania nie zostały jeszcze spełnione.")

    if (
        quest.objective_type is QuestObjectiveType.COLLECT
        and quest.consume_objective_items
    ):
        player.inventory.remove_item(
            quest.target_id,
            quest.required_count,
        )

    levels_gained = player.gain_experience(quest.reward_exp)
    player.add_gold(quest.reward_gold)

    if quest.reward_item_id is not None:
        get_item_definition(quest.reward_item_id)
        player.inventory.add(
            quest.reward_item_id,
            quest.reward_item_quantity,
        )

    # Stan questa zmieniamy jednoznacznie: ukończony quest nie może
    # pozostać aktywny ani ponownie trafić na listę dostępnych zadań.
    log.active.pop(quest.quest_id, None)
    log.completed.add(quest.quest_id)
    normalize_quest_log(log)

    return QuestTurnInResult(
        quest_id=quest.quest_id,
        title=quest.title,
        experience=quest.reward_exp,
        gold=quest.reward_gold,
        levels_gained=levels_gained,
        attribute_points_gained=(
            levels_gained * ATTRIBUTE_POINTS_PER_LEVEL
        ),
        reward_item_id=quest.reward_item_id,
        reward_item_quantity=(
            quest.reward_item_quantity
            if quest.reward_item_id is not None
            else 0
        ),
        completion_text=quest.completion_text,
    )
