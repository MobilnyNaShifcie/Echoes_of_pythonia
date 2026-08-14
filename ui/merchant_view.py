import re

from items.affixes import item_power_display
from items.catalog import get_item_definition
from items.models import ItemCategory
from items.upgrades import format_upgrade_name
from player.player import Player
from systems.economy import (
    MerchantStockEntry,
    get_equipment_sell_price,
    get_stack_sell_price,
    max_affordable_quantity,
)
from ui.console import print_header
from ui.selection_parser import parse_index_ranges


def show_merchant_menu(player: Player) -> str:
    while True:
        print_header(); print(); print("KRAM ORENA"); print("-" * 58)
        print(f"Gold: {player.gold}\n")
        print("[1] Kup")
        print("[2] Sprzedaj materiały i przedmioty użytkowe")
        print("[3] Sprzedaj wyposażenie z plecaka")
        print("[0] Powrót\n")
        choice = input("> ").strip()
        if choice in {"1", "2", "3", "0"}: return choice
        print("\nNieprawidłowa opcja."); input("Naciśnij Enter...")


def show_buy_menu(player: Player, stock: list[MerchantStockEntry]) -> None:
    print_header(); print(); print("KUP"); print("-" * 58); print(f"Gold: {player.gold}\n")
    for index, entry in enumerate(stock, start=1):
        definition = get_item_definition(entry.item_id)
        affordable = max_affordable_quantity(player, entry)
        print(
            f"[{index}] {definition.name:<30} {entry.buy_price} Gold / szt. "
            f"(możesz: {affordable})"
        )
    print("\n[0] Anuluj")


def ask_buy_quantity(player: Player, entry: MerchantStockEntry) -> int | None:
    maximum = max_affordable_quantity(player, entry)
    if maximum <= 0:
        raise ValueError("Nie stać cię nawet na jedną sztukę.")
    print()
    print(f"Ile sztuk? Maksymalnie za obecny Gold: {maximum}")
    print("Wpisz liczbę albo MAX. [0] Anuluj")
    raw = input("> ").strip().lower()
    if raw == "0":
        return None
    if raw == "max":
        return maximum
    quantity = int(raw)
    if quantity <= 0:
        raise ValueError("Ilość musi być większa od zera.")
    return quantity


def get_sellable_stacks(player: Player) -> list[str]:
    item_ids = [
        item_id
        for item_id, quantity in player.inventory.stacks.items()
        if quantity > 0
        and get_item_definition(item_id).category
        in {ItemCategory.MATERIAL, ItemCategory.CONSUMABLE}
    ]
    return sorted(
        item_ids,
        key=lambda item_id: get_item_definition(item_id).name,
    )


def show_stack_sell_menu(player: Player, item_ids: list[str]) -> None:
    print_header(); print(); print("SPRZEDAJ — MATERIAŁY I PRZEDMIOTY"); print("-" * 58)
    print(f"Gold: {player.gold}\n")
    if not item_ids:
        print("Nie masz niczego, co Oren chce kupić.")
    else:
        for index, item_id in enumerate(item_ids, start=1):
            definition = get_item_definition(item_id)
            quantity = player.inventory.count(item_id)
            price = get_stack_sell_price(item_id)
            print(f"[{index}] {definition.name} x{quantity} → {price} Gold / szt.")
    print("\n[0] Anuluj")


def show_equipment_sell_menu(player: Player) -> None:
    print_header(); print(); print("SPRZEDAJ — WYPOSAŻENIE"); print("-" * 58)
    print(f"Gold: {player.gold}\n")
    if not player.inventory.equipment_items:
        print("Nie masz wyposażenia w plecaku.")
    else:
        for index, item in enumerate(player.inventory.equipment_items, start=1):
            definition = get_item_definition(item.item_id)
            price = get_equipment_sell_price(item)
            print(
                f"[{index}] {format_upgrade_name(item)} "
                f"[{definition.rarity.display_name} | "
                f"IP {item_power_display(item.item_power)} | "
                f"Wym. poz. {definition.required_level}] → {price} Gold"
            )
    print("\n[0] Anuluj")



