class_name EquipmentItem
extends RefCounted

const ItemDefinitionClass := preload("res://core/items/item_definition.gd")
const EquipmentAffixClass := preload("res://core/items/equipment_affix.gd")
const MAX_UPGRADE_LEVEL := 10

var definition: ItemDefinitionClass
var upgrade_level := 0
var instance_id := ""
var generated_item_power := 0
var affixes: Array[EquipmentAffixClass] = []

var item_id: String:
	get:
		return definition.item_id if definition != null else ""

var display_name: String:
	get:
		return definition.display_name if definition != null else ""

var slot: String:
	get:
		return definition.slot if definition != null else ""

var item_power: int:
	get:
		return generated_item_power


func _init(
	item_definition: ItemDefinitionClass,
	initial_upgrade_level := 0,
	initial_affixes: Array = [],
	initial_item_power := -1
) -> void:
	definition = item_definition
	upgrade_level = clampi(initial_upgrade_level, 0, MAX_UPGRADE_LEVEL)
	generated_item_power = (
		initial_item_power
		if initial_item_power >= 0
		else (definition.item_power if definition != null else 0)
	)
	for affix in initial_affixes:
		if affix != null:
			affixes.append(affix)
	instance_id = Crypto.new().generate_random_bytes(16).hex_encode()


func formatted_name() -> String:
	return "%s +%d" % [display_name, upgrade_level]
