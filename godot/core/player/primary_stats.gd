class_name PrimaryStats
extends RefCounted

const STARTING_HP := 20

var max_hp := STARTING_HP
var current_hp := STARTING_HP
var attack := 0
var defense := 0
var dodge := 0.0
var max_mana := 0
var magic_power := 0
var current_mana := 0
var health_regen := 0
var crit_chance := 0.0
var crit_damage := 0.0
var skill_damage := 0.0
var armor_penetration := 0.0
var damage_vs_elite := 0.0
var damage_vs_boss := 0.0
var average_damage := 0.0


func is_alive() -> bool:
	return current_hp > 0


func needs_restoration() -> bool:
	return current_hp < max_hp or current_mana < max_mana


func take_damage(amount: int) -> int:
	if amount < 0:
		return 0
	var damage_taken := mini(amount, current_hp)
	current_hp -= damage_taken
	return damage_taken


func heal(amount: int) -> int:
	if amount < 0:
		return 0
	var healed := mini(amount, max_hp - current_hp)
	current_hp += healed
	return healed


func can_spend_mana(amount: int) -> bool:
	return amount >= 0 and amount <= current_mana


func spend_mana(amount: int) -> bool:
	if not can_spend_mana(amount):
		return false
	current_mana -= amount
	return true


func restore_mana(amount: int) -> int:
	if amount < 0:
		return 0
	var restored := mini(amount, max_mana - current_mana)
	current_mana += restored
	return restored


func restore_full() -> void:
	current_hp = max_hp
	current_mana = max_mana


func apply_derived_stats(
	derived_attack: int,
	derived_defense: int,
	bonus_hp: int,
	derived_dodge: float,
	derived_max_mana: int,
	derived_magic_power := 0
) -> bool:
	var numeric_values := [
		derived_attack,
		derived_defense,
		bonus_hp,
		derived_dodge,
		derived_max_mana,
		derived_magic_power,
	]
	if numeric_values.any(func(value: float) -> bool: return value < 0):
		return false

	attack = derived_attack
	defense = derived_defense
	max_hp = STARTING_HP + bonus_hp
	dodge = derived_dodge
	max_mana = derived_max_mana
	magic_power = derived_magic_power
	current_hp = mini(current_hp, max_hp)
	current_mana = mini(current_mana, max_mana)
	return true
