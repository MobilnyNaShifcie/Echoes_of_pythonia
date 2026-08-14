from pathlib import Path

from game.config import SAVE_SLOT_COUNT
from systems.save_system import SaveSummary
from ui.console import print_header


def show_save_slots(
    summaries: dict[int, SaveSummary | None],
    *,
    title: str,
    active_slot: int | None = None,
) -> None:
    print_header()
    print()
    print(title)
    print("-" * 58)
    for number in range(1, SAVE_SLOT_COUNT + 1):
        summary = summaries.get(number)
        active = " [AKTYWNY]" if active_slot == number else ""
        if summary is None:
            print(f"[{number}] Slot {number}: [PUSTY]{active}")
            continue
        print(
            f"[{number}] Slot {number}: {summary.player_name} | "
            f"Poziom {summary.level} | {summary.city_name}{active}"
        )
        print(
            f"    Dzień {summary.day}, {summary.hour:02d}:00 | "
            f"{summary.location_name} | v{summary.game_version}"
        )
    print("[0] Anuluj")
    print()


def show_save_summary(summary: SaveSummary | None, slot_number: int = 1) -> None:
    print_header()
    print()
    print("ZAPIS GRY")
    print("-" * 58)

    if summary is None:
        print(f"Slot {slot_number}: [PUSTY]")
        return

    print(f"Slot {slot_number}:")
    print(f"  Bohater: {summary.player_name}")
    print(f"  Poziom: {summary.level}")
    print(f"  Czas świata: Dzień {summary.day} | {summary.hour:02d}:00")
    print(f"  Lokacja: {summary.location_name}")
    print(f"  Miasto: {summary.city_name}")
    print(f"  Wersja zapisu: {summary.game_version}")


def show_save_success(slot_number: int = 1) -> None:
    print()
    print(f"Gra została zapisana w Slocie {slot_number}.")


def show_load_success(summary: SaveSummary, slot_number: int = 1) -> None:
    print_header()
    print()
    print("WCZYTANO GRĘ")
    print("-" * 58)
    print(
        f"Slot {slot_number} | {summary.player_name} | Poziom {summary.level} | "
        f"{summary.city_name}"
    )


def show_save_error(message: str) -> None:
    print()
    print(f"Błąd zapisu: {message}")


def show_migration_success(source: Path) -> None:
    print_header()
    print()
    print("MIGRACJA ZAPISU")
    print("-" * 58)
    print("Znaleziono zapis z poprzedniej wersji gry.")
    print("Został przeniesiony do stałego folderu danych użytkownika jako Slot 1.")
    print()
    print(f"Źródło: {source}")
    print()
    print("Od teraz aktualizacja folderu gry nie usuwa sejwa.")
