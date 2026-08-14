from dataclasses import dataclass


@dataclass(frozen=True)
class ClassPathDefinition:
    path_id: str
    class_code: str
    name: str
    description: str
    book_item_id: str | None = None
    specialization_name: str | None = None


@dataclass(frozen=True)
class TalentDefinition:
    talent_id: str
    class_code: str
    path_id: str
    name: str
    description: str
    max_rank: int = 1
    prerequisites: tuple[tuple[str, int], ...] = ()
    active_skill_id: str | None = None


CLASS_PATHS: dict[str, ClassPathDefinition] = {
    "warrior_assault": ClassPathDefinition(
        "warrior_assault", "warrior", "Natarcie",
        "Agresywny rozwój Wojownika: krwawienie, przełamywanie obrony i egzekucja.",
    ),
    "warrior_heavy_knight": ClassPathDefinition(
        "warrior_heavy_knight", "warrior", "Ciężki Rycerz",
        "Ciężki pancerz, tarcza, blok, prowokacja i kontry skalujące się z DEF.",
        book_item_id="path_heavy_knight_book",
        specialization_name="Ciężki Rycerz",
    ),
    "hunter_volley": ClassPathDefinition(
        "hunter_volley", "hunter", "Mistrz Salwy",
        "Techniki strzeleckie układane w trzystrzałowe sekwencje i odkrywane kombinacje.",
    ),
    "hunter_phantom_archer": ClassPathDefinition(
        "hunter_phantom_archer", "hunter", "Widmowy Strzelec",
        "Widmowe echa, kopie łuku i salwy powtarzające wcześniejsze techniki.",
        book_item_id="path_phantom_archer_book",
        specialization_name="Widmowy Strzelec",
    ),
    "mage_elements": ClassPathDefinition(
        "mage_elements", "mage", "Żywioły",
        "Wzmacnia ogień, mróz i błyskawice oraz nagradza świadome łączenie żywiołów.",
    ),
    "mage_arcana": ClassPathDefinition(
        "mage_arcana", "mage", "Arkana",
        "Splot Magii, ekonomia Many i możliwość rzucenia dwóch zaklęć w jednej turze.",
        book_item_id="path_arcana_book",
        specialization_name="Arkanista",
    ),
    "pierrot_chaos": ClassPathDefinition(
        "pierrot_chaos", "pierrot", "Chaos",
        "Więcej kości, większe ryzyko, dublety, odbicia i ekstremalne jackpoty.",
    ),
    "pierrot_fortuna": ClassPathDefinition(
        "pierrot_fortuna", "pierrot", "Fortuna",
        "Manipulowanie wynikiem, oszukiwanie pecha i świadome wykorzystywanie Żetonów Losu.",
        book_item_id="path_fortuna_book",
        specialization_name="Wybraniec Fortuny",
    ),
}


