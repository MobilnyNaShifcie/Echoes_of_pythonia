class_name RiftModifier
extends RefCounted

var modifier_id := ""
var display_name := ""
var description := ""
var enemy_hp_multiplier := 1.0
var enemy_attack_multiplier := 1.0
var enemy_defense_bonus := 0
var player_mana_cost_multiplier := 1.0


func _init(
	initial_id := "",
	initial_name := "",
	initial_description := "",
	initial_enemy_hp_multiplier := 1.0,
	initial_enemy_attack_multiplier := 1.0,
	initial_enemy_defense_bonus := 0,
	initial_player_mana_cost_multiplier := 1.0
) -> void:
	modifier_id = initial_id
	display_name = initial_name
	description = initial_description
	enemy_hp_multiplier = initial_enemy_hp_multiplier
	enemy_attack_multiplier = initial_enemy_attack_multiplier
	enemy_defense_bonus = initial_enemy_defense_bonus
	player_mana_cost_multiplier = initial_player_mana_cost_multiplier
