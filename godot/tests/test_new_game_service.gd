extends GutTest

const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const NEW_GAME_SCENE := preload("res://ui/screens/new_game/new_game.tscn")

var service := NewGameServiceClass.new()


func test_normalizes_whitespace_around_player_name() -> void:
	assert_eq(service.normalize_player_name("  Aria  "), "Aria")


func test_rejects_names_shorter_than_two_characters() -> void:
	assert_false(service.get_player_name_error("A").is_empty())
	assert_null(service.create_session("A", 1))


func test_rejects_names_longer_than_twenty_characters() -> void:
	var too_long_name := "A".repeat(21)
	assert_false(service.get_player_name_error(too_long_name).is_empty())
	assert_null(service.create_session(too_long_name, 1))


func test_accepts_boundary_name_lengths() -> void:
	assert_true(service.get_player_name_error("Al").is_empty())
	assert_true(service.get_player_name_error("A".repeat(20)).is_empty())


func test_rejects_save_slots_outside_legacy_range() -> void:
	assert_null(service.create_session("Aria", 0))
	assert_null(service.create_session("Aria", 5))


func test_rejects_unknown_gender_when_gender_is_requested() -> void:
	assert_true(service.get_gender_error("female").is_empty())
	assert_true(service.get_gender_error("male").is_empty())
	assert_null(service.create_session("Aria", 1, null, "unknown"))


func test_creates_level_zero_session_with_gender_and_without_a_class() -> void:
	var session := service.create_session("Aria", 2, null, "female")

	assert_not_null(session)
	assert_eq(session.player.level, 0)
	assert_eq(session.player.gender_code, "female")
	assert_eq(session.player.character_class_code, "none")
	assert_eq(session.player.character_class_name, "Poszukiwaczka")
	assert_eq(session.player.weapon_id, "starter_sword")
	assert_false(session.player.can_choose_class)


func test_new_game_screen_requires_gender_and_shows_matching_neutral_art() -> void:
	var screen = NEW_GAME_SCENE.instantiate()
	add_child_autofree(screen)

	assert_eq(screen.gender_selector.item_count, 2)
	assert_eq(screen._selected_gender_code, "")
	assert_true(screen.create_button.disabled)
	screen.name_input.text = "Aria"
	screen._on_name_changed(screen.name_input.text)
	assert_true(screen.create_button.disabled)
	screen.gender_selector.select(0)
	screen.gender_selector.item_selected.emit(0)
	assert_eq(screen._selected_gender_code, "female")
	assert_eq(screen.role_name_label.text, "Poszukiwaczka")
	assert_not_null(screen.character_preview.character_texture())
	assert_eq(
		screen.character_preview.character_texture().resource_path,
		"res://assets/combat/heroes/seeker_female.png",
	)
	screen.gender_selector.select(1)
	screen.gender_selector.item_selected.emit(1)
	assert_eq(screen._selected_gender_code, "male")
	assert_eq(screen.role_name_label.text, "Poszukiwacz")
	assert_not_null(screen.character_preview.character_texture())
	assert_eq(
		screen.character_preview.character_texture().resource_path,
		"res://assets/combat/heroes/seeker_male.png",
	)
	assert_false(screen.create_button.disabled)
	var created_sessions: Array = []
	screen.session_created.connect(func(session): created_sessions.append(session))
	screen._create_new_session()
	assert_eq(created_sessions.size(), 1)
	assert_eq(created_sessions[0].player.gender_code, "male")
	assert_eq(created_sessions[0].player.character_class_code, "none")


func test_new_game_screen_keeps_character_creation_inside_a_720p_scroll_view() -> void:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_child(host)
	var screen = NEW_GAME_SCENE.instantiate()
	host.add_child(screen)
	await get_tree().process_frame

	assert_true(screen is ScrollContainer)
	assert_eq(screen.horizontal_scroll_mode, ScrollContainer.SCROLL_MODE_DISABLED)
	assert_lte(screen.get_node("Center/Panel").size.x, screen.size.x)
	assert_true(screen.get_v_scroll_bar().visible)
	host.free()


func test_creates_session_with_legacy_starting_state() -> void:
	var session := service.create_session("  Aria  ", 3)

	assert_not_null(session)
	assert_eq(session.save_slot, 3)
	assert_eq(session.player.display_name, "Aria")
	assert_eq(session.player.level, 0)
	assert_eq(session.player.health, 20)
	assert_eq(session.player.max_health, 20)
	assert_eq(session.player.stats.attack, 3)
	assert_eq(session.player.stats.defense, 2)
	assert_eq(session.player.weapon_id, "starter_sword")
	assert_eq(session.player.armor_id, "worn_leather_armor")
	assert_eq(session.current_location_id, "twilight_plains")
	assert_eq(session.current_city_id, "varenhold")
	assert_eq(session.day, 1)
	assert_eq(session.hour, 8)
	assert_true(session.is_active)
