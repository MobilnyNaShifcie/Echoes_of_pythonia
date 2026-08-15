class_name GuildMilestoneDefinition
extends RefCounted

var milestone_id: String
var display_name: String
var reputation: int
var source_text: String
var dependency_note: String


func _init(
	id: String,
	name: String,
	reputation_reward: int,
	source: String,
	dependency := "",
) -> void:
	milestone_id = id
	display_name = name
	reputation = reputation_reward
	source_text = source
	dependency_note = dependency
