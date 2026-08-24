class_name ClassCombatMechanicDefinition
extends RefCounted

var mechanic_id := ""
var character_class_code := ""
var display_name := ""
var description := ""


func _init(data: Dictionary) -> void:
	mechanic_id = str(data.get("mechanic_id", ""))
	character_class_code = str(data.get("character_class_code", ""))
	display_name = str(data.get("display_name", mechanic_id))
	description = str(data.get("description", ""))
