from __future__ import annotations

from dataclasses import dataclass, field

from player.inventory import Inventory


GUILD_STORAGE_CAPACITY_SLOTS = 200


@dataclass
class GuildStorage:
    inventory: Inventory = field(default_factory=Inventory)

    @property
    def used_slots(self) -> int:
        # Każdy stos zajmuje jedno miejsce niezależnie od ilości.
        return len(self.inventory.stacks) + len(self.inventory.equipment_items)

    @property
    def free_slots(self) -> int:
        return max(0, GUILD_STORAGE_CAPACITY_SLOTS - self.used_slots)

    def can_accept_stack(self, item_id: str) -> bool:
        return item_id in self.inventory.stacks or self.used_slots < GUILD_STORAGE_CAPACITY_SLOTS

    def can_accept_equipment(self) -> bool:
        return self.used_slots < GUILD_STORAGE_CAPACITY_SLOTS


def deposit_stack(player, storage: GuildStorage, item_id: str, quantity: int) -> None:
    if quantity <= 0:
        raise ValueError("Ilość musi być większa od zera.")
    if not player.inventory.has(item_id, quantity):
        raise ValueError("Nie masz tylu sztuk tego przedmiotu.")
    if not storage.can_accept_stack(item_id):
        raise ValueError("Magazyn Gildii jest pełny.")
    player.inventory.remove_item(item_id, quantity)
    storage.inventory.add(item_id, quantity)


def withdraw_stack(player, storage: GuildStorage, item_id: str, quantity: int) -> None:
    if quantity <= 0:
        raise ValueError("Ilość musi być większa od zera.")
    if not storage.inventory.has(item_id, quantity):
        raise ValueError("W magazynie nie ma tylu sztuk tego przedmiotu.")
    storage.inventory.remove_item(item_id, quantity)
    player.inventory.add(item_id, quantity)


def deposit_equipment(player, storage: GuildStorage, inventory_index: int):
    if not storage.can_accept_equipment():
        raise ValueError("Magazyn Gildii jest pełny.")
    item = player.inventory.pop_equipment(inventory_index)
    storage.inventory.add_equipment_instance(item)
    return item


def withdraw_equipment(player, storage: GuildStorage, storage_index: int):
    item = storage.inventory.pop_equipment(storage_index)
    player.inventory.add_equipment_instance(item)
    return item


def deposit_stacks(
    player,
    storage: GuildStorage,
    selections: dict[str, int],
) -> dict[str, int]:
    """Atomowo odkłada wiele stosów do Magazynu Gildii."""
    if not selections:
        raise ValueError("Nie wybrano żadnych przedmiotów.")

    required_new_slots = 0
    for item_id, quantity in selections.items():
        if quantity <= 0:
            raise ValueError("Ilość musi być większa od zera.")
        if not player.inventory.has(item_id, quantity):
            raise ValueError("Nie masz tylu sztuk jednego z wybranych przedmiotów.")
        if item_id not in storage.inventory.stacks:
            required_new_slots += 1

    if required_new_slots > storage.free_slots:
        raise ValueError(
            "Za mało wolnych miejsc w Magazynie Gildii "
            f"(potrzeba {required_new_slots}, wolne {storage.free_slots})."
        )

    for item_id, quantity in selections.items():
        player.inventory.remove_item(item_id, quantity)
        storage.inventory.add(item_id, quantity)

    return dict(selections)


def withdraw_stacks(
    player,
    storage: GuildStorage,
    selections: dict[str, int],
) -> dict[str, int]:
    """Atomowo odbiera wiele stosów z Magazynu Gildii."""
    if not selections:
        raise ValueError("Nie wybrano żadnych przedmiotów.")

    for item_id, quantity in selections.items():
        if quantity <= 0:
            raise ValueError("Ilość musi być większa od zera.")
        if not storage.inventory.has(item_id, quantity):
            raise ValueError("W magazynie nie ma tylu sztuk jednego z wybranych przedmiotów.")

    for item_id, quantity in selections.items():
        storage.inventory.remove_item(item_id, quantity)
        player.inventory.add(item_id, quantity)

    return dict(selections)


def deposit_equipment_many(
    player,
    storage: GuildStorage,
    inventory_indexes: list[int],
):
    """Atomowo odkłada wiele konkretnych egzemplarzy wyposażenia."""
    if not inventory_indexes:
        raise ValueError("Nie wybrano żadnego wyposażenia.")
    if len(set(inventory_indexes)) != len(inventory_indexes):
        raise ValueError("Ten sam przedmiot został wybrany więcej niż raz.")
    if any(index < 0 or index >= len(player.inventory.equipment_items) for index in inventory_indexes):
        raise IndexError("Nieprawidłowy indeks wyposażenia.")
    if len(inventory_indexes) > storage.free_slots:
        raise ValueError(
            "Za mało wolnych miejsc w Magazynie Gildii "
            f"(potrzeba {len(inventory_indexes)}, wolne {storage.free_slots})."
        )

    selected_items = [player.inventory.equipment_items[index] for index in inventory_indexes]
    for index in sorted(inventory_indexes, reverse=True):
        player.inventory.pop_equipment(index)
    for item in selected_items:
        storage.inventory.add_equipment_instance(item)
    return selected_items


def withdraw_equipment_many(
    player,
    storage: GuildStorage,
    storage_indexes: list[int],
):
    """Atomowo odbiera wiele konkretnych egzemplarzy wyposażenia."""
    if not storage_indexes:
        raise ValueError("Nie wybrano żadnego wyposażenia.")
    if len(set(storage_indexes)) != len(storage_indexes):
        raise ValueError("Ten sam przedmiot został wybrany więcej niż raz.")
    if any(index < 0 or index >= len(storage.inventory.equipment_items) for index in storage_indexes):
        raise IndexError("Nieprawidłowy indeks wyposażenia.")

    selected_items = [storage.inventory.equipment_items[index] for index in storage_indexes]
    for index in sorted(storage_indexes, reverse=True):
        storage.inventory.pop_equipment(index)
    for item in selected_items:
        player.inventory.add_equipment_instance(item)
    return selected_items

