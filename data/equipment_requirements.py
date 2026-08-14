# Wymagany poziom postaci do założenia wyposażenia.
#
# Wymagany poziom jest niezależny od:
# - Item Power (skala statystyk),
# - poziomu ulepszenia +0..+10,
# - rarity.
EQUIPMENT_REQUIRED_LEVEL: dict[str, int] = {
    # Start
    "starter_sword": 0,
    "worn_leather_armor": 0,

    # Zmierzchowe Równiny — poziom 1-3
    "leather_hood": 1,
    "stitched_armor": 1,
    "hunter_gloves": 2,
    "reinforced_boots": 2,
    "leather_belt": 2,
    "sharpened_sword": 2,
    "wolf_tooth_necklace": 2,
    "nature_amulet": 3,
    "nature_bracelet": 3,
    "nature_earrings": 3,
    "nature_ring": 3,
    "stormroot_blade": 3,
    "frostroot_blade": 3,
    "windroot_blade": 3,
    "aurora_root_blade": 3,

    # Czarny Bór — poziom 3-5
    "spiderstep_boots": 3,
    "spiderweave_gloves": 3,
    "cultist_pendant": 3,
    "dark_sigil_ring": 3,
    "rotting_knight_helm": 4,
    "blackwood_mail": 4,
    "bearhide_belt": 4,
    "wraith_ring": 4,
    "black_antler_charm": 4,
    "executioner_axe": 5,
    "executioner_mask": 5,
    "storm_executioner_axe": 5,
    "frost_executioner_axe": 5,
    "wind_executioner_axe": 5,
    "aurora_executioner_axe": 5,

    # Mokradła Głuchej Wody — poziom 5-8
    "mirewalker_boots": 5,
    "drowned_gauntlets": 5,
    "witchbone_ring": 5,
    "scale_belt": 6,
    "mist_earrings": 6,
    "sunken_knight_armor": 7,
    "drowned_mother_blade": 8,
    "drowned_mother_crown": 8,
    "drowned_mother_medallion": 8,
    "storm_tide_blade": 8,
    "frost_tide_blade": 8,
    "wind_tide_blade": 8,
    "aurora_tide_blade": 8,

    # Krypta Zatopionego Zakonu
    "grandmaster_sword": 10,
    "sunken_order_cloak": 10,
    "abyss_ring": 10,
    "order_bracelet": 10,

    # Popielne Pogranicze — poziom 11-14
    "wasteland_armor": 11,
    "sun_talisman": 12,
    "wasteland_belt": 13,
    "hearth_gauntlets": 13,
    "azhar_blade": 14,
    "azhar_crown": 14,
    "azhar_ring": 14,

    # Lodowe Wybrzeże — poziom 15-18
    "northern_trail_boots": 15,
    "black_pearl_earrings": 16,
    "north_armor": 16,
    "snow_griffin_cloak": 16,
    "black_sea_amulet": 16,
    "captain_signet": 17,
    "leviathan_ring": 18,

    # Wrak Czarnej Floty
    "varek_sabre": 20,
}

# v0.23.0 — starter class equipment.
EQUIPMENT_REQUIRED_LEVEL.update({
    "training_shield": 5,
    "hunting_bow": 5,
    "simple_quiver": 5,
    "apprentice_staff": 5,
    "mana_crystal_artifact": 5,
    "caprice_lance": 5,
    "worn_fate_dice": 5,
    "trickster_card_deck": 14,
})

EQUIPMENT_REQUIRED_LEVEL.update({
    "hearthguard_shield": 14,
    "echo_quiver": 14,
    "weave_relic": 14,
})


EQUIPMENT_REQUIRED_LEVEL.update({
    "blackwood_longbow": 5, "blackwood_staff": 5, "crooked_fate_lance": 5,
    "mireglass_bow": 8, "mire_staff": 8, "drowned_fate_lance": 8,
    "ashwind_bow": 13, "ember_staff": 13, "ashen_fate_lance": 13,
    "black_sea_bow": 17, "black_sea_staff": 17, "black_tide_fate_lance": 17,
})

# v0.24.0 — pierwsza pula Unikatów Szczelin.
EQUIPMENT_REQUIRED_LEVEL.update({
    "rift_bastion_shield": 18, "last_guard_plate": 18, "oathbreaker_edge": 18, "warden_chain": 18,
    "third_echo_quiver": 18, "riftglass_bow": 18, "silent_volley_cloak": 18, "afterimage_ring": 18,
    "split_weave_artifact": 18, "twin_star_staff": 18, "empty_mana_robe": 18, "storm_archive_relic": 18,
    "two_lies_dice": 18, "deck_without_ace": 18, "seven_chances_lance": 18, "crooked_smile_mask": 18,
})
