class_name RegionBossCatalog
extends RefCounted

const RegionBossDefinitionClass := preload("res://core/world/region_boss_definition.gd")
const AzharCombatEngineClass := preload("res://core/combat/azhar_combat_engine.gd")
const LeviathanNorthCombatEngineClass := preload(
	"res://core/combat/leviathan_north_combat_engine.gd"
)

const BOSS_ORDER := ["azhar", "leviathan_north"]
const DATA := {
	"azhar":
	{
		"boss_id": "azhar",
		"region_id": "ashen_borderlands",
		"display_name": "Azhar, Władca Pustkowi",
		"recommended_level": 14,
		"challenge_title": "WYZWANIE AZHARA",
		"challenge_description":
		"Władca Pustkowi czeka poza zwykłą tabelą spotkań. Walka ma trzy fazy.",
		"engine_script": AzharCombatEngineClass,
	},
	"leviathan_north":
	{
		"boss_id": "leviathan_north",
		"region_id": "ice_coast",
		"display_name": "Lewiatan Północy",
		"recommended_level": 18,
		"challenge_title": "WYZWANIE LEWIATANA",
		"challenge_description":
		"Lewiatan wynurza się wyłącznie na jawne wyzwanie. Walka ma trzy fazy.",
		"engine_script": LeviathanNorthCombatEngineClass,
	},
}


static func get_definition(boss_id: String) -> RegionBossDefinitionClass:
	var data: Dictionary = DATA.get(boss_id, {})
	return RegionBossDefinitionClass.new(data) if not data.is_empty() else null


static func boss_for_region(region_id: String) -> RegionBossDefinitionClass:
	for boss_id: String in BOSS_ORDER:
		var definition := get_definition(boss_id)
		if definition.region_id == region_id:
			return definition
	return null


static func get_all() -> Array[RegionBossDefinitionClass]:
	var definitions: Array[RegionBossDefinitionClass] = []
	for boss_id: String in BOSS_ORDER:
		definitions.append(get_definition(boss_id))
	return definitions


static func is_valid_id(boss_id: String) -> bool:
	return boss_id in BOSS_ORDER
