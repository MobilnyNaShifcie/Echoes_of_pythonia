class_name FateEngine
extends RefCounted

const FateRollClass := preload("res://core/combat/fate_roll.gd")

var rng: RandomNumberGenerator
var history: Array[FateRollClass] = []
var loaded_die_used := false
var second_chance_used := false
var _die_roller: Callable


func _init(
	random_number_generator: RandomNumberGenerator,
	die_roller: Callable = Callable(),
) -> void:
	rng = random_number_generator
	_die_roller = die_roller


func roll(count: int) -> FateRollClass:
	return roll_with_options(count).roll


func roll_with_options(
	count: int,
	loaded_die := false,
	second_chance := false,
	cheat_to_seven := false,
	fate_tokens := 0,
) -> Dictionary:
	if count <= 0:
		push_error("Liczba Kości Losu musi być dodatnia.")
		return {"roll": null, "spent_tokens": 0}
	var original: Array[int] = []
	for _die_index in count:
		original.append(_roll_die())
	var dice: Array[int] = []
	dice.assign(original)
	var notes: Array[String] = []
	if loaded_die and not loaded_die_used and 1 in dice:
		var index := dice.find(1)
		var before := dice[index]
		dice[index] = _roll_die()
		loaded_die_used = true
		notes.append("Dociążona Kość: %d → %d." % [before, dice[index]])
	if second_chance and count == 3 and _sum(dice) <= 5 and not second_chance_used:
		var before_text := _dice_text(dice)
		dice.clear()
		for _die_index in count:
			dice.append(_roll_die())
		second_chance_used = true
		notes.append("Druga Szansa: katastrofalny rzut %s został przerzucony." % before_text)
	var spent_tokens := 0
	if cheat_to_seven and count == 2 and _sum(dice) in [6, 8] and fate_tokens > 0:
		var delta := 1 if _sum(dice) == 6 else -1
		for index in dice.size():
			if dice[index] + delta in range(1, 7):
				var before := dice[index]
				dice[index] += delta
				spent_tokens = 1
				notes.append("Kant: %d → %d; suma zostaje ustawiona na 7." % [before, dice[index]])
				break
	var result := FateRollClass.new(dice, original, notes)
	history.append(result)
	return {"roll": result, "spent_tokens": spent_tokens}


func _roll_die() -> int:
	if _die_roller.is_valid():
		return clampi(int(_die_roller.call()), 1, 6)
	return rng.randi_range(1, 6)


func _sum(dice: Array[int]) -> int:
	var result := 0
	for value: int in dice:
		result += value
	return result


func _dice_text(dice: Array[int]) -> String:
	var values: Array[String] = []
	for value: int in dice:
		values.append(str(value))
	return "+".join(values)
