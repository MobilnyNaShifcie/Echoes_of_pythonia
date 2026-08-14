from data.affixes import AFFIX_DATA
from items.affixes import format_affix_value, item_power_display
from items.catalog import get_item_definition
from items.class_effects import get_class_effect
from items.models import EquipmentItem, EquipmentSlot, ItemCategory
from items.signature_weapons import format_average_damage
from items.upgrades import calculate_upgraded_stats, format_upgrade_name
from player.player import Player
from systems.carry_weight import carry_status, equipment_weight, stack_weight
from systems.item_usage import get_item_usage
from ui.console import print_header


def _format_equipment_stats(
    item: EquipmentItem,
    *,
    include_special: bool = True,
) -> str:
    """Kompaktowe bazowe statystyki. Affixy są pokazywane osobno."""
    definition = get_item_definition(item.item_id)
    stats = calculate_upgraded_stats(item)
    parts: list[str] = []
    if stats.attack:
        parts.append(f"ATK {stats.attack}")
    if stats.defense:
        parts.append(f"DEF {stats.defense}")
    if stats.max_hp:
        parts.append(f"HP +{stats.max_hp}")
    if stats.max_mana:
        parts.append(f"MANA +{stats.max_mana}")
    if stats.magic_power:
        parts.append(f"MOC MAG. +{stats.magic_power}")
    if stats.dodge:
        parts.append(f"UNIK +{stats.dodge:.1f}%")
    if include_special and item.average_damage_percent is not None:
        parts.append(
            f"ŚR. OBR {format_average_damage(item.average_damage_percent)}"
        )
    for name, value in definition.resistances.as_dict().items():
        if value:
            parts.append(f"{name.upper()} RES +{value}%")
    return ", ".join(parts) if parts else "brak statystyk bazowych"


def _set_suffix(item: EquipmentItem) -> str:
    definition = get_item_definition(item.item_id)
    return " [SET]" if definition.set_id else ""


def _equipment_meta(item: EquipmentItem) -> str:
    definition = get_item_definition(item.item_id)
    return (
        f"{definition.rarity.display_name} | "
        f"IP {item_power_display(item.item_power)} | "
        f"Wym. poz. {definition.required_level}"
    )


def show_inventory_menu(player: Player) -> None:
    show_inventory(player)
    print()
    print("[1] Użyj przedmiotu użytkowego")
    print("[2] Szczegóły wyposażenia")
    print("[3] Księgi")
    print("[4] Sprawdź zastosowanie materiału / wejściówki")
    print("[0] Powrót")


def show_inventory(player: Player) -> None:
    print_header()
    print()
    print("PLECAK")
    print("-" * 58)
    load = carry_status(player)
    print(f"Udźwig: {load.current_kg:.1f}/{load.capacity_kg:.1f} kg | Stan: {load.display_name}")
    if load.overloaded:
        print("[PRZECIĄŻENIE] Odłóż lub sprzedaj część łupu przed kolejną zwykłą wyprawą.")
    print()
    if player.inventory.is_empty():
        print("Plecak jest pusty.")
        return

    if player.inventory.stacks:
        print("PRZEDMIOTY I MATERIAŁY\n")
        for item_id, quantity in sorted(
            player.inventory.stacks.items(),
            key=lambda pair: get_item_definition(pair[0]).name,
        ):
            definition = get_item_definition(item_id)
            category_name = {
                ItemCategory.MATERIAL: "Materiał",
                ItemCategory.CONSUMABLE: "Przedmiot użytkowy",
                ItemCategory.KEY: "Wejściówka",
                ItemCategory.BOOK: "Księga",
            }.get(definition.category, "Przedmiot")
            effect_parts: list[str] = []
            if definition.heal_hp:
                effect_parts.append(f"Leczenie: {definition.heal_hp} HP")
            if definition.heal_hp_percent:
                effect_parts.append(f"Leczenie: {definition.heal_hp_percent:g}% maks. HP")
            if definition.restore_mana:
                effect_parts.append(f"Mana: +{definition.restore_mana}")
            if definition.restore_mana_percent:
                effect_parts.append(f"Mana: +{definition.restore_mana_percent:g}% maks.")
            effect = (" | " + ", ".join(effect_parts)) if effect_parts else ""
            total_weight = stack_weight(item_id, quantity)
            print(
                f"- {definition.name} x{quantity} "
                f"[{definition.rarity.display_name} | {category_name}]"
                f"{effect} | Waga: {total_weight:.1f} kg"
            )

    if player.inventory.equipment_items:
        if player.inventory.stacks:
            print()
        print("WYPOSAŻENIE W PLECAKU\n")
        for index, item in enumerate(
            player.inventory.equipment_items,
            start=1,
        ):
            definition = get_item_definition(item.item_id)
            print(
                f"{index}. {format_upgrade_name(item)} "
                f"[{_equipment_meta(item)}]{_set_suffix(item)}"
            )
            print(
                f"   Slot: {definition.slot.display_name} | "
                f"Waga: {equipment_weight(item):.1f} kg | "
                f"{_format_equipment_stats(item)}"
            )


