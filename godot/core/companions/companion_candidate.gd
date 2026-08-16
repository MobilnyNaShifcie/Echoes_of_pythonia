class_name CompanionCandidate
extends RefCounted

const CompanionStateClass := preload("res://core/companions/companion_state.gd")

var candidate_id := ""
var companion: CompanionStateClass
var generated_day := 0
var recruitment_roll := 0
var impression := 0
var talked := false
var recruitment_attempted := false
var returning := false


func _init(
	initial_candidate_id := "",
	initial_companion: CompanionStateClass = null,
	initial_generated_day := 0,
	initial_recruitment_roll := 0
) -> void:
	candidate_id = initial_candidate_id
	companion = initial_companion
	generated_day = initial_generated_day
	recruitment_roll = initial_recruitment_roll
