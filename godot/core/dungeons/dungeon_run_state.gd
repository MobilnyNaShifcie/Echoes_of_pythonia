class_name DungeonRunState
extends RefCounted

var dungeon_id := ""
var step := "entrance"
var pending_next_step := ""
var pending_enemy_id := ""
var pending_battle_title := ""
var snapshot_stacks := {}
var snapshot_equipment_ids: Array[String] = []
var last_message := ""
var last_loot: Array[Dictionary] = []
var outcome := ""
var completed := false
var branch_ambush_pending := false


func _init(id := "") -> void:
	dungeon_id = id


func is_finished() -> bool:
	return outcome in ["completed", "retreated", "defeated"]
