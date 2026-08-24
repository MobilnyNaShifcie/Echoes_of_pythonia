class_name QuestDefinition
extends RefCounted

const KILL := "kill"
const COLLECT := "collect"

var quest_id := ""
var title := ""
var description := ""
var recommended_level := 0
var unlock_level := 0
var objective_type := KILL
var target_id := ""
var target_name := ""
var required_count := 1
var reward_exp := 0
var reward_gold := 0
var guild_reputation := 0
var prerequisite_quest_id := ""
var story_arc := ""
var chapter := ""
var completion_text := ""
var consume_objective_items := true
var dependency_note := ""


func _init(id: String, data: Dictionary) -> void:
	quest_id = id
	title = str(data.get("title", id))
	description = str(data.get("description", ""))
	recommended_level = int(data.get("recommended_level", 0))
	unlock_level = int(data.get("unlock_level", recommended_level))
	objective_type = str(data.get("objective_type", KILL))
	target_id = str(data.get("target_id", ""))
	target_name = str(data.get("target_name", target_id))
	required_count = int(data.get("required_count", 1))
	reward_exp = int(data.get("reward_exp", 0))
	reward_gold = int(data.get("reward_gold", 0))
	guild_reputation = int(data.get("guild_reputation", 0))
	prerequisite_quest_id = str(data.get("prerequisite_quest_id", ""))
	story_arc = str(data.get("story_arc", ""))
	chapter = str(data.get("chapter", ""))
	completion_text = str(data.get("completion_text", ""))
	consume_objective_items = bool(data.get("consume_objective_items", true))
	dependency_note = str(data.get("dependency_note", ""))


func objective_text(current: int) -> String:
	var action := "Pokonaj"
	if objective_type == COLLECT:
		action = "Zdobądź" if consume_objective_items else "Posiadaj"
	return "%s: %s  •  %d/%d" % [action, target_name, mini(current, required_count), required_count]
