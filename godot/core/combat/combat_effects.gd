class_name CombatEffects
extends RefCounted

var enemy_defense_reduction := 0
var enemy_defense_reduction_actions := 0
var enemy_bleed_damage := 0
var enemy_bleed_turns := 0
var player_guard_percent := 0
var player_guard_hits := 0
var player_dodge_bonus := 0.0
var player_dodge_bonus_hits := 0


func apply_armor_break(value: int, duration: int) -> void:
	enemy_defense_reduction = maxi(enemy_defense_reduction, maxi(0, value))
	enemy_defense_reduction_actions = maxi(enemy_defense_reduction_actions, maxi(0, duration))


func effective_enemy_defense(base_defense: int) -> int:
	return maxi(0, base_defense - enemy_defense_reduction)


func consume_offensive_action() -> void:
	if enemy_defense_reduction_actions <= 0:
		return
	enemy_defense_reduction_actions -= 1
	if enemy_defense_reduction_actions == 0:
		enemy_defense_reduction = 0


func apply_bleed(value: int, duration: int) -> void:
	enemy_bleed_damage = maxi(enemy_bleed_damage, maxi(0, value))
	enemy_bleed_turns = maxi(enemy_bleed_turns, maxi(0, duration))


func tick_bleed() -> int:
	if enemy_bleed_turns <= 0:
		return 0
	var damage := enemy_bleed_damage
	enemy_bleed_turns -= 1
	if enemy_bleed_turns == 0:
		enemy_bleed_damage = 0
	return damage


func apply_guard(value: int, duration: int) -> void:
	player_guard_percent = maxi(player_guard_percent, clampi(value, 0, 90))
	player_guard_hits = maxi(player_guard_hits, maxi(0, duration))


func reduce_damage_by_guard(damage: int) -> int:
	if player_guard_hits <= 0:
		return damage
	return maxi(0, int(damage * (100.0 - player_guard_percent) / 100.0))


func consume_guard_hit() -> void:
	if player_guard_hits <= 0:
		return
	player_guard_hits -= 1
	if player_guard_hits == 0:
		player_guard_percent = 0


func apply_dodge(value: int, duration: int) -> void:
	player_dodge_bonus = maxf(player_dodge_bonus, maxf(0.0, float(value)))
	player_dodge_bonus_hits = maxi(player_dodge_bonus_hits, maxi(0, duration))


func current_dodge_bonus() -> float:
	return player_dodge_bonus if player_dodge_bonus_hits > 0 else 0.0


func consume_dodge_hit() -> void:
	if player_dodge_bonus_hits <= 0:
		return
	player_dodge_bonus_hits -= 1
	if player_dodge_bonus_hits == 0:
		player_dodge_bonus = 0.0
