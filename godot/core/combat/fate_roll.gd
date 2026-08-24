class_name FateRoll
extends RefCounted

var dice: Array[int] = []
var original_dice: Array[int] = []
var notes: Array[String] = []


func _init(
	rolled_dice: Array[int],
	original_values: Array[int] = [],
	roll_notes: Array[String] = [],
) -> void:
	dice.assign(rolled_dice)
	original_dice.assign(original_values if not original_values.is_empty() else rolled_dice)
	notes.assign(roll_notes)


func total() -> int:
	var result := 0
	for value: int in dice:
		result += value
	return result


func is_double() -> bool:
	if dice.size() < 2:
		return false
	var distinct := {}
	for value: int in dice:
		distinct[value] = true
	return distinct.size() < dice.size()


func is_triple() -> bool:
	return dice.size() == 3 and dice[0] == dice[1] and dice[1] == dice[2]
