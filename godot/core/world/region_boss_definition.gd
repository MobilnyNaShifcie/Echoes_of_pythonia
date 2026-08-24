class_name RegionBossDefinition
extends RefCounted

var boss_id := ""
var region_id := ""
var display_name := ""
var recommended_level := 0
var challenge_title := ""
var challenge_description := ""
var engine_script: Script


func _init(data: Dictionary) -> void:
	boss_id = str(data.get("boss_id", ""))
	region_id = str(data.get("region_id", ""))
	display_name = str(data.get("display_name", ""))
	recommended_level = int(data.get("recommended_level", 0))
	challenge_title = str(data.get("challenge_title", ""))
	challenge_description = str(data.get("challenge_description", ""))
	engine_script = data.get("engine_script") as Script


func level_warning(player_level: int) -> String:
	if player_level >= recommended_level:
		return ""
	return "UWAGA: ten przeciwnik przewyższa obecny poziom bohatera."
