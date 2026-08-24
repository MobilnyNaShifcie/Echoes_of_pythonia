class_name CompanionStoryDefinition
extends RefCounted

# gdlint: disable=function-arguments-number

const CompanionPersonalArcClass := preload("res://core/companions/companion_personal_arc.gd")

var template_id := ""
var intro := ""
var recruit_success := ""
var recruit_fail := ""
var farewell := ""
var return_line := ""
var idle_lines: Array[String] = []
var messages: Array[String] = []
var camp_lines: Array[String] = []
var arcs: Array[CompanionPersonalArcClass] = []
var conversations: Array[Dictionary] = []


func _init(
	initial_template_id := "",
	initial_intro := "",
	initial_recruit_success := "",
	initial_recruit_fail := "",
	initial_farewell := "",
	initial_return_line := "",
	initial_idle_lines: Array[String] = [],
	initial_messages: Array[String] = [],
	initial_camp_lines: Array[String] = [],
	initial_arcs: Array[CompanionPersonalArcClass] = [],
	initial_conversations: Array[Dictionary] = []
) -> void:
	template_id = initial_template_id
	intro = initial_intro
	recruit_success = initial_recruit_success
	recruit_fail = initial_recruit_fail
	farewell = initial_farewell
	return_line = initial_return_line
	idle_lines.assign(initial_idle_lines)
	messages.assign(initial_messages)
	camp_lines.assign(initial_camp_lines)
	arcs.assign(initial_arcs)
	conversations.assign(initial_conversations)


func arc_by_id(arc_id: String) -> CompanionPersonalArcClass:
	for arc: CompanionPersonalArcClass in arcs:
		if arc.arc_id == arc_id:
			return arc
	return null
