extends GutTest

const CompanionStateClass := preload("res://core/companions/companion_state.gd")
const ExpeditionPreparationSaveCodecClass := preload(
	"res://core/save/expedition_preparation_save_codec.gd"
)
const ExpeditionPreparationServiceClass := preload(
	"res://core/world/expedition_preparation_service.gd"
)
const ExpeditionPreparationStateClass := preload("res://core/world/expedition_preparation_state.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")
const PREPARATION_SCENE := preload(
	"res://ui/screens/expedition_preparation/expedition_preparation.tscn"
)
const APP_SCENE := preload("res://scenes/app/app.tscn")
const WORLD_MAP_SCENE := preload("res://ui/screens/world_map/world_map.tscn")


func test_stage_six_d_has_four_terminal_presets() -> void:
	assert_eq(
		ExpeditionPreparationServiceClass.PRESET_NAMES,
		{
			"solo": "SOLO",
			"boss": "BOSS",
			"dungeon": "DUNGEON",
			"rift": "SZCZELINA",
		},
	)
	var state := ExpeditionPreparationStateClass.new()
	assert_eq(state.presets.size(), 4)
	for preset_id: String in ExpeditionPreparationServiceClass.PRESET_ORDER:
		assert_false(state.preset_for(preset_id).configured)


func test_preset_saves_active_party_and_solo_always_clears_composition() -> void:
	var session = _session()
	var first: CompanionStateClass = _companion("companion_a", "Aria", true)
	var second: CompanionStateClass = _companion("companion_b", "Borin", true)
	session.party.companions.assign([first, second])

	var saved := (
		ExpeditionPreparationServiceClass
		. save_preset(
			session.expedition_preparation,
			"boss",
			session.party,
			{"strong_healing_potion": 5},
		)
	)
	assert_true(saved.ok)
	assert_eq(
		session.expedition_preparation.preset_for("boss").active_companion_ids,
		["companion_a", "companion_b"],
	)
	assert_eq(
		session.expedition_preparation.preset_for("boss").supplies,
		{"strong_healing_potion": 5},
	)

	assert_true(
		(
			ExpeditionPreparationServiceClass
			. save_preset(
				session.expedition_preparation,
				"solo",
				session.party,
				{"weak_healing_potion": 2},
			)
			. ok
		)
	)
	assert_true(session.expedition_preparation.preset_for("solo").active_companion_ids.is_empty())


func test_preset_uses_current_day_when_a_companion_has_recovered() -> void:
	var session = _session()
	session.day = 10
	var recovered: CompanionStateClass = _companion("companion_a", "Aria", true)
	recovered.injury_until_day = 9
	session.party.companions.append(recovered)
	var result := (
		ExpeditionPreparationServiceClass
		. save_preset(
			session.expedition_preparation,
			"boss",
			session.party,
			{},
			session.day,
		)
	)
	assert_true(result.ok)
	assert_eq(
		session.expedition_preparation.preset_for("boss").active_companion_ids,
		["companion_a"],
	)


func test_preset_rejects_negative_and_non_consumable_targets() -> void:
	var session = _session()
	assert_false(
		(
			ExpeditionPreparationServiceClass
			. save_preset(
				session.expedition_preparation,
				"solo",
				session.party,
				{"weak_healing_potion": -1},
			)
			. ok
		)
	)
	assert_false(
		(
			ExpeditionPreparationServiceClass
			. save_preset(
				session.expedition_preparation,
				"solo",
				session.party,
				{"wolf_fur": 1},
			)
			. ok
		)
	)


func test_apply_preset_withdraws_only_missing_quantity_and_reports_shortage() -> void:
	var session = _session()
	session.player.inventory.add("strong_healing_potion", 2)
	session.guild_storage.inventory.add("strong_healing_potion", 2)
	(
		ExpeditionPreparationServiceClass
		. save_preset(
			session.expedition_preparation,
			"dungeon",
			session.party,
			{"strong_healing_potion": 5},
		)
	)

	var result := ExpeditionPreparationServiceClass.apply_preset(session, "dungeon")
	assert_true(result.ok)
	assert_eq(session.player.inventory.count("strong_healing_potion"), 4)
	assert_eq(session.guild_storage.inventory.count("strong_healing_potion"), 0)
	assert_eq(result.withdrawn, {"strong_healing_potion": 2})
	assert_eq(result.missing, {"strong_healing_potion": 1})


func test_apply_preset_is_atomic_when_projected_weight_is_over_capacity() -> void:
	var session = _session()
	var companion: CompanionStateClass = _companion("companion_a", "Aria", true)
	session.party.companions.append(companion)
	session.player.inventory.add("wolf_fur", 1000)
	session.guild_storage.inventory.add("weak_healing_potion", 1)
	(
		ExpeditionPreparationServiceClass
		. save_preset(
			session.expedition_preparation,
			"solo",
			session.party,
			{"weak_healing_potion": 1},
		)
	)

	var result := ExpeditionPreparationServiceClass.apply_preset(session, "solo")
	assert_false(result.ok)
	assert_true(companion.active, "Skład nie może zmienić się przed walidacją udźwigu.")
	assert_eq(session.guild_storage.inventory.count("weak_healing_potion"), 1)
	assert_eq(session.player.inventory.count("weak_healing_potion"), 0)


