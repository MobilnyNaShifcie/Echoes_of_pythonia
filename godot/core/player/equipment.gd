class_name PlayerEquipment
extends RefCounted

const EquipmentItemClass := preload("res://core/items/equipment_item.gd")
const ElementalResistancesClass := preload("res://core/combat/elemental_resistances.gd")
const UpgradeServiceClass := preload("res://core/economy/upgrade_service.gd")

const WEAPON := "weapon"
const HEAD := "head"
const CHEST := "chest"
const HANDS := "hands"
const FEET := "feet"
const BELT := "belt"
const NECKLACE := "necklace"
const BRACELET := "bracelet"
const EARRINGS := "earrings"
const RING := "ring"
const OFF_HAND := "off_hand"

var slots := {}


func equip_and_return_previous(item: EquipmentItemClass) -> EquipmentItemClass:
	if item == null or item.definition == null or not item.definition.is_equipment():
		return null
	var previous: EquipmentItemClass = slots.get(item.slot)
	slots[item.slot] = item
	return previous


func unequip(slot: String) -> EquipmentItemClass:
	var item: EquipmentItemClass = slots.get(slot)
	slots.erase(slot)
	return item


func get_item(slot: String) -> EquipmentItemClass:
	return slots.get(slot)


func total_bonuses() -> Dictionary:
	var bonuses := {
		"attack": 0,
		"defense": 0,
		"max_hp": 0,
		"dodge": 0.0,
		"max_mana": 0,
		"magic_power": 0,
		"elemental_resistances": ElementalResistancesClass.new(),
	}
	for item: EquipmentItemClass in slots.values():
		var stats := UpgradeServiceClass.effective_stats(item)
		bonuses.attack += stats.attack
		bonuses.defense += stats.defense
		bonuses.max_hp += stats.max_hp
		bonuses.dodge += stats.dodge
		bonuses.max_mana += stats.max_mana
		bonuses.magic_power += stats.magic_power
		var definition = item.definition
		var item_resistances := {
			"fire": definition.fire_resistance,
			"wind": definition.wind_resistance,
			"frost": definition.frost_resistance,
			"earth": definition.earth_resistance,
			"water": definition.water_resistance,
		}
		for damage_type: String in ElementalResistancesClass.ELEMENT_ORDER:
			var total: int = (
				bonuses.elemental_resistances.get_value(damage_type)
				+ int(item_resistances[damage_type])
			)
			bonuses.elemental_resistances.set_value(damage_type, total)
	bonuses.dodge = snappedf(bonuses.dodge, 0.1)
	return bonuses
