class_name PlayerFactory
extends RefCounted

const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const PlayerEquipmentClass := preload("res://core/player/equipment.gd")
const PlayerProfileClass := preload("res://core/player/player_profile.gd")
const STARTING_WEAPON_ID := "starter_sword"
const STARTING_ARMOR_ID := "worn_leather_armor"


static func create_player(player_name: String) -> PlayerProfileClass:
	var player := PlayerProfileClass.new(player_name)
	player.equipment.equip_and_return_previous(
		ItemCatalogClass.create_equipment_item(STARTING_WEAPON_ID)
	)
	player.equipment.equip_and_return_previous(
		ItemCatalogClass.create_equipment_item(STARTING_ARMOR_ID)
	)
	player.recalculate_stats()
	player.stats.restore_full()
	return player
