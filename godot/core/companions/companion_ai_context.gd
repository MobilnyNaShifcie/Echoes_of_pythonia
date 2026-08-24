class_name CompanionAiContext
extends RefCounted

var current_hp := 1
var max_hp := 1
var current_mana := 0
var max_mana := 0
var standing_party_resources: Array[Vector2i] = []


func _init(
	initial_current_hp := 1, initial_max_hp := 1, initial_current_mana := 0, initial_max_mana := 0
) -> void:
	current_hp = initial_current_hp
	max_hp = maxi(1, initial_max_hp)
	current_mana = maxi(0, initial_current_mana)
	max_mana = maxi(0, initial_max_mana)


func add_standing_member(member_current_hp: int, member_max_hp: int) -> void:
	standing_party_resources.append(Vector2i(member_current_hp, maxi(1, member_max_hp)))


func hp_ratio() -> float:
	return float(current_hp) / float(maxi(1, max_hp))


func mana_ratio() -> float:
	return float(current_mana) / float(max_mana) if max_mana > 0 else 1.0


func has_party_member_in_danger() -> bool:
	for resources: Vector2i in standing_party_resources:
		if resources.x < float(resources.y) * 0.35:
			return true
	return false
