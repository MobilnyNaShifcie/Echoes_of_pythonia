extends GutTest

const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const OpenWorldEncounterStateClass := preload("res://core/world/open_world_encounter_state.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")
const WorldEncounterSaveCodecClass := preload("res://core/save/world_encounter_save_codec.gd")


func test_new_session_owns_an_empty_open_world_encounter_state() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)

	assert_not_null(session.world_encounters)
	assert_true(session.world_encounters.elite_discoveries.is_empty())
	assert_true(session.world_encounters.elite_miss_streaks.is_empty())
	assert_true(session.world_encounters.region_boss_respawns.is_empty())


func test_world_encounter_codec_round_trip_preserves_terminal_state() -> void:
	var state := OpenWorldEncounterStateClass.new()
	state.elite_discoveries.assign(["furious", "vampiric", "elemental"])
	state.elite_miss_streaks = {"twilight_plains": 4, "ice_coast": 9}
	state.region_boss_respawns = {"azhar": 0, "leviathan_north": 6}

	var data := WorldEncounterSaveCodecClass.serialize(state)
	var restored := WorldEncounterSaveCodecClass.deserialize(data)

	assert_true(restored.ok, restored.get("message", ""))
	assert_eq(restored.state.elite_discoveries, ["furious", "vampiric", "elemental"])
	assert_eq(restored.state.elite_miss_streaks, {"twilight_plains": 4, "ice_coast": 9})
	assert_eq(restored.state.region_boss_respawns, {"azhar": 0, "leviathan_north": 6})


func test_world_encounter_codec_rejects_unknown_duplicate_and_invalid_values() -> void:
	var data := WorldEncounterSaveCodecClass.empty_data()
	data.elite_discoveries = ["furious", "furious"]
	var duplicate := WorldEncounterSaveCodecClass.deserialize(data)
	assert_false(duplicate.ok)
	assert_string_contains(duplicate.message, "powtórzony")

	data = WorldEncounterSaveCodecClass.empty_data()
	data.elite_miss_streaks = {"unknown_region": 2}
	var unknown_region := WorldEncounterSaveCodecClass.deserialize(data)
	assert_false(unknown_region.ok)
	assert_string_contains(unknown_region.message, "region")

	data = WorldEncounterSaveCodecClass.empty_data()
	data.elite_miss_streaks = {"twilight_plains": -1}
	var negative_streak := WorldEncounterSaveCodecClass.deserialize(data)
	assert_false(negative_streak.ok)
	assert_string_contains(negative_streak.message, "nieujemną")

	data = WorldEncounterSaveCodecClass.empty_data()
	data.region_boss_respawns = {"unknown_boss": 3}
	var unknown_boss := WorldEncounterSaveCodecClass.deserialize(data)
	assert_false(unknown_boss.ok)
	assert_string_contains(unknown_boss.message, "bossa")

	data = WorldEncounterSaveCodecClass.empty_data()
	data.region_boss_respawns = {"azhar": 1.5}
	var fractional_counter := WorldEncounterSaveCodecClass.deserialize(data)
	assert_false(fractional_counter.ok)
	assert_string_contains(fractional_counter.message, "całkowitą")


func test_schema_sixteen_migrates_to_an_empty_world_encounter_state() -> void:
	var service := SaveGameServiceClass.new("user://stage_eight_a_not_written")
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var payload := service._serialize_session(session)
	assert_eq(payload.schema_version, 17)
	assert_true(payload.session.has("world_encounters"))

	payload.schema_version = 16
	payload.session.erase("world_encounters")
	var result := service._deserialize_payload(payload, 1)

	assert_true(result.ok, result.get("message", ""))
	assert_true(result.session.world_encounters.elite_discoveries.is_empty())
	assert_true(result.session.world_encounters.elite_miss_streaks.is_empty())
	assert_true(result.session.world_encounters.region_boss_respawns.is_empty())


func test_save_round_trip_preserves_open_world_encounter_state() -> void:
	var service := SaveGameServiceClass.new("user://stage_eight_a_not_written")
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.world_encounters.elite_discoveries.assign(["armored", "cursed"])
	session.world_encounters.elite_miss_streaks = {"ashen_borderlands": 7}
	session.world_encounters.region_boss_respawns = {"azhar": 5}

	var result := service._deserialize_payload(service._serialize_session(session), 1)

	assert_true(result.ok, result.get("message", ""))
	assert_eq(result.session.world_encounters.elite_discoveries, ["armored", "cursed"])
	assert_eq(result.session.world_encounters.elite_miss_streaks, {"ashen_borderlands": 7})
	assert_eq(result.session.world_encounters.region_boss_respawns, {"azhar": 5})
