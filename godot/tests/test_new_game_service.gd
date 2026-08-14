extends GutTest

const NewGameServiceClass := preload("res://core/game/new_game_service.gd")

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


func test_creates_session_with_legacy_starting_state() -> void:
	var session := service.create_session("  Aria  ", 3)

	assert_not_null(session)
	assert_eq(session.save_slot, 3)
	assert_eq(session.player.display_name, "Aria")
	assert_eq(session.player.level, 0)
	assert_eq(session.player.health, 20)
	assert_eq(session.player.max_health, 20)
	assert_eq(session.player.weapon_id, "starter_sword")
	assert_eq(session.player.armor_id, "worn_leather_armor")
	assert_eq(session.current_location_id, "twilight_plains")
	assert_eq(session.current_city_id, "varenhold")
	assert_eq(session.day, 1)
	assert_eq(session.hour, 8)
	assert_true(session.is_active)
