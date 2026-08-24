class_name BookCatalog
extends RefCounted

const BookDefinitionClass := preload("res://core/progression/book_definition.gd")
const BOOK_ORDER := [
	"mastery_regeneration_book",
	"mastery_attack_speed_book",
	"mastery_critical_book",
	"mastery_strength_book",
	"path_heavy_knight_book",
	"path_phantom_archer_book",
	"path_arcana_book",
	"path_fortuna_book",
]


static func get_definition(item_id: String) -> BookDefinitionClass:
	match item_id:
		"mastery_regeneration_book":
			return BookDefinitionClass.new(item_id, "mastery", "health_regen", "", "", 36000, 16000)
		"mastery_attack_speed_book":
			return BookDefinitionClass.new(item_id, "mastery", "attack_speed", "", "", 42000, 18000)
		"mastery_critical_book":
			return BookDefinitionClass.new(
				item_id, "mastery", "critical_damage", "", "", 48000, 21000
			)
		"mastery_strength_book":
			return BookDefinitionClass.new(
				item_id, "mastery", "increased_attack", "", "", 40000, 17000
			)
		"path_heavy_knight_book":
			return BookDefinitionClass.new(
				item_id, "path_unlock", "", "warrior_heavy_knight", "warrior", 78000, 32000
			)
		"path_phantom_archer_book":
			return BookDefinitionClass.new(
				item_id, "path_unlock", "", "hunter_phantom_archer", "hunter", 82000, 34000
			)
		"path_arcana_book":
			return BookDefinitionClass.new(
				item_id, "path_unlock", "", "mage_arcana", "mage", 88000, 36000
			)
		"path_fortuna_book":
			return BookDefinitionClass.new(
				item_id, "path_unlock", "", "pierrot_fortuna", "pierrot", 95000, 40000
			)
	return null


static func get_all_definitions() -> Array[BookDefinitionClass]:
	var result: Array[BookDefinitionClass] = []
	for item_id: String in BOOK_ORDER:
		result.append(get_definition(item_id))
	return result


static func is_book(item_id: String) -> bool:
	return get_definition(item_id) != null
