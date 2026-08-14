from dataclasses import dataclass, field
from typing import Optional

from game.adventure_log import AdventureLog
from companions.models import PartyState
from rifts.models import RiftState
from game.config import STARTING_CITY_ID, STARTING_LOCATION_ID
from systems.black_market import BlackMarketState
from systems.guild_storage import GuildStorage
from systems.guild_progression import GuildProgress
from systems.expedition_preparation import ExpeditionPreparationState
from player.player import Player
from quests.contracts import ContractBoard
from quests.models import QuestLog
from world.time_system import GameClock
from world.weather import WeatherState


@dataclass
class GameState:
    running: bool = True
    active_game: bool = False
    player: Optional[Player] = None
    current_location_id: str = STARTING_LOCATION_ID
    current_city_id: str = STARTING_CITY_ID
    world_clock: GameClock = field(default_factory=GameClock)
    weather: WeatherState = field(default_factory=WeatherState)
    quest_log: QuestLog = field(default_factory=QuestLog)
    contract_board: ContractBoard = field(default_factory=ContractBoard)
    elite_discoveries: set[str] = field(default_factory=set)
    elite_miss_streaks: dict[str, int] = field(default_factory=dict)
    region_boss_respawns: dict[str, int] = field(default_factory=dict)
    guild_progress: GuildProgress = field(default_factory=GuildProgress)
    black_market: BlackMarketState = field(default_factory=BlackMarketState)
    guild_storage: GuildStorage = field(default_factory=GuildStorage)
    adventure_log: AdventureLog = field(default_factory=AdventureLog)
    party: PartyState = field(default_factory=PartyState)
    rifts: RiftState = field(default_factory=RiftState)
    expedition_preparation: ExpeditionPreparationState = field(default_factory=ExpeditionPreparationState)
    camp_rest_available: bool = True
    last_inn_rest_day: int = 0
