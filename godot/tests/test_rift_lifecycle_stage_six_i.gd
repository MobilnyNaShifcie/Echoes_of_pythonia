extends GutTest

const CompanionRecruitmentServiceClass := preload(
	"res://core/companions/companion_recruitment_service.gd"
)
const CompanionServiceClass := preload("res://core/companions/companion_service.gd")
const CompanionStateClass := preload("res://core/companions/companion_state.gd")
const ExpeditionPreparationServiceClass := preload(
	"res://core/world/expedition_preparation_service.gd"
)
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const RiftCatalogClass := preload("res://core/rifts/rift_catalog.gd")
const RiftInstanceClass := preload("res://core/rifts/rift_instance.gd")
const RiftLifecycleServiceClass := preload("res://core/rifts/rift_lifecycle_service.gd")
const RiftSaveCodecClass := preload("res://core/save/rift_save_codec.gd")
const RiftStateClass := preload("res://core/rifts/rift_state.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")
const APP_SCENE := preload("res://scenes/app/app.tscn")
const GUILD_SCENE := preload("res://ui/screens/guild/guild.tscn")
const RIFT_BOARD_SCENE := preload("res://ui/screens/rift_board/rift_board.tscn")


func test_catalog_preserves_terminal_ranks_lengths_requirements_themes_and_modifiers() -> void:
	assert_eq(RiftCatalogClass.RANKS, ["F", "E", "D", "C", "B", "A", "S"])
	assert_eq(
		RiftCatalogClass.SEGMENTS,
		{"F": 12, "E": 14, "D": 16, "C": 18, "B": 20, "A": 22, "S": 24},
	)
	assert_eq(
		RiftCatalogClass.MIN_COMPANIONS,
		{"F": 2, "E": 2, "D": 3, "C": 3, "B": 3, "A": 3, "S": 3},
	)
	assert_eq(RiftCatalogClass.THEME_ORDER.size(), 5)
	assert_eq(RiftCatalogClass.MODIFIER_ORDER.size(), 6)
	assert_eq(RiftCatalogClass.get_theme("black_tide").name, "Czarna Przypływowa Szczelina")
	assert_eq(RiftCatalogClass.get_modifier("hungry").enemy_hp_multiplier, 1.18)
	assert_eq(RiftCatalogClass.get_modifier("violent").enemy_attack_multiplier, 1.15)
	assert_eq(RiftCatalogClass.get_modifier("armored").enemy_defense_bonus, 2)
	assert_eq(RiftCatalogClass.get_modifier("mana_static").player_mana_cost_multiplier, 1.15)


func test_alarm_spawns_only_on_schedule_and_is_deterministic_inside_godot() -> void:
	var first := RiftStateClass.new()
	var second := RiftStateClass.new()
	var early := RiftLifecycleServiceClass.ensure_state(first, "Aria", 1, "C")
	assert_true(early.ok)
	assert_false(early.changed)
	assert_null(first.active_rift)

	var spawned := RiftLifecycleServiceClass.ensure_state(first, "Aria", 2, "C")
	var repeated := RiftLifecycleServiceClass.ensure_state(second, "Aria", 2, "C")
	assert_true(spawned.ok)
	assert_true(spawned.changed)
	assert_true(repeated.changed)
	assert_eq(_rift_snapshot(first), _rift_snapshot(second))
	assert_between(first.active_rift.expires_day - first.active_rift.discovered_day, 2, 4)
	assert_between(first.next_spawn_day - 2, 4, 7)
	assert_string_contains(spawned.notice, "ALARM GILDII")
	assert_eq(
		first.active_rift.segment_count, RiftCatalogClass.SEGMENTS[first.active_rift.rank_code]
	)
	assert_lte(
		RiftCatalogClass.rank_index(first.active_rift.rank_code), RiftCatalogClass.rank_index("C")
	)


func test_world_time_refreshes_rifts_and_logs_the_notice() -> void:
	var session = _session()
	assert_null(session.rifts.active_rift)
	assert_true(session.advance_hours(24))
	assert_eq(session.day, 2)
	assert_not_null(session.rifts.active_rift)
	assert_true(
		session.adventure_log.entries.any(
			func(entry: String) -> bool: return "ALARM GILDII" in entry
		)
	)


func test_ignored_expired_rift_is_closed_by_a_stable_other_team() -> void:
	var first := RiftStateClass.new()
	first.active_rift = _rift("ignored", "C", 1, 2)
	first.next_spawn_day = 99
	var second := RiftStateClass.new()
	second.active_rift = _rift("ignored", "C", 1, 2)
	second.next_spawn_day = 99

	var resolved := RiftLifecycleServiceClass.ensure_state(first, "Aria", 3, "S")
	var repeated := RiftLifecycleServiceClass.ensure_state(second, "Aria", 3, "S")
	assert_true(resolved.changed)
	assert_null(first.active_rift)
	assert_eq(resolved.notice, repeated.notice)
	assert_string_contains(resolved.notice, "zamknęła")
	assert_eq(first.last_resolution_day, 3)
	assert_between(first.next_spawn_day - 3, 2, 5)


