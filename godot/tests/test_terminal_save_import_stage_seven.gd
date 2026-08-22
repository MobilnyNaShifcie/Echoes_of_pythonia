extends GutTest

const BuildServiceClass := preload("res://core/companions/companion_build_service.gd")
const CompanionCatalogClass := preload("res://core/companions/companion_catalog.gd")
const CompanionStateClass := preload("res://core/companions/companion_state.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const PartySaveCodecClass := preload("res://core/save/party_save_codec.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")
const SkillCatalogClass := preload("res://core/skills/skill_catalog.gd")
const TerminalSaveV15ImporterClass := preload("res://core/save/terminal_save_v15_importer.gd")
const TerminalSaveV15MapperClass := preload("res://core/save/terminal_save_v15_mapper.gd")
const LoadGameScreenClass := preload("res://ui/screens/load_game/load_game.gd")
const LOAD_GAME_SCENE := preload("res://ui/screens/load_game/load_game.tscn")

var _source_root: String
var _save_root: String
var _source_path: String
var _service: SaveGameServiceClass


func before_each() -> void:
	var suffix := Crypto.new().generate_random_bytes(8).hex_encode()
	_source_root = "user://test_terminal_v15_%s" % suffix
	_save_root = "user://test_stage_seven_%s" % suffix
	_source_path = "%s/save_1.json" % _source_root
	_service = SaveGameServiceClass.new(_save_root)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(_source_root))


func after_each() -> void:
	_remove_tree(_source_root)
	_remove_tree(_save_root)


func test_mapper_preserves_supported_progress_and_maps_stage_eight_world_state() -> void:
	var payload := _terminal_payload()
	payload.player.gold = 347
	payload.quests.completed = ["awakening_missing_recruits"]
	payload.guild.reputation = 25
	payload.guild.milestones = ["quest:awakening_missing_recruits", "boss:azhar"]
	payload.party.companions.append(_terminal_companion())
	payload.expedition_preparation.presets.rift = {
		"configured": true,
		"active_companion_ids": ["kael-imported"],
		"supplies": {"weak_healing_potion": 2},
	}

	var result := _map(payload, 3)

	assert_true(result.ok, result.get("message", ""))
	assert_eq(result.payload.session.save_slot, 3)
	assert_eq(result.payload.session.player.display_name, "Aria")
	assert_eq(result.payload.session.player.gold, 347)
	assert_true(result.payload.session.quest_log.completed.awakening_missing_recruits)
	assert_eq(result.payload.session.guild_milestones, ["boss:azhar"])
	assert_eq(result.payload.session.party.companions[0].companion_id, "kael-imported")
	assert_false(result.payload.session.party.companions[0].hp_initialized)
	assert_false(result.payload.session.party.companions[0].mana_initialized)
	assert_eq(result.payload.session.expedition_preparation.presets.rift.preset_id, "rift")
	assert_eq(result.payload.session.world_encounters.elite_discoveries, ["furious"])
	assert_eq(result.payload.session.world_encounters.elite_miss_streaks, {"twilight_plains": 2})
	assert_eq(result.payload.session.world_encounters.region_boss_respawns, {"azhar": 3})
	assert_true(result.audit.not_migrated.is_empty())
	assert_true("world_encounters" in result.audit.mapped_sections)
	assert_eq(result.audit.normalized[0].values, ["quest:awakening_missing_recruits"])


func test_mapper_accepts_only_exact_terminal_v15_format() -> void:
	var payload := _terminal_payload()
	payload.schema_version = 14
	var old_schema := _map(payload, 1)
	payload = _terminal_payload()
	payload.game_version = "0.24.6"
	var old_game := _map(payload, 1)

	assert_false(old_schema.ok)
	assert_string_contains(old_schema.message, "v15")
	assert_false(old_game.ok)
	assert_string_contains(old_game.message, "v0.24.7")


func test_mapper_rejects_corrupt_terminal_only_state_instead_of_dropping_it() -> void:
	var payload := _terminal_payload()
	payload.elite_discoveries = ["unknown_elite"]
	var elite_result := _map(payload, 1)
	payload = _terminal_payload()
	payload.elite_miss_streaks = {"unknown_region": 2}
	var streak_result := _map(payload, 1)
	payload = _terminal_payload()
	payload.region_boss_respawns = {"unknown_boss": 3}
	var boss_result := _map(payload, 1)

	assert_false(elite_result.ok)
	assert_string_contains(elite_result.message, "typ elity")
	assert_false(streak_result.ok)
	assert_string_contains(streak_result.message, "region")
	assert_false(boss_result.ok)
	assert_string_contains(boss_result.message, "bossa")


