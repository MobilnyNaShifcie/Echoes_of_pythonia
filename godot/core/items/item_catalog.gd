class_name ItemCatalog
extends RefCounted

const EquipmentItemClass := preload("res://core/items/equipment_item.gd")
const ItemDefinitionClass := preload("res://core/items/item_definition.gd")
const DEFINITIONS := {
	"starter_sword": preload("res://data/items/starter_sword.tres"),
	"worn_leather_armor": preload("res://data/items/worn_leather_armor.tres"),
	"weak_leather": preload("res://data/items/weak_leather.tres"),
	"slime_gel": preload("res://data/items/slime_gel.tres"),
	"weak_healing_potion": preload("res://data/items/weak_healing_potion.tres"),
	"wolf_fur": preload("res://data/items/wolf_fur.tres"),
	"wolf_fang": preload("res://data/items/wolf_fang.tres"),
	"wolf_tooth_necklace": preload("res://data/items/wolf_tooth_necklace.tres"),
	"raw_boar_meat": preload("res://data/items/raw_boar_meat.tres"),
	"truffle": preload("res://data/items/truffle.tres"),
	"whetstone": preload("res://data/items/whetstone.tres"),
	"grinding_stone": preload("res://data/items/grinding_stone.tres"),
	"leather_hood": preload("res://data/items/leather_hood.tres"),
	"stitched_armor": preload("res://data/items/stitched_armor.tres"),
	"sharpened_sword": preload("res://data/items/sharpened_sword.tres"),
	"hunter_provisions": preload("res://data/items/hunter_provisions.tres"),
	"strong_healing_potion": preload("res://data/items/strong_healing_potion.tres"),
	"grandmaster_elixir": preload("res://data/items/grandmaster_elixir.tres"),
	"old_clothes": preload("res://data/items/old_clothes.tres"),
	"spark_of_life": preload("res://data/items/spark_of_life.tres"),
	"common_essence": preload("res://data/items/common_essence.tres"),
	"hard_wood": preload("res://data/items/hard_wood.tres"),
	"worn_strap": preload("res://data/items/worn_strap.tres"),
	"metal_buckle": preload("res://data/items/metal_buckle.tres"),
	"hunter_gloves": preload("res://data/items/hunter_gloves.tres"),
	"reinforced_boots": preload("res://data/items/reinforced_boots.tres"),
	"leather_belt": preload("res://data/items/leather_belt.tres"),
	"nature_amulet": preload("res://data/items/nature_amulet.tres"),
	"nature_bracelet": preload("res://data/items/nature_bracelet.tres"),
	"nature_earrings": preload("res://data/items/nature_earrings.tres"),
	"nature_ring": preload("res://data/items/nature_ring.tres"),
	"training_shield": preload("res://data/items/training_shield.tres"),
	"hunting_bow": preload("res://data/items/hunting_bow.tres"),
	"simple_quiver": preload("res://data/items/simple_quiver.tres"),
	"apprentice_staff": preload("res://data/items/apprentice_staff.tres"),
	"mana_crystal_artifact": preload("res://data/items/mana_crystal_artifact.tres"),
	"caprice_lance": preload("res://data/items/caprice_lance.tres"),
	"worn_fate_dice": preload("res://data/items/worn_fate_dice.tres"),
}


static func get_definition(item_id: String) -> ItemDefinitionClass:
	return DEFINITIONS.get(item_id)


static func get_all_definitions() -> Array:
	return DEFINITIONS.values()


static func create_equipment_item(item_id: String) -> EquipmentItemClass:
	var definition := get_definition(item_id)
	if definition == null or not definition.is_equipment():
		return null
	return EquipmentItemClass.new(definition)
