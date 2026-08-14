"""Drop-only wyposażenie klasowe v0.23.

Sprzęt klasowy nie trafia do Warsztatu Mireli. Rzadkie OFF-HAND-y korzystają
z szerokiej puli późnych regionów, natomiast łuki/kostury/Lance Losu mają
regionalne pule progresji, dzięki czemu nowe klasy nie zostają z bronią lvl 5.
"""

CLASS_GEAR_POOL: tuple[str, ...] = (
    "hearthguard_shield",
    "echo_quiver",
    "weave_relic",
    "trickster_card_deck",
)

LATE_GAME_GEAR_ENEMIES: set[str] = {
    # Popielne Pogranicze
    "sand_golem", "desert_harpy", "desert_wanderer", "boneburner",
    "red_salamander", "hearth_devourer", "azhar",
    # Lodowe Wybrzeże
    "frozen_castaway", "ice_bear", "snow_griffin", "ice_crab",
    "black_sea_siren", "ghost_ship_captain", "leviathan_north",
}

CLASS_WEAPON_POOLS: dict[str, tuple[str, ...]] = {
    "blackwood": (
        "blackwood_longbow", "blackwood_staff", "crooked_fate_lance",
    ),
    "marsh": (
        "mireglass_bow", "mire_staff", "drowned_fate_lance",
    ),
    "ashlands": (
        "ashwind_bow", "ember_staff", "ashen_fate_lance",
    ),
    "ice_coast": (
        "black_sea_bow", "black_sea_staff", "black_tide_fate_lance",
    ),
}

CLASS_WEAPON_REGION_BY_ENEMY: dict[str, str] = {}
for _enemy in (
    "venom_spider", "forest_cultist", "rotting_knight", "corrupted_bear",
    "gallows_wraith", "black_hart", "blackwood_executioner",
):
    CLASS_WEAPON_REGION_BY_ENEMY[_enemy] = "blackwood"
for _enemy in (
    "bog_crawler", "drowned_dead", "swamp_witch", "bone_crocodile",
    "mist_walker", "sunken_knight", "drowned_mother",
):
    CLASS_WEAPON_REGION_BY_ENEMY[_enemy] = "marsh"
for _enemy in (
    "sand_golem", "desert_harpy", "desert_wanderer", "boneburner",
    "red_salamander", "hearth_devourer", "azhar",
):
    CLASS_WEAPON_REGION_BY_ENEMY[_enemy] = "ashlands"
for _enemy in (
    "frozen_castaway", "ice_bear", "snow_griffin", "ice_crab",
    "black_sea_siren", "ghost_ship_captain", "leviathan_north",
):
    CLASS_WEAPON_REGION_BY_ENEMY[_enemy] = "ice_coast"
