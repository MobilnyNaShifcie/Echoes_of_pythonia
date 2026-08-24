extends GutTest

const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const UpgradeServiceClass := preload("res://core/economy/upgrade_service.gd")


func test_first_three_upgrades_use_only_shop_whetstones() -> void:
	var item = ItemCatalogClass.create_equipment_item("starter_sword")
	assert_eq(UpgradeServiceClass.get_upgrade_cost(0, item).materials, {"whetstone": 1})
	assert_eq(UpgradeServiceClass.get_upgrade_cost(1, item).materials, {"whetstone": 1})
	assert_eq(UpgradeServiceClass.get_upgrade_cost(2, item).materials, {"whetstone": 2})


func test_five_level_plan_matches_the_terminal_total() -> void:
	var item = ItemCatalogClass.create_equipment_item("starter_sword")
	var plan := UpgradeServiceClass.get_upgrade_plan(item, 5)

	assert_true(plan.ok)
	assert_eq(plan.gold, 400)
	assert_eq(plan.materials, {"whetstone": 4, "grinding_stone": 2, "common_essence": 3})


func test_upgrade_is_atomic_and_recalculates_equipped_stats() -> void:
	var player = NewGameServiceClass.new().create_session("Aria", 1).player
	var weapon = player.equipment.get_item("weapon")
	player.gold = 500
	player.inventory.add("whetstone", 2)

	assert_true(UpgradeServiceClass.upgrade_item(player, weapon).ok)
	assert_eq(player.stats.attack, 3)
	assert_true(UpgradeServiceClass.upgrade_item(player, weapon).ok)
	assert_eq(weapon.upgrade_level, 2)
	assert_eq(player.stats.attack, 4)
	assert_eq(player.gold, 425)

	var failed := UpgradeServiceClass.upgrade_item(player, weapon)
	assert_false(failed.ok)
	assert_eq(weapon.upgrade_level, 2)
	assert_eq(player.gold, 425)


func test_full_ip_one_upgrade_keeps_the_legacy_minimum_power() -> void:
	var item = ItemCatalogClass.create_equipment_item("starter_sword")
	item.upgrade_level = 10
	assert_eq(UpgradeServiceClass.effective_stats(item).attack, 8)
