class_name PlayerAttributes
extends RefCounted

const STRENGTH := "strength"
const VITALITY := "vitality"
const INTELLIGENCE := "intelligence"
const DEXTERITY := "dexterity"
const ENDURANCE := "endurance"
const LUCK := "luck"

const STRENGTH_ATTACK_PER_POINT := 1
const VITALITY_HP_PER_POINT := 5
const INTELLIGENCE_MANA_PER_POINT := 5
const DEXTERITY_DODGE_PER_POINT := 1.5
const ENDURANCE_POINTS_PER_DEFENSE := 2

var strength := 0
var vitality := 0
var intelligence := 0
var dexterity := 0
var endurance := 0
var luck := 0


func get_value(attribute_code: String) -> int:
	var value := -1
	match attribute_code:
		STRENGTH:
			value = strength
		VITALITY:
			value = vitality
		INTELLIGENCE:
			value = intelligence
		DEXTERITY:
			value = dexterity
		ENDURANCE:
			value = endurance
		LUCK:
			value = luck
	return value


func increase(attribute_code: String, amount := 1) -> bool:
	if amount <= 0 or get_value(attribute_code) < 0:
		return false
	match attribute_code:
		STRENGTH:
			strength += amount
		VITALITY:
			vitality += amount
		INTELLIGENCE:
			intelligence += amount
		DEXTERITY:
			dexterity += amount
		ENDURANCE:
			endurance += amount
		LUCK:
			luck += amount
	return true


func calculate_bonuses() -> Dictionary:
	return {
		"attack": strength * STRENGTH_ATTACK_PER_POINT,
		"max_hp": vitality * VITALITY_HP_PER_POINT,
		"max_mana": intelligence * INTELLIGENCE_MANA_PER_POINT,
		"dodge": dexterity * DEXTERITY_DODGE_PER_POINT,
		"defense": int(endurance / ENDURANCE_POINTS_PER_DEFENSE),
	}


func as_display_dict() -> Dictionary:
	return {
		"Siła": strength,
		"Witalność": vitality,
		"Inteligencja": intelligence,
		"Zręczność": dexterity,
		"Wytrzymałość": endurance,
		"Szczęście": luck,
	}
