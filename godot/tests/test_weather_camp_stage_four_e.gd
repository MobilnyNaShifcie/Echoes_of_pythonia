extends GutTest

const AdventureServiceClass := preload("res://core/world/adventure_service.gd")
const CampRestServiceClass := preload("res://core/economy/camp_rest_service.gd")
const CombatScreenClass := preload("res://ui/screens/combat/combat.gd")
const COMBAT_SCENE := preload("res://ui/screens/combat/combat.tscn")
const EnemyCatalogClass := preload("res://core/combat/enemy_catalog.gd")
const InnServiceClass := preload("res://core/economy/inn_service.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")
const WeatherServiceClass := preload("res://core/world/weather_service.gd")
const WorldMapScreenClass := preload("res://ui/screens/world_map/world_map.gd")
const WORLD_MAP_SCENE := preload("res://ui/screens/world_map/world_map.tscn")


func test_weather_catalog_preserves_terminal_weights_and_polish_names() -> void:
	assert_eq(WeatherServiceClass.roll_weather_from_value(1), WeatherServiceClass.SUNNY)
	assert_eq(WeatherServiceClass.roll_weather_from_value(30), WeatherServiceClass.SUNNY)
	assert_eq(WeatherServiceClass.roll_weather_from_value(31), WeatherServiceClass.STORM)
	assert_eq(WeatherServiceClass.roll_weather_from_value(51), WeatherServiceClass.FROST)
	assert_eq(WeatherServiceClass.roll_weather_from_value(71), WeatherServiceClass.WIND)
	assert_eq(WeatherServiceClass.roll_weather_from_value(91), WeatherServiceClass.AURORA)
	assert_eq(WeatherServiceClass.display_name_for("frost"), "MRÓZ")
	assert_eq(WeatherServiceClass.display_name_for("aurora"), "ZORZA POLARNA")


func test_weather_advances_in_six_hour_cycles_with_the_world_clock() -> void:
	var session = _session()
	session.weather_code = WeatherServiceClass.SUNNY
	session.weather_remaining_hours = 6
	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	assert_true(session.advance_hours(13, rng))
	assert_eq(session.hour, 21)
	assert_eq(session.weather_remaining_hours, 5)
	assert_eq(session.last_weather_changes.size(), 2)
	assert_true(WeatherServiceClass.is_valid_code(session.weather_code))


func test_aurora_strengthens_every_enemy_and_miniboss_weather_is_specialized() -> void:
	var wolf = EnemyCatalogClass.create_enemy("wolf")
	WeatherServiceClass.apply_to_enemy(wolf, WeatherServiceClass.AURORA)
	assert_eq(wolf.max_hp, 11)
	assert_eq(wolf.attack, 5)
	assert_eq(wolf.defense, 2)
	assert_eq(wolf.dodge, 10.0)
	assert_eq(wolf.weather_note, "Wzmocniony przez Zorzę Polarną")

	var guardian = EnemyCatalogClass.create_enemy("nature_guardian")
	WeatherServiceClass.apply_to_enemy(guardian, WeatherServiceClass.STORM)
	assert_eq(guardian.max_hp, 29)
	assert_eq(guardian.attack, 8)
	assert_eq(guardian.basic_damage_type, "wind")
	assert_eq(guardian.weather_note, "Wzmocniony przez Burzę")

	var ordinary = EnemyCatalogClass.create_enemy("wolf")
	WeatherServiceClass.apply_to_enemy(ordinary, WeatherServiceClass.STORM)
	assert_eq(ordinary.max_hp, 9)
	assert_eq(ordinary.attack, 3)
	assert_eq(ordinary.weather_note, "")


func test_aurora_increases_experience_gold_and_loot_chance_by_half() -> void:
	var session = _session()
	var enemy = EnemyCatalogClass.create_enemy("wolf")
	WeatherServiceClass.apply_to_enemy(enemy, WeatherServiceClass.AURORA)
	var rng := RandomNumberGenerator.new()
	rng.seed = 19

	var rewards := AdventureServiceClass.resolve_victory(session, enemy, rng)

	assert_eq(rewards.experience, 21)
	assert_eq(rewards.gold, 15)
	assert_eq(rewards.reward_multiplier, 1.5)
	assert_eq(rewards.drop_chance_multiplier, 1.5)
	assert_eq(session.player.experience, 21)
	assert_eq(session.player.gold, 15)


func test_camp_restores_partial_resources_advances_time_and_enters_cooldown() -> void:
	var session = _session()
	session.weather_code = WeatherServiceClass.SUNNY
	session.weather_remaining_hours = 6
	session.player.stats.current_hp = 1
	session.player.stats.max_mana = 10
	session.player.stats.current_mana = 0
	var rng := RandomNumberGenerator.new()
	rng.seed = 8

	var result := CampRestServiceClass.rest(session, rng)

	assert_true(result.ok, result.message)
	assert_eq(result.healed_hp, 5)
	assert_eq(result.restored_mana, 4)
	assert_eq(session.player.stats.current_hp, 6)
	assert_eq(session.player.stats.current_mana, 4)
	assert_eq(session.hour, 10)
	assert_eq(session.weather_remaining_hours, 4)
	assert_false(session.camp_rest_available)
	assert_false(CampRestServiceClass.rest(session, rng).ok)