def show_equipment_detail_selection(player: Player) -> None:
    print_header()
    print()
    print("SZCZEGÓŁY WYPOSAŻENIA")
    print("-" * 58)
    if not player.inventory.equipment_items:
        print("Nie masz wyposażenia w plecaku.")
        return

    for index, item in enumerate(player.inventory.equipment_items, start=1):
        print(
            f"[{index}] {format_upgrade_name(item)} "
            f"[{_equipment_meta(item)}]"
        )
    print("\n[0] Powrót")


def _print_equipment_detail_body(item: EquipmentItem) -> None:
    definition = get_item_definition(item.item_id)
    print(format_upgrade_name(item).upper())
    print("-" * 58)
    print(f"Rzadkość: {definition.rarity.display_name}")
    print(f"Slot: {definition.slot.display_name}")
    print(f"Item Power: {item_power_display(item.item_power)}")
    print(f"Wymagany poziom: {definition.required_level}")
    if definition.equipment_type is not None:
        print(f"Typ: {definition.equipment_type}")
    if definition.required_class_name is not None:
        print(f"Wymagana klasa: {definition.required_class_name}")
    print(f"Ulepszenie: +{item.upgrade_level}")
    print()
    print("BAZA + ULEPSZENIE")
    print(f"- {_format_equipment_stats(item, include_special=False)}")
    if item.average_damage_percent is not None:
        print()
        print("ŚREDNIE OBRAŻENIA")
        print(
            f"- {format_average_damage(item.average_damage_percent)}"
        )
    if definition.class_effect_id is not None:
        effect = get_class_effect(definition.class_effect_id)
        print()
        print(f"EFEKT KLASOWY — {effect.player_class_name.upper()}")
        print(f"- {effect.name}: {effect.description}")
    if definition.class_bonus_class_code is not None:
        print()
        print(f"PREMIA KLASOWA — {definition.class_bonus_class_code.upper()}")
        bonuses = []
        if definition.class_bonus_attack: bonuses.append(f"ATK +{definition.class_bonus_attack}")
        if definition.class_bonus_defense: bonuses.append(f"DEF +{definition.class_bonus_defense}")
        if definition.class_bonus_max_hp: bonuses.append(f"HP +{definition.class_bonus_max_hp}")
        if definition.class_bonus_max_mana: bonuses.append(f"MANA +{definition.class_bonus_max_mana}")
        if definition.class_bonus_dodge: bonuses.append(f"UNIK +{definition.class_bonus_dodge:.1f}%")
        print("- " + (", ".join(bonuses) if bonuses else "unikalny efekt klasy"))
    print()
    print("LOSOWE BONUSY")
    if not item.affixes:
        print("- Brak (Zwykły przedmiot)")
    else:
        for affix in item.affixes:
            name = str(AFFIX_DATA[affix.affix_id]["name"])
            print(
                f"- [T{affix.tier}] {name}: "
                f"{format_affix_value(affix)}"
            )
    print()
    print(definition.description)


def show_equipment_details(item: EquipmentItem) -> None:
    print_header()
    print()
    _print_equipment_detail_body(item)


def show_all_equipped_details(player: Player) -> None:
    print_header()
    print()
    print("WSZYSTKIE SZCZEGÓŁY ZAŁOŻONEGO EKWIPUNKU")
    print("=" * 58)

    shown = 0
    for slot in EquipmentSlot:
        item = player.equipment.get(slot)
        if item is None:
            continue

        if shown > 0:
            print()
            print("=" * 58)
            print()

        print(f"{slot.display_name.upper()}")
        _print_equipment_detail_body(item)
        shown += 1

    if shown == 0:
        print("Nie masz założonego wyposażenia.")


def show_item_usage_selection(player: Player) -> list[str]:
    print_header()
    print()
    print("ZASTOSOWANIE PRZEDMIOTÓW")
    print("-" * 58)
    item_ids = [
        item_id
        for item_id, quantity in player.inventory.stacks.items()
        if quantity > 0
        and get_item_definition(item_id).category
        in {ItemCategory.MATERIAL, ItemCategory.KEY}
    ]
    item_ids.sort(key=lambda item_id: get_item_definition(item_id).name)
    if not item_ids:
        print("Nie masz materiałów ani wejściówek do sprawdzenia.")
        return []
    for index, item_id in enumerate(item_ids, start=1):
        definition = get_item_definition(item_id)
        quantity = player.inventory.count(item_id)
        label = "Wejściówka" if definition.category is ItemCategory.KEY else "Materiał"
        print(f"[{index}] {definition.name} x{quantity} [{label}]")
    print("\n[0] Powrót")
    return item_ids


def show_item_usage(item_id: str) -> None:
    definition = get_item_definition(item_id)
    usage = get_item_usage(item_id)
    print_header()
    print()
    print(definition.name.upper())
    print("-" * 58)
    print(definition.description)
    print()
    if usage.dungeon_names:
        print("WEJŚCIÓWKA DO:")
        for name in usage.dungeon_names:
            print(f"- {name} (przedmiot jest zużywany przy wejściu)")
    if usage.recipe_names:
        if usage.dungeon_names:
            print()
        print("UŻYWANY W RECEPTURACH:")
        for name in usage.recipe_names:
            print(f"- {name}")
    if not usage.has_gameplay_use:
        print("Brak obecnego zastosowania gameplayowego.")


def show_consumables(player: Player) -> list[str]:
    print_header()
    print()
    print("PRZEDMIOTY UŻYTKOWE")
    print("-" * 58)
    consumables = [
        item_id
        for item_id, quantity in player.inventory.stacks.items()
        if quantity > 0 and get_item_definition(item_id).is_consumable
    ]
    consumables.sort(key=lambda item_id: get_item_definition(item_id).name)
    if not consumables:
        print("Nie masz żadnych przedmiotów użytkowych.")
        return []
    for index, item_id in enumerate(consumables, start=1):
        definition = get_item_definition(item_id)
        quantity = player.inventory.count(item_id)
        effects: list[str] = []
        if definition.heal_hp > 0:
            effects.append(f"{definition.heal_hp} HP")
        if definition.heal_hp_percent > 0:
            effects.append(f"{definition.heal_hp_percent:g}% maks. HP")
        if definition.restore_mana > 0:
            effects.append(f"{definition.restore_mana} Many")
        if definition.restore_mana_percent > 0:
            effects.append(f"{definition.restore_mana_percent:g}% maks. Many")
        effect = ", ".join(effects) if effects else "brak aktywnego efektu"
        print(f"[{index}] {definition.name} x{quantity} - przywraca {effect}")
    print("\n[0] Anuluj")
    return consumables


def show_equipment(player: Player) -> None:
    print_header()
    print()
    print("EKWIPUNEK")
    print("-" * 58)
    print(
        f"ATK {player.stats.attack} | DEF {player.stats.defense} | "
        f"HP {player.stats.current_hp}/{player.stats.max_hp} | "
        f"MANA {player.stats.current_mana}/{player.stats.max_mana} | "
        f"UNIK {player.stats.dodge:.1f}%\n"
    )
    for slot in EquipmentSlot:
        item = player.equipment.get(slot)
        if item is None:
            print(f"{slot.display_name:<12} - puste")
            continue
        print(
            f"{slot.display_name:<12} - {format_upgrade_name(item)} "
            f"[{_equipment_meta(item)}]{_set_suffix(item)}"
        )
        print(f"{'':14}{_format_equipment_stats(item)}")

    bonuses = player.equipment.total_bonuses()
    if bonuses.active_set_names:
        print("\nAKTYWNE BONUSY ZESTAWÓW")
        for name in bonuses.active_set_names:
            print(f"- {name}")
    print("\n[1] Załóż przedmiot z plecaka")
    print("[2] Zdejmij przedmiot")
    print("[3] Szczegóły założonego przedmiotu")
    print("[0] Powrót")


def show_equipped_detail_selection(player: Player) -> list[EquipmentItem]:
    print_header()
    print()
    print("SZCZEGÓŁY ZAŁOŻONEGO EKWIPUNKU")
    print("-" * 58)
    items: list[EquipmentItem] = []
    for slot in EquipmentSlot:
        item = player.equipment.get(slot)
        if item is None:
            continue
        items.append(item)
        print(
            f"[{len(items)}] {slot.display_name}: {format_upgrade_name(item)} "
            f"[{_equipment_meta(item)}]"
        )
    if not items:
        print("Nie masz założonego wyposażenia.")
    else:
        print("\n[A] Pokaż wszystkie szczegóły")
    print("[0] Powrót")
    return items


def show_equippable_inventory(player: Player) -> None:
    print_header()
    print()
    print("ZAŁÓŻ PRZEDMIOT")
    print("-" * 58)
    if not player.inventory.equipment_items:
        print("Nie masz w plecaku żadnego wyposażenia.")
        return
    for index, item in enumerate(player.inventory.equipment_items, start=1):
        definition = get_item_definition(item.item_id)
        print(
            f"[{index}] {format_upgrade_name(item)} "
            f"({definition.slot.display_name}) "
            f"[{definition.rarity.display_name} | "
            f"IP {item_power_display(item.item_power)} | "
            f"Wym. poz. {definition.required_level}]"
        )
        print(f"    {_format_equipment_stats(item)}{_set_suffix(item)}")
    print("\n[0] Anuluj")


def show_unequip_slots(player: Player) -> list[EquipmentSlot]:
    print_header()
    print()
    print("ZDEJMIJ PRZEDMIOT")
    print("-" * 58)
    occupied = [
        slot
        for slot in EquipmentSlot
        if player.equipment.get(slot) is not None
    ]
    for index, slot in enumerate(occupied, start=1):
        item = player.equipment.get(slot)
        print(
            f"[{index}] {slot.display_name}: "
            f"{format_upgrade_name(item)} "
            f"[IP {item_power_display(item.item_power)}]"
        )
    print("\n[0] Anuluj")
    return occupied
