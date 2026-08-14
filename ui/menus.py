from ui.console import print_header


def show_main_menu(has_save: bool = False, has_active_game: bool = False) -> str:
    while True:
        print_header()
        print()
        continue_note = "" if has_active_game else " [BRAK AKTYWNEJ GRY]"
        save_note = "" if has_active_game else " [BRAK AKTYWNEJ GRY]"
        load_note = "" if has_save else " [BRAK ZAPISÓW]"
        print(f"[1] Kontynuuj grę{continue_note}")
        print("[2] Nowa gra")
        print(f"[3] Wczytaj grę{load_note}")
        print(f"[4] Zapisz grę{save_note}")
        print("[5] Stan projektu")
        print("[0] Wyjście")
        print()

        choice = input("> ").strip()
        if choice in {"1", "2", "3", "4", "5", "0"}:
            return choice

        print("\nNieprawidłowa opcja. Spróbuj ponownie.")
        input("Naciśnij Enter...")


def ask_player_name() -> str:
    while True:
        print_header()
        print()
        print("TWORZENIE BOHATERA")
        print("-" * 58)
        name = input("Podaj imię bohatera: ").strip()
        if 2 <= len(name) <= 20:
            return name

        print("\nImię musi mieć od 2 do 20 znaków.")
        input("Naciśnij Enter...")
