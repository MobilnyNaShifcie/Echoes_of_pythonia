class_name PartyCombatRoundResult
extends RefCounted

var lines: Array[String] = []
var victory := false
var defeat := false
var turn_consumed := false
var error := ""
var round_number := 1
var enemy_hp_before := 0
var enemy_hp_after := 0
var player_skill_id := ""
var companion_action_order: Array[String] = []
var companion_skill_ids := {}
var enemy_target_ids: Array[String] = []
var enemy_damage_by_fighter := {}
var enemy_bleed_damage := 0
var enemy_frenzy := false


func add_enemy_damage(fighter_id: String, damage: int) -> void:
	enemy_target_ids.append(fighter_id)
	enemy_damage_by_fighter[fighter_id] = (int(enemy_damage_by_fighter.get(fighter_id, 0)) + damage)