func test_apply_preset_activates_available_and_reports_injured_companion() -> void:
	var session = _session()
	var available: CompanionStateClass = _companion("companion_a", "Aria", false)
	var injured: CompanionStateClass = _companion("companion_b", "Borin", false)
	injured.injury_until_day = session.day + 2
	session.party.companions.assign([available, injured])
	var preset = session.expedition_preparation.preset_for("rift")
	preset.configured = true
	preset.active_companion_ids.assign([available.companion_id, injured.companion_id])

	var result := ExpeditionPreparationServiceClass.apply_preset(session, "rift")
	assert_true(result.ok)
	assert_true(available.active)
	assert_false(injured.active)
	assert_eq(result.activated_companions, ["Aria"])
	assert_eq(result.unavailable_companions, ["Borin"])


func test_supply_withdrawal_checks_category_storage_and_projected_weight() -> void:
	var session = _session()
	session.guild_storage.inventory.add("weak_healing_potion", 3)
	assert_true(
		ExpeditionPreparationServiceClass.withdraw_supply(session, "weak_healing_potion", 2).ok
	)
	assert_eq(session.player.inventory.count("weak_healing_potion"), 2)
	assert_eq(session.guild_storage.inventory.count("weak_healing_potion"), 1)
	assert_false(ExpeditionPreparationServiceClass.withdraw_supply(session, "wolf_fur", 1).ok)

	session.player.inventory.add("wolf_fur", 994)
	var blocked := ExpeditionPreparationServiceClass.withdraw_supply(
		session, "weak_healing_potion", 1
	)
	assert_false(blocked.ok)
	assert_eq(session.guild_storage.inventory.count("weak_healing_potion"), 1)


func test_consumable_is_not_spent_without_effect_and_restores_before_departure() -> void:
	var session = _session()
	session.player.inventory.add("weak_healing_potion", 2)
	var no_effect := ExpeditionPreparationServiceClass.use_supply(session, "weak_healing_potion")
	assert_false(no_effect.ok)
	assert_eq(session.player.inventory.count("weak_healing_potion"), 2)

	session.player.stats.current_hp = 5
	var used := ExpeditionPreparationServiceClass.use_supply(session, "weak_healing_potion")
	assert_true(used.ok)
	assert_eq(used.healed_hp, 15)
	assert_eq(session.player.stats.current_hp, session.player.stats.max_hp)
	assert_eq(session.player.inventory.count("weak_healing_potion"), 1)


func test_warnings_match_terminal_low_hp_healing_overload_and_injury_rules() -> void:
	var session = _session()
	session.player.stats.current_hp = 1
	var companion: CompanionStateClass = _companion("companion_a", "Aria", false)
	companion.injury_until_day = session.day + 1
	session.party.companions.append(companion)
	session.player.inventory.add("wolf_fur", 1001)

	var values := ExpeditionPreparationServiceClass.warnings(session)
	assert_true(values.any(func(value: String) -> bool: return "Niskie PŻ" in value))
	assert_true(values.any(func(value: String) -> bool: return "Brak mikstur" in value))
	assert_true(values.any(func(value: String) -> bool: return value.begins_with("PRZECIĄŻENIE")))
	assert_true(values.any(func(value: String) -> bool: return "Aria" in value))


func test_departure_requires_target_blocks_overload_and_confirms_other_warnings() -> void:
	var session = _session()
	assert_false(ExpeditionPreparationServiceClass.departure_status(session).ok)
	assert_true(
		(
			ExpeditionPreparationServiceClass
			. select_location(
				session.expedition_preparation,
				"black_forest",
				session.known_region_ids,
			)
			. ok
		)
	)

	var warning := ExpeditionPreparationServiceClass.departure_status(session)
	assert_false(warning.ok)
	assert_true(warning.needs_confirmation)
	var accepted := ExpeditionPreparationServiceClass.departure_status(session, true)
	assert_true(accepted.ok)
	assert_eq(accepted.region_id, "black_forest")
	assert_eq(session.current_location_id, "black_forest")

	session.player.inventory.add("wolf_fur", 1001)
	var overloaded := ExpeditionPreparationServiceClass.departure_status(session, true)
	assert_false(overloaded.ok)
	assert_false(overloaded.needs_confirmation)


