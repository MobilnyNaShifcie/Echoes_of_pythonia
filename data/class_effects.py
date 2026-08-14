CLASS_EFFECT_DATA: dict[str, dict[str, object]] = {
    "warrior_retribution": {
        "name": "Odwet",
        "class": "warrior",
        "class_name": "Wojownik",
        "description": (
            "Po użyciu Obrony następny podstawowy atak otrzymuje "
            "dodatkową siłę równą 50% twojego DEF."
        ),
    },
    "hunter_predatory_instinct": {
        "name": "Drapieżny Odruch",
        "class": "hunter",
        "class_name": "Łowca",
        "description": (
            "Po udanym uniku następny podstawowy atak zadaje +20% obrażeń "
            "i otrzymuje +10 p.p. szansy na trafienie krytyczne."
        ),
    },
    "mage_mana_tide": {
        "name": "Przypływ Many",
        "class": "mage",
        "class_name": "Mag",
        "description": (
            "Za każde 20 Many wydane na umiejętności odzyskujesz 5 Many. "
            "Postęp liczy się w obrębie jednej walki."
        ),
    },
}

# v0.24.0 — efekty Unikatów Szczelin.
CLASS_EFFECT_DATA.update({
    "rift_bastion_memory": {
        "name": "Pamięć Bastionu", "class": "warrior", "class_name": "Wojownik",
        "description": "Udany Blok zwiększa siłę następnego podstawowego ataku o dodatkowe 25% DEF.",
    },
    "last_guard": {
        "name": "Ostatnia Straż", "class": "warrior", "class_name": "Wojownik",
        "description": "Poniżej 35% HP Wojownik otrzymuje +20% efektywnego DEF przeciw zwykłym atakom.",
    },
    "oathbreaker_bleed": {
        "name": "Złamana Przysięga", "class": "warrior", "class_name": "Wojownik",
        "description": "Krwawy Zamach wydłuża swoje krwawienie o 1 turę.",
    },
    "warden_afterguard": {
        "name": "Po Straży", "class": "warrior", "class_name": "Wojownik",
        "description": "Po użyciu Obrony następny otrzymany zwykły cios jest dodatkowo osłabiony o 15%.",
    },
    "third_echo": {
        "name": "Trzecie Echo", "class": "hunter", "class_name": "Łowca",
        "description": "Trzecia technika kończąca sekwencję Salwy zadaje +15% obrażeń.",
    },
    "riftglass_echo": {
        "name": "Szkło Echa", "class": "hunter", "class_name": "Łowca",
        "description": "Widmowe Echo wraca z 20% większą mocą.",
    },
    "silent_volley": {
        "name": "Bezgłośna Salwa", "class": "hunter", "class_name": "Łowca",
        "description": "Po ukończeniu sekwencji trzech różnych technik Łowca zyskuje +15 p.p. Uniku na następny atak.",
    },
    "afterimage_mana": {
        "name": "Powidok", "class": "hunter", "class_name": "Łowca",
        "description": "Widmowe dodatkowe trafienia mają 30% szansy zwrócić 2 Many.",
    },
    "split_weave": {
        "name": "Rozszczepiony Splot", "class": "mage", "class_name": "Mag",
        "description": "Drugie zaklęcie Podwójnego Splotu działa z dodatkową mocą +10 p.p.",
    },
    "twin_star": {
        "name": "Dwie Gwiazdy", "class": "mage", "class_name": "Mag",
        "description": "Dwa różne żywioły użyte w Podwójnym Splocie wzmacniają drugie zaklęcie o 15%.",
    },
    "empty_mana_power": {
        "name": "Ostatnia Iskra", "class": "mage", "class_name": "Mag",
        "description": "Poniżej 25% maksymalnej Many zaklęcia ofensywne zadają +12% obrażeń.",
    },
    "storm_archive_refund": {
        "name": "Margines Archiwum", "class": "mage", "class_name": "Mag",
        "description": "Każde zaklęcie ma 20% szansy zwrócić 3 Many po rozpatrzeniu.",
    },
    "two_lies": {
        "name": "Dwa Kłamstwa", "class": "pierrot", "class_name": "Pierrot",
        "description": "Każdy dublet Kości Losu zapewnia +1 dodatkowy Żeton Losu.",
    },
    "ace_less_deck": {
        "name": "Bez Asa", "class": "pierrot", "class_name": "Pierrot",
        "description": "Katastrofalne wyniki 3k6 są łagodniejsze, ale Jackpot zadaje 10% mniej obrażeń.",
    },
    "seven_chances": {
        "name": "Siedem Przypadków", "class": "pierrot", "class_name": "Pierrot",
        "description": "Podstawowy atak Pierrota losuje jeden z siedmiu dodatkowych efektów broni.",
    },
    "crooked_smile": {
        "name": "Krzywy Uśmiech", "class": "pierrot", "class_name": "Pierrot",
        "description": "Po udanym odbiciu Krzywym Zwierciadłem Pierrot odzyskuje 1 Żeton Losu.",
    },
})