func test_terminal_talent_ranks_restore_their_godot_combat_unlocks() -> void:
	var payload := _terminal_payload()
	payload.player.level = 5
	payload.player.character_class = "hunter"
	payload.player.talents = {"hunter_piercing_arrow": 1}
	var mapping := _map(payload, 1)

	assert_true(mapping.ok, mapping.get("message", ""))
	var validation := _service._deserialize_payload(mapping.payload, 1)
	assert_true(validation.ok, validation.get("message", ""))
	assert_true(
		(
			SkillCatalogClass
			. is_unlocked(
				validation.session.player,
				SkillCatalogClass.get_definition("piercing_arrow"),
			)
		)
	)


func test_import_creates_new_copy_and_report_without_touching_source() -> void:
	var original_text := JSON.stringify(_terminal_payload(), "\t", false)
	_write_source(original_text)
	var source_hash := FileAccess.get_sha256(_source_path)
	var importer := TerminalSaveV15ImporterClass.new(_service, [_source_path])

	var result := importer.import_copy(_source_path, 2)

	assert_true(result.ok, result.get("message", ""))
	assert_eq(_read_text(_source_path), original_text)
	assert_eq(FileAccess.get_sha256(_source_path), source_hash)
	assert_true(FileAccess.file_exists(_service.slot_path(2)))
	assert_true(FileAccess.file_exists(result.report_path))
	assert_false(result.report.source.modified)
	assert_eq(result.report.source.sha256_before, source_hash)
	assert_eq(result.report.source.sha256_after, source_hash)
	assert_true(result.report.round_trip_verified)
	assert_true(result.report.audit.not_migrated.is_empty())
	assert_true("world_encounters" in result.report.audit.mapped_sections)


func test_import_refuses_to_overwrite_an_existing_godot_slot() -> void:
	_write_source(JSON.stringify(_terminal_payload()))
	var existing = NewGameServiceClass.new().create_session("Beata", 2)
	assert_true(_service.save_session(existing).ok)
	var destination_hash := FileAccess.get_sha256(_service.slot_path(2))
	var source_hash := FileAccess.get_sha256(_source_path)
	var importer := TerminalSaveV15ImporterClass.new(_service, [_source_path])

	var result := importer.import_copy(_source_path, 2)

	assert_false(result.ok)
	assert_string_contains(result.message, "nie jest pusty")
	assert_eq(FileAccess.get_sha256(_service.slot_path(2)), destination_hash)
	assert_eq(FileAccess.get_sha256(_source_path), source_hash)


func test_importer_discovers_and_inspects_only_explicit_terminal_sources() -> void:
	_write_source(JSON.stringify(_terminal_payload()))
	var missing_path := "%s/save_2.json" % _source_root
	var importer := TerminalSaveV15ImporterClass.new(_service, [_source_path, missing_path])

	var sources := importer.discover_sources()

	assert_eq(sources.size(), 1)
	assert_true(sources[0].ok, sources[0].get("message", ""))
	assert_eq(sources[0].path, _source_path)
	assert_eq(sources[0].source_slot, 1)
	assert_eq(sources[0].player_name, "Aria")
	assert_eq(sources[0].day, 5)


