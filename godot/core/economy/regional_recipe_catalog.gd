class_name RegionalRecipeCatalog
extends RefCounted

# Recipe notes intentionally preserve the terminal version's complete prose.
# gdlint: disable=max-line-length
const RECIPE_ORDER_BY_REGION := {
	"twilight_plains":
	[
		"leather_hood",
		"stitched_armor",
		"hunter_gloves",
		"reinforced_boots",
		"sharpened_sword",
		"leather_belt",
		"wolf_tooth_necklace",
		"hunter_provisions",
		"nature_ring",
		"weak_to_strong_potion"
	],
	"black_forest":
	[
		"spiderweave_gloves",
		"blackwood_mail",
		"dark_sigil_ring",
		"cultist_pendant",
		"bearhide_belt",
		"black_antler_charm",
		"executioner_axe",
		"executioner_mask"
	],
	"silent_water_marshes":
	[
		"mirewalker_boots",
		"witchbone_ring",
		"scale_belt",
		"strong_healing_potion",
		"great_healing_potion",
		"drowned_gauntlets",
		"mist_earrings",
		"sunken_knight_armor",
		"drowned_mother_blade",
		"drowned_mother_crown",
		"drowned_mother_medallion",
		"ancient_order_key"
	],
	"ashen_borderlands":
	[
		"wasteland_armor",
		"wasteland_belt",
		"sun_talisman",
		"hearth_gauntlets",
		"azhar_blade",
		"azhar_crown",
		"azhar_ring"
	],
	"ice_coast":
	[
		"northern_trail_boots",
		"black_pearl_earrings",
		"captain_signet",
		"leviathan_ring",
		"black_fleet_medallion"
	]
}
const RECIPES := {
	"leather_hood":
	{
		"name": "Skórzany Kaptur",
		"output_item_id": "leather_hood",
		"quantity": 1,
		"ingredients": {"weak_leather": 2},
		"region_id": "twilight_plains"
	},
	"stitched_armor":
	{
		"name": "Zszywana Zbroja",
		"output_item_id": "stitched_armor",
		"quantity": 1,
		"ingredients": {"old_clothes": 5, "weak_leather": 1},
		"region_id": "twilight_plains"
	},
	"hunter_gloves":
	{
		"name": "Rękawice Myśliwego",
		"output_item_id": "hunter_gloves",
		"quantity": 1,
		"ingredients": {"weak_leather": 3, "worn_strap": 2},
		"region_id": "twilight_plains"
	},
	"reinforced_boots":
	{
		"name": "Wzmocnione Buty",
		"output_item_id": "reinforced_boots",
		"quantity": 1,
		"ingredients": {"weak_leather": 4, "old_clothes": 2},
		"region_id": "twilight_plains"
	},
	"sharpened_sword":
	{
		"name": "Ostrzony Miecz",
		"output_item_id": "sharpened_sword",
		"quantity": 1,
		"ingredients": {"starter_sword": 1, "whetstone": 2},
		"region_id": "twilight_plains",
		"note": "Stary Miecz musi znajdować się w plecaku."
	},
	"leather_belt":
	{
		"name": "Pas Skórzany",
		"output_item_id": "leather_belt",
		"quantity": 1,
		"ingredients": {"worn_strap": 2, "metal_buckle": 1, "weak_leather": 1},
		"region_id": "twilight_plains"
	},
	"wolf_tooth_necklace":
	{
		"name": "Ząb Wilka",
		"output_item_id": "wolf_tooth_necklace",
		"quantity": 1,
		"ingredients": {"wolf_fur": 3, "wolf_fang": 2},
		"region_id": "twilight_plains",
		"note": "Alternatywa dla bezpośredniego dropu z Wilka."
	},
	"hunter_provisions":
	{
		"name": "Prowiant Myśliwego",
		"output_item_id": "hunter_provisions",
		"quantity": 1,
		"ingredients": {"raw_boar_meat": 2, "truffle": 1},
		"region_id": "twilight_plains"
	},
	"nature_ring":
	{
		"name": "Pierścień Natury",
		"output_item_id": "nature_ring",
		"quantity": 1,
		"ingredients": {"spark_of_life": 1, "common_essence": 3, "hard_wood": 2},
		"region_id": "twilight_plains",
		"note": "Alternatywa dla bezpośredniego dropu ze Strażnika Natury."
	},
	"weak_to_strong_potion":
	{
		"name": "Wzmocnienie: Słaba → Mocna",
		"output_item_id": "strong_healing_potion",
		"quantity": 1,
		"ingredients": {"weak_healing_potion": 3},
		"region_id": "twilight_plains",
		"note": "Trzy Słabe Mikstury Lecznicze można połączyć w jedną Mocną."
	},
	"spiderweave_gloves":
	{
		"name": "Rękawice Pajęczego Splotu",
		"output_item_id": "spiderweave_gloves",
		"quantity": 1,
		"ingredients": {"spider_silk": 4, "venom_gland": 1},
		"region_id": "black_forest"
	},
	"blackwood_mail":
	{
		"name": "Pancerz Czarnego Boru",
		"output_item_id": "blackwood_mail",
		"quantity": 1,
		"ingredients": {"rusted_plate": 3, "corrupted_hide": 2},
		"region_id": "black_forest"
	},
	"dark_sigil_ring":
	{
		"name": "Pierścień Mrocznego Sygnetu",
		"output_item_id": "dark_sigil_ring",
		"quantity": 1,
		"ingredients": {"dark_sigil": 2, "damned_essence": 1},
		"region_id": "black_forest"
	},
	"cultist_pendant":
	{
		"name": "Wisiorek Kultysty",
		"output_item_id": "cultist_pendant",
		"quantity": 1,
		"ingredients": {"cultist_cloth": 4, "dark_sigil": 1, "damned_essence": 1},
		"region_id": "black_forest"
	},
	"bearhide_belt":
	{
		"name": "Pas z Czarnej Skóry",
		"output_item_id": "bearhide_belt",
		"quantity": 1,
		"ingredients": {"corrupted_hide": 2, "black_bear_claw": 1},
		"region_id": "black_forest",
		"note": "Alternatywa dla bezpośredniego dropu ze Spaczonego Niedźwiedzia."
	},
	"black_antler_charm":
	{
		"name": "Bransoleta Czarnego Jelenia",
		"output_item_id": "black_antler_charm",
		"quantity": 1,
		"ingredients": {"black_antler": 3, "spider_silk": 2},
		"region_id": "black_forest",
		"note": "Alternatywa dla bezpośredniego dropu z Czarnego Jelenia."
	},
	"executioner_axe":
	{
		"name": "Topór Leśnego Egzekutora",
		"output_item_id": "executioner_axe",
		"quantity": 1,
		"ingredients": {"blackwood_heart": 3, "hard_wood": 4, "grinding_stone": 2},
		"region_id": "black_forest",
		"note": "Trzy Serca Czarnego Boru gwarantują drogę do bossowej broni.",
		"gold_cost": 450
	},
	"executioner_mask":
	{
		"name": "Maska Leśnego Egzekutora",
		"output_item_id": "executioner_mask",
		"quantity": 1,
		"ingredients": {"blackwood_heart": 3, "rusted_plate": 4, "cultist_cloth": 3},
		"region_id": "black_forest",
		"note": "Alternatywne wykorzystanie Serc Czarnego Boru.",
		"gold_cost": 400
	},
	"mirewalker_boots":
	{
		"name": "Buty Brodzącego w Mule",
		"output_item_id": "mirewalker_boots",
		"quantity": 1,
		"ingredients": {"swamp_reed": 4, "bog_ichor": 2},
		"region_id": "silent_water_marshes"
	},
	"witchbone_ring":
	{
		"name": "Pierścień z Kości Wiedźmy",
		"output_item_id": "witchbone_ring",
		"quantity": 1,
		"ingredients": {"drowned_bone": 3, "witch_herb": 2, "mist_essence": 1},
		"region_id": "silent_water_marshes"
	},
	"scale_belt":
	{
		"name": "Pas z Prastarych Łusek",
		"output_item_id": "scale_belt",
		"quantity": 1,
		"ingredients": {"ancient_scale": 3, "bone_fang": 1},
		"region_id": "silent_water_marshes"
	},
	"strong_healing_potion":
	{
		"name": "Mocna Mikstura Lecznicza",
		"output_item_id": "strong_healing_potion",
		"quantity": 1,
		"ingredients": {"witch_herb": 2, "slime_gel": 2},
		"region_id": "silent_water_marshes",
		"note": "Klasyczna receptura Mireli z ziół i śluzu."
	},
	"great_healing_potion":
	{
		"name": "Wzmocnienie: Mocna → Wielka",
		"output_item_id": "great_healing_potion",
		"quantity": 1,
		"ingredients": {"strong_healing_potion": 3, "mist_essence": 1},
		"region_id": "silent_water_marshes",
		"note": "Trzy Mocne Mikstury można połączyć w jedną Wielką Miksturę Leczniczą."
	},
	"drowned_gauntlets":
	{
		"name": "Rękawice Topielca",
		"output_item_id": "drowned_gauntlets",
		"quantity": 1,
		"ingredients": {"drowned_bone": 3, "drowned_coin": 2},
		"region_id": "silent_water_marshes"
	},
	"mist_earrings":
	{
		"name": "Kolczyki Wędrowca Mgieł",
		"output_item_id": "mist_earrings",
		"quantity": 1,
		"ingredients": {"mist_essence": 3, "cursed_resin": 2},
		"region_id": "silent_water_marshes"
	},
	"sunken_knight_armor":
	{
		"name": "Pancerz Zatopionego Zakonu",
		"output_item_id": "sunken_knight_armor",
		"quantity": 1,
		"ingredients": {"sunken_plate": 5, "ancient_scale": 2, "drowned_coin": 2},
		"region_id": "silent_water_marshes",
		"note": "Alternatywa dla bezpośredniego dropu z Rycerza Zatopionego Zakonu.",
		"gold_cost": 450
	},
	"drowned_mother_blade":
	{
		"name": "Ostrze Matki Głuchej Wody",
		"output_item_id": "drowned_mother_blade",
		"quantity": 1,
		"ingredients": {"silentwater_heart": 3, "ancient_scale": 3, "bone_fang": 2},
		"region_id": "silent_water_marshes",
		"note": "Trzy Serca Głuchej Wody gwarantują drogę do bossowej broni.",
		"gold_cost": 750
	},
	"drowned_mother_crown":
	{
		"name": "Korona Utopionej Matki",
		"output_item_id": "drowned_mother_crown",
		"quantity": 1,
		"ingredients":
		{"silentwater_heart": 3, "mist_essence": 3, "cursed_resin": 2, "sunken_plate": 2},
		"region_id": "silent_water_marshes",
		"note": "Alternatywne wykorzystanie Serc Głuchej Wody.",
		"gold_cost": 750
	},
	"drowned_mother_medallion":
	{
		"name": "Medalion Utopionej Matki",
		"output_item_id": "drowned_mother_medallion",
		"quantity": 1,
		"ingredients": {"silentwater_heart": 2, "mist_essence": 3, "drowned_coin": 2},
		"region_id": "silent_water_marshes",
		"note": "Pośredni naszyjnik dla bohaterów, którzy wyrośli już z wyposażenia Czarnego Boru.",
		"gold_cost": 650,
		"equipment_quality": "miniboss"
	},
	"ancient_order_key":
	{
		"name": "Starożytny Klucz Zakonu",
		"output_item_id": "ancient_order_key",
		"quantity": 1,
		"ingredients": {"silentwater_heart": 1, "sunken_plate": 2, "mist_essence": 2},
		"region_id": "silent_water_marshes",
		"note": "Alternatywne źródło wejściówki do Krypty. Klucz jest zużywany przy wejściu.",
		"gold_cost": 300
	},
	"wasteland_armor":
	{
		"name": "Pancerz Pustkowi",
		"output_item_id": "wasteland_armor",
		"quantity": 1,
		"ingredients":
		{"desert_cloth": 4, "sand_golem_core": 3, "charred_bone": 2, "common_essence": 2},
		"region_id": "ashen_borderlands",
		"gold_cost": 1400
	},
	"wasteland_belt":
	{
		"name": "Pas Pustkowi",
		"output_item_id": "wasteland_belt",
		"quantity": 1,
		"ingredients":
		{"desert_cloth": 3, "sand_golem_core": 3, "salamander_scale": 2, "common_essence": 2},
		"region_id": "ashen_borderlands",
		"note": "Następca Pasa z Prastarych Łusek dla środkowej części progresji.",
		"gold_cost": 1500
	},
	"sun_talisman":
	{
		"name": "Talizman Słońca",
		"output_item_id": "sun_talisman",
		"quantity": 1,
		"ingredients":
		{"harpy_feather": 3, "salamander_scale": 3, "common_essence": 3, "spark_of_life": 1},
		"region_id": "ashen_borderlands",
		"gold_cost": 1200
	},
	"hearth_gauntlets":
	{
		"name": "Karwasze Paleniska",
		"output_item_id": "hearth_gauntlets",
		"quantity": 1,
		"ingredients":
		{"hearth_core": 3, "charred_bone": 4, "salamander_scale": 2, "common_essence": 2},
		"region_id": "ashen_borderlands",
		"gold_cost": 1700,
		"equipment_quality": "miniboss"
	},
	"azhar_blade":
	{
		"name": "Ostrze Azhara",
		"output_item_id": "azhar_blade",
		"quantity": 1,
		"ingredients":
		{"azhar_sigil": 6, "hearth_core": 2, "salamander_scale": 4, "grinding_stone": 3},
		"region_id": "ashen_borderlands",
		"gold_cost": 2600,
		"equipment_quality": "boss"
	},
	"azhar_crown":
	{
		"name": "Korona Azhara",
		"output_item_id": "azhar_crown",
		"quantity": 1,
		"ingredients":
		{"azhar_sigil": 6, "sand_golem_core": 4, "common_essence": 3, "spark_of_life": 1},
		"region_id": "ashen_borderlands",
		"gold_cost": 2400,
		"equipment_quality": "boss"
	},
	"azhar_ring":
	{
		"name": "Pierścień Azhara",
		"output_item_id": "azhar_ring",
		"quantity": 1,
		"ingredients": {"azhar_sigil": 6, "harpy_feather": 4, "common_essence": 3},
		"region_id": "ashen_borderlands",
		"gold_cost": 2200,
		"equipment_quality": "boss"
	},
	"northern_trail_boots":
	{
		"name": "Buty Północnego Szlaku",
		"output_item_id": "northern_trail_boots",
		"quantity": 1,
		"ingredients":
		{
			"frozen_cloth": 4,
			"white_fur": 3,
			"snow_griffin_feather": 2,
			"ice_chitin": 2,
			"common_essence": 2
		},
		"region_id": "ice_coast",
		"gold_cost": 1800
	},
	"black_pearl_earrings":
	{
		"name": "Kolczyki Czarnej Perły",
		"output_item_id": "black_pearl_earrings",
		"quantity": 1,
		"ingredients": {"black_pearl": 2, "ice_chitin": 3, "common_essence": 3, "spark_of_life": 1},
		"region_id": "ice_coast",
		"gold_cost": 1900
	},
	"captain_signet":
	{
		"name": "Bransoleta Czarnej Floty",
		"output_item_id": "captain_signet",
		"quantity": 1,
		"ingredients": {"cursed_compass": 3, "black_pearl": 2, "common_essence": 3},
		"region_id": "ice_coast",
		"note":
		"Rzadka bransoleta związana z Czarną Flotą; receptura pozostaje zabezpieczeniem przed pechem.",
		"gold_cost": 2300,
		"equipment_quality": "miniboss"
	},
	"leviathan_ring":
	{
		"name": "Pierścień Lewiatana",
		"output_item_id": "leviathan_ring",
		"quantity": 1,
		"ingredients":
		{"leviathan_scale": 6, "black_pearl": 3, "common_essence": 4, "spark_of_life": 1},
		"region_id": "ice_coast",
		"note":
		"Sześć Łusek Lewiatana zapewnia drogę do bossowego pierścienia bez wpływania na drop przedmiotów klasowych.",
		"gold_cost": 3200,
		"equipment_quality": "boss"
	},
	"black_fleet_medallion":
	{
		"name": "Medalion Czarnej Floty",
		"output_item_id": "black_fleet_medallion",
		"quantity": 1,
		"ingredients": {"black_pearl": 1, "ice_chitin": 3, "white_fur": 2, "common_essence": 2},
		"region_id": "ice_coast",
		"note":
		"Alternatywne źródło wejściówki do Wraku Czarnej Floty. Medalion jest zużywany przy wejściu.",
		"gold_cost": 900
	}
}


static func get_recipe(recipe_id: String) -> Dictionary:
	if not RECIPES.has(recipe_id):
		return {}
	var recipe: Dictionary = RECIPES[recipe_id].duplicate(true)
	recipe.recipe_id = recipe_id
	return recipe


static func get_recipes(region_id := "") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var region_ids: Array = RECIPE_ORDER_BY_REGION.keys() if region_id.is_empty() else [region_id]
	for current_region_id: String in region_ids:
		for recipe_id: String in RECIPE_ORDER_BY_REGION.get(current_region_id, []):
			result.append(get_recipe(recipe_id))
	return result
