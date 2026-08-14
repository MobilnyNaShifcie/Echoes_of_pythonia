from __future__ import annotations

from dataclasses import dataclass, field

from items.models import EquipmentItem, EquipmentSlot
from player.attributes import Attributes
from player.equipment import Equipment

COMPANION_TACTICS: dict[str, str] = {
    "aggressive": "Agresywna",
    "balanced": "Zrównoważona",
    "cautious": "Ostrożna",
    "defensive": "Obronna",
}


@dataclass
class Companion:
    companion_id: str
    template_id: str
    name: str
    class_code: str
    level: int
    experience: int
    path_id: str
    talents: dict[str, int]
    attributes: Attributes
    equipment: Equipment = field(default_factory=Equipment)
    personal_instance_ids: set[str] = field(default_factory=set)
    personal_storage: list[EquipmentItem] = field(default_factory=list)
    relation: int = 0
    quest_arc_id: str = ""
    quest_stage: int = 0
    memories: set[str] = field(default_factory=set)
    rifts_together: int = 0
    injury_until_day: int = 0
    dead: bool = False
    active: bool = False
    tactic: str = "balanced"
    current_hp: int = 0
    current_mana: int = 0
    dismissed_day: int = 0

    @property
    def is_injured(self) -> bool:
        return self.injury_until_day > 0

    @property
    def can_join_party(self) -> bool:
        return not self.dead and not self.is_injured

    def owns_item(self, item: EquipmentItem) -> bool:
        return item.instance_id in self.personal_instance_ids


@dataclass
class CompanionCandidate:
    candidate_id: str
    companion: Companion
    generated_day: int
    recruitment_roll: int
    impression: int = 0
    talked: bool = False
    recruitment_attempted: bool = False
    returning: bool = False


@dataclass(frozen=True)
class PartyMessage:
    day: int
    sender_id: str
    sender_name: str
    text: str
    read: bool = False


@dataclass(frozen=True)
class FallenCompanion:
    companion_id: str
    name: str
    class_code: str
    level: int
    day: int
    cause: str
    rift_rank: str | None = None


@dataclass
class PartyState:
    companions: list[Companion] = field(default_factory=list)
    dismissed_companions: list[Companion] = field(default_factory=list)
    candidates_day: int = 0
    candidates: list[CompanionCandidate] = field(default_factory=list)
    messages: list[PartyMessage] = field(default_factory=list)
    last_message_day: int = 0
    seen_banter: set[str] = field(default_factory=set)
    fallen: list[FallenCompanion] = field(default_factory=list)

    def living_companions(self) -> list[Companion]:
        return [companion for companion in self.companions if not companion.dead]

    def active_companions(self) -> list[Companion]:
        return [
            companion
            for companion in self.companions
            if companion.active and companion.can_join_party
        ]

    def companion_by_id(self, companion_id: str) -> Companion | None:
        for companion in self.companions:
            if companion.companion_id == companion_id:
                return companion
        return None

    def unread_messages(self) -> int:
        return sum(1 for message in self.messages if not message.read)
