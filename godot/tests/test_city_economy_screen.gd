extends GutTest

const CITY_ECONOMY_SCENE := preload("res://ui/screens/city_economy/city_economy.tscn")
const CityEconomyScreenClass := preload("res://ui/screens/city_economy/city_economy.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")


func test_merchant_exposes_buy_sell_modes_and_performs_purchase() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.gold = 100
	var screen := CITY_ECONOMY_SCENE.instantiate() as CityEconomyScreenClass
	add_child_autofree(screen)
	screen.configure(session, "merchant")

	assert_eq(screen.mode_selector.item_count, 3)
	assert_eq(screen.item_list.item_count, 6)
	assert_false(screen.action_button.disabled)
	screen.action_button.pressed.emit()
	assert_eq(session.player.gold, 75)
	assert_eq(session.player.inventory.count("weak_healing_potion"), 1)


func test_workshop_crafts_selected_first_region_recipe() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.inventory.add("weak_leather", 2)
	var screen := CITY_ECONOMY_SCENE.instantiate() as CityEconomyScreenClass
	add_child_autofree(screen)
	screen.configure(session, "workshop")

	assert_eq(screen.item_list.item_count, 10)
	screen.action_button.pressed.emit()
	assert_eq(session.player.inventory.count("leather_hood"), 1)
	assert_eq(session.player.inventory.count("weak_leather"), 0)


func test_blacksmith_upgrades_the_selected_equipped_item() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.gold = 100
	session.player.inventory.add("whetstone", 1)
	var screen := CITY_ECONOMY_SCENE.instantiate() as CityEconomyScreenClass
	add_child_autofree(screen)
	screen.configure(session, "blacksmith")
	var selected_item = screen._selected_entry().item

	screen.action_button.pressed.emit()
	assert_eq(selected_item.upgrade_level, 1)
	assert_eq(session.player.gold, 75)


func test_quartermaster_shows_storage_and_carry_operations() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.inventory.add("weak_leather", 3)
	var screen := CITY_ECONOMY_SCENE.instantiate() as CityEconomyScreenClass
	add_child_autofree(screen)
	screen.configure(session, "quartermaster")

	assert_eq(screen.mode_selector.item_count, 5)
	assert_eq(screen.item_list.item_count, 1)
	screen.action_button.pressed.emit()
	assert_eq(session.guild_storage.inventory.count("weak_leather"), 1)
	assert_eq(session.player.inventory.count("weak_leather"), 2)
