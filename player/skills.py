from dataclasses import dataclass
from typing import TYPE_CHECKING

from data.skills import CLASS_SKILL_ORDER, SKILL_DATA
from player.classes import PlayerClass

if TYPE_CHECKING:
    from player.player import Player


@dataclass(frozen=True)
class SkillDefinition:
    skill_id: str
    name: str
    player_class: PlayerClass
    unlock_level: int
    mana_cost: int
    description: str
    scaling: str
    multiplier: float
    damage_type: str
    hits: int
    effect: str | None
    effect_value: int
    effect_duration: int
    guaranteed_hit: bool
    required_weapon_type: str | None = None
    required_offhand_type: str | None = None
    hunter_technique: str | None = None
    special_armor_penetration: float = 0.0

    @property
    def is_offensive(self) -> bool:
        # Część nowych umiejętności nie używa statycznego `hits`, bo liczbę
        # trafień wyznacza mechanika klasy (Pierrot) albo efekt opóźniony.
        if self.hits > 0 or self.effect == "delayed_rain":
            return True
        return bool(
            self.effect
            and self.effect.startswith("fate_")
            and self.effect != "fate_feint"
        )


def _class_from_code(code: str) -> PlayerClass:
    for player_class in PlayerClass:
        if player_class.code == code:
            return player_class
    raise ValueError(f"Nieznana klasa w definicji umiejętności: {code}")


def get_skill(skill_id: str) -> SkillDefinition:
    try:
        data = SKILL_DATA[skill_id]
    except KeyError as error:
        raise KeyError(f"Nieznana umiejętność: {skill_id}") from error

    return SkillDefinition(
        skill_id=skill_id,
        name=str(data["name"]),
        player_class=_class_from_code(str(data["class"])),
        unlock_level=int(data["unlock_level"]),
        mana_cost=int(data["mana_cost"]),
        description=str(data["description"]),
        scaling=str(data["scaling"]),
        multiplier=float(data["multiplier"]),
        damage_type=str(data["damage_type"]),
        hits=int(data["hits"]),
        effect=(
            None
            if data.get("effect") is None
            else str(data["effect"])
        ),
        effect_value=int(data.get("effect_value", 0)),
        effect_duration=int(data.get("effect_duration", 0)),
        guaranteed_hit=bool(data.get("guaranteed_hit", False)),
        required_weapon_type=(None if data.get("required_weapon_type") is None else str(data["required_weapon_type"])),
        required_offhand_type=(None if data.get("required_offhand_type") is None else str(data["required_offhand_type"])),
        hunter_technique=(None if data.get("hunter_technique") is None else str(data["hunter_technique"])),
        special_armor_penetration=float(data.get("special_armor_penetration", 0.0)),
    )


def skills_for_class(
    player_class: PlayerClass,
) -> list[SkillDefinition]:
    if player_class is PlayerClass.NONE:
        return []

    skill_ids = CLASS_SKILL_ORDER.get(player_class.code, ())
    return [get_skill(skill_id) for skill_id in skill_ids]


def unlocked_skills(player: "Player") -> list[SkillDefinition]:
    from player.talents import active_skill_talent_ids
    skill_ids = list(CLASS_SKILL_ORDER.get(player.character_class.code, ()))
    for skill_id in sorted(active_skill_talent_ids(player)):
        if skill_id not in skill_ids:
            skill_ids.append(skill_id)
    return [
        get_skill(skill_id)
        for skill_id in skill_ids
        if player.level >= get_skill(skill_id).unlock_level
    ]


def skill_is_unlocked(
    player: "Player",
    skill: SkillDefinition,
) -> bool:
    return any(candidate.skill_id == skill.skill_id for candidate in unlocked_skills(player))
