class_name DungeonDefinition
extends RefCounted

var dungeon_id := ""
var display_name := ""
var description := ""
var region_id := ""
var recommended_level_min := 0
var recommended_level_max := 0
var room_one_enemies: Array[String] = []
var room_two_enemies: Array[String] = []
var room_three_enemies: Array[String] = []
var iron_path_enemy := ""
var flooded_ambush_enemy := ""
var flooded_ambush_chance := 0.0
var mandatory_elite_enemy := ""
var boss_enemy := ""
var chest_loot: Array[Dictionary] = []
var entry_item_id := ""
var entry_item_quantity := 1
var entry_source_text := ""
var scenes := {}


func _init(data: Dictionary) -> void:
	dungeon_id = str(data.get("dungeon_id", ""))
	display_name = str(data.get("display_name", dungeon_id))
	description = str(data.get("description", ""))
	region_id = str(data.get("region_id", ""))
	recommended_level_min = int(data.get("recommended_level_min", 0))
	recommended_level_max = int(data.get("recommended_level_max", recommended_level_min))
	room_one_enemies.assign(data.get("room_one_enemies", []))
	room_two_enemies.assign(data.get("room_two_enemies", []))
	room_three_enemies.assign(data.get("room_three_enemies", []))
	iron_path_enemy = str(data.get("iron_path_enemy", ""))
	flooded_ambush_enemy = str(data.get("flooded_ambush_enemy", ""))
	flooded_ambush_chance = float(data.get("flooded_ambush_chance", 0.0))
	mandatory_elite_enemy = str(data.get("mandatory_elite_enemy", ""))
	boss_enemy = str(data.get("boss_enemy", ""))
	for entry: Dictionary in data.get("chest_loot", []):
		chest_loot.append(entry.duplicate(true))
	entry_item_id = str(data.get("entry_item_id", ""))
	entry_item_quantity = maxi(1, int(data.get("entry_item_quantity", 1)))
	entry_source_text = str(data.get("entry_source_text", ""))
	scenes = data.get("scenes", {}).duplicate(true)


func recommended_level_text() -> String:
	return "%d–%d" % [recommended_level_min, recommended_level_max]
