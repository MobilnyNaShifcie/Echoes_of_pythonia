class_name CompanionQuestStage
extends RefCounted

const CompanionDialogueChoiceClass := preload("res://core/companions/companion_dialogue_choice.gd")

var title := ""
var text := ""
var unlock_rifts := 0
var choices: Array[CompanionDialogueChoiceClass] = []


func _init(
	initial_title := "",
	initial_text := "",
	initial_unlock_rifts := 0,
	initial_choices: Array[CompanionDialogueChoiceClass] = []
) -> void:
	title = initial_title
	text = initial_text
	unlock_rifts = initial_unlock_rifts
	choices.assign(initial_choices)
