class_name FallenCompanion
extends RefCounted

var companion_id := ""
var display_name := ""
var class_code := "none"
var level := 1
var day := 0
var cause := ""
var rift_rank := ""


func _init(
	initial_companion_id := "",
	initial_display_name := "",
	initial_class_code := "none",
	initial_level := 1,
	initial_day := 0,
	initial_cause := "",
	initial_rift_rank := ""
) -> void:
	companion_id = initial_companion_id
	display_name = initial_display_name
	class_code = initial_class_code
	level = initial_level
	day = initial_day
	cause = initial_cause
	rift_rank = initial_rift_rank
