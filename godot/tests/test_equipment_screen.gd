extends GutTest

const EquipmentScreenClass := preload("res://ui/screens/equipment/equipment.gd")
const EQUIPMENT_SCENE := preload("res://ui/screens/equipment/equipment.tscn")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")


func test_lists_all_legacy_slots_and_empty_starting_backpack() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var screen := EQUIPMENT_SCENE.instantiate() as EquipmentScreenClass
	screen.configure(session)
	add_child_autofree(screen)

	assert_eq(screen.equipped_list.item_count, 11)
	assert_string_contains(screen.equipped_list.get_item_text(0), "Stary Miecz +0")
	assert_eq(screen.inventory_list.item_count, 1)
	assert_eq(screen.inventory_list.get_item_text(0), "Plecak jest pusty.")


func test_unequip_and_equip_buttons_change_live_character_state() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var screen := EQUIPMENT_SCENE.instantiate() as EquipmentScreenClass
	screen.configure(session)
	add_child_autofree(screen)

	screen.equipped_list.select(0)
	screen.equipped_list.item_selected.emit(0)
	assert_false(screen.unequip_button.disabled)
	screen.unequip_button.pressed.emit()

	assert_eq(session.player.stats.attack, 0)
	assert_eq(session.player.inventory.equipment_items.size(), 1)
	assert_string_contains(screen.hero_stats_label.text, "ATK 0")

	screen.inventory_list.select(0)
	screen.inventory_list.item_selected.emit(0)
	assert_false(screen.equip_button.disabled)
	screen.equip_button.pressed.emit()

	assert_eq(session.player.stats.attack, 3)
	assert_true(session.player.inventory.is_empty())
	assert_string_contains(screen.hero_stats_label.text, "ATK 3")
