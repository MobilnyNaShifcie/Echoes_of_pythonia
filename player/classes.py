from enum import Enum


class PlayerClass(Enum):
    NONE = (
        "none",
        "Poszukiwacz",
        0,
        "Bez wybranej drogi.",
        "Brak",
    )
    WARRIOR = (
        "warrior",
        "Wojownik",
        12,
        "Ciężkie uderzenia, łamanie obrony i wytrzymałość.",
        "Siła / Wytrzymałość",
    )
    HUNTER = (
        "hunter",
        "Łowca",
        16,
        "Łuk, techniki strzeleckie, trzystrzałowe sekwencje i odkrywane kombinacje.",
        "Zręczność / Siła",
    )
    MAGE = (
        "mage",
        "Mag",
        24,
        "Zaklęcia żywiołów, Splot Magii i wysoka skuteczność Inteligencji.",
        "Inteligencja",
    )
    PIERROT = (
        "pierrot",
        "Pierrot",
        18,
        "Lanca Losu, Kości Losu, Chaos i manipulowanie Szczęściem.",
        "Szczęście / Zręczność",
    )

    def __init__(
        self,
        code: str,
        display_name: str,
        base_mana: int,
        description: str,
        primary_attributes: str,
    ) -> None:
        self.code = code
        self.display_name = display_name
        self.base_mana = base_mana
        self.description = description
        self.primary_attributes = primary_attributes


PLAYABLE_CLASSES = (
    PlayerClass.WARRIOR,
    PlayerClass.HUNTER,
    PlayerClass.MAGE,
    PlayerClass.PIERROT,
)


def player_class_from_code(code: str) -> PlayerClass:
    for player_class in PlayerClass:
        if player_class.code == code:
            return player_class
    raise ValueError(f"Nieznana klasa bohatera: {code}")
