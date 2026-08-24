class_name EquipmentAffix
extends RefCounted

var affix_id := ""
var tier := 1
var value := 0.0


func _init(initial_id := "", initial_tier := 1, initial_value := 0.0) -> void:
	affix_id = initial_id
	tier = initial_tier
	value = initial_value