func test_imported_copy_survives_load_save_load_full_cycle() -> void:
	var payload := _terminal_payload()
	payload.party.companions.append(_terminal_companion())
	var direct_mapping := _map(payload, 4)
	assert_true(direct_mapping.ok)
	assert_eq(direct_mapping.payload.session.party.companions[0].level, 10)
	assert_typeof(direct_mapping.payload.session.party.companions[0].relation, TYPE_INT)
	var direct_validation := _service._deserialize_payload(direct_mapping.payload, 4)
	assert_true(direct_validation.ok, direct_validation.get("message", ""))
	_write_source(JSON.stringify(payload, "\t", false))
	var source_hash := FileAccess.get_sha256(_source_path)
	var importer := TerminalSaveV15ImporterClass.new(_service, [_source_path])
	var imported := importer.import_copy(_source_path, 4)
	assert_true(imported.ok, imported.get("message", ""))
	if not imported.ok:
		return

	var first_load := _service.load_session(4)
	assert_true(first_load.ok, first_load.get("message", ""))
	assert_eq(first_load.session.player.display_name, "Aria")
	assert_eq(first_load.session.party.companions.size(), 1)
	assert_eq(first_load.session.party.companions[0].companion_id, "kael-imported")
	assert_false(first_load.session.party.companions[0].hp_initialized)
	assert_eq(first_load.session.world_encounters.elite_discoveries, ["furious"])
	assert_eq(first_load.session.world_encounters.elite_miss_streaks, {"twilight_plains": 2})
	assert_eq(first_load.session.world_encounters.region_boss_respawns, {"azhar": 3})
	var personal_item_count: int = (
		first_load.session.party.companions[0].personal_instance_ids.size()
	)
	assert_gt(personal_item_count, 0)
	assert_true(_service.save_session(first_load.session).ok)
	var second_load := _service.load_session(4)
	assert_true(second_load.ok, second_load.get("message", ""))
	assert_eq(
		second_load.session.party.companions[0].personal_instance_ids.size(),
		personal_item_count,
	)
	assert_eq(second_load.session.party.companions[0].current_hp, 0)
	assert_eq(second_load.session.world_encounters.elite_discoveries, ["furious"])
	assert_eq(second_load.session.world_encounters.elite_miss_streaks, {"twilight_plains": 2})
	assert_eq(second_load.session.world_encounters.region_boss_respawns, {"azhar": 3})
	assert_eq(FileAccess.get_sha256(_source_path), source_hash)


func test_failed_import_leaves_no_copy_or_report() -> void:
	var payload := _terminal_payload()
	payload.player.current_hp = 999
	_write_source(JSON.stringify(payload))
	var source_hash := FileAccess.get_sha256(_source_path)
	var importer := TerminalSaveV15ImporterClass.new(_service, [_source_path])

	var result := importer.import_copy(_source_path, 1)

	assert_false(result.ok)
	assert_false(FileAccess.file_exists(_service.slot_path(1)))
	assert_false(FileAccess.file_exists(_report_path(1)))
	assert_eq(FileAccess.get_sha256(_source_path), source_hash)


func test_load_screen_imports_copy_into_selected_empty_slot_without_terminal() -> void:
	_write_source(JSON.stringify(_terminal_payload()))
	var source_hash := FileAccess.get_sha256(_source_path)
	var paths: Array[String] = [_source_path]
	var screen := LOAD_GAME_SCENE.instantiate() as LoadGameScreenClass
	add_child_autofree(screen)
	screen.configure(_service, paths)

	assert_eq(screen.terminal_source_selector.item_count, 1)
	assert_false(screen.import_button.disabled)
	assert_false(screen.import_button.tooltip_text.is_empty())
	assert_false(screen.slot_selector.tooltip_text.is_empty())
	screen.import_button.pressed.emit()
	assert_true(_service.save_exists(1))
	assert_eq(FileAccess.get_sha256(_source_path), source_hash)
	assert_string_contains(screen.import_details_label.text, "Oryginał pozostał bez zmian")


func _map(payload: Dictionary, slot: int) -> Dictionary:
	return (
		TerminalSaveV15MapperClass
		. map_to_godot(
			payload,
			slot,
			SaveGameServiceClass.FORMAT_ID,
			SaveGameServiceClass.SCHEMA_VERSION,
		)
	)


