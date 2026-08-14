from copy import copy

from game.config import MAX_UPGRADE_LEVEL
from items.affixes import calculate_affix_bonuses, item_power_display
from items.catalog import get_item_definition
from items.signature_weapons import format_average_damage
from items.upgrades import (
    calculate_upgraded_stats,
    format_upgrade_name,
    is_max_upgrade,
)
from player.player import Player
from systems.blacksmith import (
    UpgradePlan,
    UpgradeTarget,
    can_upgrade,
    get_upgrade_cost,
    max_affordable_upgrade_levels,
)
from ui.console import print_header


def _resource_status(owned: int, required: int) -> str:
    return "OK" if owned >= required else "BRAK"


def _show_next_upgrade_resources(player: Player, cost) -> None:
    gold_status = _resource_status(player.gold, cost.gold)
    print(
        f"    Gold: {player.gold}/{cost.gold} [{gold_status}]"
    )
    print("    Materiały:")
    for item_id, quantity in cost.materials.items():
        material = get_item_definition(item_id)
        owned = player.inventory.count(item_id)
        status = _resource_status(owned, quantity)
        print(
            f"    - {material.name}: {owned}/{quantity} [{status}]"
        )


def _format_stats(target: UpgradeTarget) -> str:
    stats = calculate_upgraded_stats(target.item)
    affix = calculate_affix_bonuses(target.item)
    parts: list[str] = []

    attack = stats.attack + affix.attack
    defense = stats.defense + affix.defense
    max_hp = stats.max_hp + affix.max_hp
    max_mana = stats.max_mana + affix.max_mana
    dodge = stats.dodge + affix.dodge

    if attack:
        parts.append(f"ATK {attack}")
    if defense:
        parts.append(f"DEF {defense}")
    if max_hp:
        parts.append(f"HP +{max_hp}")
    if max_mana:
        parts.append(f"MANA +{max_mana}")
    if dodge:
        parts.append(f"UNIK +{dodge:.1f}%")
    if target.item.average_damage_percent is not None:
        parts.append(
            f"ŚR. OBR {format_average_damage(target.item.average_damage_percent)}"
        )

    return ", ".join(parts) if parts else "brak statystyk"


def show_blacksmith_menu(
    player: Player,
    targets: list[UpgradeTarget],
) -> None:
    print_header()
    print()
    print("KOWAL")
    print("-" * 58)
    print(f"Gold: {player.gold}")
    print(
        f"Osełki: {player.inventory.count('whetstone')} | "
        f"Kamienie Szlifierskie: "
        f"{player.inventory.count('grinding_stone')}"
    )
    print()
    print(
        "Ulepszenia są gwarantowane. "
        "Możesz wykonać kilka kolejnych ulepszeń naraz."
    )
    print(
        "+0..+3 wymagają podstawowych materiałów; wyższe poziomy "
        "korzystają z łupów regionu, minibossów i bossów."
    )
    print()

    if not targets:
        print("Nie posiadasz żadnego wyposażenia.")
        print()
        print("[0] Powrót")
        return

    equipped_targets = [
        (index, target)
        for index, target in enumerate(targets, start=1)
        if target.slot is not None
    ]
    backpack_targets = [
        (index, target)
        for index, target in enumerate(targets, start=1)
        if target.slot is None
    ]

    def show_target(index: int, target: UpgradeTarget) -> None:
        name = format_upgrade_name(target.item)
        slot_label = (
            f" [{target.slot.display_name}]"
            if target.slot is not None
            else ""
        )

        if is_max_upgrade(target.item):
            print(
                f"[{index}] {name} "
                f"[IP {item_power_display(target.item.item_power)} | "
                f"Wym. poz. {get_item_definition(target.item.item_id).required_level}]"
                f"{slot_label} [MAX]"
            )
            print(f"    {_format_stats(target)}")
            return

        cost = get_upgrade_cost(target.item.upgrade_level, target.item)
        status = (
            "MOŻNA ULEPSZYĆ"
            if can_upgrade(player, target.item)
            else "BRAK ZASOBÓW"
        )

        print(
            f"[{index}] {name} "
            f"[IP {item_power_display(target.item.item_power)} | "
            f"Wym. poz. {get_item_definition(target.item.item_id).required_level}]"
            f"{slot_label} [{status}]"
        )
        print(f"    {_format_stats(target)}")
        print(
            f"    Następny: +{target.item.upgrade_level + 1}"
        )
        _show_next_upgrade_resources(player, cost)

        preview_item = copy(target.item)
        preview_item.upgrade_level += 1
        current = calculate_upgraded_stats(target.item)
        after = calculate_upgraded_stats(preview_item)
        gains: list[str] = []
        if after.attack > current.attack:
            gains.append(f"ATK +{after.attack - current.attack}")
        if after.defense > current.defense:
            gains.append(f"DEF +{after.defense - current.defense}")
        if after.max_hp > current.max_hp:
            gains.append(f"HP +{after.max_hp - current.max_hp}")
        if after.max_mana > current.max_mana:
            gains.append(f"MANA +{after.max_mana - current.max_mana}")
        if after.dodge > current.dodge:
            gains.append(f"UNIK +{after.dodge - current.dodge:.1f}%")
        if gains:
            print(f"    Wzrost: {', '.join(gains)}")

    if equipped_targets:
        print("=== ZAŁOŻONE ===")
        print()
        for index, target in equipped_targets:
            show_target(index, target)
        print()

    if backpack_targets:
        print("=== PLECAK ===")
        print()
        for index, target in backpack_targets:
            show_target(index, target)

    print()
    print(f"Maksymalny poziom ulepszenia: +{MAX_UPGRADE_LEVEL}")
    print("[0] Powrót")


def ask_upgrade_quantity(
    player: Player,
    target: UpgradeTarget,
) -> int | None:
    remaining = MAX_UPGRADE_LEVEL - target.item.upgrade_level
    affordable = max_affordable_upgrade_levels(player, target.item)

    if remaining <= 0:
        print("\nPrzedmiot osiągnął już maksymalny poziom.")
        return None
    if affordable <= 0:
        print("\nBrakuje zasobów nawet na jedno ulepszenie.")
        return None

    while True:
        print()
        print(
            f"Ile kolejnych ulepszeń wykonać? "
            f"[1-{affordable} / MAX | 0 = anuluj]"
        )
        print(
            f"MAX = wykonaj wszystkie obecnie dostępne "
            f"ulepszenia ({affordable})."
        )
        choice = input("> ").strip()

        if choice == "0":
            return None
        if choice.upper() == "MAX":
            return affordable

        try:
            levels = int(choice)
        except ValueError:
            print("Wpisz liczbę, MAX albo 0.")
            continue

        if not 1 <= levels <= affordable:
            print(
                f"Obecne zasoby pozwalają wykonać od 1 do "
                f"{affordable} ulepszeń."
            )
            continue

        return levels


def show_upgrade_preview(
    target: UpgradeTarget,
    plan: UpgradePlan,
) -> None:
    print_header()
    print()
    print("KOWAL — PODSUMOWANIE")
    print("-" * 58)
    print(
        f"{get_item_definition(target.item.item_id).name}: "
        f"+{plan.start_level} -> +{plan.target_level}"
    )
    print()
    print(f"Łączny koszt: {plan.gold} Gold")
    for item_id, quantity in plan.materials.items():
        material = get_item_definition(item_id)
        print(f"- {material.name} x{quantity}")

    preview_item = copy(target.item)
    preview_item.upgrade_level = plan.target_level
    preview_target = UpgradeTarget(
        item=preview_item,
        source=target.source,
        slot=target.slot,
    )
    print()
    print(f"Po ulepszeniu: {_format_stats(preview_target)}")
    print()
    print("[1] Ulepsz")
    print("[0] Anuluj")


def ask_upgrade_confirmation() -> bool:
    while True:
        choice = input("> ").strip()
        if choice == "1":
            return True
        if choice == "0":
            return False
        print("Wybierz 1 albo 0.")


def show_upgrade_result(
    target: UpgradeTarget,
    old_level: int,
) -> None:
    print_header()
    print()
    print("KOWAL")
    print("-" * 58)
    print("ULEPSZENIE ZAKOŃCZONE")
    print()
    print(
        f"{get_item_definition(target.item.item_id).name}: "
        f"+{old_level} -> +{target.item.upgrade_level}"
    )
    print(f"Nowe statystyki: {_format_stats(target)}")
