extends GutTest

const EliteCatalogClass := preload("res://core/world/elite_catalog.gd")
const EliteEncounterServiceClass := preload("res://core/world/elite_encounter_service.gd")
const EnemyCatalogClass := preload("res://core/combat/enemy_catalog.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const RegionBossCatalogClass := preload("res://core/world/region_boss_catalog.gd")
const RegionBossChallengeServiceClass := preload(
	"res://core/world/region_boss_challenge_service.gd"
)
const RegionBossRespawnServiceClass := preload("res://core/world/region_boss_respawn_service.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")
const WeatherServiceClass := preload("res://core/world/weather_service.gd")


func test_stage_eight_authored_contract_is_complete() -> void:
	assert_eq(EliteCatalogClass.MODIFIERS.size(), 5)
	assert_eq(EliteCatalogClass.COMPATIBILITY.size(), 31)
	assert_eq(RegionBossCatalogClass.BOSS_ORDER, ["azhar", "leviathan_north"])
	assert_eq(RegionBossCatalogClass.get_all().size(), 2)
	assert_eq(RegionBossRespawnServiceClass.RESPAWN_EXPEDITIONS, 6)
	assert_eq(SaveGameServiceClass.SCHEMA_VERSION, 18)


func test_boss_respawn_starts_after_attempt_time_and_uses_the_new_timestamp() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var rewards := RegionBossChallengeServiceClass.resolve_victory(
		session, EnemyCatalogClass.create_enemy("azhar"), _rng(8201)
	)
	assert_true(rewards.ok)
	assert_eq(session.hour, 8)
	assert_true(session.world_encounters.region_boss_respawns.is_empty())

	var attempt := RegionBossChallengeServiceClass.finish_attempt(
		session, "azhar", "victory", _rng(8202)
	)
	assert_true(attempt.ok)
	assert_true(attempt.boss_respawn.started)
	assert_eq(session.hour, 9)
	assert_eq(session.world_encounters.region_boss_respawns, {"azhar": 6})
	assert_string_starts_with(session.adventure_log.entries[-1], "Dzień 1, 09:00")
	assert_string_contains(session.adventure_log.entries[-1], "Odrodzenie wymaga 6 wypraw")


func test_invalid_boss_attempt_result_is_rejected_without_mutation() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.camp_rest_available = false
	var result := RegionBossChallengeServiceClass.finish_attempt(
		session, "azhar", "unknown", _rng(8203)
	)
	assert_false(result.ok)
	assert_eq(session.hour, 8)
	assert_false(session.camp_rest_available)
	assert_true(session.world_encounters.region_boss_respawns.is_empty())


func test_stage_eight_state_remains_live_across_two_save_round_trips() -> void:
	var service := SaveGameServiceClass.new("user://stage_eight_e_not_written")
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.world_encounters.elite_discoveries.assign(["furious"])
	session.world_encounters.elite_miss_streaks = {"twilight_plains": 2}
	session.world_encounters.region_boss_respawns = {"azhar": 3}

	var first := service._deserialize_payload(service._serialize_session(session), 1)
	assert_true(first.ok, first.get("message", ""))
	var restored = first.session
	var blocked := RegionBossChallengeServiceClass.prepare_challenge(restored, "ashen_borderlands")
	assert_false(blocked.ok)
	assert_eq(blocked.remaining, 3)
	assert_eq(restored.current_location_id, "twilight_plains")

	var missed := (
		EliteEncounterServiceClass
		. resolve_roll(
			EnemyCatalogClass.create_enemy("wolf"),
			"day",
			WeatherServiceClass.SUNNY,
			"twilight_plains",
			restored.world_encounters,
			0.99,
			0,
		)
	)
	assert_true(missed.ok)
	assert_true(missed.modifier_id.is_empty())
	assert_eq(restored.world_encounters.elite_miss_streaks.twilight_plains, 3)

	var elite_enemy = EnemyCatalogClass.create_enemy("wolf")
	var elite := (
		EliteEncounterServiceClass
		. resolve_roll(
			elite_enemy,
			"day",
			WeatherServiceClass.SUNNY,
			"twilight_plains",
			restored.world_encounters,
			0.0,
			1,
		)
	)
	assert_true(elite.ok)
	assert_eq(elite.modifier_id, "vampiric")
	assert_false(
		(
			EliteEncounterServiceClass
			. record_discovery(restored.world_encounters, elite_enemy)
			. is_empty()
		)
	)
	var countdown := RegionBossRespawnServiceClass.record_region_expedition(
		restored, "ashen_borderlands"
	)
	assert_eq(countdown.remaining, 2)

	var second := service._deserialize_payload(service._serialize_session(restored), 1)
	assert_true(second.ok, second.get("message", ""))
	assert_eq(second.session.world_encounters.elite_discoveries, ["furious", "vampiric"])
	assert_eq(second.session.world_encounters.elite_miss_streaks, {"twilight_plains": 0})
	assert_eq(second.session.world_encounters.region_boss_respawns, {"azhar": 2})


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng
