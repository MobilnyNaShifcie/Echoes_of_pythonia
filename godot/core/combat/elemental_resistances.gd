class_name ElementalResistances
extends RefCounted

const MAX_RESISTANCE := 75
const ELEMENT_ORDER := ["fire", "wind", "frost", "earth", "water"]
const DISPLAY_NAMES := {
	"physical": "Fizyczne",
	"fire": "Ogień",
	"wind": "Wiatr",
	"frost": "Mróz",
	"earth": "Ziemia",
	"water": "Woda",
}

var fire := 0
var wind := 0
var frost := 0
var earth := 0
var water := 0


func _init(values: Dictionary = {}) -> void:
	for damage_type: String in ELEMENT_ORDER:
		set_value(damage_type, int(values.get(damage_type, 0)))


func get_value(damage_type: String) -> int:
	match damage_type:
		"fire":
			return fire
		"wind":
			return wind
		"frost":
			return frost
		"earth":
			return earth
		"water":
			return water
	return 0


func set_value(damage_type: String, value: int) -> bool:
	var clamped := clampi(value, 0, MAX_RESISTANCE)
	match damage_type:
		"fire":
			fire = clamped
		"wind":
			wind = clamped
		"frost":
			frost = clamped
		"earth":
			earth = clamped
		"water":
			water = clamped
		_:
			return false
	return true


func reduce_damage(damage: int, damage_type: String) -> int:
	if damage <= 0:
		return 0
	if damage_type == "physical":
		return damage
	var reduced := int(damage * (1.0 - get_value(damage_type) / 100.0))
	return maxi(1, reduced)


func as_dictionary() -> Dictionary:
	return {
		"fire": fire,
		"wind": wind,
		"frost": frost,
		"earth": earth,
		"water": water,
	}


static func display_name(damage_type: String) -> String:
	return str(DISPLAY_NAMES.get(damage_type, damage_type))
