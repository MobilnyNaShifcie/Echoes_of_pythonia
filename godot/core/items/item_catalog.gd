class_name ItemCatalog
extends RefCounted

const EquipmentItemClass := preload("res://core/items/equipment_item.gd")
const ItemDefinitionClass := preload("res://core/items/item_definition.gd")
const STARTER_SWORD := preload("res://data/items/starter_sword.tres")
const WORN_LEATHER_ARMOR := preload("res://data/items/worn_leather_armor.tres")


static func get_definition(item_id: String) -> ItemDefinitionClass:
	match item_id:
		"starter_sword":
			return STARTER_SWORD
		"worn_leather_armor":
			return WORN_LEATHER_ARMOR
		_:
			return null


static func create_equipment_item(item_id: String) -> EquipmentItemClass:
	var definition := get_definition(item_id)
	if definition == null or not definition.is_equipment():
		return null
	return EquipmentItemClass.new(definition)
