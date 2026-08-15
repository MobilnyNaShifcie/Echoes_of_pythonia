class_name FateEngine
extends RefCounted

const FateRollClass := preload("res://core/combat/fate_roll.gd")

var rng: RandomNumberGenerator
var history: Array[FateRollClass] = []
var _die_roller: Callable


func _init(
	random_number_generator: RandomNumberGenerator,
	die_roller: Callable = Callable(),
) -> void:
	rng = random_number_generator
	_die_roller = die_roller


func roll(count: int) -> FateRollClass:
	if count <= 0:
		push_error("Liczba Kości Losu musi być dodatnia.")
		return null
	var dice: Array[int] = []
	for _die_index in count:
		dice.append(_roll_die())
	var result := FateRollClass.new(dice)
	history.append(result)
	return result


func _roll_die() -> int:
	if _die_roller.is_valid():
		return clampi(int(_die_roller.call()), 1, 6)
	return rng.randi_range(1, 6)
