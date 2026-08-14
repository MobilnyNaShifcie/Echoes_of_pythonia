from __future__ import annotations

from companions.models import COMPANION_TACTICS, Companion, PartyState
from items.catalog import get_item_definition
from player.classes import player_class_from_code
from systems.carry_weight import carry_status
from systems.companions import companion_to_player
from systems.expedition_preparation import PRESET_NAMES, PRESET_ORDER, ExpeditionPreparationState
from systems.guild_storage import GuildStorage
from ui.console import print_header
from world.location import Location


def _healing_supply_summary(player) -> list[str]:
    lines: list[str] = []
    for item_id, quantity in player.inventory.stacks.items():
        if quantity <= 0:
            continue
        definition = get_item_definition(item_id)
        if not definition.is_consumable:
            continue
        effects: list[str] = []
        if definition.heal_hp:
            effects.append(f"+{definition.heal_hp} HP")
        if definition.heal_hp_percent:
            effects.append(f"+{definition.heal_hp_percent:g}% HP")
        if definition.restore_mana:
            effects.append(f"+{definition.restore_mana} Many")
        if definition.restore_mana_percent:
            effects.append(f"+{definition.restore_mana_percent:g}% Many")
        effect = ", ".join(effects) if effects else "użytkowy"
        lines.append(f"{definition.name} x{quantity} ({effect})")
    lines.sort()
    return lines


def preparation_warnings(player, party: PartyState) -> list[str]:
    warnings: list[str] = []
    hp_ratio = player.stats.current_hp / max(1, player.stats.max_hp)
    if hp_ratio <= 0.35:
        warnings.append(f"Niskie HP bohatera: {player.stats.current_hp}/{player.stats.max_hp}.")
    has_healing = False
    for item_id, quantity in player.inventory.stacks.items():
        if quantity <= 0:
            continue
        definition = get_item_definition(item_id)
        if definition.is_consumable and (definition.heal_hp > 0 or definition.heal_hp_percent > 0):
            has_healing = True
            break
    if not has_healing:
        warnings.append("Brak mikstur lub prowiantu odnawiającego HP w plecaku.")
    load = carry_status(player)
    if load.overloaded:
        warnings.append(f"PRZECIĄŻENIE: {load.current_kg:.1f}/{load.capacity_kg:.1f} kg.")
    injured = [c.name for c in party.companions if c.is_injured]
    if injured:
        warnings.append("Ciężko ranni kompani: " + ", ".join(injured) + ".")
    return warnings


def show_preparation_menu(
    player,
    party: PartyState,
    storage: GuildStorage,
    preparation: ExpeditionPreparationState,
    selected_location: Location | None,
) -> str:
    print_header(); print(); print("PRZYGOTOWANIE DO WYPRAWY"); print("-" * 58)
    load = carry_status(player)
    target = selected_location.name if selected_location is not None else "[nie wybrano]"
    print(f"Cel: {target}")
    print(
        f"HP {player.stats.current_hp}/{player.stats.max_hp} | "
        f"MANA {player.stats.current_mana}/{player.stats.max_mana} | "
        f"Udźwig {load.current_kg:.1f}/{load.capacity_kg:.1f} kg [{load.display_name}]"
    )
    active = party.active_companions()
    print(f"Tryb: {'DRUŻYNA' if active else 'SOLO'} | Aktywni kompani: {len(active)}/3")
    if active:
        for companion in active:
            tactic = COMPANION_TACTICS.get(companion.tactic, "Zrównoważona")
            combatant = companion_to_player(companion)
            print(
                f"- {companion.name} | {player_class_from_code(companion.class_code).display_name} lvl {companion.level} "
                f"| HP {combatant.stats.current_hp}/{combatant.stats.max_hp} "
                f"| MANA {combatant.stats.current_mana}/{combatant.stats.max_mana} | {tactic}"
            )
    print()
    supplies = _healing_supply_summary(player)
    print("ZAPASY:")
    if supplies:
        for line in supplies[:8]:
            print(f"- {line}")
        if len(supplies) > 8:
            print(f"- ... i {len(supplies) - 8} kolejnych")
    else:
        print("- Brak przedmiotów użytkowych.")
    print(f"Magazyn Gildii: {storage.used_slots}/200 miejsc")

    warnings = preparation_warnings(player, party)
    if warnings:
        print(); print("UWAGI:")
        for warning in warnings:
            print(f"! {warning}")

    print()
    print("[1] Wybierz cel")
    print("[2] Ustaw skład drużyny")
    print("[3] Taktyki kompanów")
    print("[4] Ekwipunek bohatera")
    print("[5] Zabierz zapasy z Magazynu")
    print("[6] Użyj mikstury / prowiantu")
    print("[7] Karczma — odpoczynek")
    print("[8] Presety wyprawowe")
    print("[9] Wyrusz")
    print("[0] Powrót")
    return input("\n> ").strip()


def show_target_selection(player, locations: list[Location]) -> int | None:
    print_header(); print(); print("WYBIERZ CEL WYPRAWY"); print("-" * 58)
    for index, location in enumerate(locations, start=1):
        risk = " [RYZYKO]" if player.level < location.recommended_level_min else ""
        print(f"[{index}] {location.name}{risk} | poziom {location.recommended_level_text}")
    print("[0] Powrót")
    raw = input("\n> ").strip()
    if raw == "0":
        return None
    try:
        value = int(raw)
    except ValueError:
        return None
    return value - 1 if 1 <= value <= len(locations) else None


def show_tactic_companion_selection(party: PartyState) -> str | None:
    print_header(); print(); print("TAKTYKI KOMPANÓW"); print("-" * 58)
    available = [companion for companion in party.companions if not companion.dead]
    if not available:
        print("Nie masz jeszcze kompanów, którym można ustawić taktykę.")
        input("\nNaciśnij Enter...")
        return None
    for index, companion in enumerate(available, start=1):
        tactic = COMPANION_TACTICS.get(companion.tactic, "Zrównoważona")
        state = "CIĘŻKO RANNY" if companion.is_injured else ("AKTYWNY" if companion.active else "POZA WYPRAWĄ")
        print(f"[{index}] {companion.name} | {tactic} | {state}")
    print("[0] Powrót")
    raw = input("\n> ").strip()
    if raw == "0":
        return None
    try:
        value = int(raw)
    except ValueError:
        return None
    return available[value - 1].companion_id if 1 <= value <= len(available) else None


def show_tactic_selection(companion: Companion) -> str | None:
    print_header(); print(); print(f"TAKTYKA — {companion.name.upper()}"); print("-" * 58)
    descriptions = {
        "aggressive": "Priorytet dla najmocniejszych ofensywnych umiejętności.",
        "balanced": "Korzysta z mechanik klasy i reaguje na sytuację drużyny.",
        "cautious": "Broni się przy niskim HP i oszczędza Manę.",
        "defensive": "Częściej osłania siebie lub drużynę, gdy rośnie zagrożenie.",
    }
    keys = list(COMPANION_TACTICS)
    for index, key in enumerate(keys, start=1):
        marker = " [AKTYWNA]" if companion.tactic == key else ""
        print(f"[{index}] {COMPANION_TACTICS[key]}{marker}")
        print(f"    {descriptions[key]}")
    print("[0] Powrót")
    raw = input("\n> ").strip()
    if raw == "0":
        return None
    try:
        value = int(raw)
    except ValueError:
        return None
    return keys[value - 1] if 1 <= value <= len(keys) else None


def show_preset_list(preparation: ExpeditionPreparationState) -> str | None:
    print_header(); print(); print("PRESETY WYPRAWOWE"); print("-" * 58)
    for index, preset_id in enumerate(PRESET_ORDER, start=1):
        preset = preparation.presets[preset_id]
        state = "GOTOWY" if preset.configured else "NIESKONFIGUROWANY"
        print(f"[{index}] {PRESET_NAMES[preset_id]} [{state}]")
        if preset.configured:
            print(f"    Kompani: {len(preset.active_companion_ids)} | Zapasy: {sum(preset.supplies.values())} szt.")
    print("[0] Powrót")
    raw = input("\n> ").strip()
    if raw == "0":
        return None
    try:
        value = int(raw)
    except ValueError:
        return None
    return PRESET_ORDER[value - 1] if 1 <= value <= len(PRESET_ORDER) else None


def show_preset_actions(preparation: ExpeditionPreparationState, preset_id: str) -> str:
    preset = preparation.presets[preset_id]
    print_header(); print(); print(f"PRESET — {PRESET_NAMES[preset_id]}"); print("-" * 58)
    if preset.configured:
        print("Skład zapisany: " + (f"{len(preset.active_companion_ids)} kompanów" if preset.active_companion_ids else "SOLO"))
        if preset.supplies:
            print("Zapasy docelowe:")
            for item_id, quantity in sorted(preset.supplies.items(), key=lambda pair: get_item_definition(pair[0]).name):
                print(f"- {get_item_definition(item_id).name} x{quantity}")
        else:
            print("Zapasy docelowe: brak")
    else:
        print("Preset nie został jeszcze skonfigurowany.")
    print()
    print("[1] Zastosuj preset")
    print("[2] Zapisz aktualny skład i skonfiguruj zapasy")
    print("[3] Wyczyść preset")
    print("[0] Powrót")
    return input("\n> ").strip()


def show_preset_supply_catalog(item_ids: list[str], totals: dict[str, int]) -> None:
    print_header(); print(); print("ZAPASY PRESETU"); print("-" * 58)
    if not item_ids:
        print("Nie masz przedmiotów użytkowych ani w plecaku, ani w Magazynie Gildii.")
        print("\nWpisz 0, aby zapisać preset bez zapasów.")
        return
    for index, item_id in enumerate(item_ids, start=1):
        definition = get_item_definition(item_id)
        print(f"[{index}] {definition.name} | dostępne łącznie: {totals[item_id]}")
    print()
    print("Podaj docelowe ilości, np. 1x5,2x3,4x1")
    print("Niewskazany przedmiot nie należy do presetu.")
    print("[0] Bez zapasów / anuluj wybór zapasów")


def show_departure_confirmation(warnings: list[str], target_name: str) -> bool:
    print_header(); print(); print("WYRUSZENIE"); print("-" * 58)
    print(f"Cel: {target_name}")
    if warnings:
        print(); print("OSTRZEŻENIA:")
        for warning in warnings:
            print(f"- {warning}")
    print(); print("Wyruszyć mimo powyższych uwag?" if warnings else "Drużyna jest gotowa. Wyruszyć?")
    raw = input("[T/N] > ").strip().lower()
    return raw in {"t", "tak", "y", "yes"}
