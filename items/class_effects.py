from dataclasses import dataclass
from typing import TYPE_CHECKING

from data.class_effects import CLASS_EFFECT_DATA
from items.catalog import get_item_definition

if TYPE_CHECKING:
    from player.player import Player


@dataclass(frozen=True)
class ClassEffectDefinition:
    effect_id: str
    name: str
    player_class_code: str
    player_class_name: str
    description: str


def get_class_effect(effect_id: str) -> ClassEffectDefinition:
    try:
        data = CLASS_EFFECT_DATA[effect_id]
    except KeyError as error:
        raise KeyError(f"Nieznany efekt klasowy: {effect_id}") from error
    return ClassEffectDefinition(
        effect_id=effect_id,
        name=str(data["name"]),
        player_class_code=str(data["class"]),
        player_class_name=str(data["class_name"]),
        description=str(data["description"]),
    )


def equipped_class_effect_ids(player: "Player") -> tuple[str, ...]:
    result: list[str] = []
    for item in player.equipment.slots.values():
        effect_id = get_item_definition(item.item_id).class_effect_id
        if effect_id is not None:
            result.append(effect_id)
    return tuple(result)


def has_active_class_effect(player: "Player", effect_id: str) -> bool:
    if effect_id not in equipped_class_effect_ids(player):
        return False
    effect = get_class_effect(effect_id)
    return player.character_class.code == effect.player_class_code