def _parse_index(token: str, maximum: int) -> int:
    index = int(token) - 1
    if index < 0 or index >= maximum:
        raise ValueError(f"Numer {token} nie istnieje na liście.")
    return index


def parse_stack_sale_selection(
    raw: str,
    player: Player,
    item_ids: list[str],
) -> dict[str, int]:
    """Parsuje np. `1x5, 2, 4xMAX`.

    Sam numer oznacza sprzedaż jednej sztuki.
    `xMAX` oznacza cały posiadany stos danego przedmiotu.
    """
    text = raw.strip()
    if not text:
        raise ValueError("Nie podano żadnego wyboru.")

    sales: dict[str, int] = {}

    for chunk in text.split(","):
        part = chunk.strip()
        if not part:
            continue

        if "x" in part.lower():
            pieces = re.split(r"[xX]", part, maxsplit=1)
            if len(pieces) != 2:
                raise ValueError(f"Nieprawidłowy zapis: {part}.")
            index_text, quantity_text = pieces[0].strip(), pieces[1].strip()
        else:
            index_text, quantity_text = part, "1"

        index = _parse_index(index_text, len(item_ids))
        item_id = item_ids[index]
        owned = player.inventory.count(item_id)

        if quantity_text.lower() == "max":
            quantity = owned
        else:
            quantity = int(quantity_text)

        if quantity <= 0:
            raise ValueError("Ilość sprzedaży musi być większa od zera.")

        previous = sales.get(item_id, 0)
        combined = previous + quantity
        if combined > owned:
            definition = get_item_definition(item_id)
            raise ValueError(
                f"{definition.name}: masz {owned}, "
                f"wybrano łącznie {combined}."
            )

        sales[item_id] = combined

    if not sales:
        raise ValueError("Nie wybrano żadnych przedmiotów.")

    return sales


def parse_equipment_sale_selection(
    raw: str,
    equipment_count: int,
) -> list[int]:
    """Parsuje listę i zakresy, np. `1,3,5-7`."""
    return parse_index_ranges(
        raw,
        equipment_count,
        missing_label="Przedmiot",
    )


def ask_stack_sale_selection(
    player: Player,
    item_ids: list[str],
) -> dict[str, int] | None:
    print()
    print("Wybierz kilka pozycji naraz.")
    print("Przykład: 1x5, 2, 4xMAX")
    print("Sam numer = 1 sztuka | xMAX = cały stos | [0] Anuluj")
    raw = input("> ").strip()

    if raw == "0":
        return None

    return parse_stack_sale_selection(raw, player, item_ids)


def ask_equipment_sale_selection(
    player: Player,
) -> list[int] | None:
    print()
    print("Wybierz kilka egzemplarzy naraz.")
    print("Przykład: 1,3,5-7")
    print("[0] Anuluj")
    raw = input("> ").strip()

    if raw == "0":
        return None

    return parse_equipment_sale_selection(
        raw,
        len(player.inventory.equipment_items),
    )


def show_stack_sale_confirmation(
    player: Player,
    sales: dict[str, int],
) -> int:
    print_header()
    print()
    print("POTWIERDŹ SPRZEDAŻ")
    print("-" * 58)

    total = 0
    for item_id, quantity in sales.items():
        definition = get_item_definition(item_id)
        subtotal = get_stack_sell_price(item_id) * quantity
        total += subtotal
        print(
            f"- {definition.name} x{quantity} "
            f"→ {subtotal} Gold"
        )

    print()
    print(f"ŁĄCZNIE: {total} Gold")
    print()
    print("[1] Potwierdź sprzedaż")
    print("[0] Anuluj")
    return total


def show_equipment_sale_confirmation(
    player: Player,
    indexes: list[int],
) -> int:
    print_header()
    print()
    print("POTWIERDŹ SPRZEDAŻ")
    print("-" * 58)

    total = 0
    for index in indexes:
        item = player.inventory.equipment_items[index]
        price = get_equipment_sell_price(item)
        total += price
        print(f"- {format_upgrade_name(item)} → {price} Gold")

    print()
    print(f"ŁĄCZNIE: {total} Gold")
    print()
    print("[1] Potwierdź sprzedaż")
    print("[0] Anuluj")
    return total
