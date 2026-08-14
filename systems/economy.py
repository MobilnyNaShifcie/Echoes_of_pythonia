from dataclasses import dataclass

from data.economy import CONSUMABLE_SELL_BASE, EQUIPMENT_SELL_BASE, MATERIAL_SELL_BASE, MERCHANT_STOCK
from items.catalog import get_item_definition
from items.models import EquipmentItem, ItemCategory
from items.upgrades import calculate_upgraded_stats
from player.player import Player


@dataclass(frozen=True)
class MerchantStockEntry:
    item_id: str
    buy_price: int


def get_merchant_stock() -> list[MerchantStockEntry]:
    return [
        MerchantStockEntry(item_id=str(entry["item_id"]), buy_price=int(entry["buy_price"]))
        for entry in MERCHANT_STOCK
    ]


def get_stack_sell_price(item_id: str) -> int:
    definition = get_item_definition(item_id)
    rarity = definition.rarity.code
    if definition.category is ItemCategory.MATERIAL:
        return MATERIAL_SELL_BASE[rarity]
    if definition.category is ItemCategory.CONSUMABLE:
        return CONSUMABLE_SELL_BASE[rarity]
    if definition.category is ItemCategory.KEY:
        raise ValueError("Kluczy do instancji nie można sprzedawać.")
    raise ValueError("Wyposażenie wymaga konkretnej instancji przedmiotu.")


def get_equipment_sell_price(item: EquipmentItem) -> int:
    definition = get_item_definition(item.item_id)
    if not definition.is_equipment:
        raise ValueError("Ten przedmiot nie jest wyposażeniem.")
    stats = calculate_upgraded_stats(item)
    base = EQUIPMENT_SELL_BASE[definition.rarity.code]
    stat_value = (
        stats.attack * 12
        + stats.defense * 10
        + stats.max_hp * 2
        + stats.max_mana * 2
        + int(stats.dodge * 10)
        + sum(definition.resistances.as_dict().values())
    )

    # Dobry roll podnosi wartość przedmiotu, ale tylko umiarkowanie.
    # Nie wyceniamy affixów 1:1 według ich bojowej mocy, bo umożliwiłoby
    # to kupowanie materiałów -> crafting -> sprzedaż z gwarantowanym zyskiem.
    roll_premium = sum(
        affix_roll.tier * max(1, item.item_power) * 2
        for affix_roll in item.affixes
    )
    upgrade_multiplier = 1.0 + item.upgrade_level * 0.15
    return max(
        1,
        int((base + stat_value + roll_premium) * upgrade_multiplier),
    )


def max_affordable_quantity(player: Player, entry: MerchantStockEntry) -> int:
    if entry.buy_price <= 0:
        raise ValueError("Cena zakupu musi być dodatnia.")
    return player.gold // entry.buy_price


def buy_item(player: Player, entry: MerchantStockEntry, quantity: int = 1) -> int:
    if quantity <= 0:
        raise ValueError("Ilość zakupu musi być większa od zera.")
    get_item_definition(entry.item_id)
    total_price = entry.buy_price * quantity
    if player.gold < total_price:
        raise ValueError(
            f"Brakuje golda. Potrzeba {total_price}, masz {player.gold}."
        )
    player.gold -= total_price
    player.inventory.add(entry.item_id, quantity)
    return total_price


def sell_stack_item(player: Player, item_id: str) -> int:
    if not player.inventory.has(item_id, 1):
        raise ValueError("Nie posiadasz tego przedmiotu.")
    price = get_stack_sell_price(item_id)
    player.inventory.remove_item(item_id, 1)
    player.add_gold(price)
    return price


def sell_equipment_item(player: Player, index: int) -> tuple[EquipmentItem, int]:
    if index < 0 or index >= len(player.inventory.equipment_items):
        raise IndexError("Nieprawidłowy przedmiot wyposażenia.")
    item = player.inventory.equipment_items[index]
    price = get_equipment_sell_price(item)
    sold = player.inventory.pop_equipment(index)
    player.add_gold(price)
    return sold, price



def sell_stack_items(
    player: Player,
    sales: dict[str, int],
) -> tuple[list[tuple[str, int, int]], int]:
    """Sprzedaje kilka stosów/ilości w jednej atomowej transakcji.

    Zwraca listę (item_id, quantity, subtotal) oraz łączny przychód.
    Jeśli choć jedna pozycja jest nieprawidłowa, nic nie zostaje sprzedane.
    """
    if not sales:
        raise ValueError("Nie wybrano żadnych przedmiotów do sprzedaży.")

    prepared: list[tuple[str, int, int]] = []
    total = 0

    for item_id, quantity in sales.items():
        if quantity <= 0:
            raise ValueError("Ilość sprzedaży musi być większa od zera.")

        definition = get_item_definition(item_id)
        if definition.is_equipment:
            raise ValueError(
                "Wyposażenie należy sprzedawać jako konkretne egzemplarze."
            )

        owned = player.inventory.count(item_id)
        if owned < quantity:
            raise ValueError(
                f"Brakuje przedmiotu {definition.name}: "
                f"masz {owned}, próbujesz sprzedać {quantity}."
            )

        unit_price = get_stack_sell_price(item_id)
        subtotal = unit_price * quantity
        prepared.append((item_id, quantity, subtotal))
        total += subtotal

    for item_id, quantity, _ in prepared:
        player.inventory.remove_item(item_id, quantity)

    player.add_gold(total)
    return prepared, total


def sell_equipment_items(
    player: Player,
    indexes: list[int],
) -> tuple[list[tuple[EquipmentItem, int]], int]:
    """Sprzedaje kilka konkretnych egzemplarzy wyposażenia atomowo."""
    if not indexes:
        raise ValueError("Nie wybrano żadnego wyposażenia do sprzedaży.")

    if len(set(indexes)) != len(indexes):
        raise ValueError("Ten sam przedmiot został wybrany więcej niż raz.")

    count = len(player.inventory.equipment_items)
    for index in indexes:
        if index < 0 or index >= count:
            raise IndexError("Nieprawidłowy przedmiot wyposażenia.")

    prepared = [
        (
            player.inventory.equipment_items[index],
            get_equipment_sell_price(player.inventory.equipment_items[index]),
        )
        for index in indexes
    ]

    # Usuwamy od końca, aby wcześniejsze indeksy nie przesuwały się.
    for index in sorted(indexes, reverse=True):
        player.inventory.pop_equipment(index)

    total = sum(price for _, price in prepared)
    player.add_gold(total)
    return prepared, total
