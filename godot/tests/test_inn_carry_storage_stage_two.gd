extends GutTest

const AdventureServiceClass := preload("res://core/world/adventure_service.gd")
const CarryWeightServiceClass := preload("res://core/economy/carry_weight_service.gd")
const GuildStorageServiceClass := preload("res://core/economy/guild_storage_service.gd")
const InnServiceClass := preload("res://core/economy/inn_service.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")


func test_inn_cost_restoration_time_and_daily_cooldown_match_terminal() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.day = 1
	session.hour = 20
	session.player.gold = 100
	session.player.stats.current_hp = 5

	var result := InnServiceClass.rest(session)
	assert_true(result.ok)
	assert_eq(result.gold, 25)
	assert_eq(session.player.gold, 75)
	assert_eq(session.player.stats.current_hp, session.player.stats.max_hp)
	assert_eq(session.day, 2)
	assert_eq(session.hour, 2)
	assert_eq(session.last_inn_rest_day, 2)

	session.player.stats.current_hp = 5
	var repeated := InnServiceClass.rest(session)
	assert_false(repeated.ok)
	assert_eq(session.player.gold, 75)


func test_weight_capacity_and_overload_thresholds_match_terminal() -> void:
	var player = NewGameServiceClass.new().create_session("Aria", 1).player
	assert_eq(CarryWeightServiceClass.inventory_weight(player.inventory), 0.0)
	assert_eq(CarryWeightServiceClass.carry_capacity(player), 50.0)
	player.attributes.strength = 10
	player.attributes.endurance = 10
	assert_eq(CarryWeightServiceClass.carry_capacity(player), 70.0)

	player.attributes.strength = 0
	player.attributes.endurance = 0
	player.inventory.add("weak_leather", 800)
	assert_eq(CarryWeightServiceClass.inventory_weight(player.inventory), 40.0)
	assert_eq(CarryWeightServiceClass.carry_status(player).display_name, "Obciążony")
	player.inventory.add("weak_leather", 300)
	assert_true(CarryWeightServiceClass.carry_status(player).overloaded)


func test_overload_blocks_expedition_without_advancing_time_or_losing_items() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.inventory.add("weak_leather", 2000)
	var before: int = session.player.inventory.count("weak_leather")
	var rng := RandomNumberGenerator.new()
	var result := AdventureServiceClass.explore_twilight_plains(session, rng)

	assert_true(result.blocked)
	assert_eq(session.day, 1)
	assert_eq(session.hour, 8)
	assert_eq(session.player.inventory.count("weak_leather"), before)


func test_storage_transfers_stacks_and_exact_equipment_instances() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var player = session.player
	var storage = session.guild_storage
	player.inventory.add("weak_leather", 12)
	assert_true(GuildStorageServiceClass.deposit_stack(player, storage, "weak_leather", 7).ok)
	assert_eq(player.inventory.count("weak_leather"), 5)
	assert_eq(storage.inventory.count("weak_leather"), 7)
	assert_true(GuildStorageServiceClass.withdraw_stack(player, storage, "weak_leather", 2).ok)
	assert_eq(player.inventory.count("weak_leather"), 7)

	var item = ItemCatalogClass.create_equipment_item("nature_amulet")
	item.upgrade_level = 7
	player.inventory.add_equipment_instance(item)
	assert_true(GuildStorageServiceClass.deposit_equipment(player, storage, 0).ok)
	assert_eq(storage.inventory.equipment_items[0].instance_id, item.instance_id)
	assert_true(GuildStorageServiceClass.withdraw_equipment(player, storage, 0).ok)
	assert_eq(player.inventory.equipment_items[0].instance_id, item.instance_id)
	assert_eq(player.inventory.equipment_items[0].upgrade_level, 7)


func test_carry_upgrades_require_terminal_gold_and_guild_ranks() -> void:
	var player = NewGameServiceClass.new().create_session("Aria", 1).player
	player.gold = 8000
	var locked := CarryWeightServiceClass.purchase_upgrade(player, 99)
	assert_false(locked.ok)
	assert_eq(player.gold, 8000)

	var bought := CarryWeightServiceClass.purchase_upgrade(player, 100)
	assert_true(bought.ok)
	assert_eq(player.gold, 0)
	assert_eq(player.carry_upgrade_level, 1)
	assert_eq(CarryWeightServiceClass.carry_capacity(player), 60.0)