func test_camp_rejects_rest_when_resources_are_full_without_using_cooldown() -> void:
	var session = _session()
	var result := CampRestServiceClass.rest(session)

	assert_false(result.ok)
	assert_string_contains(result.message, "Nie potrzebujesz")
	assert_true(session.camp_rest_available)
	assert_eq(session.hour, 8)


func test_inn_uses_the_same_weather_clock_and_reports_a_change() -> void:
	var session = _session()
	session.player.gold = 100
	session.player.stats.current_hp = 1
	session.weather_code = WeatherServiceClass.SUNNY
	session.weather_remaining_hours = 2

	var result := InnServiceClass.rest(session)

	assert_true(result.ok, result.message)
	assert_eq(session.hour, 14)
	assert_eq(session.weather_remaining_hours, 2)
	assert_eq(session.last_weather_changes.size(), 1)
	assert_string_contains(result.message, "Pogoda zmienia się")


func test_expedition_reopens_camp_and_keeps_weather_from_encounter_start() -> void:
	var session = _session()
	session.camp_rest_available = false
	session.weather_code = WeatherServiceClass.AURORA
	session.weather_remaining_hours = 1
	var rng := RandomNumberGenerator.new()
	rng.seed = 9

	var result := AdventureServiceClass.explore_region(session, "black_forest", rng)

	assert_false(result.get("blocked", false))
	assert_eq(result.weather_code, WeatherServiceClass.AURORA)
	assert_eq(result.weather_changes.size(), 1)
	assert_eq(session.weather_remaining_hours, 6)
	assert_true(session.camp_rest_available)
	assert_eq(session.hour, 9)


func test_world_map_exposes_weather_and_functional_camp_placeholder() -> void:
	var session = _session()
	session.weather_code = WeatherServiceClass.FROST
	session.weather_remaining_hours = 3
	session.player.stats.current_hp = 10
	var screen := WORLD_MAP_SCENE.instantiate() as WorldMapScreenClass
	screen.configure(session)
	add_child_autofree(screen)

	assert_string_contains(screen.weather_label.text, "MRÓZ")
	assert_string_contains(screen.weather_label.text, "3 godz.")
	assert_false(screen.camp_button.disabled)
	screen.camp_button.pressed.emit()
	assert_false(session.camp_rest_available)
	assert_eq(session.hour, 10)
	assert_string_contains(screen.event_label.text, "Odpoczynek przy ognisku")


func test_combat_uses_weather_captured_by_the_expedition() -> void:
	var session = _session()
	var screen := COMBAT_SCENE.instantiate() as CombatScreenClass
	screen.configure(session, "wolf", "expedition", WeatherServiceClass.AURORA)
	add_child_autofree(screen)

	assert_eq(screen._enemy.max_hp, 11)
	assert_eq(screen._enemy.attack, 5)
	assert_string_contains(screen.weather_label.text, "ZORZA POLARNA")
	assert_string_contains(screen._enemy.weather_note, "Wzmocniony")


func test_schema_eight_persists_weather_camp_and_migrates_schema_seven() -> void:
	var service := SaveGameServiceClass.new("user://stage_four_e_not_written")
	var session = _session()
	session.weather_code = WeatherServiceClass.WIND
	session.weather_remaining_hours = 2
	session.camp_rest_available = false
	var payload: Dictionary = service._serialize_session(session)

	assert_eq(payload.schema_version, 15)
	var round_trip := service._deserialize_payload(payload, 1)
	assert_true(round_trip.ok, round_trip.message)
	assert_eq(round_trip.session.weather_code, WeatherServiceClass.WIND)
	assert_eq(round_trip.session.weather_remaining_hours, 2)
	assert_false(round_trip.session.camp_rest_available)

	var legacy_payload := payload.duplicate(true)
	legacy_payload.schema_version = 7
	legacy_payload.session.erase("weather_code")
	legacy_payload.session.erase("weather_remaining_hours")
	legacy_payload.session.erase("camp_rest_available")
	var migrated := service._deserialize_payload(legacy_payload, 1)
	assert_true(migrated.ok, migrated.message)
	assert_eq(migrated.session.weather_code, WeatherServiceClass.SUNNY)
	assert_eq(migrated.session.weather_remaining_hours, 6)
	assert_true(migrated.session.camp_rest_available)

	var invalid_payload := payload.duplicate(true)
	invalid_payload.session.weather_code = "meteor_shower"
	var invalid := service._deserialize_payload(invalid_payload, 1)
	assert_false(invalid.ok)
	assert_string_contains(invalid.message, "nieznany stan pogody")


func _session():
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	return NewGameServiceClass.new().create_session("Aria", 1, rng)