TALENT_DATA: dict[str, TalentDefinition] = {
    # Wojownik — Natarcie
    "warrior_battle_fury": TalentDefinition(
        "warrior_battle_fury", "warrior", "warrior_assault", "Furia Bitewna",
        "+4% obrażeń umiejętności Wojownika za rangę.", max_rank=3,
    ),
    "warrior_deep_wounds": TalentDefinition(
        "warrior_deep_wounds", "warrior", "warrior_assault", "Głębokie Rany",
        "Krwawienia Wojownika zadają +1 obrażenie na turę za rangę.", max_rank=3,
        prerequisites=(("warrior_battle_fury", 1),),
    ),
    "warrior_breaker": TalentDefinition(
        "warrior_breaker", "warrior", "warrior_assault", "Łamacz",
        "Roztrzaskanie Pancerza obniża dodatkowo DEF o 1 za rangę.", max_rank=2,
        prerequisites=(("warrior_battle_fury", 1),),
    ),
    "warrior_executioner": TalentDefinition(
        "warrior_executioner", "warrior", "warrior_assault", "Egzekutor",
        "Krwawy Zamach zadaje +30% obrażeń celom poniżej 35% HP.",
        prerequisites=(("warrior_deep_wounds", 2),),
    ),
    "warrior_relentless": TalentDefinition(
        "warrior_relentless", "warrior", "warrior_assault", "Nieustępliwy",
        "Podstawowe ataki zadają +5% obrażeń za rangę.", max_rank=2,
        prerequisites=(("warrior_breaker", 1),),
    ),
    # Wojownik — Ciężki Rycerz
    "heavy_knight_core": TalentDefinition(
        "heavy_knight_core", "warrior", "warrior_heavy_knight", "Przysięga Ciężkiego Rycerza",
        "Aktywuje specjalizację Ciężkiego Rycerza i pozwala pełniej wykorzystywać tarcze.",
    ),
    "heavy_shield_mastery": TalentDefinition(
        "heavy_shield_mastery", "warrior", "warrior_heavy_knight", "Mistrz Tarczy",
        "+5 p.p. szansy na Blok za rangę podczas używania tarczy.", max_rank=3,
        prerequisites=(("heavy_knight_core", 1),),
    ),
    "heavy_shield_bash": TalentDefinition(
        "heavy_shield_bash", "warrior", "warrior_heavy_knight", "Uderzenie Tarczą",
        "Odblokowuje atak skalujący się z ATK i DEF.",
        prerequisites=(("heavy_knight_core", 1),), active_skill_id="shield_bash",
    ),
    "heavy_counter": TalentDefinition(
        "heavy_counter", "warrior", "warrior_heavy_knight", "Żelazna Kontra",
        "Udany Blok natychmiast zadaje przeciwnikowi obrażenia równe 70% DEF.",
        prerequisites=(("heavy_shield_mastery", 2),),
    ),
    "heavy_provoke": TalentDefinition(
        "heavy_provoke", "warrior", "warrior_heavy_knight", "Prowokacja",
        "Wymusza zwykły atak przeciwnika i zwiększa szansę Bloku na tę wymianę.",
        prerequisites=(("heavy_shield_mastery", 1),), active_skill_id="provoke",
    ),
    "heavy_bastion": TalentDefinition(
        "heavy_bastion", "warrior", "warrior_heavy_knight", "Bastion",
        "Obrona z tarczą przygotowuje wzmocniony Odwet: 75% DEF zamiast 50%.",
        prerequisites=(("heavy_counter", 1), ("heavy_provoke", 1)),
    ),
    # Łowca — Mistrz Salwy
    "hunter_piercing_arrow": TalentDefinition(
        "hunter_piercing_arrow", "hunter", "hunter_volley", "Przebijająca Strzała",
        "Odblokowuje technikę ignorującą dużą część DEF.", active_skill_id="piercing_arrow",
    ),
    "hunter_frost_arrow": TalentDefinition(
        "hunter_frost_arrow", "hunter", "hunter_volley", "Lodowa Strzała",
        "Odblokowuje technikę mrozu przygotowującą lodowe kombinacje.", active_skill_id="frost_arrow",
    ),
    "hunter_explosive_arrow": TalentDefinition(
        "hunter_explosive_arrow", "hunter", "hunter_volley", "Wybuchowa Strzała",
        "Odblokowuje technikę wbijającą ładunki wybuchowe w cel.",
        prerequisites=(("hunter_piercing_arrow", 1),), active_skill_id="explosive_arrow",
    ),
    "hunter_phantom_arrow": TalentDefinition(
        "hunter_phantom_arrow", "hunter", "hunter_volley", "Widmowa Strzała",
        "Odblokowuje technikę pozostawiającą echo atakujące po następnej akcji.",
        prerequisites=(("hunter_frost_arrow", 1),), active_skill_id="phantom_arrow",
    ),
    "hunter_rain_of_arrows": TalentDefinition(
        "hunter_rain_of_arrows", "hunter", "hunter_volley", "Deszcz Strzał",
        "Odblokowuje opóźnioną salwę spadającą po następnej akcji Łowcy.",
        prerequisites=(("hunter_explosive_arrow", 1),), active_skill_id="rain_of_arrows",
    ),
    "hunter_splitting_arrow": TalentDefinition(
        "hunter_splitting_arrow", "hunter", "hunter_volley", "Rozszczepiająca Strzała",
        "Odblokowuje strzał rozpadający się na dwa widmowe odłamki.",
        prerequisites=(("hunter_phantom_arrow", 1),), active_skill_id="splitting_arrow",
    ),
    "hunter_sequence_mastery": TalentDefinition(
        "hunter_sequence_mastery", "hunter", "hunter_volley", "Perfekcyjna Sekwencja",
        "Sekwencja trzech różnych technik wzmacnia kończący ją strzał o 15%.",
        prerequisites=(("hunter_explosive_arrow", 1), ("hunter_phantom_arrow", 1)),
    ),
    # Łowca — Widmowy Strzelec
    "phantom_archer_core": TalentDefinition(
        "phantom_archer_core", "hunter", "hunter_phantom_archer", "Przysięga Widmowego Strzelca",
        "Aktywuje specjalizację Widmowego Strzelca.",
    ),
    "phantom_echo_mastery": TalentDefinition(
        "phantom_echo_mastery", "hunter", "hunter_phantom_archer", "Echo Łowcy",
        "Widmowe Echo zadaje +15% swojej bazowej mocy za rangę.", max_rank=2,
        prerequisites=(("phantom_archer_core", 1),),
    ),
    "phantom_bows": TalentDefinition(
        "phantom_bows", "hunter", "hunter_phantom_archer", "Widmowe Łuki",
        "Po ukończeniu nazwanej kombinacji pojawia się widmowy łuk i powtarza 35% Finishera.",
        prerequisites=(("phantom_echo_mastery", 1),),
    ),
    "phantom_thousand_arrows": TalentDefinition(
        "phantom_thousand_arrows", "hunter", "hunter_phantom_archer", "Tysiąc Strzał",
        "Odblokowuje finałową salwę widmowych kopii łuku.",
        prerequisites=(("phantom_bows", 1),), active_skill_id="thousand_arrows",
    ),
    # Mag — Żywioły
    "mage_fire_mastery": TalentDefinition(
        "mage_fire_mastery", "mage", "mage_elements", "Serce Ognia",
        "+8% obrażeń Ognistego Pocisku za rangę.", max_rank=2,
    ),
    "mage_frost_mastery": TalentDefinition(
        "mage_frost_mastery", "mage", "mage_elements", "Wieczny Mróz",
        "+8% obrażeń Lodowej Lancy za rangę.", max_rank=2,
    ),
    "mage_storm_mastery": TalentDefinition(
        "mage_storm_mastery", "mage", "mage_elements", "Głos Burzy",
        "+8% obrażeń Pioruna za rangę.", max_rank=2,
    ),
    "mage_elemental_cycle": TalentDefinition(
        "mage_elemental_cycle", "mage", "mage_elements", "Cykl Żywiołów",
        "Rzucenie trzech różnych żywiołów z rzędu wzmacnia trzeci o 20%.",
        prerequisites=(("mage_fire_mastery", 1), ("mage_frost_mastery", 1), ("mage_storm_mastery", 1)),
    ),
    # Mag — Arkana
    "arcana_core": TalentDefinition(
        "arcana_core", "mage", "mage_arcana", "Przysięga Arkanisty",
        "Aktywuje Splot Magii. Każde zaklęcie daje 1 Splot, maksymalnie 3.",
    ),
    "arcana_double_weave": TalentDefinition(
        "arcana_double_weave", "mage", "mage_arcana", "Podwójny Splot",
        "Przy 3/3 Splotu możesz rzucić dwa zaklęcia w jednej turze; drugie ma 80% mocy.",
        prerequisites=(("arcana_core", 1),),
    ),
    "arcana_efficiency": TalentDefinition(
        "arcana_efficiency", "mage", "mage_arcana", "Oszczędny Splot",
        "Drugie zaklęcie Podwójnego Splotu kosztuje 25% mniej Many.",
        prerequisites=(("arcana_double_weave", 1),),
    ),
    "arcana_perfect_weave": TalentDefinition(
        "arcana_perfect_weave", "mage", "mage_arcana", "Perfekcyjny Splot",
        "Drugie zaklęcie Podwójnego Splotu ma 95% mocy zamiast 80%.",
        prerequisites=(("arcana_efficiency", 1),),
    ),
    "arcana_mana_cycle": TalentDefinition(
        "arcana_mana_cycle", "mage", "mage_arcana", "Obieg Many",
        "Po Podwójnym Splocie odzyskujesz 4 Many.",
        prerequisites=(("arcana_perfect_weave", 1),),
    ),
    # Pierrot — Chaos
    "pierrot_wild_roll": TalentDefinition(
        "pierrot_wild_roll", "pierrot", "pierrot_chaos", "Dziki Rzut",
        "Jackpot z Pchnięcia Losu uruchamia dodatkowy rzut kością za bonusowe obrażenia.",
    ),
    "pierrot_crooked_mirror": TalentDefinition(
        "pierrot_crooked_mirror", "pierrot", "pierrot_chaos", "Krzywe Zwierciadło",
        "Dublet w rzucie 2k6 lub 3k6 przygotowuje odbicie następnego bezpośredniego ataku.",
        prerequisites=(("pierrot_wild_roll", 1),),
    ),
    "pierrot_double_stake": TalentDefinition(
        "pierrot_double_stake", "pierrot", "pierrot_chaos", "Podwójna Stawka",
        "Najlepsze i najgorsze wyniki Kości Losu mają o 25% silniejsze skutki.",
        prerequisites=(("pierrot_wild_roll", 1),),
    ),
    "pierrot_domino": TalentDefinition(
        "pierrot_domino", "pierrot", "pierrot_chaos", "Efekt Domina",
        "Jackpot ma 50% szansy uruchomić dodatkowy rzut k6 z obrażeniami.",
        prerequisites=(("pierrot_double_stake", 1),),
    ),
    "pierrot_va_banque": TalentDefinition(
        "pierrot_va_banque", "pierrot", "pierrot_chaos", "Va Banque",
        "Odblokowuje ekstremalny rzut 3k6 zużywający wszystkie Żetony Losu.",
        prerequisites=(("pierrot_crooked_mirror", 1), ("pierrot_domino", 1)), active_skill_id="va_banque",
    ),
    # Pierrot — Fortuna
    "fortuna_core": TalentDefinition(
        "fortuna_core", "pierrot", "pierrot_fortuna", "Przysięga Fortuny",
        "Aktywuje specjalizację Fortuny i zwiększa maksymalną pulę Żetonów Losu o 2.",
    ),
    "fortuna_loaded_die": TalentDefinition(
        "fortuna_loaded_die", "pierrot", "pierrot_fortuna", "Dociążona Kość",
        "Pierwsza wyrzucona jedynka w walce zostaje automatycznie przerzucona.",
        prerequisites=(("fortuna_core", 1),),
    ),
    "fortuna_cheat": TalentDefinition(
        "fortuna_cheat", "pierrot", "pierrot_fortuna", "Kant",
        "Przy 2k6 wynik 6 albo 8 może zużyć 1 Żeton Losu i zostać zmieniony w Szczęśliwą Siódemkę.",
        prerequisites=(("fortuna_loaded_die", 1),),
    ),
    "fortuna_second_chance": TalentDefinition(
        "fortuna_second_chance", "pierrot", "pierrot_fortuna", "Druga Szansa",
        "Raz na walkę katastrofalny rzut 3k6 (suma 5 lub mniej) zostaje przerzucony.",
        prerequisites=(("fortuna_cheat", 1),),
    ),
    "fortuna_favored": TalentDefinition(
        "fortuna_favored", "pierrot", "pierrot_fortuna", "Wybraniec Fortuny",
        "Jackpoty skalują się mocniej ze Szczęściem, a pech daje +1 dodatkowy Żeton Losu.",
        prerequisites=(("fortuna_second_chance", 1),),
    ),
}


CLASS_PATH_ORDER: dict[str, tuple[str, ...]] = {
    "warrior": ("warrior_assault", "warrior_heavy_knight"),
    "hunter": ("hunter_volley", "hunter_phantom_archer"),
    "mage": ("mage_elements", "mage_arcana"),
    "pierrot": ("pierrot_chaos", "pierrot_fortuna"),
}


def talents_for_path(path_id: str) -> list[TalentDefinition]:
    return [talent for talent in TALENT_DATA.values() if talent.path_id == path_id]
