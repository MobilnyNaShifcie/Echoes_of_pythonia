class_name EliteModifierDefinition
extends RefCounted

var modifier_id: String
var display_name: String
var description: String


func _init(id: String, name: String, details: String) -> void:
	modifier_id = id
	display_name = name
	description = details
