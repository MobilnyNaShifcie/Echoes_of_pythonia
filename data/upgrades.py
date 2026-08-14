"""Dane systemu ulepszania wyposażenia.

Moduł zawiera wyłącznie konfigurację balansu. Mechanika pobierania kosztów
pozostaje w systems.blacksmith, a przeliczanie statystyk w items.upgrades.
"""

# Krzywa 0..1 opisująca, jak duża część maksymalnego bonusu skalowanego
# jest aktywna na danym poziomie ulepszenia. Końcowe poziomy są celowo
# bardziej wartościowe, bo wymagają materiałów z trudniejszej zawartości.
UPGRADE_SCALING_PROGRESS: tuple[float, ...] = (
    0.00,  # +0
    0.07,  # +1
    0.14,  # +2
    0.22,  # +3
    0.31,  # +4
    0.41,  # +5
    0.52,  # +6
    0.64,  # +7
    0.76,  # +8
    0.88,  # +9
    1.00,  # +10
)

# Maksymalny procent bazowej statystyki dodawany na +10.
# Stare płaskie bonusy nadal działają jako minimum (patrz items.upgrades),
# więc aktualizacja nigdy nie osłabia już ulepszonego przedmiotu.
UPGRADE_STAT_MAX_BONUS: dict[str, float] = {
    "attack": 0.90,
    "defense": 0.60,
    "max_hp": 0.85,
    "max_mana": 0.85,
    "dodge": 1.00,
}

# Bazowe koszty Gold dla IP I. Wyższy Item Power korzysta z mnożnika poniżej.
BASE_UPGRADE_GOLD_COSTS: tuple[int, ...] = (
    25,    # +0 -> +1
    50,    # +1 -> +2
    75,    # +2 -> +3
    100,   # +3 -> +4
    150,   # +4 -> +5
    225,   # +5 -> +6
    400,   # +6 -> +7
    650,   # +7 -> +8
    950,   # +8 -> +9
    1400,  # +9 -> +10
)

ITEM_POWER_GOLD_MULTIPLIER: dict[int, float] = {
    1: 1.00,
    2: 1.10,
    3: 1.25,
    4: 1.45,
    5: 1.70,
    6: 2.00,
    7: 2.35,
}

# Materiały przypisane do generacji wyposażenia. Dzięki temu sklep daje tylko
# podstawę (+0..+3), a dalsze ulepszanie odsyła gracza do odpowiedniego etapu
# świata. Pola:
# - regional: regularny materiał regionu/dungeonu,
# - elite: materiał mocniejszego przeciwnika/minibossa,
# - boss: materiał głównego bossa danego etapu.
UPGRADE_MATERIAL_PROFILE_BY_ITEM_POWER: dict[int, dict[str, str]] = {
    1: {
        "regional": "common_essence",
        "elite": "common_essence",
        "boss": "spark_of_life",
    },
    2: {
        "regional": "spider_silk",
        "elite": "blackwood_heart",
        "boss": "blackwood_heart",
    },
    3: {
        "regional": "sunken_plate",
        "elite": "silentwater_heart",
        "boss": "silentwater_heart",
    },
    4: {
        "regional": "order_seal",
        "elite": "grandmaster_chain",
        "boss": "crown_fragment",
    },
    5: {
        "regional": "salamander_scale",
        "elite": "hearth_core",
        "boss": "azhar_sigil",
    },
    6: {
        "regional": "ice_chitin",
        "elite": "cursed_compass",
        "boss": "leviathan_scale",
    },
    7: {
        "regional": "black_pearl",
        "elite": "cursed_compass",
        "boss": "varek_sabre_fragment",
    },
}
