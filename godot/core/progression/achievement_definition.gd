class_name AchievementDefinition
extends RefCounted

var achievement_id: String
var display_name: String
var description: String
var title: String


func _init(id: String, name: String, achievement_description: String, unlocked_title: String):
	achievement_id = id
	display_name = name
	description = achievement_description
	title = unlocked_title
