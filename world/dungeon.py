from dataclasses import dataclass
import random

from data.dungeons import DUNGEON_DATA
from items.affixes import EquipmentQuality
from items.catalog import get_item_definition
from items.loot import LootDrop, add_loot_to_inventory
from player.inventory import Inventory
from player.player import Player


@dataclass(frozen=True)
class DungeonDefinition:
    dungeon_id: str
    name: str
    description: str
    recommended_level_min: int
    recommended_level_max: int
    room_one_enemies: tuple[str, ...]
    room_two_enemies: tuple[str, ...]
    room_three_enemies: tuple[str, ...]
    iron_path_enemy: str
    flooded_ambush_enemy: str
    flooded_ambush_chance: float
    mandatory_elite_enemy: str
    boss_enemy: str
    flooded_chest_loot: tuple[dict[str, object], ...]
    entry_item_id: str | None = None
    entry_item_quantity: int = 0
    entry_source_text: str = ""

    @property
    def recommended_level_text(self) -> str:
        return f"{self.recommended_level_min}-{self.recommended_level_max}"


@dataclass(frozen=True)
class DungeonLootSnapshot:
    stack_counts: dict[str, int]
    equipment_instance_ids: frozenset[str]


@dataclass(frozen=True)
class DungeonLootChange:
    item_id: str
    quantity: int


def create_dungeon(dungeon_id: str) -> DungeonDefinition:
    if dungeon_id not in DUNGEON_DATA:
        raise KeyError(f"Nieznany dungeon: {dungeon_id}")
    data = DUNGEON_DATA[dungeon_id]
    return DungeonDefinition(
        dungeon_id=dungeon_id,
        name=str(data["name"]),
        description=str(data["description"]),
        recommended_level_min=int(data["recommended_level_min"]),
        recommended_level_max=int(data["recommended_level_max"]),
        room_one_enemies=tuple(data["room_one_enemies"]),
        room_two_enemies=tuple(data["room_two_enemies"]),
        room_three_enemies=tuple(data["room_three_enemies"]),
        iron_path_enemy=str(data["iron_path_enemy"]),
        flooded_ambush_enemy=str(data["flooded_ambush_enemy"]),
        flooded_ambush_chance=float(data["flooded_ambush_chance"]),
        mandatory_elite_enemy=str(data["mandatory_elite_enemy"]),
        boss_enemy=str(data["boss_enemy"]),
        flooded_chest_loot=tuple(data["flooded_chest_loot"]),
        entry_item_id=(
            None
            if data.get("entry_item_id") is None
            else str(data["entry_item_id"])
        ),
        entry_item_quantity=int(data.get("entry_item_quantity", 0)),
        entry_source_text=str(data.get("entry_source_text", "")),
    )


def capture_dungeon_loot_snapshot(inventory: Inventory) -> DungeonLootSnapshot:
    return DungeonLootSnapshot(
        stack_counts=dict(inventory.stacks),
        equipment_instance_ids=frozenset(
            item.instance_id for item in inventory.equipment_items
        ),
    )


def dungeon_loot_since_snapshot(
    inventory: Inventory,
    snapshot: DungeonLootSnapshot,
) -> list[DungeonLootChange]:
    changes: dict[str, int] = {}

    for item_id, current in inventory.stacks.items():
        baseline = snapshot.stack_counts.get(item_id, 0)
        if current > baseline:
            changes[item_id] = changes.get(item_id, 0) + current - baseline

    for item in inventory.equipment_items:
        if item.instance_id not in snapshot.equipment_instance_ids:
            changes[item.item_id] = changes.get(item.item_id, 0) + 1

    return [
        DungeonLootChange(item_id=item_id, quantity=quantity)
        for item_id, quantity in sorted(
            changes.items(),
            key=lambda pair: get_item_definition(pair[0]).name,
        )
    ]


def discard_unsecured_dungeon_loot(
    inventory: Inventory,
    snapshot: DungeonLootSnapshot,
) -> list[DungeonLootChange]:
    lost = dungeon_loot_since_snapshot(inventory, snapshot)

    for item_id, current in list(inventory.stacks.items()):
        baseline = snapshot.stack_counts.get(item_id, 0)
        if current > baseline:
            if baseline > 0:
                inventory.stacks[item_id] = baseline
            else:
                del inventory.stacks[item_id]

    inventory.equipment_items = [
        item
        for item in inventory.equipment_items
        if item.instance_id in snapshot.equipment_instance_ids
    ]

    return lost


def roll_dungeon_chest(
    dungeon: DungeonDefinition,
    inventory: Inventory,
    rng: random.Random,
) -> list[LootDrop]:
    drops: list[LootDrop] = []
    for entry in dungeon.flooded_chest_loot:
        chance = float(entry["chance"])
        if not 0.0 <= chance <= 1.0:
            raise ValueError("Nieprawidłowa szansa łupu ze skrzyni.")
        if rng.random() < chance:
            drops.append(
                LootDrop(
                    item_id=str(entry["item_id"]),
                    quantity=int(entry.get("quantity", 1)),
                )
            )
    add_loot_to_inventory(
        inventory,
        drops,
        rng=rng,
        equipment_quality=EquipmentQuality.DUNGEON,
    )
    return drops


def restore_dungeon_resources(
    player: Player,
    fraction: float,
) -> tuple[int, int]:
    if not 0.0 < fraction <= 1.0:
        raise ValueError("Ułamek odnowienia musi mieścić się w zakresie (0, 1].")

    hp_amount = max(1, int(round(player.stats.max_hp * fraction)))
    healed_hp = player.stats.heal(hp_amount)

    if player.stats.max_mana <= 0:
        return healed_hp, 0

    mana_amount = max(1, int(round(player.stats.max_mana * fraction)))
    before = player.stats.current_mana
    player.stats.current_mana = min(
        player.stats.max_mana,
        player.stats.current_mana + mana_amount,
    )
    return healed_hp, player.stats.current_mana - before


def use_dungeon_shrine(player: Player) -> tuple[int, int]:
    return restore_dungeon_resources(player, 0.25)


def use_medical_cabin(player: Player) -> tuple[int, int]:
    return restore_dungeon_resources(player, 0.30)



def dungeon_entry_item_count(
    inventory: Inventory,
    dungeon: DungeonDefinition,
) -> int:
    if dungeon.entry_item_id is None:
        return 0
    return inventory.count(dungeon.entry_item_id)


def can_enter_dungeon(
    inventory: Inventory,
    dungeon: DungeonDefinition,
) -> bool:
    if dungeon.entry_item_id is None:
        return True
    return inventory.has(
        dungeon.entry_item_id,
        max(1, dungeon.entry_item_quantity),
    )


def consume_dungeon_entry(
    inventory: Inventory,
    dungeon: DungeonDefinition,
) -> None:
    """Zużywa wejściówkę dopiero po pełnej walidacji wymagania."""
    if dungeon.entry_item_id is None:
        return

    quantity = max(1, dungeon.entry_item_quantity)

    if not inventory.has(dungeon.entry_item_id, quantity):
        definition = get_item_definition(dungeon.entry_item_id)
        raise ValueError(
            f"Brak wejściówki: {definition.name} x{quantity}."
        )

    inventory.remove_item(dungeon.entry_item_id, quantity)
