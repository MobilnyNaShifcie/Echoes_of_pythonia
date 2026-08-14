from dataclasses import dataclass

from combat.elements import ElementalResistances
from data.item_sets import ITEM_SET_DATA
from items.catalog import get_item_definition
from items.models import EquipmentItem


@dataclass(frozen=True)
class ActiveSetBonus:
    set_id: str
    name: str
    attack: int = 0
    defense: int = 0
    max_hp: int = 0
    dodge: float = 0.0
    max_mana: int = 0
    resistances: ElementalResistances = ElementalResistances()


def get_active_set_bonuses(
    equipped_items: list[EquipmentItem],
) -> list[ActiveSetBonus]:
    equipped_ids = {item.item_id for item in equipped_items}
    active: list[ActiveSetBonus] = []

    for set_id, data in ITEM_SET_DATA.items():
        required = set(data["required_items"])
        if not required.issubset(equipped_ids):
            continue

        active.append(
            ActiveSetBonus(
                set_id=set_id,
                name=str(data["name"]),
                attack=int(data.get("attack", 0)),
                defense=int(data.get("defense", 0)),
                max_hp=int(data.get("max_hp", 0)),
                dodge=float(data.get("dodge", 0.0)),
                max_mana=int(data.get("max_mana", 0)),
                resistances=ElementalResistances(
                    fire=int(data.get("fire_resistance", 0)),
                    wind=int(data.get("wind_resistance", 0)),
                    frost=int(data.get("frost_resistance", 0)),
                    earth=int(data.get("earth_resistance", 0)),
                    water=int(data.get("water_resistance", 0)),
                ),
            )
        )

    return active
