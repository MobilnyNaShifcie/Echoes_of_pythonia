class_name LootCatalog
extends RefCounted

const TABLES := {
	"wild_dog": [{"item_id": "weak_leather", "chance": 0.7}],
	"slime":
	[{"item_id": "slime_gel", "chance": 0.7}, {"item_id": "weak_healing_potion", "chance": 0.1}],
	"wolf":
	[
		{"item_id": "wolf_fur", "chance": 0.7},
		{"item_id": "wolf_fang", "chance": 0.4},
		{"item_id": "wolf_tooth_necklace", "chance": 0.2}
	],
	"boar": [{"item_id": "raw_boar_meat", "chance": 1.0}, {"item_id": "truffle", "chance": 0.1}],
	"bandit":
	[
		{"item_id": "whetstone", "chance": 0.3},
		{"item_id": "leather_hood", "chance": 0.2},
		{"item_id": "grinding_stone", "chance": 0.1}
	],
	"cursed_scarecrow":
	[{"item_id": "old_clothes", "chance": 0.5}, {"item_id": "spark_of_life", "chance": 0.2}],
	"plains_spirit": [{"item_id": "common_essence", "chance": 0.6}],
	"night_guard":
	[
		{"item_id": "hard_wood", "chance": 0.4},
		{"item_id": "worn_strap", "chance": 0.3},
		{"item_id": "metal_buckle", "chance": 0.15}
	],
	"hunter":
	[
		{"item_id": "hunter_gloves", "chance": 0.2},
		{"item_id": "reinforced_boots", "chance": 0.15},
		{"item_id": "leather_belt", "chance": 0.1}
	],
	"nature_guardian":
	[
		{"item_id": "nature_amulet", "chance": 0.3},
		{"item_id": "nature_ring", "chance": 0.2},
		{"item_id": "nature_bracelet", "chance": 0.2},
		{"item_id": "nature_earrings", "chance": 0.2}
	],
	"venom_spider":
	[
		{"item_id": "spider_silk", "chance": 0.7},
		{"item_id": "venom_gland", "chance": 0.25},
		{"item_id": "spiderstep_boots", "chance": 0.1}
	],
	"forest_cultist":
	[
		{"item_id": "cultist_cloth", "chance": 0.6},
		{"item_id": "dark_sigil", "chance": 0.2},
		{"item_id": "cultist_pendant", "chance": 0.1}
	],
	"rotting_knight":
	[
		{"item_id": "rusted_plate", "chance": 0.6},
		{"item_id": "rotting_knight_helm", "chance": 0.15}
	],
	"corrupted_bear":
	[
		{"item_id": "corrupted_hide", "chance": 1.0},
		{"item_id": "black_bear_claw", "chance": 0.3},
		{"item_id": "bearhide_belt", "chance": 0.12}
	],
	"gallows_wraith":
	[{"item_id": "damned_essence", "chance": 0.6}, {"item_id": "wraith_ring", "chance": 0.1}],
	"black_hart":
	[{"item_id": "black_antler", "chance": 0.5}, {"item_id": "black_antler_charm", "chance": 0.12}],
	"blackwood_executioner":
	[
		{"item_id": "blackwood_heart", "chance": 1.0},
		{"item_id": "executioner_axe", "chance": 0.18},
		{"item_id": "executioner_mask", "chance": 0.18}
	],
	"bog_crawler":
	[
		{"item_id": "bog_ichor", "chance": 0.7},
		{"item_id": "swamp_reed", "chance": 0.35},
		{"item_id": "mirewalker_boots", "chance": 0.1}
	],
	"drowned_dead":
	[
		{"item_id": "drowned_bone", "chance": 0.75},
		{"item_id": "drowned_coin", "chance": 0.25},
		{"item_id": "drowned_gauntlets", "chance": 0.1}
	],
	"swamp_witch":
	[
		{"item_id": "witch_herb", "chance": 0.65},
		{"item_id": "cursed_resin", "chance": 0.25},
		{"item_id": "strong_healing_potion", "chance": 0.1},
		{"item_id": "witchbone_ring", "chance": 0.1}
	],
	"bone_crocodile":
	[
		{"item_id": "ancient_scale", "chance": 1.0},
		{"item_id": "bone_fang", "chance": 0.35},
		{"item_id": "scale_belt", "chance": 0.12}
	],
	"mist_walker":
	[{"item_id": "mist_essence", "chance": 0.65}, {"item_id": "mist_earrings", "chance": 0.1}],
	"sunken_knight":
	[
		{"item_id": "sunken_plate", "chance": 0.6},
		{"item_id": "sunken_knight_armor", "chance": 0.12}
	],
	"drowned_mother":
	[
		{"item_id": "silentwater_heart", "chance": 1.0},
		{"item_id": "drowned_mother_medallion", "chance": 0.12},
		{"item_id": "drowned_mother_blade", "chance": 0.18},
		{"item_id": "drowned_mother_crown", "chance": 0.18},
		{"item_id": "ancient_order_key", "chance": 1.0}
	],
	"desert_wanderer": [{"item_id": "desert_cloth", "chance": 0.7}],
	"desert_harpy":
	[{"item_id": "harpy_feather", "chance": 0.7}, {"item_id": "common_essence", "chance": 0.2}],
	"red_salamander": [{"item_id": "salamander_scale", "chance": 0.65}],
	"boneburner": [{"item_id": "charred_bone", "chance": 0.75}],
	"sand_golem": [{"item_id": "sand_golem_core", "chance": 0.7}],
	"hearth_devourer":
	[
		{"item_id": "hearth_core", "chance": 1.0},
		{"item_id": "common_essence", "chance": 0.5},
		{"item_id": "hearth_gauntlets", "chance": 0.15}
	],
	"frozen_castaway": [{"item_id": "frozen_cloth", "chance": 0.75}],
	"ice_bear":
	[
		{"item_id": "white_fur", "chance": 0.75},
		{"item_id": "north_armor", "chance": 0.025, "elite_chance": 0.08}
	],
	"snow_griffin":
	[
		{"item_id": "snow_griffin_feather", "chance": 0.7},
		{"item_id": "common_essence", "chance": 0.18},
		{"item_id": "snow_griffin_cloak", "chance": 0.025, "elite_chance": 0.08}
	],
	"ice_crab": [{"item_id": "ice_chitin", "chance": 0.75}],
	"black_sea_siren":
	[
		{"item_id": "black_pearl", "chance": 0.65},
		{"item_id": "common_essence", "chance": 0.25},
		{"item_id": "black_sea_amulet", "chance": 0.02, "elite_chance": 0.07}
	],
	"ghost_ship_captain":
	[
		{"item_id": "cursed_compass", "chance": 1.0},
		{"item_id": "black_fleet_medallion", "chance": 1.0},
		{"item_id": "captain_signet", "chance": 0.12}
	],
	"drowned_acolyte":
	[{"item_id": "order_seal", "chance": 0.55}, {"item_id": "cursed_resin", "chance": 0.25}],
	"drowned_priestess":
	[{"item_id": "order_seal", "chance": 0.7}, {"item_id": "mist_essence", "chance": 0.4}],
	"iron_gate_guardian":
	[
		{"item_id": "order_seal", "chance": 1.0},
		{"item_id": "sunken_plate", "chance": 0.6},
		{"item_id": "strong_healing_potion", "chance": 0.2}
	],
	"crypt_warden":
	[{"item_id": "grandmaster_chain", "chance": 1.0}, {"item_id": "order_seal", "chance": 0.75}],
	"order_grandmaster":
	[
		{"item_id": "crown_fragment", "chance": 1.0},
		{"item_id": "order_seal", "chance": 1.0},
		{"item_id": "grandmaster_sword", "chance": 0.12},
		{"item_id": "sunken_order_cloak", "chance": 0.1},
		{"item_id": "abyss_ring", "chance": 0.08}
	],
	"cursed_sailor":
	[{"item_id": "frozen_cloth", "chance": 0.7}, {"item_id": "cursed_compass", "chance": 0.18}],
	"black_fleet_drowned":
	[{"item_id": "frozen_cloth", "chance": 0.6}, {"item_id": "black_pearl", "chance": 0.18}],
	"cursed_gunner":
	[{"item_id": "common_essence", "chance": 0.4}, {"item_id": "cursed_compass", "chance": 0.25}],
	"spectral_marksman":
	[{"item_id": "common_essence", "chance": 0.45}, {"item_id": "black_pearl", "chance": 0.18}],
	"black_fleet_boatswain":
	[
		{"item_id": "cursed_compass", "chance": 0.65},
		{"item_id": "strong_healing_potion", "chance": 0.22}
	],
	"black_fleet_first_officer":
	[
		{"item_id": "cursed_compass", "chance": 1.0},
		{"item_id": "black_pearl", "chance": 0.55},
		{"item_id": "grandmaster_elixir", "chance": 0.2}
	],
	"admiral_varek":
	[
		{"item_id": "varek_sabre_fragment", "chance": 1.0},
		{"item_id": "cursed_compass", "chance": 1.0},
		{"item_id": "varek_sabre", "chance": 0.1}
	]
}


static func has_table(enemy_id: String) -> bool:
	return TABLES.has(enemy_id)


static func get_table(enemy_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry: Dictionary in TABLES.get(enemy_id, []):
		result.append(entry.duplicate(true))
	return result


static func roll_loot(
	enemy_id: String,
	rng: RandomNumberGenerator,
	chance_multiplier := 1.0,
	elite := false,
) -> Array[Dictionary]:
	if rng == null or chance_multiplier < 0.0:
		return []
	var drops: Array[Dictionary] = []
	for entry: Dictionary in TABLES.get(enemy_id, []):
		var base_chance := float(entry.get("elite_chance", entry.chance) if elite else entry.chance)
		var chance := minf(1.0, base_chance * chance_multiplier)
		if rng.randf() < chance:
			drops.append({"item_id": str(entry.item_id), "quantity": int(entry.get("quantity", 1))})
	return drops
