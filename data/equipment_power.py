EQUIPMENT_ITEM_POWER: dict[str, int] = {
    # Item Power I — Zmierzchowe Równiny / początek gry
    "starter_sword": 1,
    "worn_leather_armor": 1,
    "leather_hood": 1,
    "stitched_armor": 1,
    "hunter_gloves": 1,
    "reinforced_boots": 1,
    "leather_belt": 1,
    "sharpened_sword": 1,
    "wolf_tooth_necklace": 1,
    "nature_amulet": 1,
    "nature_bracelet": 1,
    "nature_earrings": 1,
    "nature_ring": 1,
    "stormroot_blade": 1,
    "frostroot_blade": 1,
    "windroot_blade": 1,
    "aurora_root_blade": 1,

    # Item Power II — Czarny Bór
    "spiderstep_boots": 2,
    "spiderweave_gloves": 2,
    "cultist_pendant": 2,
    "dark_sigil_ring": 2,
    "rotting_knight_helm": 2,
    "blackwood_mail": 2,
    "bearhide_belt": 2,
    "wraith_ring": 2,
    "black_antler_charm": 2,
    "executioner_axe": 2,
    "executioner_mask": 2,
    "storm_executioner_axe": 2,
    "frost_executioner_axe": 2,
    "wind_executioner_axe": 2,
    "aurora_executioner_axe": 2,

    # Item Power III — Mokradła Głuchej Wody
    "mirewalker_boots": 3,
    "drowned_gauntlets": 3,
    "witchbone_ring": 3,
    "scale_belt": 3,
    "drowned_mother_medallion": 3,
    "mist_earrings": 3,
    "sunken_knight_armor": 3,
    "drowned_mother_blade": 3,
    "drowned_mother_crown": 3,
    "storm_tide_blade": 3,
    "frost_tide_blade": 3,
    "wind_tide_blade": 3,
    "aurora_tide_blade": 3,

    # Item Power IV — Krypta Zatopionego Zakonu
    "grandmaster_sword": 4,
    "sunken_order_cloak": 4,
    "abyss_ring": 4,
    "order_bracelet": 4,

    # Item Power V — Popielne Pogranicze
    "wasteland_armor": 5,
    "wasteland_belt": 5,
    "sun_talisman": 5,
    "hearth_gauntlets": 5,
    "azhar_blade": 5,
    "azhar_crown": 5,
    "azhar_ring": 5,

    # Item Power VI — Lodowe Wybrzeże
    "north_armor": 6,
    "snow_griffin_cloak": 6,
    "black_sea_amulet": 6,
    "northern_trail_boots": 6,
    "black_pearl_earrings": 6,
    "captain_signet": 6,
    "leviathan_ring": 6,

    # Item Power VII — Wrak Czarnej Floty
    "varek_sabre": 7,
}

# v0.23.0 — starter class equipment.
EQUIPMENT_ITEM_POWER.update({
    "training_shield": 2,
    "hunting_bow": 2,
    "simple_quiver": 2,
    "apprentice_staff": 2,
    "mana_crystal_artifact": 2,
    "caprice_lance": 2,
    "worn_fate_dice": 2,
    "trickster_card_deck": 5,
})

EQUIPMENT_ITEM_POWER.update({
    "hearthguard_shield": 5,
    "echo_quiver": 5,
    "weave_relic": 5,
})


EQUIPMENT_ITEM_POWER.update({
    "blackwood_longbow": 2, "blackwood_staff": 2, "crooked_fate_lance": 2,
    "mireglass_bow": 3, "mire_staff": 3, "drowned_fate_lance": 3,
    "ashwind_bow": 5, "ember_staff": 5, "ashen_fate_lance": 5,
    "black_sea_bow": 6, "black_sea_staff": 6, "black_tide_fate_lance": 6,
})

# v0.24.0 — Unikaty Szczelin.
EQUIPMENT_ITEM_POWER.update({
    "rift_bastion_shield": 7, "last_guard_plate": 7, "oathbreaker_edge": 7, "warden_chain": 7,
    "third_echo_quiver": 7, "riftglass_bow": 7, "silent_volley_cloak": 7, "afterimage_ring": 7,
    "split_weave_artifact": 7, "twin_star_staff": 7, "empty_mana_robe": 7, "storm_archive_relic": 7,
    "two_lies_dice": 7, "deck_without_ace": 7, "seven_chances_lance": 7, "crooked_smile_mask": 7,
})
