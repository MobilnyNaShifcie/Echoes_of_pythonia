extends GutTest

const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const PlayerEquipmentClass := preload("res://core/player/equipment.gd")
const PlayerFactoryClass := preload("res://core/player/player_factory.gd")
const PlayerInventoryClass := preload("res://core/player/inventory.gd")


func test_equipment_items_are_separate_instances() -> void:
	var inventory := PlayerInventoryClass.new()

	assert_true(inventory.add("starter_sword", 2))
	assert_eq(inventory.equipment_items.size(), 2)
	assert_ne(inventory.equipment_items[0].instance_id, inventory.equipment_items[1].instance_id)


func test_unequip_moves_item_to_inventory_and_recalculates_stats() -> void:
	var player := PlayerFactoryClass.create_player("Tester")

	var removed = player.unequip_to_inventory(PlayerEquipmentClass.WEAPON)

	assert_not_null(removed)
	assert_null(player.equipment.get_item(PlayerEquipmentClass.WEAPON))
	assert_eq(player.inventory.count("starter_sword"), 1)
	assert_eq(player.stats.attack, 0)
	assert_eq(player.stats.defense, 2)


func test_equipping_from_inventory_restores_item_and_stats() -> void:
	var player := PlayerFactoryClass.create_player("Tester")
	player.unequip_to_inventory(PlayerEquipmentClass.WEAPON)

	var equipped = player.equip_from_inventory(0)

	assert_not_null(equipped)
	assert_eq(player.weapon_id, "starter_sword")
	assert_eq(player.inventory.equipment_items.size(), 0)
	assert_eq(player.stats.attack, 3)


func test_swapping_item_returns_previous_instance_to_inventory() -> void:
	var player := PlayerFactoryClass.create_player("Tester")
	var previous_instance_id := player.equipment.get_item(PlayerEquipmentClass.WEAPON).instance_id
	player.inventory.add_equipment_instance(ItemCatalogClass.create_equipment_item("starter_sword"))

	var equipped = player.equip_from_inventory(0)

	assert_not_null(equipped)
	assert_eq(player.inventory.equipment_items.size(), 1)
	assert_eq(player.inventory.equipment_items[0].instance_id, previous_instance_id)
	assert_ne(player.weapon_id, "")
	assert_eq(player.stats.attack, 3)


func test_invalid_inventory_index_does_not_change_equipment() -> void:
	var player := PlayerFactoryClass.create_player("Tester")

	assert_null(player.equip_from_inventory(4))
	assert_eq(player.weapon_id, "starter_sword")
	assert_true(player.inventory.is_empty())
