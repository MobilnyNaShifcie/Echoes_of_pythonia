class_name TalentDefinition
extends RefCounted

var talent_id := ""
var character_class_code := ""
var path_id := ""
var display_name := ""
var description := ""
var max_rank := 1
var prerequisites := {}
var active_skill_id := ""


func _init(data: Dictionary) -> void:
	talent_id = str(data.get("talent_id", ""))
	character_class_code = str(data.get("character_class_code", ""))
	path_id = str(data.get("path_id", ""))
	display_name = str(data.get("display_name", talent_id))
	description = str(data.get("description", ""))
	max_rank = maxi(1, int(data.get("max_rank", 1)))
	prerequisites = data.get("prerequisites", {}).duplicate(true)
	active_skill_id = str(data.get("active_skill_id", ""))
