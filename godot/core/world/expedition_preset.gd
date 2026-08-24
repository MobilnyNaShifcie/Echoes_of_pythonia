class_name ExpeditionPreset
extends RefCounted

var preset_id := ""
var configured := false
var active_companion_ids: Array[String] = []
var supplies := {}


func _init(initial_preset_id := "") -> void:
	preset_id = initial_preset_id