func test_active_expedition_protects_an_expired_rift_from_other_teams() -> void:
	var state := RiftStateClass.new()
	state.active_rift = _rift("reserved", "F", 1, 2)
	var started := RiftLifecycleServiceClass.start_expedition(
		state, 1, ["companion-a", "companion-b"], "S"
	)
	assert_true(started.ok, started.message)
	var refresh := RiftLifecycleServiceClass.ensure_state(state, "Aria", 20, "S")
	assert_true(refresh.ok)
	assert_false(refresh.changed)
	assert_not_null(state.active_rift)
	assert_not_null(state.expedition)


func test_start_requires_guild_rank_and_a_real_party_then_binds_exact_ids() -> void:
	var state := RiftStateClass.new()
	state.active_rift = _rift("gate", "D", 5, 8)
	var wrong_rank := RiftLifecycleServiceClass.start_expedition(state, 5, ["a", "b", "c"], "E")
	assert_false(wrong_rank.ok)
	assert_string_contains(wrong_rank.message, "Ranga Gildii: D")
	var too_small := RiftLifecycleServiceClass.start_expedition(state, 5, ["a", "b"], "S")
	assert_false(too_small.ok)
	assert_string_contains(too_small.message, "co najmniej 3")
	var started := RiftLifecycleServiceClass.start_expedition(state, 5, ["a", "b", "c"], "S")
	assert_true(started.ok, started.message)
	assert_eq(state.expedition.party_companion_ids, ["a", "b", "c"])
	assert_eq(state.expedition.segment_index, 0)
	assert_eq(state.expedition.started_day, 5)


func test_reserved_expedition_locks_composition_recruitment_dismissal_and_departure() -> void:
	var session = _session()
	var first := _companion("a", "Kael")
	var second := _companion("b", "Mira")
	session.party.companions.assign([first, second])
	session.rifts.active_rift = _rift("locked", "F", 1, 5)
	assert_true(
		RiftLifecycleServiceClass.start_expedition(session.rifts, session.day, ["a", "b"], "F").ok
	)

	var toggle := CompanionServiceClass.set_active(
		session.party, "a", false, session.day, session.rifts.expedition != null
	)
	assert_false(toggle.ok)
	assert_true(first.active)
	var dismiss := (
		CompanionRecruitmentServiceClass
		. dismiss_companion(
			session.party,
			session.player,
			"a",
			session.day,
			session.rifts.expedition != null,
		)
	)
	assert_false(dismiss.ok)
	assert_eq(session.party.companions.size(), 2)
	CompanionRecruitmentServiceClass.ensure_daily_candidates(
		session.party, session.player, session.day, "S"
	)
	var recruit := (
		CompanionRecruitmentServiceClass
		. recruit_candidate(
			session.party,
			session.party.candidates[0],
			session.player,
			"S",
			session.rifts.completed_total,
			session.rifts.expedition != null,
		)
	)
	assert_false(recruit.ok)
	assert_false(session.party.candidates[0].recruitment_attempted)
	var departure := ExpeditionPreparationServiceClass.departure_status(session)
	assert_false(departure.ok)
	assert_string_contains(departure.message, "Trwa ekspedycja Szczeliny")


func test_abandoning_an_expired_reservation_allows_immediate_world_resolution() -> void:
	var state := RiftStateClass.new()
	state.active_rift = _rift("expired-reservation", "F", 1, 2)
	assert_true(RiftLifecycleServiceClass.start_expedition(state, 1, ["a", "b"], "F").ok)
	var abandoned := RiftLifecycleServiceClass.abandon_expedition(state, 8)
	assert_true(abandoned.ok)
	assert_null(state.expedition)
	assert_eq(state.active_rift.expires_day, 7)
	var resolved := RiftLifecycleServiceClass.ensure_state(state, "Aria", 8, "F")
	assert_true(resolved.changed)
	assert_null(state.active_rift)


func test_schema_fifteen_round_trip_preserves_active_rift_and_reservation() -> void:
	var session = _session()
	var first := _companion("a", "Kael")
	var second := _companion("b", "Mira")
	session.party.companions.assign([first, second])
	session.rifts.active_rift = _rift("save-rift", "F", 1, 4)
	assert_true(RiftLifecycleServiceClass.start_expedition(session.rifts, 1, ["a", "b"], "F").ok)
	session.rifts.completed_total = 3
	session.rifts.completed_by_rank = {"F": 2, "E": 1}
	session.rifts.last_notice = "Zapamiętany alarm."
	var service := SaveGameServiceClass.new("user://stage_six_i_not_written")
	var payload := service._serialize_session(session)
	var loaded := service._deserialize_payload(payload, session.save_slot)

	assert_eq(payload.schema_version, 15)
	assert_true(loaded.ok, loaded.message)
	assert_eq(loaded.session.rifts.active_rift.rift_id, "save-rift")
	assert_eq(loaded.session.rifts.expedition.party_companion_ids, ["a", "b"])
	assert_eq(loaded.session.rifts.completed_total, 3)
	assert_eq(loaded.session.rifts.completed_by_rank, {"F": 2, "E": 1})
	assert_eq(loaded.session.rifts.last_notice, "Zapamiętany alarm.")


