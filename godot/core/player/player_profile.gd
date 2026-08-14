class_name PlayerProfile
extends RefCounted

const PlayerAttributesClass := preload("res://core/player/attributes.gd")
const PlayerEquipmentClass := preload("res://core/player/equipment.gd")
const PrimaryStatsClass := preload("res://core/player/primary_stats.gd")
const STARTING_LEVEL := 0
const ATTRIBUTE_POINTS_PER_LEVEL := 4
const CLASS_NONE := "none"
const CLASS_PIERROT := "pierrot"
const CLASS_DISPLAY_NAMES := {
	"none": "Poszukiwacz",
	"warrior": "Wojownik",
	"hunter": "Łowca",
	"mage": "Mag",
	"pierrot": "Pierrot",
}
const CLASS_BASE_MANA := {
	"none": 0,
	"warrior": 12,
	"hunter": 16,
	"mage": 24,
	"pierrot": 18,
}

var display_name: String
var level := STARTING_LEVEL
var experience := 0
var gold := 0
var rubies := 0
var unspent_attribute_points := 0
var character_class_code := CLASS_NONE
var attributes := PlayerAttributesClass.new()
var stats := PrimaryStatsClass.new()
var equipment := PlayerEquipmentClass.new()

var health: int:
	get:
		return stats.current_hp

var max_health: int:
	get:
		return stats.max_hp

var weapon_id: String:
	get:
		return get_equipped_item_id(PlayerEquipmentClass.WEAPON)

var armor_id: String:
	get:
		return get_equipped_item_id(PlayerEquipmentClass.CHEST)

var character_class_name: String:
	get:
		return CLASS_DISPLAY_NAMES.get(character_class_code, character_class_code)


func _init(player_name: String) -> void:
	display_name = player_name


func experience_to_next_level() -> int:
	var next_level := level + 1
	return int(50 * pow(next_level, 1.5))


func experience_remaining_to_next_level() -> int:
	return experience_to_next_level() - experience


func gain_experience(amount: int) -> int:
	if amount < 0:
		return 0
	experience += amount
	var levels_gained := 0
	while experience >= experience_to_next_level():
		experience -= experience_to_next_level()
		level += 1
		unspent_attribute_points += ATTRIBUTE_POINTS_PER_LEVEL
		levels_gained += 1
	return levels_gained


func get_attribute_spend_error(attribute_code: String, amount := 1) -> String:
	if amount <= 0:
		return "Liczba punktów musi być większa od zera."
	if attributes.get_value(attribute_code) < 0:
		return "Nieznany atrybut bohatera."
	if amount > unspent_attribute_points:
		return "Brak tylu wolnych punktów atrybutów."
	if attribute_code == PlayerAttributesClass.LUCK and character_class_code != CLASS_PIERROT:
		return "Atrybut Szczęście jest dostępny wyłącznie dla Pierrota."
	return ""


func spend_attribute_points(attribute_code: String, amount := 1) -> bool:
	if not get_attribute_spend_error(attribute_code, amount).is_empty():
		return false
	if not attributes.increase(attribute_code, amount):
		return false
	unspent_attribute_points -= amount
	recalculate_stats()
	return true


func recalculate_stats() -> void:
	var equipment_bonuses := equipment.total_bonuses()
	var attribute_bonuses := attributes.calculate_bonuses()
	stats.apply_derived_stats(
		equipment_bonuses.attack + attribute_bonuses.attack,
		equipment_bonuses.defense + attribute_bonuses.defense,
		equipment_bonuses.max_hp + attribute_bonuses.max_hp,
		equipment_bonuses.dodge + attribute_bonuses.dodge,
		(
			equipment_bonuses.max_mana
			+ attribute_bonuses.max_mana
			+ CLASS_BASE_MANA.get(character_class_code, 0)
		),
		equipment_bonuses.magic_power
	)


func get_equipped_item_id(slot: String) -> String:
	var item = equipment.get_item(slot)
	return item.item_id if item != null else ""


func get_equipped_item_name(slot: String) -> String:
	var item = equipment.get_item(slot)
	return item.formatted_name() if item != null else "Brak"
