from dataclasses import dataclass


@dataclass(frozen=True)
class PassiveSpecialization:
    specialization_id: str
    passive_code: str
    name: str
    description: str


PASSIVE_SPECIALIZATIONS: dict[str, PassiveSpecialization] = {
    "iron_will": PassiveSpecialization(
        "iron_will", "health_regen", "Żelazna Wola",
        "Przy 40% HP lub mniej regeneracja zdrowia jest zwiększona o 50%.",
    ),
    "second_wind": PassiveSpecialization(
        "second_wind", "health_regen", "Drugi Oddech",
        "Raz na walkę, gdy po ataku wroga spadniesz do 25% HP lub mniej, odzyskujesz 20% maks. HP.",
    ),
    "flurry": PassiveSpecialization(
        "flurry", "attack_speed", "Nawałnica Ciosów",
        "Szansa na dodatkowe uderzenie rośnie o 5 p.p.",
    ),
    "deadly_tempo": PassiveSpecialization(
        "deadly_tempo", "attack_speed", "Zabójcze Tempo",
        "Trafienie krytyczne przygotowuje +15 p.p. szansy na dodatkowe uderzenie przy następnym podstawowym ataku.",
    ),
    "precision": PassiveSpecialization(
        "precision", "critical_damage", "Precyzja",
        "+3 p.p. stałej szansy na trafienie krytyczne.",
    ),
    "execution": PassiveSpecialization(
        "execution", "critical_damage", "Egzekucja",
        "Krytyki przeciw celom poniżej 30% HP zadają o 20% więcej obrażeń.",
    ),
    "raw_strength": PassiveSpecialization(
        "raw_strength", "increased_attack", "Surowa Siła",
        "+5 stałego ATK.",
    ),
    "momentum": PassiveSpecialization(
        "momentum", "increased_attack", "Rozpęd",
        "Kolejne ofensywne akcje budują Rozpęd do 3 ładunków; każdy daje +3% obrażeń.",
    ),
}


SPECIALIZATIONS_BY_PASSIVE: dict[str, tuple[str, str]] = {
    "health_regen": ("iron_will", "second_wind"),
    "attack_speed": ("flurry", "deadly_tempo"),
    "critical_damage": ("precision", "execution"),
    "increased_attack": ("raw_strength", "momentum"),
}
