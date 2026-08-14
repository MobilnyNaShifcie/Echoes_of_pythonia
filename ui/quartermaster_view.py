from __future__ import annotations

from items.catalog import get_item_definition
from items.upgrades import format_upgrade_name
from player.player import Player
from systems.carry_weight import carry_status, item_unit_weight, next_carry_upgrade, stack_weight
from systems.guild_storage import GUILD_STORAGE_CAPACITY_SLOTS, GuildStorage
from ui.console import print_header
from ui.selection_parser import parse_index_ranges


def _load_line(player: Player) -> str:
    status = carry_status(player)
    return (
        f"Udźwig: {status.current_kg:.1f}/{status.capacity_kg:.1f} kg "
        f"| Stan: {status.display_name}"
    )


def show_quartermaster_menu(player: Player, storage: GuildStorage) -> str:
    print_header(); print(); print("KWATERMISTRZ GILDII"); print("-" * 58)
    print('„Sprzęt na później zostaw tutaj. Na wyprawę bierz tylko to, czego naprawdę potrzebujesz.”')
    print()
    print(_load_line(player))
    print(f"Magazyn: {storage.used_slots}/{GUILD_STORAGE_CAPACITY_SLOTS} miejsc")
    print()
    print("[1] Magazyn")
    print("[2] Odłóż przedmioty")
    print("[3] Odbierz przedmioty")
    print("[4] Ulepszenia udźwigu")
    print("[0] Powrót")
    return input("\n> ").strip()


def show_storage(player: Player, storage: GuildStorage) -> None:
    print_header(); print(); print("MAGAZYN GILDII"); print("-" * 58)
    print(f"Miejsca: {storage.used_slots}/{GUILD_STORAGE_CAPACITY_SLOTS}")
    print(_load_line(player))
    print()
    if storage.inventory.is_empty():
        print("Magazyn jest pusty.")
        return
    if storage.inventory.stacks:
        print("PRZEDMIOTY I MATERIAŁY")
        for item_id, quantity in sorted(storage.inventory.stacks.items(), key=lambda p: get_item_definition(p[0]).name):
            definition = get_item_definition(item_id)
            total = stack_weight(item_id, quantity)
            print(f"- {definition.name} x{quantity} | Waga: {total:.1f} kg")
        print()
    if storage.inventory.equipment_items:
        print("WYPOSAŻENIE")
        for index, item in enumerate(storage.inventory.equipment_items, start=1):
            definition = get_item_definition(item.item_id)
            print(f"{index}. {format_upgrade_name(item)} | {definition.slot.display_name} | {item_unit_weight(item.item_id):.1f} kg")


def show_deposit_type_menu(player: Player, storage: GuildStorage) -> str:
    print_header(); print(); print("ODŁÓŻ DO MAGAZYNU"); print("-" * 58)
    print(_load_line(player))
    print(f"Magazyn: {storage.used_slots}/{GUILD_STORAGE_CAPACITY_SLOTS} miejsc")
    print()
    print("[1] Przedmioty / materiały")
    print("[2] Wyposażenie")
    print("[0] Powrót")
    return input("\n> ").strip()


def show_withdraw_type_menu(player: Player, storage: GuildStorage) -> str:
    print_header(); print(); print("ODBIERZ Z MAGAZYNU"); print("-" * 58)
    print(_load_line(player))
    print(f"Magazyn: {storage.used_slots}/{GUILD_STORAGE_CAPACITY_SLOTS} miejsc")
    print()
    print("[1] Przedmioty / materiały")
    print("[2] Wyposażenie")
    print("[0] Powrót")
    return input("\n> ").strip()


def show_stack_selection(inventory, title: str) -> list[str]:
    print_header(); print(); print(title); print("-" * 58)
    item_ids = [item_id for item_id, quantity in inventory.stacks.items() if quantity > 0]
    item_ids.sort(key=lambda item_id: get_item_definition(item_id).name)
    if not item_ids:
        print("Brak przedmiotów do wyboru.")
        return []
    for index, item_id in enumerate(item_ids, start=1):
        definition = get_item_definition(item_id)
        quantity = inventory.count(item_id)
        unit = item_unit_weight(item_id)
        total = stack_weight(item_id, quantity)
        print(
            f"[{index}] {definition.name} x{quantity} | "
            f"Waga: {total:.1f} kg ({unit:.2f} kg/szt.)"
        )
    print("\n[0] Powrót")
    return item_ids


