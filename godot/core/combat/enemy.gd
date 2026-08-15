class_name CombatEnemy
extends RefCounted

const ElementalResistancesClass := preload("res://core/combat/elemental_resistances.gd")

var enemy_id := ""
var display_name := ""
var max_hp := 0
var current_hp := 0
var attack := 0
var defense := 0
var dodge := 0.0
var experience_reward := 0
var gold_min := 0
var gold_max := 0
var rank := "normal"
var special_name := ""
var special_chance := 0.0
var special_attack_bonus := 0
var extra_attack_chance := 0.0
var first_attack_bonus := 0
var physical_damage_reduction := 0
var basic_damage_type := "physical"
var special_damage_type := ""
var status_resistance := 0.0
var elemental_resistances := ElementalResistancesClass.new()
var attacks_made := 0


func _init(data: Dictionary) -> void:
	enemy_id = data.get("enemy_id", "")
	display_name = data.get("display_name", enemy_id)
	max_hp = data.get("max_hp", 1)
	current_hp = max_hp
	attack = data.get("attack", 0)
	defense = data.get("defense", 0)
	dodge = data.get("dodge", 0.0)
	experience_reward = data.get("experience_reward", 0)
	gold_min = data.get("gold_min", 0)
	gold_max = data.get("gold_max", gold_min)
	rank = data.get("rank", "normal")
	special_name = data.get("special_name", "")
	special_chance = data.get("special_chance", 0.0)
	special_attack_bonus = data.get("special_attack_bonus", 0)
	extra_attack_chance = data.get("extra_attack_chance", 0.0)
	first_attack_bonus = data.get("first_attack_bonus", 0)
	physical_damage_reduction = data.get("physical_damage_reduction", 0)
	basic_damage_type = str(data.get("basic_damage_type", "physical"))
	special_damage_type = str(data.get("special_damage_type", ""))
	status_resistance = clampf(float(data.get("status_resistance", 0.0)), 0.0, 1.0)
	elemental_resistances = ElementalResistancesClass.new(data.get("elemental_resistances", {}))


func is_alive() -> bool:
	return current_hp > 0


func take_damage(amount: int) -> int:
	var damage_taken := mini(maxi(0, amount), current_hp)
	current_hp -= damage_taken
	return damage_taken


func heal(amount: int) -> int:
	var healed := mini(maxi(0, amount), max_hp - current_hp)
	current_hp += healed
	return healed


func reduce_physical_damage(amount: int) -> int:
	if amount <= 0:
		return 0
	return maxi(1, amount - physical_damage_reduction)
