# Dane bonusów Equipment 2.0.
#
# `kind` określa sposób formatowania i zaokrąglania wartości.
# `role` ogranicza bonus do ofensywnych lub defensywnych slotów.
# Pas korzysta z obu pul, ale jego wartości są osłabione w generatorze.
AFFIX_DATA: dict[str, dict[str, object]] = {
    # Defensywne
    "max_hp": {
        "name": "Maks. HP",
        "role": "defensive",
        "kind": "flat_int",
    },
    "defense": {
        "name": "DEF",
        "role": "defensive",
        "kind": "flat_int",
    },
    "dodge": {
        "name": "Unik",
        "role": "defensive",
        "kind": "percent",
    },
    "health_regen": {
        "name": "Regeneracja HP",
        "role": "defensive",
        "kind": "flat_int",
    },
    "fire_resistance": {
        "name": "Odporność na Ogień",
        "role": "defensive",
        "kind": "percent_int",
    },
    "wind_resistance": {
        "name": "Odporność na Wiatr",
        "role": "defensive",
        "kind": "percent_int",
    },
    "frost_resistance": {
        "name": "Odporność na Mróz",
        "role": "defensive",
        "kind": "percent_int",
    },
    "earth_resistance": {
        "name": "Odporność na Ziemię",
        "role": "defensive",
        "kind": "percent_int",
    },
    "water_resistance": {
        "name": "Odporność na Wodę",
        "role": "defensive",
        "kind": "percent_int",
    },

    # Ofensywne
    "attack": {
        "name": "ATK",
        "role": "offensive",
        "kind": "flat_int",
    },
    "max_mana": {
        "name": "Maks. Mana",
        "role": "offensive",
        "kind": "flat_int",
    },
    "crit_chance": {
        "name": "Szansa na krytyk",
        "role": "offensive",
        "kind": "percent",
    },
    "crit_damage": {
        "name": "Obrażenia krytyczne",
        "role": "offensive",
        "kind": "percent",
    },
    "skill_damage": {
        "name": "Obrażenia umiejętności",
        "role": "offensive",
        "kind": "percent",
    },
    "armor_penetration": {
        "name": "Penetracja pancerza",
        "role": "offensive",
        "kind": "percent",
    },
    "damage_vs_elite": {
        "name": "Obrażenia przeciw elitom",
        "role": "offensive",
        "kind": "percent",
    },
    "damage_vs_boss": {
        "name": "Obrażenia przeciw bossom",
        "role": "offensive",
        "kind": "percent",
    },
}

DEFENSIVE_AFFIX_IDS: tuple[str, ...] = tuple(
    affix_id
    for affix_id, data in AFFIX_DATA.items()
    if data["role"] == "defensive"
)

OFFENSIVE_AFFIX_IDS: tuple[str, ...] = tuple(
    affix_id
    for affix_id, data in AFFIX_DATA.items()
    if data["role"] == "offensive"
)
