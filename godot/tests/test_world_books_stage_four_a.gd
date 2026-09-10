extends GutTest

const BookCatalogClass := preload("res://core/progression/book_catalog.gd")
const BookServiceClass := preload("res://core/progression/book_service.gd")
const EquipmentScreenClass := preload("res://ui/screens/equipment/equipment.gd")
const EQUIPMENT_SCENE := preload("res://ui/screens/equipment/equipment.tscn")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const RegionCatalogClass := preload("res://core/world/region_catalog.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")
const WorldMapScreenClass := preload("res://ui/screens/world_map/world_map.gd")
const WORLD_MAP_SCENE := preload("res://ui/screens/world_map/world_map.tscn")

var _save_root: String


func before_each() -> void:
	_save_root = "user://test_stage_four_a_%s" % Crypto.new().generate_random_bytes(8).hex_encode()


func after_each() -> void:
	var directory := DirAccess.open(_save_root)
	if directory != null:
		for file_name in directory.get_files():
			DirAccess.remove_absolute(
				ProjectSettings.globalize_path("%s/%s" % [_save_root, file_name])
			)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_save_root))


func test_book_catalog_matches_the_eight_terminal_books() -> void:
	assert_eq(BookCatalogClass.BOOK_ORDER.size(), 8)
	var regeneration = BookCatalogClass.get_definition("mastery_regeneration_book")
	assert_eq(regeneration.passive_code, "health_regen")
	assert_eq(regeneration.buy_price, 36000)
	assert_eq(regeneration.sell_price, 16000)
	var fortuna = BookCatalogClass.get_definition("path_fortuna_book")
	assert_eq(fortuna.path_id, "pierrot_fortuna")
	assert_eq(fortuna.character_class_code, "pierrot")
	assert_eq(fortuna.buy_price, 95000)
	assert_eq(ItemCatalogClass.get_definition("path_fortuna_book").category, "book")


func test_mastery_book_is_consumed_once_and_unlocks_rank_ten_cap() -> void:
	var player = NewGameServiceClass.new().create_session("Aria", 1).player
	player.inventory.add("mastery_regeneration_book", 2)

	var first := BookServiceClass.read(player, "mastery_regeneration_book")
	var second := BookServiceClass.read(player, "mastery_regeneration_book")

	assert_true(first.ok, first.message)
	assert_eq(player.unlocked_passive_mastery_ids, ["health_regen"])
	assert_eq(player.inventory.count("mastery_regeneration_book"), 1)
	assert_false(second.ok)
	assert_string_contains(second.message, "już poznane")


func test_path_book_for_another_class_is_not_consumed() -> void:
	var player = NewGameServiceClass.new().create_session("Aria", 1).player
	player.level = 5
	assert_true(player.choose_class("hunter"))
	player.inventory.add("path_fortuna_book")

	var wrong_class := BookServiceClass.read(player, "path_fortuna_book")

	assert_false(wrong_class.ok)
	assert_eq(player.inventory.count("path_fortuna_book"), 1)
	assert_string_contains(wrong_class.message, "Pierrot")


func test_matching_path_book_unlocks_the_terminal_path() -> void:
	var player = NewGameServiceClass.new().create_session("Aria", 1).player
	player.level = 5
	assert_true(player.choose_class("pierrot"))
	player.inventory.add("path_fortuna_book")

	var result := BookServiceClass.read(player, "path_fortuna_book")

	assert_true(result.ok, result.message)
	assert_has(player.unlocked_class_path_ids, "pierrot_fortuna")
	assert_eq(player.inventory.count("path_fortuna_book"), 0)