def show_equipment_selection(inventory, title: str):
    print_header(); print(); print(title); print("-" * 58)
    if not inventory.equipment_items:
        print("Brak wyposażenia do wyboru.")
        return []
    for index, item in enumerate(inventory.equipment_items, start=1):
        definition = get_item_definition(item.item_id)
        print(f"[{index}] {format_upgrade_name(item)} | {definition.slot.display_name} | {item_unit_weight(item.item_id):.1f} kg")
    print("\n[0] Powrót")
    return list(inventory.equipment_items)




def parse_multi_index_selection(raw: str, item_count: int) -> list[int]:
    """Parsuje wybór wielu pozycji, np. `1,3,5-7`, i zwraca indeksy 0-based."""
    return parse_index_ranges(raw, item_count)


def ask_equipment_multi_selection(item_count: int) -> list[int] | None:
    print()
    print("Wybierz kilka egzemplarzy naraz.")
    print("Przykład: 1,3,5-7")
    print("[0] Anuluj")
    raw = input("> ").strip()
    if raw == "0":
        return None
    return parse_multi_index_selection(raw, item_count)


def parse_stack_multi_selection(raw: str, inventory, item_ids: list[str]) -> dict[str, int]:
    """Parsuje wiele stosów, np. `1x5,2xMAX,4` (sam numer = cały stos)."""
    text = raw.strip()
    if not text:
        raise ValueError("Nie podano żadnego wyboru.")

    selections: dict[str, int] = {}
    for chunk in text.split(","):
        part = chunk.strip()
        if not part:
            continue
        if "x" in part.lower():
            number_text, quantity_text = part.lower().split("x", maxsplit=1)
        else:
            number_text, quantity_text = part, "max"

        number = int(number_text.strip())
        if not 1 <= number <= len(item_ids):
            raise ValueError(f"Pozycja [{number}] nie istnieje.")
        item_id = item_ids[number - 1]
        if item_id in selections:
            raise ValueError(f"Pozycja [{number}] została wybrana więcej niż raz.")

        owned = inventory.count(item_id)
        quantity_text = quantity_text.strip().lower()
        quantity = owned if quantity_text == "max" else int(quantity_text)
        if not 1 <= quantity <= owned:
            definition = get_item_definition(item_id)
            raise ValueError(f"{definition.name}: dostępne {owned}, wybrano {quantity}.")
        selections[item_id] = quantity

    if not selections:
        raise ValueError("Nie wybrano żadnych przedmiotów.")
    return selections


def ask_stack_multi_selection(inventory, item_ids: list[str]) -> dict[str, int] | None:
    print()
    print("Wybierz kilka pozycji naraz.")
    print("Przykład: 1,3,5 albo 1x5,2xMAX,4x2")
    print("Sam numer = cały stos | xN = wybrana liczba sztuk | [0] Anuluj")
    raw = input("> ").strip()
    if raw == "0":
        return None
    return parse_stack_multi_selection(raw, inventory, item_ids)

def ask_quantity(maximum: int) -> int | None:
    if maximum <= 0:
        return None
    raw = input(f"Ile sztuk? [1-{maximum} / MAX | 0 = anuluj]\n> ").strip().lower()
    if raw == "0":
        return None
    if raw == "max":
        return maximum
    try:
        value = int(raw)
    except ValueError:
        return None
    if not 1 <= value <= maximum:
        return None
    return value


def show_carry_upgrade(player: Player, guild_rank_code: str) -> None:
    print_header(); print(); print("ULEPSZENIA UDŹWIGU"); print("-" * 58)
    print(_load_line(player))
    print(f"Aktualny poziom: {player.carry_upgrade_level}/3")
    print()
    upgrade = next_carry_upgrade(player)
    if upgrade is None:
        print("Masz już najlepszy plecak Kwatermistrza.")
        print("\n[0] Powrót")
        return
    level, name, bonus, cost, rank = upgrade
    print(f"Następne ulepszenie: {name}")
    print(f"Bonus: +{bonus:.0f} kg do bazowego udźwigu")
    print(f"Koszt: {cost} Gold")
    print(f"Wymagana ranga Gildii: {rank}")
    print(f"Twoja ranga: {guild_rank_code}")
    print()
    print("[1] Kup ulepszenie")
    print("[0] Powrót")
