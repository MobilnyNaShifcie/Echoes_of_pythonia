class_name CompanionDialogueChoice
extends RefCounted

var text := ""
var response := ""
var relation_delta := 0
var memory_tag := ""


func _init(
	initial_text := "",
	initial_response := "",
	initial_relation_delta := 0,
	initial_memory_tag := ""
) -> void:
	text = initial_text
	response = initial_response
	relation_delta = initial_relation_delta
	memory_tag = initial_memory_tag
