from dataclasses import dataclass, field

from data.guild import (
    DAILY_CONTRACT_REPUTATION,
    GUILD_MILESTONE_REPUTATION,
    GUILD_RANKS,
    STORY_QUEST_REPUTATION,
    WEEKLY_CONTRACT_REPUTATION,
    GuildRankDefinition,
)


@dataclass
class GuildProgress:
    reputation: int = 0
    milestones: set[str] = field(default_factory=set)


@dataclass(frozen=True)
class GuildReputationUpdate:
    amount: int
    old_rank: GuildRankDefinition
    new_rank: GuildRankDefinition
    reason: str

    @property
    def rank_changed(self) -> bool:
        return self.old_rank.code != self.new_rank.code


def guild_rank_for_reputation(reputation: int) -> GuildRankDefinition:
    reputation = max(0, int(reputation))
    result = GUILD_RANKS[0]
    for rank in GUILD_RANKS:
        if reputation >= rank.reputation_required:
            result = rank
        else:
            break
    return result


def current_guild_rank(progress: GuildProgress) -> GuildRankDefinition:
    return guild_rank_for_reputation(progress.reputation)


def next_guild_rank(progress: GuildProgress) -> GuildRankDefinition | None:
    current = current_guild_rank(progress)
    index = GUILD_RANKS.index(current)
    if index + 1 >= len(GUILD_RANKS):
        return None
    return GUILD_RANKS[index + 1]


def has_guild_rank(progress: GuildProgress, required_code: str) -> bool:
    required_index = next(
        index for index, rank in enumerate(GUILD_RANKS)
        if rank.code == required_code
    )
    current_index = GUILD_RANKS.index(current_guild_rank(progress))
    return current_index >= required_index


def _award_once(
    progress: GuildProgress,
    milestone_id: str,
    amount: int,
    reason: str,
) -> GuildReputationUpdate | None:
    if milestone_id in progress.milestones:
        return None
    old_rank = current_guild_rank(progress)
    progress.milestones.add(milestone_id)
    progress.reputation += max(0, int(amount))
    new_rank = current_guild_rank(progress)
    return GuildReputationUpdate(amount, old_rank, new_rank, reason)


def record_story_quest_reputation(
    progress: GuildProgress,
    quest_id: str,
    amount: int | None = None,
) -> GuildReputationUpdate | None:
    return _award_once(
        progress,
        f"quest:{quest_id}",
        STORY_QUEST_REPUTATION if amount is None else max(0, int(amount)),
        "zadanie fabularne Gildii",
    )


def record_contract_reputation(
    progress: GuildProgress,
    contract_id: str,
) -> GuildReputationUpdate | None:
    amount = (
        DAILY_CONTRACT_REPUTATION
        if contract_id.startswith("daily-")
        else WEEKLY_CONTRACT_REPUTATION
    )
    return _award_once(
        progress,
        f"contract:{contract_id}",
        amount,
        "kontrakt Gildii",
    )


def record_guild_milestone(
    progress: GuildProgress,
    milestone_id: str,
) -> GuildReputationUpdate | None:
    amount = GUILD_MILESTONE_REPUTATION.get(milestone_id, 0)
    if amount <= 0:
        return None
    return _award_once(progress, milestone_id, amount, "ważne osiągnięcie")


def reputation_to_next_rank(progress: GuildProgress) -> tuple[int, int] | None:
    next_rank = next_guild_rank(progress)
    if next_rank is None:
        return None
    return progress.reputation, next_rank.reputation_required
