def ask_point_quantity(maximum: int) -> int | None:
    """Pyta o liczbę punktów do wydania.

    Zwraca None po anulowaniu. `MAX` wydaje maksymalną dozwoloną
    liczbę punktów dla aktualnie wybranej statystyki.
    """
    if maximum <= 0:
        raise ValueError("Maksymalna liczba punktów musi być dodatnia.")

    while True:
        print()
        print(
            f"Ile punktów chcesz dodać? "
            f"[1-{maximum} / MAX | 0 = anuluj]"
        )
        choice = input("> ").strip()

        if choice == "0":
            return None

        if choice.upper() == "MAX":
            return maximum

        try:
            amount = int(choice)
        except ValueError:
            print("Nieprawidłowa ilość. Wpisz liczbę albo MAX.")
            continue

        if 1 <= amount <= maximum:
            return amount

        print(f"Wybierz wartość od 1 do {maximum}.")
