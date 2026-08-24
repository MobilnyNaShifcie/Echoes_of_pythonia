class_name ExpeditionPreparationState
extends RefCounted

const ExpeditionPresetClass := preload("res://core/world/expedition_preset.gd")
const PRESET_ORDER := ["solo", "boss", "dungeon", "rift"]

var selected_location_id := ""
var presets := {}


func _init() -> void:
	for preset_id: String in PRESET_ORDER:
		presets[preset_id] = ExpeditionPresetClass.new(preset_id)


func preset_for(preset_id: String) -> ExpeditionPresetClass:
	return presets.get(preset_id)
