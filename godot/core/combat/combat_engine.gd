class_name TurnBasedCombatEngine
extends RefCounted

const EnemyClass := preload("res://core/combat/enemy.gd")
const PlayerProfileClass := preload("res://core/player/player_profile.gd")
const ONGOING := "ongoing"
const VICTORY := "victory"
const DEFEAT := "defeat"
const FLED := "fled"

var player: PlayerProfileClass
var enemy: EnemyClass
var result := ONGOING
var rng: RandomNumberGenerator


func _init(
	player_profile: PlayerProfileClass,
	combat_enemy: EnemyClass,
	random_number_generator: RandomNumberGenerator = null
) -> void:
	player = player_profile
	enemy = combat_enemy
	rng = (
		random_number_generator if random_number_generator != null else RandomNumberGenerator.new()
	)


func player_attack() -> Dictionary:
	if result != ONGOING:
		return {}
	var report := _new_report()
	if rng.randf() < enemy.dodge / 100.0:
		report.enemy_dodged = true
	else:
		var damage := maxi(1, player.stats.attack - enemy.defense)
		damage = enemy.reduce_physical_damage(damage)
		report.player_damage = enemy.take_damage(damage)
	if not enemy.is_alive():
		result = VICTORY
		return report
	_enemy_turn(report)
	return report


func player_defend() -> Dictionary:
	if result != ONGOING:
		return {}
	var report := _new_report()
	report.player_defended = true
	_enemy_turn(report, true)
	return report


func player_flee() -> Dictionary:
	if result != ONGOING:
		return {}
	var report := _new_report()
	if rng.randf() < 0.5:
		result = FLED
		return report
	report.flee_failed = true
	_enemy_turn(report)
	return report


func player_use_healing(heal_amount: int) -> Dictionary:
	if result != ONGOING or heal_amount <= 0:
		return {}
	var report := _new_report()
	report.player_healed = player.stats.heal(heal_amount)
	_enemy_turn(report)
	return report


func _enemy_turn(report: Dictionary, defending := false) -> void:
	report.enemy_acted = true
	var attack_value := enemy.attack
	if enemy.attacks_made == 0:
		attack_value += enemy.first_attack_bonus
	if not enemy.special_name.is_empty() and rng.randf() < enemy.special_chance:
		attack_value += enemy.special_attack_bonus
		report.enemy_special_name = enemy.special_name
	enemy.attacks_made += 1
	report.enemy_damage = _resolve_enemy_hit(attack_value, defending)
	if not player.stats.is_alive():
		result = DEFEAT
		return
	if enemy.extra_attack_chance > 0.0 and rng.randf() < enemy.extra_attack_chance:
		report.enemy_extra_damage = _resolve_enemy_hit(enemy.attack, false)
		if not player.stats.is_alive():
			result = DEFEAT


func _resolve_enemy_hit(attack_value: int, defending: bool) -> int:
	if rng.randf() < player.stats.dodge / 100.0:
		return 0
	var damage := maxi(1, attack_value - player.stats.defense)
	if defending:
		damage = int(damage / 2.0)
	return player.stats.take_damage(damage)


func _new_report() -> Dictionary:
	return {
		"player_damage": 0,
		"player_healed": 0,
		"enemy_damage": 0,
		"enemy_extra_damage": 0,
		"enemy_dodged": false,
		"player_defended": false,
		"flee_failed": false,
		"enemy_special_name": "",
		"enemy_acted": false,
	}
