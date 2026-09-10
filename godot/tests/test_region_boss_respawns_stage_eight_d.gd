extends GutTest

const AdventureServiceClass := preload("res://core/world/adventure_service.gd")
const CampRestServiceClass := preload("res://core/economy/camp_rest_service.gd")
const DungeonServiceClass := preload("res://core/dungeons/dungeon_service.gd")
const EnemyCatalogClass := preload("res://core/combat/enemy_catalog.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const RegionBossChallengeServiceClass := preload(
	"res://core/world/region_boss_challenge_service.gd"
)
const RegionBossRespawnServiceClass := preload("res://core/world/region_boss_respawn_service.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")
const WORLD_MAP_SCENE := preload("res://ui/screens/world_map/world_map.tscn")


func test_victory_starts_six_expedition_respawn_and_defeat_does_not() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var victory := RegionBossChallengeServiceClass.resolve_victory(
		session, EnemyCatalogClass.create_enemy("azhar"), _rng(8105)
	)
	assert_true(victory.ok)
	assert_true(session.world_encounters.region_boss_respawns.is_empty())
	var finished := RegionBossChallengeServiceClass.finish_attempt(
		session, "azhar", "victory", _rng(8106)
	)
	assert_true(finished.boss_respawn.started)
	assert_eq(finished.boss_respawn.remaining, 6)
	assert_eq(session.world_encounters.region_boss_respawns, {"azhar": 6})
	assert_false(RegionBossRespawnServiceClass.is_available(session.world_encounters, "azhar"))

	var untouched = NewGameServiceClass.new().create_session("Bela", 2)
	RegionBossChallengeServiceClass.finish_attempt(untouched, "azhar", "defeat", _rng(1))
	RegionBossChallengeServiceClass.finish_attempt(untouched, "azhar", "fled", _rng(2))
	assert_true(untouched.world_encounters.region_boss_respawns.is_empty())


func test_only_normal_expeditions_in_the_boss_region_reduce_the_counter() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.world_encounters.region_boss_respawns = {"azhar": 6, "leviathan_north": 4}
	var plains := AdventureServiceClass.explore_region(session, "twilight_plains", _rng(10))
	assert_false(plains.get("blocked", false))
	assert_eq(session.world_encounters.region_boss_respawns, {"azhar": 6, "leviathan_north": 4})

	var ashlands := AdventureServiceClass.explore_region(session, "ashen_borderlands", _rng(11))
	assert_false(ashlands.get("blocked", false))
	assert_true(ashlands.boss_respawn.changed)
	assert_eq(ashlands.boss_respawn.remaining, 5)
	assert_eq(session.world_encounters.region_boss_respawns.azhar, 5)
	assert_eq(session.world_encounters.region_boss_respawns.leviathan_north, 4)

	var overloaded = NewGameServiceClass.new().create_session("Bela", 2)
	overloaded.world_encounters.region_boss_respawns = {"azhar": 6}
	overloaded.player.inventory.add("weak_leather", 2000)
	var blocked := AdventureServiceClass.explore_region(overloaded, "ashen_borderlands", _rng(12))
	assert_true(blocked.blocked)
	assert_eq(overloaded.world_encounters.region_boss_respawns.azhar, 6)
	assert_eq(overloaded.hour, 8)


func test_guaranteed_encounters_count_without_waiting_for_the_combat_result() -> void:
	for seed_value in range(1, 30):
		var session = NewGameServiceClass.new().create_session("Aria", 1)
		session.world_encounters.region_boss_respawns = {"azhar": 2}
		var result := AdventureServiceClass.explore_region(
			session, "ashen_borderlands", _rng(seed_value)
		)
		assert_eq(session.world_encounters.region_boss_respawns.azhar, 1)
		assert_false(result.enemy_id.is_empty())


