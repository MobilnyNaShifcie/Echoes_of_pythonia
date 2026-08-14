from dataclasses import dataclass


@dataclass(frozen=True)
class GuildRankDefinition:
    code: str
    name: str
    reputation_required: int

    @property
    def display_name(self) -> str:
        return f"{self.code} — {self.name}"


GUILD_RANKS: tuple[GuildRankDefinition, ...] = (
    GuildRankDefinition("F", "Nowicjusz", 0),
    GuildRankDefinition("E", "Adept", 100),
    GuildRankDefinition("D", "Poszukiwacz", 300),
    GuildRankDefinition("C", "Zdobywca", 700),
    GuildRankDefinition("B", "Weteran", 1400),
    GuildRankDefinition("A", "Mistrz", 2600),
    GuildRankDefinition("S", "Legenda", 4500),
)

GUILD_RANK_BY_CODE = {rank.code: rank for rank in GUILD_RANKS}

STORY_QUEST_REPUTATION = 50
DAILY_CONTRACT_REPUTATION = 15
WEEKLY_CONTRACT_REPUTATION = 75

GUILD_MILESTONE_REPUTATION: dict[str, int] = {
    "boss:azhar": 100,
    "boss:leviathan_north": 150,
    "dungeon:sunken_order_crypt": 150,
    "dungeon:black_fleet_wreck": 250,
}

DAILY_UNLOCK_RANK = "E"
WEEKLY_UNLOCK_RANK = "D"
BLACK_MARKET_CONTACT_RANK = "C"
