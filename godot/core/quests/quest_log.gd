class_name QuestLog
extends RefCounted

var active := {}
var completed := {}


func is_active(quest_id: String) -> bool:
	return active.has(quest_id) and not completed.has(quest_id)


func is_completed(quest_id: String) -> bool:
	return completed.has(quest_id)