func test_boss_returns_after_exactly_six_expeditions_and_logs_once() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	RegionBossRespawnServiceClass.start_after_victory(session, "leviathan_north")
	for expected in [5, 4, 3, 2, 1]:
		var result := RegionBossRespawnServiceClass.record_region_expedition(session, "ice_coast")
		assert_eq(result.remaining, expected)
		assert_false(result.respawned)
		assert_false(
			RegionBossRespawnServiceClass.is_available(session.world_encounters, "leviathan_north")
		)
	var final := RegionBossRespawnServiceClass.record_region_expedition(session, "ice_coast")
	assert_eq(final.remaining, 0)
	assert_true(final.respawned)
	assert_true(
		RegionBossRespawnServiceClass.is_available(session.world_encounters, "leviathan_north")
	)
	assert_false(session.world_encounters.region_boss_respawns.has("leviathan_north"))
	assert_string_contains(final.message, "ponownie można rzucić mu wyzwanie")
	assert_string_contains(session.adventure_log.entries[-1], "Lewiatan Północy")


func test_blocked_challenge_does_not_mutate_time_contracts_or_location() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.current_location_id = "twilight_plains"
	session.world_encounters.region_boss_respawns = {"azhar": 3}
	var result := RegionBossChallengeServiceClass.prepare_challenge(session, "ashen_borderlands")
	assert_false(result.ok)
	assert_true(result.blocked)
	assert_eq(result.remaining, 3)
	assert_string_contains(result.message, "3 wyprawy")
	assert_eq(session.current_location_id, "twilight_plains")
	assert_eq(session.hour, 8)
	assert_true(session.contract_board.daily_contracts.is_empty())


func test_camp_dungeon_and_boss_attempt_do_not_reduce_active_respawn() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.world_encounters.region_boss_respawns = {"azhar": 4}
	session.player.stats.current_hp = 1
	assert_true(CampRestServiceClass.rest(session, _rng(3)).ok)
	assert_eq(session.world_encounters.region_boss_respawns.azhar, 4)

	session.player.inventory.add("ancient_order_key")
	assert_true(DungeonServiceClass.start(session, "sunken_order_crypt", _rng(4)).ok)
	assert_eq(session.world_encounters.region_boss_respawns.azhar, 4)
	RegionBossChallengeServiceClass.finish_attempt(session, "azhar", "defeat", _rng(5))
	assert_eq(session.world_encounters.region_boss_respawns.azhar, 4)


func test_respawn_state_survives_save_load_without_schema_bump() -> void:
	var service := SaveGameServiceClass.new("user://stage_eight_d_not_written")
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.world_encounters.region_boss_respawns = {"azhar": 3, "leviathan_north": 6}
	var payload := service._serialize_session(session)
	assert_eq(payload.schema_version, 18)
	var restored := service._deserialize_payload(payload, 1)
	assert_true(restored.ok, restored.get("message", ""))
	assert_eq(
		restored.session.world_encounters.region_boss_respawns,
		{"azhar": 3, "leviathan_north": 6},
	)


func test_world_map_shows_counter_blocks_click_and_refreshes_after_expedition() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 18
	session.world_encounters.region_boss_respawns = {"azhar": 2}
	var world = WORLD_MAP_SCENE.instantiate()
	add_child_autofree(world)
	world.configure(session, "ashen_borderlands")
	assert_string_contains(world.boss_button.text, "Odrodzenie: 2 wyprawy")
	watch_signals(world)
	world.boss_button.pressed.emit()
	assert_signal_not_emitted(world, "boss_requested")
	assert_string_contains(world.event_label.text, "jeszcze się nie odrodził")

	world.explore_button.pressed.emit()
	assert_eq(session.world_encounters.region_boss_respawns.azhar, 1)
	assert_string_contains(world.boss_button.text, "Odrodzenie: 1 wyprawa")


func test_polish_expedition_count_matches_terminal_inflection() -> void:
	assert_eq(RegionBossRespawnServiceClass.format_expedition_count(1), "1 wyprawa")
	assert_eq(RegionBossRespawnServiceClass.format_expedition_count(2), "2 wyprawy")
	assert_eq(RegionBossRespawnServiceClass.format_expedition_count(4), "4 wyprawy")
	assert_eq(RegionBossRespawnServiceClass.format_expedition_count(5), "5 wypraw")
	assert_eq(RegionBossRespawnServiceClass.format_expedition_count(12), "12 wypraw")
	assert_eq(RegionBossRespawnServiceClass.format_expedition_count(22), "22 wyprawy")


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng
