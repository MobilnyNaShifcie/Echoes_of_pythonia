extends GutTest

const CompanionBuildServiceClass := preload("res://core/companions/companion_build_service.gd")
const CompanionCatalogClass := preload("res://core/companions/companion_catalog.gd")
const CompanionStateClass := preload("res://core/companions/companion_state.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const PartyCombatEngineClass := preload("res://core/combat/party_combat_engine.gd")
const PartyCombatRoundResultClass := preload("res://core/combat/party_combat_round_result.gd")
const RiftCatalogClass := preload("res://core/rifts/rift_catalog.gd")
const RiftExpeditionServiceClass := preload("res://core/rifts/rift_expedition_service.gd")
const RiftInstanceClass := preload("res://core/rifts/rift_instance.gd")
const RiftLifecycleServiceClass := preload("res://core/rifts/rift_lifecycle_service.gd")
const RiftSegmentServiceClass := preload("res://core/rifts/rift_segment_service.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")
const RIFT_BOARD_SCENE := preload("res://ui/screens/rift_board/rift_board.tscn")


func test_segment_schedule_preserves_terminal_camps_midpoint_and_boss() -> void:
	for rank_code: String in RiftCatalogClass.RANKS:
		var rift := _rift("schedule-" + rank_code, rank_code, 771)
		assert_eq(
			RiftSegmentServiceClass.segment_kind(rift, rift.segment_count - 1),
			"boss",
			rank_code,
		)
		var midpoint := int(rift.segment_count / 2.0)
		var expected_midpoint := (
			"camp" if midpoint in RiftSegmentServiceClass.CAMP_SEGMENT_INDICES else "miniboss"
		)
		assert_eq(
			RiftSegmentServiceClass.segment_kind(rift, midpoint), expected_midpoint, rank_code
		)
		for camp_index: int in RiftSegmentServiceClass.CAMP_SEGMENT_INDICES:
			if camp_index < rift.segment_count - 1 and camp_index != int(rift.segment_count / 2.0):
				assert_eq(RiftSegmentServiceClass.segment_kind(rift, camp_index), "camp")


func test_regular_segment_and_authored_event_are_stable_inside_godot() -> void:
	var rift := _rift("stable", "C", 424242)
	var first_kinds: Array[String] = []
	var second_kinds: Array[String] = []
	for index in rift.segment_count:
		first_kinds.append(RiftSegmentServiceClass.segment_kind(rift, index))
		second_kinds.append(RiftSegmentServiceClass.segment_kind(rift, index))
	assert_eq(first_kinds, second_kinds)
	var event_index := _find_segment(rift, "event")
	assert_gte(event_index, 0)
	var first_event := RiftSegmentServiceClass.event_text(rift, event_index)
	var second_event := RiftSegmentServiceClass.event_text(rift, event_index)
	assert_eq(first_event, second_event)
	assert_true(first_event.title in _event_titles())


func test_enemy_scaling_and_anomalies_match_terminal_rules() -> void:
	var rift := _rift("scaled", "C", 123)
	rift.modifier_ids.assign(["hungry", "violent", "armored", "mana_static"])
	var enemy = RiftSegmentServiceClass.create_enemy(rift, 20, 0, "battle")
	assert_eq(enemy.max_hp, 1688)
	assert_eq(enemy.attack, 59)
	assert_eq(enemy.defense, 11)
	assert_eq(enemy.rank, "normal")
	assert_eq(enemy.enemy_id, "scaled-0-battle")
	assert_almost_eq(RiftSegmentServiceClass.mana_cost_multiplier(rift), 1.15, 0.0001)
	var repeated = RiftSegmentServiceClass.create_enemy(rift, 20, 0, "battle")
	assert_eq(repeated.display_name, enemy.display_name)
	assert_eq(repeated.max_hp, enemy.max_hp)


func test_start_combat_uses_bound_survivors_and_party_combat_engine() -> void:
	var session = _session_with_party()
	_start_expedition(session, _rift("party", "F", 81))
	var combat_index := _find_combat_segment(session.rifts.active_rift)
	session.rifts.expedition.segment_index = combat_index
	var excluded = session.party.companion_by_id("elyra")
	excluded.injury_until_day = session.day + 3

	var result := RiftExpeditionServiceClass.start_combat(session)

	assert_true(result.ok, str(result.get("message", "")))
	assert_true(result.engine is PartyCombatEngineClass)
	assert_eq(result.engine.rift_rank_code, "F")
	assert_eq(result.engine.companions.size(), 2)
	assert_eq(
		result.engine.companions.map(func(value): return value.companion_id),
		["kael", "mira"],
	)


func test_event_advances_exactly_one_segment_without_rewards() -> void:
	var session = _session_with_party()
	var rift := _rift("event", "C", _seed_with_kind("C", "event"))
	_start_expedition(session, rift)
	var gold_before: int = session.player.gold

	var result := RiftExpeditionServiceClass.resolve_event(session)

	assert_true(result.ok, result.message)
	assert_eq(result.outcome, RiftExpeditionServiceClass.OUTCOME_SEGMENT_COMPLETED)
	assert_eq(session.rifts.expedition.segment_index, 1)
	assert_eq(session.player.gold, gold_before)
	assert_true(_event_titles().any(func(title: String) -> bool: return title in result.title))


func test_camp_restores_quarter_resources_and_persists_the_segment() -> void:
	var session = _session_with_party()
	_start_expedition(session, _rift("camp", "F", 55))
	session.rifts.expedition.segment_index = 4
	session.player.stats.current_hp = 2
	session.player.stats.current_mana = 1
	var companion = session.party.companion_by_id("kael")
	var limits := CompanionBuildServiceClass.resource_limits(companion)
	companion.current_hp = 2
	companion.current_mana = 1

	var result := RiftExpeditionServiceClass.resolve_camp(session)

	assert_true(result.ok, result.message)
	assert_eq(session.rifts.expedition.segment_index, 5)
	assert_eq(session.rifts.expedition.camp_visits, 1)
	assert_eq(
		companion.current_hp,
		mini(int(limits.max_hp), 2 + maxi(1, roundi(int(limits.max_hp) * 0.25))),
	)
	var save := SaveGameServiceClass.new("user://stage_six_j_not_written")
	var loaded := save._deserialize_payload(save._serialize_session(session), session.save_slot)
	assert_true(loaded.ok, loaded.message)
	assert_eq(loaded.session.rifts.expedition.segment_index, 5)
	assert_eq(loaded.session.rifts.expedition.camp_visits, 1)
	assert_eq(loaded.session.party.companion_by_id("kael").current_hp, companion.current_hp)


func test_victory_persists_resources_grants_companion_exp_and_advances() -> void:
	var session = _session_with_party()
	var rift := _rift("victory", "D", 61)
	_start_expedition(session, rift)
	var segment_index := _find_combat_segment(rift)
	session.rifts.expedition.segment_index = segment_index
	var started := RiftExpeditionServiceClass.start_combat(session)
	var engine: PartyCombatEngineClass = started.engine
	engine.enemy.current_hp = 1
	var companion = session.party.companion_by_id("kael")
	var experience_before: int = companion.experience

	var report = engine.player_basic_attack()
	var result := RiftExpeditionServiceClass.apply_combat_round(session, engine, report)

	assert_true(report.victory)
	assert_true(result.ok, result.message)
	assert_eq(result.outcome, RiftExpeditionServiceClass.OUTCOME_SEGMENT_COMPLETED)
	assert_eq(session.rifts.expedition.segment_index, segment_index + 1)
	assert_gt(companion.experience, experience_before)
	assert_eq(companion.current_hp, engine.companion_fighters[0].profile.stats.current_hp)


func test_defeat_ends_only_the_attempt_and_keeps_the_alarm() -> void:
	var session = _session_with_party()
	var rift := _rift("defeat", "F", 72)
	_start_expedition(session, rift)
	session.rifts.expedition.segment_index = _find_combat_segment(rift)
	var started := RiftExpeditionServiceClass.start_combat(session)
	var report := PartyCombatRoundResultClass.new()
	report.defeat = true
	report.turn_consumed = true
	session.player.stats.current_hp = 0

	var result := RiftExpeditionServiceClass.apply_combat_round(session, started.engine, report)

	assert_true(result.ok, result.message)
	assert_eq(result.outcome, RiftExpeditionServiceClass.OUTCOME_DEFEAT)
	assert_eq(session.player.stats.current_hp, 1)
	assert_null(session.rifts.expedition)
	assert_eq(session.rifts.active_rift, rift)
	assert_false(rift.closed)


func test_boss_completion_closes_once_and_grants_all_terminal_rewards() -> void:
	var session = _session_with_party()
	var rift := _rift("completion", "C", 991)
	_start_expedition(session, rift)
	session.rifts.expedition.segment_index = rift.segment_count - 1
	var started := RiftExpeditionServiceClass.start_combat(session)
	var engine: PartyCombatEngineClass = started.engine
	engine.enemy.current_hp = 0
	var report := PartyCombatRoundResultClass.new()
	report.victory = true
	report.turn_consumed = true
	var gold_before: int = session.player.gold
	var relation_before: int = session.party.companion_by_id("kael").relation
	var rifts_before: int = session.party.companion_by_id("kael").rifts_together

	var result := RiftExpeditionServiceClass.apply_combat_round(session, engine, report)

	assert_true(result.ok, result.message)
	assert_eq(result.outcome, RiftExpeditionServiceClass.OUTCOME_RIFT_COMPLETED)
	assert_between(result.reward.gold, 3500, 5200)
	assert_eq(result.reward.experience, 620)
	assert_eq(session.player.gold, gold_before + result.reward.gold)
	assert_null(session.rifts.active_rift)
	assert_null(session.rifts.expedition)
	assert_eq(session.rifts.completed_total, 1)
	assert_eq(session.rifts.completed_by_rank, {"C": 1})
	assert_eq(session.rifts.last_resolution_day, session.day)
	assert_between(session.rifts.next_spawn_day - session.day, 3, 6)
	assert_eq(session.party.companion_by_id("kael").relation, relation_before + 3)
	assert_eq(session.party.companion_by_id("kael").rifts_together, rifts_before + 1)
	assert_false(result.reward.companion_levels_gained.is_empty())
	if not result.reward.unique_item_id.is_empty():
		assert_true(result.reward.unique_item_id in RiftCatalogClass.UNIQUE_POOLS["warrior"])
		assert_eq(session.player.inventory.count(result.reward.unique_item_id), 1)
	assert_false(RiftExpeditionServiceClass.current_segment(session).ok)


func test_completion_rng_is_deterministic_and_uses_no_new_save_schema() -> void:
	var first := _completion_snapshot(8128)
	var second := _completion_snapshot(8128)
	assert_eq(first, second)
	assert_eq(SaveGameServiceClass.SCHEMA_VERSION, 15)


func test_rift_board_runs_event_and_party_battle_without_a_second_hub() -> void:
	var session = _session_with_party()
	var event_rift := _rift("ui-event", "F", _seed_with_kind("F", "event"))
	session.rifts.active_rift = event_rift
	var screen = RIFT_BOARD_SCENE.instantiate()
	add_child_autofree(screen)
	screen.configure(session)
	watch_signals(screen)

	screen.start_button.pressed.emit()
	assert_not_null(session.rifts.expedition)
	assert_string_contains(screen.start_button.text, "wydarzenie")
	screen.start_button.pressed.emit()
	assert_eq(session.rifts.expedition.segment_index, 1)

	var combat_index := _find_combat_segment(event_rift)
	session.rifts.expedition.segment_index = combat_index
	screen._render()
	screen.start_button.pressed.emit()
	assert_not_null(screen._combat)
	assert_true(screen.combat_panel.visible)
	assert_true(screen.back_button.disabled)
	screen._combat.enemy.current_hp = 1
	screen.attack_button.pressed.emit()
	assert_null(screen._combat)
	assert_eq(session.rifts.expedition.segment_index, combat_index + 1)
	assert_signal_emit_count(screen, "state_changed", 3)


func test_rift_domain_is_separate_from_ui_and_ordinary_combat() -> void:
	var ui_source := FileAccess.get_file_as_string("res://ui/screens/rift_board/rift_board.gd")
	var expedition_source := FileAccess.get_file_as_string(
		"res://core/rifts/rift_expedition_service.gd"
	)
	var lifecycle_source := FileAccess.get_file_as_string(
		"res://core/rifts/rift_lifecycle_service.gd"
	)
	assert_true("RiftExpeditionService" in ui_source)
	assert_true("PartyCombatEngine" in expedition_source)
	assert_false("TurnBasedCombatEngine" in expedition_source)
	assert_false("PartyCombatEngine" in lifecycle_source)
	assert_false("RiftBattleEngine" in expedition_source)


func _completion_snapshot(seed_value: int) -> Dictionary:
	var session = _session_with_party()
	var rift := _rift("snapshot", "B", seed_value)
	_start_expedition(session, rift)
	session.rifts.expedition.segment_index = rift.segment_count - 1
	var started := RiftExpeditionServiceClass.start_combat(session)
	started.engine.enemy.current_hp = 0
	var report := PartyCombatRoundResultClass.new()
	report.victory = true
	report.turn_consumed = true
	var result := RiftExpeditionServiceClass.apply_combat_round(session, started.engine, report)
	return {
		"gold": result.reward.gold,
		"experience": result.reward.experience,
		"unique_item_id": result.reward.unique_item_id,
		"next_spawn_day": session.rifts.next_spawn_day,
	}


func _start_expedition(session, rift: RiftInstanceClass) -> void:
	session.rifts.active_rift = rift
	var ids: Array[String] = []
	for companion in session.party.companions:
		ids.append(companion.companion_id)
	var result := RiftLifecycleServiceClass.start_expedition(session.rifts, session.day, ids, "S")
	assert_true(result.ok, result.message)


func _session_with_party():
	var session = NewGameServiceClass.new().create_session("Aria", 1, _rng(4))
	session.player.level = 20
	session.player.character_class_code = "warrior"
	session.player.attributes.strength = 8
	session.player.attributes.vitality = 6
	session.player.attributes.endurance = 6
	session.player.recalculate_stats()
	session.player.stats.restore_full()
	(
		session
		. party
		. companions
		. assign(
			[
				_companion("kael", "warrior", 20),
				_companion("mira", "pierrot", 20),
				_companion("elyra", "mage", 20),
			]
		)
	)
	return session


func _companion(companion_id: String, class_code: String, level: int) -> CompanionStateClass:
	var definition = CompanionCatalogClass.get_definition(companion_id)
	var companion := CompanionStateClass.new(
		companion_id, companion_id, definition.display_name, class_code
	)
	companion.level = level
	companion.path_id = str(
		{
			"warrior": "warrior_assault",
			"hunter": "hunter_volley",
			"mage": "mage_elements",
			"pierrot": "pierrot_chaos",
		}[class_code]
	)
	companion.active = true
	companion.attributes.strength = 6
	companion.attributes.vitality = 4
	companion.attributes.intelligence = 4
	companion.attributes.dexterity = 4
	companion.attributes.endurance = 4
	companion.attributes.luck = 4 if class_code == "pierrot" else 0
	companion.current_hp = int(CompanionBuildServiceClass.resource_limits(companion).max_hp)
	companion.current_mana = int(CompanionBuildServiceClass.resource_limits(companion).max_mana)
	return companion


func _rift(rift_id: String, rank_code: String, seed_value: int) -> RiftInstanceClass:
	return (
		RiftInstanceClass
		. new(
			{
				"rift_id": rift_id,
				"rank_code": rank_code,
				"theme_id": "blood_moon",
				"theme_name": "Pęknięcie Krwawego Księżyca",
				"modifier_ids": ["hungry"],
				"discovered_day": 1,
				"expires_day": 4,
				"seed": seed_value,
				"segment_count": int(RiftCatalogClass.SEGMENTS[rank_code]),
				"boss_id": "blood_devourer",
				"boss_name": "Pożeracz Krwawego Księżyca",
			}
		)
	)


func _seed_with_kind(rank_code: String, expected_kind: String) -> int:
	for seed_value in range(1, 10000):
		if (
			RiftSegmentServiceClass.segment_kind(_rift("search", rank_code, seed_value), 0)
			== expected_kind
		):
			return seed_value
	return -1


func _find_segment(rift: RiftInstanceClass, expected_kind: String) -> int:
	for index in rift.segment_count:
		if RiftSegmentServiceClass.segment_kind(rift, index) == expected_kind:
			return index
	return -1


func _find_combat_segment(rift: RiftInstanceClass) -> int:
	for index in rift.segment_count - 1:
		if RiftSegmentServiceClass.segment_kind(rift, index) in ["battle", "elite", "miniboss"]:
			return index
	return -1


func _event_titles() -> Array[String]:
	var titles: Array[String] = []
	for event: Array in RiftSegmentServiceClass.EVENTS:
		titles.append(str(event[0]))
	return titles


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng
