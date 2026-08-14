from __future__ import annotations

from companions.models import COMPANION_TACTICS, Companion, CompanionCandidate, PartyState
from data.companions import COMPANION_TEMPLATES
from data.talents import CLASS_PATHS
from items.catalog import get_item_definition
from items.models import EquipmentSlot
from player.classes import player_class_from_code
from systems.companions import candidate_path_name, willingness_label
from ui.console import print_header


def show_companion_hub(party: PartyState) -> str:
    print_header(); print(); print("DRUŻYNA I KOMPANI"); print("-" * 58)
    active = party.active_companions()
    print(f"Aktywna wyprawa: {len(active)}/3 kompanów")
    print(f"Związani z drużyną: {len(party.companions)}/4")
    if party.unread_messages():
        print(f"Nowe wiadomości: {party.unread_messages()}")
    print()
    print("[1] Moi kompani")
    print("[2] Ustaw skład wyprawy")
    print("[3] Kandydaci w Gildii")
    print("[4] Wiadomości drużyny")
    print("[5] Tablica poległych")
    print("[0] Powrót")
    return input("\n> ").strip()


def show_party_setup(party: PartyState) -> tuple[str, str | None]:
    print_header(); print(); print("USTAW SKŁAD WYPRAWY"); print("-" * 58)
    active = party.active_companions()
    if active:
        print(f"Tryb: DRUŻYNA | Aktywni kompani: {len(active)}/3")
    else:
        print("Tryb: SOLO | Aktywni kompani: 0/3")
    print()

    if not party.companions:
        print("Nie masz jeszcze stałych kompanów.")
    else:
        for index, companion in enumerate(party.companions, start=1):
            path = CLASS_PATHS[companion.path_id]
            if companion.dead:
                marker = "†"
                state = "POLEGŁY"
            elif companion.is_injured:
                marker = "!"
                state = "CIĘŻKO RANNY"
            elif companion.active:
                marker = "✓"
                state = "AKTYWNY"
            else:
                marker = " "
                state = "POZA WYPRAWĄ"
            print(f"[{index}] [{marker}] {companion.name} | {player_class_from_code(companion.class_code).display_name} lvl {companion.level}")
            print(f"    Drzewko: {path.name} | {state}")

    print()
    print("[S] Wyruszaj solo — wyłącz wszystkich aktywnych kompanów")
    print("[0] Gotowe")
    raw = input("\n> ").strip().lower()
    if raw == "0":
        return "done", None
    if raw in {"s", "solo"}:
        return "solo", None
    try:
        value = int(raw)
    except ValueError:
        return "invalid", None
    if 1 <= value <= len(party.companions):
        return "toggle", party.companions[value - 1].companion_id
    return "invalid", None


def show_candidate_list(candidates: list[CompanionCandidate], guild_rank_code: str, scores: dict[str, int]) -> int | None:
    print_header(); print(); print("KANDYDACI DO DRUŻYNY"); print("-" * 58)
    if not candidates:
        print("Dzisiaj nie ma nikogo, kto szukałby stałej drużyny.")
        input("\nNaciśnij Enter...")
        return None
    for index, candidate in enumerate(candidates, start=1):
        companion = candidate.companion
        player_class = player_class_from_code(companion.class_code)
        path_name, rare = candidate_path_name(candidate)
        marker = " [RZADKA ŚCIEŻKA]" if rare else ""
        print(f"[{index}] {companion.name} | {player_class.display_name} | lvl {companion.level}")
        print(f"    Drzewko: {path_name}{marker}")
        print(f"    Nastawienie: {willingness_label(scores[candidate.candidate_id])}")
        print("    Ekwipunek: ???")
        if candidate.returning:
            print("    [ZNANY KOMPAN — spotykaliście się wcześniej]")
        print()
    print("[0] Powrót")
    raw = input("\n> ").strip()
    if raw == "0":
        return None
    try:
        value = int(raw)
    except ValueError:
        return None
    return value - 1 if 1 <= value <= len(candidates) else None


def show_candidate(candidate: CompanionCandidate, score: int) -> str:
    companion = candidate.companion
    template = COMPANION_TEMPLATES[companion.template_id]
    path = CLASS_PATHS[companion.path_id]
    print_header(); print(); print(companion.name.upper()); print("-" * 58)
    print(template.intro)
    print()
    print(f"Pochodzenie: {template.origin}")
    print(f"Klasa: {player_class_from_code(companion.class_code).display_name}")
    print(f"Poziom: {companion.level}")
    print(f"Drzewko: {path.name}" + (" [RZADKA ŚCIEŻKA]" if path.book_item_id else ""))
    print(f"Styl: {template.voice}")
    print(f"Szansa na porozumienie: {willingness_label(score)}")
    print("Ekwipunek: nieznany do czasu dołączenia")
    print()
    print("[1] Porozmawiaj")
    print("[2] Zaproponuj współpracę")
    print("[0] Powrót")
    return input("\n> ").strip()


def show_candidate_talk_choices(name: str) -> int | None:
    print_header(); print(); print(f"ROZMOWA — {name.upper()}"); print("-" * 58)
    print("[1] Powiedz wprost, czego oczekujesz od drużyny.")
    print("[2] Pogadaj zwyczajnie, bez kontraktów i rang.")
    print("[3] Opowiedz o najtrudniejszej walce, jaką masz za sobą.")
    print("[0] Zakończ rozmowę")
    raw = input("\n> ").strip()
    if raw == "0":
        return None
    return int(raw) if raw in {"1", "2", "3"} else None


def show_companion_list(party: PartyState) -> int | None:
    print_header(); print(); print("MOI KOMPANI"); print("-" * 58)
    if not party.companions:
        print("Nie masz jeszcze stałych kompanów.")
        input("\nNaciśnij Enter...")
        return None
    for index, companion in enumerate(party.companions, start=1):
        path = CLASS_PATHS[companion.path_id]
        status = "AKTYWNY" if companion.active and companion.can_join_party else "POZA WYPRAWĄ"
        if companion.is_injured:
            status = "CIĘŻKO RANNY"
        print(f"[{index}] {companion.name} | {player_class_from_code(companion.class_code).display_name} lvl {companion.level}")
        print(f"    Drzewko: {path.name} | Relacja: {companion.relation:+d} | {status}")
    print("[0] Powrót")
    raw = input("\n> ").strip()
    if raw == "0":
        return None
    try:
        value = int(raw)
    except ValueError:
        return None
    return value - 1 if 1 <= value <= len(party.companions) else None


def show_companion_detail(companion: Companion, current_day: int) -> str:
    template = COMPANION_TEMPLATES[companion.template_id]
    path = CLASS_PATHS[companion.path_id]
    print_header(); print(); print(companion.name.upper()); print("-" * 58)
    print(f"Klasa: {player_class_from_code(companion.class_code).display_name} | Poziom {companion.level}")
    print(f"Drzewko: {path.name}" + (" [RZADKA ŚCIEŻKA]" if path.book_item_id else ""))
    print(f"Relacja: {companion.relation:+d}")
    print(f"Taktyka AI: {COMPANION_TACTICS.get(companion.tactic, 'Zrównoważona')}")
    if companion.injury_until_day:
        print(f"Stan: CIĘŻKO RANNY | Powrót do sił: {max(0, companion.injury_until_day-current_day)} dni Pythonii")
    else:
        print("Stan: gotowy do wyprawy" if companion.active else "Stan: pozostaje dziś w Varenhold")
    print(f"Wspólne zamknięte Szczeliny: {companion.rifts_together}")
    print()
    print("[1] Ekwipunek")
    print("[2] Drzewko i build")
    print("[3] Rozmowa osobista")
    print("[4] " + ("Zostaw poza wyprawą" if companion.active else "Dołącz do aktywnej trójki"))
    print("[5] Rozstań się")
    print("[0] Powrót")
    return input("\n> ").strip()


def show_companion_build(companion: Companion) -> None:
    print_header(); print(); print(f"BUILD — {companion.name.upper()}"); print("-" * 58)
    print(f"Główne drzewko: {CLASS_PATHS[companion.path_id].name}")
    print("Talenty:")
    for talent_id, rank in sorted(companion.talents.items()):
        from data.talents import TALENT_DATA
        talent = TALENT_DATA[talent_id]
        print(f"- {talent.name}: {rank}/{talent.max_rank}")
    print()
    print("Atrybuty:")
    print(f"Siła {companion.attributes.strength} | Witalność {companion.attributes.vitality} | Inteligencja {companion.attributes.intelligence}")
    print(f"Zręczność {companion.attributes.dexterity} | Wytrzymałość {companion.attributes.endurance} | Szczęście {companion.attributes.luck}")


def show_companion_equipment(companion: Companion) -> str:
    print_header(); print(); print(f"EKWIPUNEK — {companion.name.upper()}"); print("-" * 58)
    for slot in EquipmentSlot:
        item = companion.equipment.get(slot)
        if item is None:
            print(f"{slot.display_name:<12}: [brak]")
            continue
        definition = get_item_definition(item.item_id)
        owner = "OSOBISTY" if companion.owns_item(item) else "POWIERZONY PRZEZ CIEBIE"
        print(f"{slot.display_name:<12}: {definition.name} +{item.upgrade_level} [{owner}]")
    print()
    print("[1] Daj przedmiot z plecaka")
    print("[2] Odbierz powierzony przedmiot")
    print("[0] Powrót")
    return input("\n> ").strip()


def show_companion_equippable_inventory(player, companion: Companion) -> int | None:
    print_header(); print(); print(f"DAJ EKWIPUNEK — {companion.name.upper()}"); print("-" * 58)
    valid: list[int] = []
    for index, item in enumerate(player.inventory.equipment_items):
        definition = get_item_definition(item.item_id)
        if definition.required_level > companion.level:
            continue
        if definition.required_class_code and definition.required_class_code != companion.class_code:
            continue
        valid.append(index)
        print(f"[{len(valid)}] {definition.name} +{item.upgrade_level} | {definition.slot.display_name if definition.slot else '?'}")
    if not valid:
        print("Brak wyposażenia, które ten kompan może teraz założyć.")
        input("\nNaciśnij Enter...")
        return None
    print("[0] Powrót")
    raw = input("\n> ").strip()
    if raw == "0":
        return None
    try:
        selected = int(raw)
    except ValueError:
        return None
    return valid[selected - 1] if 1 <= selected <= len(valid) else None


def show_companion_loaned_slots(companion: Companion) -> EquipmentSlot | None:
    slots = []
    print_header(); print(); print("ODBIERZ POWIERZONY PRZEDMIOT"); print("-" * 58)
    for slot in EquipmentSlot:
        item = companion.equipment.get(slot)
        if item is None or companion.owns_item(item):
            continue
        slots.append(slot)
        print(f"[{len(slots)}] {slot.display_name}: {get_item_definition(item.item_id).name} +{item.upgrade_level}")
    if not slots:
        print("Kompan nie ma na sobie żadnego twojego przedmiotu.")
        input("\nNaciśnij Enter...")
        return None
    print("[0] Powrót")
    raw = input("\n> ").strip()
    if raw == "0":
        return None
    try:
        selected = int(raw)
    except ValueError:
        return None
    return slots[selected - 1] if 1 <= selected <= len(slots) else None


def show_messages(party: PartyState) -> None:
    print_header(); print(); print("WIADOMOŚCI DRUŻYNY"); print("-" * 58)
    if not party.messages:
        print("Brak wiadomości.")
        return
    for message in party.messages[-12:]:
        marker = "[NOWA] " if not message.read else ""
        print(f"{marker}Dzień {message.day} — {message.sender_name}")
        print(f"  „{message.text}”")
        print()


def show_fallen(party: PartyState) -> None:
    print_header(); print(); print("TABLICA POLEGŁYCH"); print("-" * 58)
    if not party.fallen:
        print("Na tablicy nie ma nazwisk z twojej drużyny.")
        return
    for fallen in party.fallen:
        rank = f" | Szczelina {fallen.rift_rank}" if fallen.rift_rank else ""
        print(f"- {fallen.name} | {player_class_from_code(fallen.class_code).display_name} lvl {fallen.level}{rank}")
        print(f"  Dzień {fallen.day}: {fallen.cause}")


def show_personal_stage(companion: Companion, arc, stage) -> int | None:
    print_header(); print(); print(f"{arc.title.upper()} — {companion.name}"); print("-" * 58)
    print(stage.title)
    print()
    print(stage.text)
    print()
    for index, choice in enumerate(stage.choices, start=1):
        print(f"[{index}] {choice.text}")
    print("[0] Jeszcze nie")
    raw = input("\n> ").strip()
    if raw == "0":
        return None
    try:
        value = int(raw)
    except ValueError:
        return None
    return value - 1 if 1 <= value <= len(stage.choices) else None
