def calculate_damage(attack: int, defense: int) -> int:
    """Oblicza bazowe obrażenia po uwzględnieniu obrony.

    Udany zwykły atak zawsze zadaje co najmniej 1 punkt obrażeń.
    Bardziej złożone modyfikatory powstaną później.
    """
    if attack < 0:
        raise ValueError("Atak nie może być ujemny.")

    if defense < 0:
        raise ValueError("Obrona nie może być ujemna.")

    return max(1, attack - defense)


def apply_defend_reduction(damage: int) -> int:
    """Zmniejsza obrażenia o połowę podczas aktywnej obrony.

    Używamy dzielenia całkowitego, więc bardzo słaby atak może
    zostać całkowicie zablokowany.
    """
    if damage < 0:
        raise ValueError("Obrażenia nie mogą być ujemne.")

    return damage // 2