func _terminal_payload() -> Dictionary:
	return {
		"schema_version": 15,
		"game_version": "0.24.7",
		"player":
		{
			"name": "Aria",
			"level": 0,
			"experience": 0,
			"gold": 0,
			"rubies": 0,
			"unspent_attribute_points": 0,
			"carry_upgrade_level": 0,
			"character_class": "none",
			"current_hp": 20,
			"current_mana": 0,
			"attributes":
			{
				"strength": 0,
				"vitality": 0,
				"intelligence": 0,
				"dexterity": 0,
				"endurance": 0,
				"luck": 0,
			},
			"passive_masteries": [],
			"passive_specializations": {},
			"talents": {},
			"unlocked_class_paths": [],
			"discovered_hunter_combos": [],
			"passives":
			{
				"attack_speed": 0,
				"critical_damage": 0,
				"health_regen": 0,
				"increased_attack": 0,
			},
			"achievements": {"unlocked": [], "equipped_title": "Wędrowiec"},
			"inventory": {"stacks": {}, "equipment_items": []},
			"equipment":
			{
				"weapon": _equipment("starter_sword", "terminal-starter-sword"),
				"chest": _equipment("worn_leather_armor", "terminal-worn-armor"),
			},
		},
		"world":
		{
			"current_location_id": "twilight_plains",
			"current_city_id": "varenhold",
			"day": 5,
			"hour": 8,
			"weather": "sunny",
			"weather_remaining_hours": 6,
			"camp_rest_available": true,
			"last_inn_rest_day": 0,
		},
		"quests": {"active": {}, "completed": []},
		"contracts":
		{
			"daily_date": "",
			"daily_contracts": [],
			"daily_claimed": [],
			"weekly_key": "",
			"weekly_contract": null,
			"weekly_claimed": false,
			"progress": {},
		},
		"elite_discoveries": ["furious"],
		"elite_miss_streaks": {"twilight_plains": 2},
		"region_boss_respawns": {"azhar": 3},
		"guild": {"reputation": 0, "milestones": []},
		"black_market":
		{
			"unlocked": false,
			"informant_last_check_day": 0,
			"informant_failed_checks": 0,
			"informant_present_day": 0,
			"rotation_key": "",
			"offers": [],
			"purchased_offer_ids": [],
			"buy_negotiated_prices": {},
			"sale_negotiated_prices": {},
		},
		"guild_storage": {"stacks": {}, "equipment_items": []},
		"adventure_log": ["Dzień 5, 08:00 — Zapis testowy Stage 7."],
		"party":
		{
			"companions": [],
			"dismissed_companions": [],
			"candidates_day": 0,
			"candidates": [],
			"messages": [],
			"last_message_day": 0,
			"seen_banter": [],
			"fallen": [],
		},
		"rifts":
		{
			"active_rift": null,
			"expedition": null,
			"next_spawn_day": 2,
			"last_resolution_day": 0,
			"completed_total": 0,
			"completed_by_rank": {},
			"last_notice": "",
		},
		"expedition_preparation":
		{
			"selected_location_id": "",
			"presets":
			{
				"solo": _terminal_preset(),
				"boss": _terminal_preset(),
				"dungeon": _terminal_preset(),
				"rift": _terminal_preset(),
			},
		},
	}


func _terminal_companion() -> Dictionary:
	var definition = CompanionCatalogClass.get_definition("kael")
	var companion := CompanionStateClass.new(
		"kael-imported", "kael", definition.display_name, "warrior"
	)
	companion.level = 10
	companion.path_id = "warrior_assault"
	assert_true(BuildServiceClass.ensure_initial_build(companion))
	companion.active = true
	var session = NewGameServiceClass.new().create_session("Builder", 1)
	session.party.companions.append(companion)
	var serialized: Dictionary = PartySaveCodecClass.serialize(session.party).companions[0]
	assert_eq(serialized.level, 10)
	assert_typeof(serialized.relation, TYPE_INT)
	serialized.erase("hp_initialized")
	serialized.erase("mana_initialized")
	return serialized


func _equipment(item_id: String, instance_id: String) -> Dictionary:
	return {
		"item_id": item_id,
		"upgrade_level": 0,
		"instance_id": instance_id,
		"item_power": 1,
		"affixes": [],
		"average_damage_percent": null,
	}


func _terminal_preset() -> Dictionary:
	return {"configured": false, "active_companion_ids": [], "supplies": {}}


func _write_source(text: String) -> void:
	var file := FileAccess.open(_source_path, FileAccess.WRITE)
	assert_not_null(file)
	file.store_string(text)
	file.flush()
	file.close()


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_not_null(file)
	var text := file.get_as_text()
	file.close()
	return text


func _report_path(slot: int) -> String:
	return _service.slot_path(slot).trim_suffix(".json") + "_migration_report.json"


func _remove_tree(path: String) -> void:
	var directory := DirAccess.open(path)
	if directory != null:
		for file_name in directory.get_files():
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path.path_join(file_name)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
