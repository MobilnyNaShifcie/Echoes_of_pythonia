from dataclasses import dataclass
import random

from data.loot_tables import LOOT_TABLES
from items.affixes import EquipmentQuality
from items.catalog import get_item_definition
from items.models import EquipmentItem
from player.inventory import Inventory


@dataclass(frozen=True)
class LootDrop:
    item_id: str
    quantity: int = 1


@dataclass(frozen=True)
class AddedLoot:
    equipment_items: tuple[EquipmentItem, ...] = ()


def roll_loot(
    enemy_id: str,
    rng: random.Random,
    chance_multiplier: float = 1.0,
    *,
    elite: bool = False,
) -> list[LootDrop]:
    if chance_multiplier < 0:
        raise ValueError("Mnożnik dropu nie może być ujemny.")

    drops: list[LootDrop] = []
    for entry in LOOT_TABLES.get(enemy_id, ()):
        base_chance = float(
            entry.get("elite_chance", entry["chance"])
            if elite
            else entry["chance"]
        )
        if not 0.0 <= base_chance <= 1.0:
            raise ValueError(f"Nieprawidłowa szansa dropu dla {enemy_id}.")
        chance = min(1.0, base_chance * chance_multiplier)
        if rng.random() < chance:
            drops.append(
                LootDrop(
                    item_id=str(entry["item_id"]),
                    quantity=int(entry.get("quantity", 1)),
                )
            )
    return drops


def add_loot_to_inventory(
    inventory: Inventory,
    drops: list[LootDrop],
    *,
    rng: random.Random | None = None,
    equipment_quality: EquipmentQuality = EquipmentQuality.NORMAL,
) -> AddedLoot:
    actual_rng = rng or random.Random()
    generated: list[EquipmentItem] = []

    for drop in drops:
        definition = get_item_definition(drop.item_id)
        if definition.is_equipment:
            generated.extend(
                inventory.add_generated_equipment(
                    drop.item_id,
                    actual_rng,
                    quality=equipment_quality,
                    quantity=drop.quantity,
                )
            )
        else:
            inventory.add(drop.item_id, drop.quantity)

    return AddedLoot(equipment_items=tuple(generated))
