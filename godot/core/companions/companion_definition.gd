class_name CompanionDefinition
extends RefCounted

var template_id: String
var display_name: String
var origin: String
var voice: String
var allowed_classes: Array[String] = []
var personality_tags: Array[String] = []
var base_willingness: int
var minimum_guild_rank: String


func _init(
	initial_template_id: String,
	initial_display_name: String,
	initial_origin: String,
	initial_voice: String,
	initial_allowed_classes: Array[String],
	initial_personality_tags: Array[String],
	initial_base_willingness: int,
	initial_minimum_guild_rank: String
) -> void:
	template_id = initial_template_id
	display_name = initial_display_name
	origin = initial_origin
	voice = initial_voice
	allowed_classes.assign(initial_allowed_classes)
	personality_tags.assign(initial_personality_tags)
	base_willingness = initial_base_willingness
	minimum_guild_rank = initial_minimum_guild_rank


func allows_class(class_code: String) -> bool:
	return class_code in allowed_classes