func test_schema_fourteen_migrates_with_safe_empty_rift_state() -> void:
	var session = _session()
	var service := SaveGameServiceClass.new()
	var payload := service._serialize_session(session)
	payload.schema_version = 14
	payload.session.erase("rifts")
	var loaded := service._deserialize_payload(payload, session.save_slot)

	assert_true(loaded.ok, loaded.message)
	assert_null(loaded.session.rifts.active_rift)
	assert_null(loaded.session.rifts.expedition)
	assert_eq(loaded.session.rifts.next_spawn_day, 2)
	assert_eq(loaded.session.rifts.completed_total, 0)


func test_rift_codec_rejects_mismatched_or_out_of_range_expeditions() -> void:
	var state := RiftStateClass.new()
	state.active_rift = _rift("correct", "F", 1, 5)
	assert_true(RiftLifecycleServiceClass.start_expedition(state, 1, ["a", "b"], "F").ok)
	var data := RiftSaveCodecClass.serialize(state)
	data.expedition.rift_id = "wrong"
	assert_false(RiftSaveCodecClass.deserialize(data).ok)
	data = RiftSaveCodecClass.serialize(state)
	data.expedition.segment_index = state.active_rift.segment_count
	assert_false(RiftSaveCodecClass.deserialize(data).ok)


func test_rift_board_is_reachable_and_stops_before_stage_six_j_content() -> void:
	var session = _session()
	var first := _companion("a", "Kael")
	var second := _companion("b", "Mira")
	session.party.companions.assign([first, second])
	session.rifts.active_rift = _rift("ui-rift", "F", 1, 5)
	var screen = RIFT_BOARD_SCENE.instantiate()
	add_child_autofree(screen)
	screen.configure(session)
	assert_string_contains(screen.title_label.text, "Pęknięcie")
	assert_false(screen.start_button.disabled)
	watch_signals(screen)
	screen.start_button.pressed.emit()
	assert_signal_emitted(screen, "state_changed")
	assert_not_null(session.rifts.expedition)
	assert_true(screen.abandon_button.visible)
	assert_string_contains(screen.start_button.text, "Stage 6J")

	var guild = GUILD_SCENE.instantiate()
	add_child_autofree(guild)
	watch_signals(guild)
	guild.get_node("Page/BoardTabs/RiftsButton").pressed.emit()
	assert_signal_emitted(guild, "rifts_requested")

	var app = APP_SCENE.instantiate()
	add_child_autofree(app)
	session.prologue_completed = true
	app._on_session_created(session)
	app._show_rift_board()
	await get_tree().process_frame
	assert_eq(app.screen_host.get_child_count(), 1)
	assert_true(app.screen_host.get_child(0) is RiftBoardScreen)


func test_stage_six_i_subsystem_does_not_import_party_combat_or_rift_battles() -> void:
	for path: String in [
		"res://core/rifts/rift_lifecycle_service.gd",
		"res://ui/screens/rift_board/rift_board.gd",
	]:
		var source := FileAccess.get_file_as_string(path)
		assert_false("PartyCombatEngine" in source, path)
		assert_false("RiftBattleEngine" in source, path)


func _rift(
	rift_id: String, rank_code: String, discovered_day: int, expires_day: int
) -> RiftInstanceClass:
	return (
		RiftInstanceClass
		. new(
			{
				"rift_id": rift_id,
				"rank_code": rank_code,
				"theme_id": "blood_moon",
				"theme_name": "Pęknięcie Krwawego Księżyca",
				"modifier_ids": ["hungry"],
				"discovered_day": discovered_day,
				"expires_day": expires_day,
				"seed": 123,
				"segment_count": int(RiftCatalogClass.SEGMENTS[rank_code]),
				"boss_id": "blood_devourer",
				"boss_name": "Pożeracz Krwawego Księżyca",
			}
		)
	)


func _rift_snapshot(state: RiftStateClass) -> Dictionary:
	var rift = state.active_rift
	return {
		"rift_id": rift.rift_id,
		"rank_code": rift.rank_code,
		"theme_id": rift.theme_id,
		"modifier_ids": rift.modifier_ids,
		"discovered_day": rift.discovered_day,
		"expires_day": rift.expires_day,
		"seed": rift.seed,
		"segment_count": rift.segment_count,
		"boss_id": rift.boss_id,
		"boss_name": rift.boss_name,
		"next_spawn_day": state.next_spawn_day,
	}


func _session():
	return NewGameServiceClass.new().create_session("Aria", 1, _rng(1))


func _companion(companion_id: String, display_name: String) -> CompanionStateClass:
	var template_id := "mira" if display_name == "Mira" else "kael"
	var class_code := "pierrot" if template_id == "mira" else "warrior"
	var companion := CompanionStateClass.new(companion_id, template_id, display_name, class_code)
	companion.active = true
	return companion


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng
