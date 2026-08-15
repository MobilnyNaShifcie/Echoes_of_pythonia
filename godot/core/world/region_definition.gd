class_name RegionDefinition
extends RefCounted

var region_id: String
var display_name: String
var description: String
var danger_rating: int
var recommended_level_min: int
var recommended_level_max: int
var encounter_chance: float
var day_encounters: Dictionary
var night_encounters: Dictionary
var quiet_events: Array[String] = []


func _init(
	id: String,
	name: String,
	region_description: String,
	danger: int,
	level_min: int,
	level_max: int,
	chance: float,
	day: Dictionary,
	night: Dictionary,
	quiet: Array
) -> void:
	region_id = id
	display_name = name
	description = region_description
	danger_rating = danger
	recommended_level_min = level_min
	recommended_level_max = level_max
	encounter_chance = chance
	day_encounters = day.duplicate(true)
	night_encounters = night.duplicate(true)
	quiet_events.assign(quiet)


func encounters_for(period_code: String) -> Dictionary:
	return day_encounters if period_code == "day" else night_encounters


func recommended_level_text() -> String:
	return "%d–%d" % [recommended_level_min, recommended_level_max]


func level_guidance(player_level: int) -> String:
	if player_level < recommended_level_min:
		return "Poziom poniżej zalecanego — wyprawa będzie bardzo ryzykowna."
	if player_level > recommended_level_max:
		return "Poziom powyżej zalecanego zakresu."
	return "Poziom mieści się w zalecanym zakresie."