func test_equipment_screen_reads_a_selected_book_from_the_backpack() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.inventory.add("mastery_strength_book")
	var screen := EQUIPMENT_SCENE.instantiate() as EquipmentScreenClass
	screen.configure(session)
	add_child_autofree(screen)

	screen.inventory_list.select(0)
	screen.inventory_list.item_selected.emit(0)
	assert_false(screen.read_book_button.disabled)
	assert_string_contains(screen.details_label.text, "NIEPRZECZYTANA")
	screen.read_book_button.pressed.emit()

	assert_has(session.player.unlocked_passive_mastery_ids, "increased_attack")
	assert_true(session.player.inventory.is_empty())
	assert_string_contains(screen.feedback_label.text, "Poznano Mistrzostwo")


func test_region_catalog_preserves_terminal_order_and_recommendations() -> void:
	assert_eq(RegionCatalogClass.REGION_ORDER.size(), 5)
	assert_eq(RegionCatalogClass.REGION_ORDER[0], "twilight_plains")
	assert_eq(RegionCatalogClass.REGION_ORDER[4], "ice_coast")
	var marshes = RegionCatalogClass.get_definition("silentwater_marshes")
	assert_eq(marshes.display_name, "Mokradła Głuchej Wody")
	assert_eq(marshes.danger_rating, 3)
	assert_eq(marshes.recommended_level_min, 5)
	assert_eq(marshes.recommended_level_max, 8)
	assert_eq(marshes.encounter_chance, 1.0)
	assert_eq(marshes.day_encounters.bog_crawler, 25)
	assert_string_contains(marshes.level_guidance(0), "ryzykowna")


func test_new_session_knows_all_regions_and_world_screen_can_inspect_them() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	assert_eq(session.known_region_ids, RegionCatalogClass.REGION_ORDER)
	var screen := WORLD_MAP_SCENE.instantiate() as WorldMapScreenClass
	screen.configure(session)
	add_child_autofree(screen)

	assert_eq(screen.region_list.item_count, 5)
	screen.region_list.select(1)
	screen.region_list.item_selected.emit(1)
	assert_eq(screen.title_label.text, "Czarny Bór")
	assert_string_contains(screen.risk_label.text, "2–4")
	assert_string_contains(screen.threats_label.text, "Jadowity Pająk")
	assert_false(screen.threats_label.is_visible_in_tree())
	assert_false(screen.weather_label.is_visible_in_tree())
	assert_false(screen.explore_button.disabled)
	assert_eq(screen.explore_button.text, "Wyrusz na wyprawę  •  +1 godzina")


func test_current_save_preserves_books_and_known_regions() -> void:
	var service := SaveGameServiceClass.new(_save_root)
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.known_region_ids.assign(["twilight_plains", "black_forest"])
	session.player.inventory.add("path_arcana_book", 2)

	var save_result := service.save_session(session)
	var load_result := service.load_session(1)

	assert_true(save_result.ok, save_result.message)
	assert_true(load_result.ok, load_result.message)
	assert_eq(load_result.session.known_region_ids, ["twilight_plains", "black_forest"])
	assert_eq(load_result.session.player.inventory.count("path_arcana_book"), 2)


func test_schema_five_save_migrates_with_all_terminal_regions_known() -> void:
	var service := SaveGameServiceClass.new(_save_root)
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var payload: Dictionary = service._serialize_session(session)
	payload.schema_version = 5
	payload.session.erase("known_region_ids")

	var result := service._deserialize_payload(payload, 1)

	assert_true(result.ok, result.message)
	assert_eq(result.session.known_region_ids, RegionCatalogClass.REGION_ORDER)


func test_save_rejects_unknown_or_repeated_regions() -> void:
	var service := SaveGameServiceClass.new(_save_root)
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var payload: Dictionary = service._serialize_session(session)
	payload.session.known_region_ids = ["twilight_plains", "unknown_region"]
	var unknown_result := service._deserialize_payload(payload, 1)
	assert_false(unknown_result.ok)

	payload.session.known_region_ids = ["twilight_plains", "twilight_plains"]
	var repeated_result := service._deserialize_payload(payload, 1)
	assert_false(repeated_result.ok)
