from __future__ import annotations

from dataclasses import dataclass, field


@dataclass(frozen=True)
class RiftModifier:
    modifier_id: str
    name: str
    description: str
    enemy_hp_multiplier: float = 1.0
    enemy_attack_multiplier: float = 1.0
    enemy_defense_bonus: int = 0
    player_mana_cost_multiplier: float = 1.0


@dataclass
class RiftInstance:
    rift_id: str
    rank_code: str
    theme_id: str
    theme_name: str
    modifier_ids: tuple[str, ...]
    discovered_day: int
    expires_day: int
    seed: int
    segment_count: int
    boss_id: str
    boss_name: str
    closed: bool = False
    closed_by: str = ""


@dataclass
class RiftExpedition:
    rift_id: str
    segment_index: int = 0
    party_companion_ids: tuple[str, ...] = ()
    secured_rewards: dict[str, int] = field(default_factory=dict)
    pending_unique_item_id: str | None = None
    started_day: int = 0
    camp_visits: int = 0
    defeated: bool = False


@dataclass
class RiftState:
    active_rift: RiftInstance | None = None
    expedition: RiftExpedition | None = None
    next_spawn_day: int = 2
    last_resolution_day: int = 0
    completed_total: int = 0
    completed_by_rank: dict[str, int] = field(default_factory=dict)
    last_notice: str = ""
