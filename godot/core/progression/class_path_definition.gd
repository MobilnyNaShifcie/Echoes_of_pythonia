class_name ClassPathDefinition
extends RefCounted

var path_id := ""
var character_class_code := ""
var display_name := ""
var description := ""
var book_item_id := ""
var specialization_name := ""


func _init(data: Dictionary) -> void:
	path_id = str(data.get("path_id", ""))
	character_class_code = str(data.get("character_class_code", ""))
	display_name = str(data.get("display_name", path_id))
	description = str(data.get("description", ""))
	book_item_id = str(data.get("book_item_id", ""))
	specialization_name = str(data.get("specialization_name", ""))


func requires_book() -> bool:
	return not book_item_id.is_empty()
