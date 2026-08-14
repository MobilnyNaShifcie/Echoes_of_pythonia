from player.achievements import AchievementDefinition
from player.player import Player
from quests.models import QuestLog
from world.weather import WeatherType


BOSS_ACHIEVEMENTS = {
    "nature_guardian": "nature_breaker",
    "blackwood_executioner": "executioners_end",
    "drowned_mother": "silence_the_mother",
}


def _unlock(player: Player, achievement_id: str) -> list[AchievementDefinition]:
    unlocked = player.achievements.unlock(achievement_id)
    return [] if unlocked is None else [unlocked]


def achievements_after_victory(
    player: Player,
    enemy_id: str,
    weather: WeatherType,
) -> list[AchievementDefinition]:
    results: list[AchievementDefinition] = []
    results.extend(_unlock(player, "first_blood"))

    boss_achievement = BOSS_ACHIEVEMENTS.get(enemy_id)
    if boss_achievement is not None:
        results.extend(_unlock(player, boss_achievement))

    if weather is WeatherType.AURORA:
        results.extend(_unlock(player, "aurora_hunter"))

    return results


def achievements_after_upgrade(
    player: Player,
    upgrade_level: int,
) -> list[AchievementDefinition]:
    if upgrade_level >= 10:
        return _unlock(player, "master_smith")
    return []


def achievements_after_quest_turn_in(
    player: Player,
    log: QuestLog,
    total_quest_count: int,
) -> list[AchievementDefinition]:
    # Od v0.22 Weteran Gildii jest nagrodą za rangę S, nie za samą
    # liczbę jednorazowych zadań.
    return []


def achievements_after_guild_rank(
    player: Player,
    rank_code: str,
) -> list[AchievementDefinition]:
    if rank_code == "S":
        return _unlock(player, "guild_veteran")
    return []


def reconcile_existing_progress(
    player: Player,
    log: QuestLog,
    total_quest_count: int,
) -> list[AchievementDefinition]:
    """Nadaje osiągnięcia, które można jednoznacznie wywnioskować ze starego sejwa."""
    results: list[AchievementDefinition] = []

    all_items = list(player.equipment.slots.values()) + list(player.inventory.equipment_items)
    if any(item.upgrade_level >= 10 for item in all_items):
        results.extend(_unlock(player, "master_smith"))

    if "mother_below" in log.completed:
        results.extend(_unlock(player, "silence_the_mother"))

    return results
