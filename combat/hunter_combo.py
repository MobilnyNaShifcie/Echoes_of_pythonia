from dataclasses import dataclass


@dataclass(frozen=True)
class HunterCombo:
    combo_id: str
    name: str
    sequence: tuple[str, str, str]
    sequence_names: tuple[str, str, str]
    description: str


TECHNIQUE_NAMES = {
    "blood": "Krwawa",
    "piercing": "Przebijająca",
    "frost": "Lodowa",
    "explosive": "Wybuchowa",
    "phantom": "Widmowa",
    "rain": "Deszcz Strzał",
    "splitting": "Rozszczepiająca",
}


def _combo(combo_id: str, name: str, seq: tuple[str, str, str], description: str) -> HunterCombo:
    return HunterCombo(combo_id, name, seq, tuple(TECHNIQUE_NAMES[x] for x in seq), description)


HUNTER_COMBOS: dict[str, HunterCombo] = {
    "scarlet_execution": _combo("scarlet_execution", "Szkarłatna Egzekucja", ("blood", "blood", "blood"), "Pogłębia krwawienie i natychmiast zadaje dodatkowe obrażenia."),
    "brittle_burst": _combo("brittle_burst", "Kruche Rozerwanie", ("frost", "frost", "explosive"), "Lód pęka wraz z ładunkiem i wywołuje mocną detonację."),
    "phantom_detonation": _combo("phantom_detonation", "Widmowa Detonacja", ("explosive", "phantom", "explosive"), "Echo przechodzi przez cel i odpala wbite ładunki od środka."),
    "phantom_parade": _combo("phantom_parade", "Parada Widm", ("phantom", "phantom", "phantom"), "Trzy echa materializują się jednocześnie i uderzają serię razy."),
    "armor_storm": _combo("armor_storm", "Burza Przebicia", ("rain", "piercing", "splitting"), "Salwa z góry zostaje rozszczepiona i przebija pancerz."),
    "bloody_echo": _combo("bloody_echo", "Szkarłatne Widmo", ("blood", "phantom", "piercing"), "Widmowe echo otwiera ranę ponownie po przebiciu pancerza."),
}


def combo_for_sequence(sequence: tuple[str, str, str]) -> HunterCombo | None:
    for combo in HUNTER_COMBOS.values():
        if combo.sequence == sequence:
            return combo
    return None
