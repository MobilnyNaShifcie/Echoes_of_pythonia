from __future__ import annotations

from dataclasses import dataclass

from rifts.models import RiftModifier


RIFT_RANKS: tuple[str, ...] = ("F", "E", "D", "C", "B", "A", "S")
RIFT_RANK_INDEX = {code: index for index, code in enumerate(RIFT_RANKS)}

RIFT_SEGMENTS: dict[str, int] = {
    "F": 12, "E": 14, "D": 16, "C": 18, "B": 20, "A": 22, "S": 24,
}

RIFT_MIN_COMPANIONS: dict[str, int] = {
    "F": 2, "E": 2, "D": 3, "C": 3, "B": 3, "A": 3, "S": 3,
}

RIFT_THEMES: dict[str, dict[str, object]] = {
    "blood_moon": {
        "name": "Pęknięcie Krwawego Księżyca",
        "intro": "Nad rozdartym niebem wisi czerwony księżyc, choć w Pythonii jest środek dnia. Ziemia pulsuje jak rana.",
        "enemy_names": ("Krwawy Tułacz", "Rozdarty Rycerz", "Ogar Pęknięcia", "Szkarłatne Widmo"),
        "elite_names": ("Herold Krwawego Księżyca", "Rzeźnik Rozdarcia"),
        "bosses": (("blood_devourer", "Pożeracz Krwawego Księżyca"), ("red_warden", "Karmazynowy Strażnik")),
    },
    "frozen_void": {
        "name": "Zamarznięta Pustka",
        "intro": "Śnieg unosi się ku górze, a każdy oddech zamarza w powietrzu na kilka sekund. Za horyzontem nie ma nic poza bielą.",
        "enemy_names": ("Pustkowy Rozbitek", "Lodowe Widmo", "Bestia Białej Ciszy", "Zamarznięty Strażnik"),
        "elite_names": ("Żniwiarz Białej Ciszy", "Pęknięty Kolos"),
        "bosses": (("white_maw", "Paszcza Białej Pustki"), ("frozen_oracle", "Zamarznięta Wyrocznia")),
    },
    "ashen_mirror": {
        "name": "Popielne Zwierciadło",
        "intro": "Każdy krok zostawia dwa ślady: jeden w popiele i drugi po niewłaściwej stronie własnego cienia.",
        "enemy_names": ("Popielny Sobowtór", "Pusty Wędrowiec", "Zwierciadlane Ostrze", "Cień bez Twarzy"),
        "elite_names": ("Kopia Bez Imienia", "Strażnik Drugiej Strony"),
        "bosses": (("mirror_lord", "Władca Krzywego Odbicia"), ("nameless_twin", "Bezimienny Bliźniak")),
    },
    "storm_archive": {
        "name": "Archiwum Burzy",
        "intro": "W powietrzu wiszą fragmenty kamiennych stron zapisanych błyskawicami. Każdy grzmot brzmi jak przewracana karta.",
        "enemy_names": ("Runiczny Wartownik", "Burzowy Skryba", "Żywa Pieczęć", "Arkaniczny Łupieżca"),
        "elite_names": ("Egzekutor Zakazanej Strony", "Strażnik Archiwum"),
        "bosses": (("archive_keeper", "Kustosz Burzowego Archiwum"), ("living_edict", "Żywy Edykt")),
    },
    "black_tide": {
        "name": "Czarna Przypływowa Szczelina",
        "intro": "Pod stopami chlupie czarna woda, choć nie ma tu morza. W oddali dzwoni okręt, którego nie da się zobaczyć.",
        "enemy_names": ("Topielec Szczeliny", "Marynarz Bez Portu", "Czarny Krab Otchłani", "Widmowy Harpunik"),
        "elite_names": ("Bosman Bez Okrętu", "Kapitan Czarnej Toni"),
        "bosses": (("tide_colossus", "Kolos Czarnej Toni"), ("bell_captain", "Kapitan Czwartego Dzwonu")),
    },
}

RIFT_MODIFIERS: dict[str, RiftModifier] = {
    "hungry": RiftModifier("hungry", "Głodna Szczelina", "Przeciwnicy są bardziej wytrzymali.", enemy_hp_multiplier=1.18),
    "violent": RiftModifier("violent", "Nadmierna Agresja", "Ataki przeciwników są silniejsze.", enemy_attack_multiplier=1.15),
    "armored": RiftModifier("armored", "Skamieniała Tkanka", "Przeciwnicy zyskują dodatkowy DEF.", enemy_defense_bonus=2),
    "mana_static": RiftModifier("mana_static", "Niestabilna Mana", "Umiejętności kosztują więcej Many.", player_mana_cost_multiplier=1.15),
    "thin_air": RiftModifier("thin_air", "Cienka Granica", "Szczelina jest niestabilna: elity pojawiają się częściej."),
    "echoing": RiftModifier("echoing", "Echo Przebudzenia", "Niektóre walki pozostawiają po sobie dodatkowe widma."),
}

OTHER_SEARCHER_TEAMS: tuple[str, ...] = (
    "Drużyna Srebrnego Wilka",
    "Drużyna Czerwonego Kła",
    "Trzy Korony",
    "Drużyna Bez Imienia",
    "Żelazne Kruki",
)

# Główne nagrody za zamknięcie. Nie istnieje pętla wejścia ponownie do tej
# samej Szczeliny: boss zamyka ją na zawsze.
RIFT_GOLD_REWARD: dict[str, tuple[int, int]] = {
    "F": (900, 1400), "E": (1400, 2200), "D": (2200, 3500),
    "C": (3500, 5200), "B": (5200, 7800), "A": (7800, 11500), "S": (11500, 17000),
}
RIFT_EXP_REWARD: dict[str, int] = {
    "F": 220, "E": 320, "D": 450, "C": 620, "B": 850, "A": 1150, "S": 1550,
}

RIFT_UNIQUE_POOLS: dict[str, tuple[str, ...]] = {
    "warrior": ("rift_bastion_shield", "last_guard_plate", "oathbreaker_edge", "warden_chain"),
    "hunter": ("third_echo_quiver", "riftglass_bow", "silent_volley_cloak", "afterimage_ring"),
    "mage": ("split_weave_artifact", "twin_star_staff", "empty_mana_robe", "storm_archive_relic"),
    "pierrot": ("two_lies_dice", "deck_without_ace", "seven_chances_lance", "crooked_smile_mask"),
}
