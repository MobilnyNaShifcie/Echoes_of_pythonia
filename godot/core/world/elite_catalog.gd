class_name EliteCatalog
extends RefCounted

const EliteModifierDefinitionClass := preload("res://core/world/elite_modifier_definition.gd")
const OpenWorldEncounterStateClass := preload("res://core/world/open_world_encounter_state.gd")

const MODIFIERS := {
	"furious":
	{
		"display_name": "Wściekły",
		"description": "Elitarna baza, +10% PŻ, +30% ATK, -1 DEF.",
	},
	"armored":
	{
		"display_name": "Opancerzony",
		"description": "Elitarna baza, +35% PŻ, mocno zwiększony DEF.",
	},
	"vampiric":
	{
		"display_name": "Wampiryczny",
		"description": "Elitarna baza, +25% PŻ, odzyskuje 40% zadanych obrażeń.",
	},
	"cursed":
	{
		"display_name": "Przeklęty",
		"description":
		"Elitarna baza, +20% PŻ, silniejsze ataki specjalne i 50% odporności na negatywne efekty.",
	},
	"elemental":
	{
		"display_name": "Żywiołowy",
		"description":
		(
			"Elitarna baza, +30% PŻ, mocniejszy ATK, żywioł zależny od pogody "
			+ "i 50% odporności na ten żywioł."
		),
	},
}
const COMPATIBILITY := {
	"wild_dog": ["furious", "vampiric", "elemental"],
	"slime": ["armored", "elemental"],
	"wolf": ["furious", "vampiric", "elemental"],
	"boar": ["furious", "armored", "elemental"],
	"bandit": ["furious", "vampiric", "cursed", "elemental"],
	"cursed_scarecrow": ["armored", "cursed", "elemental"],
	"plains_spirit": ["cursed", "elemental"],
	"night_guard": ["armored", "cursed", "elemental"],
	"hunter": ["furious", "vampiric", "elemental"],
	"venom_spider": ["furious", "vampiric", "elemental"],
	"forest_cultist": ["cursed", "vampiric", "elemental"],
	"rotting_knight": ["armored", "cursed", "elemental"],
	"corrupted_bear": ["furious", "armored", "vampiric", "elemental"],
	"gallows_wraith": ["cursed", "elemental"],
	"black_hart": ["furious", "elemental"],
	"bog_crawler": ["armored", "elemental"],
	"drowned_dead": ["armored", "cursed", "vampiric"],
	"swamp_witch": ["cursed", "vampiric", "elemental"],
	"bone_crocodile": ["furious", "armored", "vampiric", "elemental"],
	"mist_walker": ["cursed", "elemental"],
	"sunken_knight": ["armored", "cursed", "elemental"],
	"desert_wanderer": ["furious", "vampiric", "cursed", "elemental"],
	"desert_harpy": ["furious", "vampiric", "elemental"],
	"red_salamander": ["furious", "armored", "elemental"],
	"boneburner": ["furious", "armored", "cursed", "elemental"],
	"sand_golem": ["armored", "cursed", "elemental"],
	"frozen_castaway": ["furious", "vampiric", "cursed", "elemental"],
	"ice_bear": ["furious", "armored", "vampiric", "elemental"],
	"snow_griffin": ["furious", "vampiric", "elemental"],
	"ice_crab": ["armored", "cursed", "elemental"],
	"black_sea_siren": ["cursed", "vampiric", "elemental"],
}


static func get_modifier(modifier_id: String):
	var data: Dictionary = MODIFIERS.get(modifier_id, {})
	if data.is_empty():
		return null
	return EliteModifierDefinitionClass.new(modifier_id, data.display_name, data.description)


static func get_all_modifiers() -> Array:
	var result := []
	for modifier_id: String in OpenWorldEncounterStateClass.ELITE_MODIFIER_IDS:
		result.append(get_modifier(modifier_id))
	return result


static func compatible_modifier_ids(enemy_id: String) -> Array[String]:
	var result: Array[String] = []
	result.assign(COMPATIBILITY.get(enemy_id, []))
	return result


static func is_compatible(enemy_id: String, modifier_id: String) -> bool:
	return modifier_id in COMPATIBILITY.get(enemy_id, [])
