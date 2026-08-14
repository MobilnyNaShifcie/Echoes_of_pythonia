class_name PlayerClassCatalog
extends RefCounted

const PlayerClassDefinitionClass := preload("res://core/player/player_class_definition.gd")
const PLAYABLE_ORDER := ["warrior", "hunter", "mage", "pierrot"]
const DEFINITIONS := {
	"none": preload("res://data/classes/seeker.tres"),
	"warrior": preload("res://data/classes/warrior.tres"),
	"hunter": preload("res://data/classes/hunter.tres"),
	"mage": preload("res://data/classes/mage.tres"),
	"pierrot": preload("res://data/classes/pierrot.tres"),
}


static func get_definition(class_code: String) -> PlayerClassDefinitionClass:
	return DEFINITIONS.get(class_code)


static func get_playable_definitions() -> Array[PlayerClassDefinitionClass]:
	var result: Array[PlayerClassDefinitionClass] = []
	for class_code: String in PLAYABLE_ORDER:
		result.append(DEFINITIONS[class_code])
	return result


static func is_valid_code(class_code: String) -> bool:
	return DEFINITIONS.has(class_code)