func test_preparation_codec_round_trip_preserves_target_party_and_supplies() -> void:
	var session = _session()
	var companion: CompanionStateClass = _companion("companion_a", "Aria", true)
	session.party.companions.append(companion)
	ExpeditionPreparationServiceClass.select_location(
		session.expedition_preparation, "ice_coast", session.known_region_ids
	)
	(
		ExpeditionPreparationServiceClass
		. save_preset(
			session.expedition_preparation,
			"boss",
			session.party,
			{"strong_healing_potion": 4},
		)
	)

	var data := ExpeditionPreparationSaveCodecClass.serialize(session.expedition_preparation)
	var restored := ExpeditionPreparationSaveCodecClass.deserialize(data, session.known_region_ids)
	assert_true(restored.ok)
	assert_eq(restored.state.selected_location_id, "ice_coast")
	assert_eq(
		restored.state.preset_for("boss").active_companion_ids,
		["companion_a"],
	)
	assert_eq(
		restored.state.preset_for("boss").supplies,
		{"strong_healing_potion": 4},
	)


func test_full_save_load_round_trip_preserves_stage_six_d_state() -> void:
	var session = _session()
	ExpeditionPreparationServiceClass.select_location(
		session.expedition_preparation, "silentwater_marshes", session.known_region_ids
	)
	(
		ExpeditionPreparationServiceClass
		. save_preset(
			session.expedition_preparation,
			"dungeon",
			session.party,
			{"hunter_provisions": 3, "weak_healing_potion": 2},
			session.day,
		)
	)
	var service := SaveGameServiceClass.new("user://stage_six_d_not_written")
	var loaded := service._deserialize_payload(service._serialize_session(session), 1)
	assert_true(loaded.ok, loaded.message)
	assert_eq(
		loaded.session.expedition_preparation.selected_location_id,
		"silentwater_marshes",
	)
	assert_eq(
		loaded.session.expedition_preparation.preset_for("dungeon").supplies,
		{"hunter_provisions": 3, "weak_healing_potion": 2},
	)


func test_schema_thirteen_migrates_to_fourteen_with_empty_preparation() -> void:
	var service := SaveGameServiceClass.new()
	var session = _session()
	var payload := service._serialize_session(session)
	payload.schema_version = 13
	payload.session.erase("expedition_preparation")

	var restored := service._deserialize_payload(payload, session.save_slot)
	assert_true(restored.ok)
	assert_eq(SaveGameServiceClass.SCHEMA_VERSION, 16)
	assert_eq(restored.session.expedition_preparation.selected_location_id, "")
	assert_eq(restored.session.expedition_preparation.presets.size(), 4)


func test_codec_rejects_unknown_target_and_free_or_invalid_supplies() -> void:
	var session = _session()
	var data := ExpeditionPreparationSaveCodecClass.empty_data()
	data.selected_location_id = "unknown_region"
	assert_false(ExpeditionPreparationSaveCodecClass.deserialize(data, session.known_region_ids).ok)

	data = ExpeditionPreparationSaveCodecClass.empty_data()
	data.presets.solo.configured = true
	data.presets.solo.supplies = {"weak_healing_potion": 0}
	assert_false(ExpeditionPreparationSaveCodecClass.deserialize(data, session.known_region_ids).ok)


func test_preparation_screen_renders_full_stage_six_d_flow_and_emits_departure() -> void:
	var session = _session()
	session.player.inventory.add("weak_healing_potion", 1)
	var screen = PREPARATION_SCENE.instantiate()
	add_child_autofree(screen)
	screen.configure(session)

	assert_eq(screen.target_selector.item_count, session.known_region_ids.size() + 1)
	assert_eq(screen.preset_selector.item_count, 4)
	assert_true("SOLO" in screen.party_label.text)
	assert_true("Udźwig" in screen.carry_label.text)

	screen.target_selector.select(1)
	screen.target_selector.item_selected.emit(1)
	watch_signals(screen)
	screen.depart_button.pressed.emit()
	assert_signal_emitted(screen, "departure_requested")


func test_app_routes_preparation_without_reusing_the_old_city_placeholder() -> void:
	var session = _session()
	session.prologue_completed = true
	var app = APP_SCENE.instantiate()
	add_child_autofree(app)
	app._on_session_created(session)
	app._show_expedition_preparation()
	await get_tree().process_frame
	assert_eq(app.screen_host.get_child_count(), 1)
	assert_true(app.screen_host.get_child(0) is ExpeditionPreparationScreen)


func test_departure_opens_the_prepared_region_without_allowing_a_target_swap() -> void:
	var session = _session()
	var world_map = WORLD_MAP_SCENE.instantiate()
	add_child_autofree(world_map)
	world_map.configure(session, "black_forest")
	await get_tree().process_frame
	var selected: int = world_map.region_list.get_selected_items()[0]
	assert_eq(world_map.region_list.get_item_metadata(selected), "black_forest")
	for index in world_map.region_list.item_count:
		if world_map.region_list.get_item_metadata(index) == "black_forest":
			assert_false(world_map.region_list.is_item_disabled(index))
		else:
			assert_true(world_map.region_list.is_item_disabled(index))


func _session():
	return NewGameServiceClass.new().create_session("PrepTester", 1)


func _companion(companion_id: String, display_name: String, active: bool) -> CompanionStateClass:
	var companion := (
		CompanionStateClass
		. new(
			companion_id,
			"cassian",
			display_name,
			"warrior",
		)
	)
	companion.active = active
	return companion
