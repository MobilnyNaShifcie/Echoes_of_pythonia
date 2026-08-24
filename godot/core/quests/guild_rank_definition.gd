class_name GuildRankDefinition
extends RefCounted

var code := "F"
var display_name := "Nowicjusz"
var reputation_required := 0


func _init(rank_code: String, name: String, required: int) -> void:
	code = rank_code
	display_name = name
	reputation_required = required


func full_name() -> String:
	return "%s — %s" % [code, display_name]
