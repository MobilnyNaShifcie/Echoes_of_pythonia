class_name CompanionPersonalArc
extends RefCounted

const CompanionQuestStageClass := preload("res://core/companions/companion_quest_stage.gd")

var arc_id := ""
var title := ""
var stages: Array[CompanionQuestStageClass] = []


func _init(
	initial_arc_id := "", initial_title := "", initial_stages: Array[CompanionQuestStageClass] = []
) -> void:
	arc_id = initial_arc_id
	title = initial_title
	stages.assign(initial_stages)
