extends GutTest

const BuildServiceClass := preload("res://core/companions/companion_build_service.gd")
const CandidateClass := preload("res://core/companions/companion_candidate.gd")
const CompanionCatalogClass := preload("res://core/companions/companion_catalog.gd")
const CompanionStateClass := preload("res://core/companions/companion_state.gd")
const FallenCompanionClass := preload("res://core/companions/fallen_companion.gd")
const MessageClass := preload("res://core/companions/party_message.gd")
const EnemyClass := preload("res://core/combat/enemy.gd")
const PartyCombatEngineClass := preload("res://core/combat/party_combat_engine.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const RiftCatalogClass := preload("res://core/rifts/rift_catalog.gd")
const RiftExpeditionClass := preload("res://core/rifts/rift_expedition.gd")
const RiftInstanceClass := preload("res://core/rifts/rift_instance.gd")
const RiftSaveCodecClass := preload("res://core/save/rift_save_codec.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")


func test_companion_save_guards_match_terminal_progression_contract() -> void:
	var session = _session()
	session.party.companions.append(
		_built_companion("kael-audit", "kael", "warrior", 12, "warrior_heavy_knight")
	)
	var service := SaveGameServiceClass.new("user://stage_six_k_not_written")

	var payload := service._serialize_session(session)
	payload.session.party.companions[0].level = 4
	var invalid_level := service._deserialize_payload(payload, 1)
	assert_false(invalid_level.ok)
	assert_string_contains(invalid_level.message, "poziom")

	payload = service._serialize_session(session)
	payload.session.party.companions[0].relation = 101
	var invalid_relation := service._deserialize_payload(payload, 1)
	assert_false(invalid_relation.ok)
	assert_string_contains(invalid_relation.message, "relację")

	payload = service._serialize_session(session)
	payload.session.party.companions[0].path_id = "mage_elements"
	var invalid_path := service._deserialize_payload(payload, 1)
	assert_false(invalid_path.ok)
	assert_string_contains(invalid_path.message, "Ścieżka")

	payload = service._serialize_session(session)
	payload.session.party.companions[0].talents = {"unknown_talent": 1}
	var unknown_talent := service._deserialize_payload(payload, 1)
	assert_false(unknown_talent.ok)
	assert_string_contains(unknown_talent.message, "talent")

	payload = service._serialize_session(session)
	payload.session.party.companions[0].talents = {"heavy_knight_core": 0}
	var zero_rank := service._deserialize_payload(payload, 1)
	assert_false(zero_rank.ok)
	assert_string_contains(zero_rank.message, "talent")


func test_resource_initialization_is_unambiguous_and_schema_fifteen_migrates() -> void:
	var companion := _built_companion("elyra-resources", "elyra", "mage", 12, "mage_elements")
	var limits := BuildServiceClass.resource_limits(companion)
	assert_false(companion.hp_initialized)
	assert_false(companion.mana_initialized)
	assert_eq(BuildServiceClass.resolved_resources(companion).current_hp, limits.max_hp)
	assert_eq(BuildServiceClass.resolved_resources(companion).current_mana, limits.max_mana)

	BuildServiceClass.sync_resources(companion, 7, 0)
	assert_true(companion.hp_initialized)
	assert_true(companion.mana_initialized)
	assert_eq(BuildServiceClass.resolved_resources(companion).current_hp, 7)
	assert_eq(BuildServiceClass.resolved_resources(companion).current_mana, 0)

	var session = _session()
	session.party.companions.append(companion)
	var service := SaveGameServiceClass.new("user://stage_six_k_resources_not_written")
	var payload := service._serialize_session(session)
	assert_eq(payload.schema_version, 16)
	var loaded := service._deserialize_payload(payload, 1)
	assert_true(loaded.ok, loaded.message)
	var restored = loaded.session.party.companions[0]
	assert_true(restored.mana_initialized)
	assert_eq(restored.current_mana, 0)
	assert_eq(BuildServiceClass.resolved_resources(restored).current_mana, 0)

	payload = service._serialize_session(session)
	payload.schema_version = 15
	payload.session.party.companions[0].erase("hp_initialized")
	payload.session.party.companions[0].erase("mana_initialized")
	var migrated := service._deserialize_payload(payload, 1)
	assert_true(migrated.ok, migrated.message)
	var legacy = migrated.session.party.companions[0]
	assert_true(legacy.hp_initialized)
	assert_false(legacy.mana_initialized)
	assert_eq(BuildServiceClass.resolved_resources(legacy).current_hp, 7)
	assert_eq(BuildServiceClass.resolved_resources(legacy).current_mana, limits.max_mana)


func test_party_load_keeps_last_sixty_messages_and_rejects_identity_collisions() -> void:
	var session = _session()
	var companion := _built_companion("kael-messages", "kael", "warrior", 10, "warrior_assault")
	session.party.companions.append(companion)
	for day in range(1, 66):
		session.party.messages.append(
			MessageClass.new(day, companion.companion_id, companion.display_name, "Dzień %d" % day)
		)
	var service := SaveGameServiceClass.new("user://stage_six_k_messages_not_written")
	var loaded := service._deserialize_payload(service._serialize_session(session), 1)
	assert_true(loaded.ok, loaded.message)
	assert_eq(loaded.session.party.messages.size(), 60)
	assert_eq(loaded.session.party.messages[0].day, 6)
	assert_eq(loaded.session.party.messages[-1].day, 65)

	var payload := service._serialize_session(session)
	(
		payload
		. session
		. party
		. fallen
		. append(
			{
				"companion_id": companion.companion_id,
				"name": companion.display_name,
				"class_code": companion.class_code,
				"level": companion.level,
				"day": 1,
				"cause": "Test",
				"rift_rank": "F",
			}
		)
	)
	var collision := service._deserialize_payload(payload, 1)
	assert_false(collision.ok)
	assert_string_contains(collision.message, "Tablica Poległych")


func test_transient_downed_timer_persists_one_hp_instead_of_a_zero_sentinel() -> void:
	var session = _session()
	var companion := _built_companion("downed-save", "kael", "warrior", 12, "warrior_assault")
	BuildServiceClass.sync_resources(companion, 5, 0)
	var enemy := (
		EnemyClass
		. new(
			{
				"enemy_id": "audit-enemy",
				"display_name": "Audytor",
				"max_hp": 999,
				"attack": 0,
				"defense": 0,
			}
		)
	)
	var combat := PartyCombatEngineClass.new(session.player, [companion], enemy, _rng(7))
	var fighter = combat.companion_fighters[0]
	fighter.profile.stats.current_hp = 0
	fighter.downed_timer = 3
	var report = combat.player_basic_attack()

	assert_eq(report.downed_timers[companion.companion_id], 2)
	assert_eq(fighter.profile.stats.current_hp, 1)
	assert_eq(companion.current_hp, 1)
	assert_true(companion.hp_initialized)


func test_rift_codec_rejects_states_that_runtime_cannot_create() -> void:
	var state = _valid_rift_state("F")
	var data := RiftSaveCodecClass.serialize(state)
	data.active_rift.segment_count += 1
	assert_false(RiftSaveCodecClass.deserialize(data).ok)

	data = RiftSaveCodecClass.serialize(state)
	data.active_rift.theme_name = "Fałszywy motyw"
	assert_false(RiftSaveCodecClass.deserialize(data).ok)

	data = RiftSaveCodecClass.serialize(state)
	data.active_rift.boss_id = "unknown_boss"
	assert_false(RiftSaveCodecClass.deserialize(data).ok)

	data = RiftSaveCodecClass.serialize(state)
	data.active_rift.closed = true
	assert_false(RiftSaveCodecClass.deserialize(data).ok)

	data = RiftSaveCodecClass.serialize(state)
	data.expedition.camp_visits = 1
	assert_false(RiftSaveCodecClass.deserialize(data).ok)

	data = RiftSaveCodecClass.serialize(state)
	data.completed_total = 1
	assert_false(RiftSaveCodecClass.deserialize(data).ok)


func test_full_stage_six_state_round_trips_without_loss_or_terminal_import() -> void:
	var session = _session()
	session.day = 10
	var kael := _built_companion("kael-roundtrip", "kael", "warrior", 18, "warrior_heavy_knight")
	var mira := _built_companion("mira-roundtrip", "mira", "pierrot", 17, "pierrot_chaos")
	BuildServiceClass.sync_resources(kael, 19, 0)
	BuildServiceClass.sync_resources(mira, 11, 4)
	kael.active = true
	mira.active = true
	session.party.companions.assign([kael, mira])

	var dismissed := _built_companion("nessa-return", "nessa", "hunter", 16, "hunter_volley")
	dismissed.dismissed_day = 3
	dismissed.relation = -9
	session.party.dismissed_companions.append(dismissed)
	var returning := CandidateClass.new("return-nessa-return-10", dismissed, 10, 60)
	returning.returning = true
	session.party.candidates.append(returning)
	session.party.candidates_day = 10
	session.party.messages.append(MessageClass.new(10, kael.companion_id, "Kael", "Gotowy."))
	session.party.fallen.append(
		FallenCompanionClass.new("elyra-fallen", "Elyra", "mage", 20, 9, "Egzekucja", "C")
	)

	var preset = session.expedition_preparation.preset_for("rift")
	preset.configured = true
	preset.active_companion_ids.assign([kael.companion_id, mira.companion_id])
	preset.supplies = {"weak_healing_potion": 3}
	session.expedition_preparation.selected_location_id = session.current_location_id

	var state = _valid_rift_state("C")
	state.active_rift.discovered_day = 7
	state.active_rift.expires_day = 9
	state.expedition = (
		RiftExpeditionClass
		. new(
			state.active_rift.rift_id,
			5,
			[kael.companion_id, mira.companion_id, "elyra-fallen"],
			8,
		)
	)
	state.expedition.camp_visits = 1
	state.completed_total = 4
	state.completed_by_rank = {"F": 2, "E": 1, "D": 1}
	session.rifts = state

	var service := SaveGameServiceClass.new("user://stage_six_k_roundtrip_not_written")
	var payload := service._serialize_session(session)
	var loaded := service._deserialize_payload(payload, 1)
	assert_true(loaded.ok, loaded.message)
	var second_payload := service._serialize_session(loaded.session)
	assert_eq(second_payload.session.party, payload.session.party)
	assert_eq(second_payload.session.expedition_preparation, payload.session.expedition_preparation)
	assert_eq(second_payload.session.rifts, payload.session.rifts)
	assert_eq(loaded.session.party.companions[0].current_mana, 0)
	assert_true(loaded.session.party.companions[0].mana_initialized)
	assert_eq(loaded.session.rifts.expedition.party_companion_ids[-1], "elyra-fallen")
	assert_eq(SaveGameServiceClass.FORMAT_ID, "echoes_of_pythonia_godot_migration")

	second_payload.session.party.fallen.clear()
	var missing_bound_companion := service._deserialize_payload(second_payload, 1)
	assert_false(missing_bound_companion.ok)
	assert_string_contains(missing_bound_companion.message, "spoza rosteru")


func _session():
	return NewGameServiceClass.new().create_session("Aria", 1, _rng(1))


func _built_companion(
	companion_id: String, template_id: String, class_code: String, level: int, path_id: String
) -> CompanionStateClass:
	var definition = CompanionCatalogClass.get_definition(template_id)
	var companion := CompanionStateClass.new(
		companion_id, template_id, definition.display_name, class_code
	)
	companion.level = level
	companion.path_id = path_id
	assert_true(BuildServiceClass.ensure_initial_build(companion), companion_id)
	return companion


func _valid_rift_state(rank_code: String):
	var state = preload("res://core/rifts/rift_state.gd").new()
	var theme: Dictionary = RiftCatalogClass.THEMES.blood_moon
	var modifier_count := (
		1
		+ (1 if RiftCatalogClass.rank_index(rank_code) >= 3 else 0)
		+ (1 if RiftCatalogClass.rank_index(rank_code) >= 5 else 0)
	)
	var modifier_ids: Array[String] = []
	for index in modifier_count:
		modifier_ids.append(RiftCatalogClass.MODIFIER_ORDER[index])
	state.active_rift = (
		RiftInstanceClass
		. new(
			{
				"rift_id": "audit-%s" % rank_code,
				"rank_code": rank_code,
				"theme_id": "blood_moon",
				"theme_name": theme.name,
				"modifier_ids": modifier_ids,
				"discovered_day": 1,
				"expires_day": 4,
				"seed": 777,
				"segment_count": int(RiftCatalogClass.SEGMENTS[rank_code]),
				"boss_id": theme.bosses[0][0],
				"boss_name": theme.bosses[0][1],
			}
		)
	)
	var party_ids: Array[String] = ["one", "two"]
	if int(RiftCatalogClass.MIN_COMPANIONS[rank_code]) == 3:
		party_ids.append("three")
	state.expedition = RiftExpeditionClass.new(state.active_rift.rift_id, 0, party_ids, 1)
	return state


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng
