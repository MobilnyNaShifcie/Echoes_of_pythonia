extends GutTest

const CandidateClass := preload("res://core/companions/companion_candidate.gd")
const CatalogClass := preload("res://core/companions/companion_catalog.gd")
const RecruitmentServiceClass := preload("res://core/companions/companion_recruitment_service.gd")
const RelationshipServiceClass := preload("res://core/companions/companion_relationship_service.gd")
const CompanionServiceClass := preload("res://core/companions/companion_service.gd")
const CompanionStateClass := preload("res://core/companions/companion_state.gd")
const StoryCatalogClass := preload("res://core/companions/companion_story_catalog.gd")
const MessageClass := preload("res://core/companions/party_message.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")
const PARTY_HUB_SCENE := preload("res://ui/screens/party_hub/party_hub.tscn")


func test_all_twelve_authored_stories_and_every_personal_arc_are_complete() -> void:
	var arc_count := 0
	for template_id: String in CatalogClass.ORDER:
		var story = StoryCatalogClass.get_story(template_id)
		assert_not_null(story, template_id)
		assert_false(story.intro.is_empty(), template_id)
		assert_false(story.recruit_success.is_empty(), template_id)
		assert_false(story.recruit_fail.is_empty(), template_id)
		assert_false(story.farewell.is_empty(), template_id)
		assert_false(story.return_line.is_empty(), template_id)
		assert_gt(story.idle_lines.size(), 0, template_id)
		assert_gt(story.messages.size(), 0, template_id)
		assert_gt(story.camp_lines.size(), 0, template_id)
		assert_eq(story.conversations.size(), 3, template_id)
		assert_gt(story.arcs.size(), 0, template_id)
		for arc in story.arcs:
			arc_count += 1
			assert_eq(arc.stages.size(), 3, arc.arc_id)
			assert_eq(arc.stages[0].unlock_rifts, 0)
			assert_eq(arc.stages[1].unlock_rifts, 1)
			assert_eq(arc.stages[2].unlock_rifts, 2)
			for stage in arc.stages:
				assert_eq(stage.choices.size(), 2)
	assert_eq(arc_count, 16)


func test_rank_filters_and_daily_candidates_are_deterministic_and_persisted() -> void:
	var session = _session()
	assert_true(
		RecruitmentServiceClass.ensure_daily_candidates(session.party, session.player, 1, "F")
	)
	assert_true(session.party.candidates.is_empty())

	session.day = 2
	assert_true(
		RecruitmentServiceClass.ensure_daily_candidates(session.party, session.player, 2, "E")
	)
	assert_eq(session.party.candidates.size(), 2)
	for candidate in session.party.candidates:
		assert_eq(
			CatalogClass.get_definition(candidate.companion.template_id).minimum_guild_rank, "E"
		)
	var first_rotation := _candidate_snapshot(session.party.candidates)
	assert_false(
		RecruitmentServiceClass.ensure_daily_candidates(session.party, session.player, 2, "S")
	)
	assert_eq(_candidate_snapshot(session.party.candidates), first_rotation)

	var second_session = _session()
	second_session.day = 2
	assert_true(
		RecruitmentServiceClass.ensure_daily_candidates(
			second_session.party, second_session.player, 2, "E"
		)
	)
	assert_eq(_candidate_snapshot(second_session.party.candidates), first_rotation)


func test_godot_candidate_generator_matches_frozen_stage_six_b_snapshots() -> void:
	var test_cases: Array[Dictionary] = [
		{
			"name": "Aria",
			"day": 2,
			"level": 0,
			"rank": "E",
			"snapshot":
			[
				_candidate_data(
					"cand-dorian-2-0-7939",
					"dorian",
					"hunter",
					5,
					"hunter_volley",
					"dorian-2-0-7939",
					"dorian_story",
					80,
				),
				_candidate_data(
					"cand-talia-2-1-1076",
					"talia",
					"hunter",
					5,
					"hunter_phantom_archer",
					"talia-2-1-1076",
					"talia_caravan",
					56,
				),
			],
		},
		{
			"name": "Mobilny",
			"day": 17,
			"level": 20,
			"rank": "C",
			"snapshot":
			[
				_candidate_data(
					"cand-brann-17-0-3205",
					"brann",
					"hunter",
					14,
					"hunter_volley",
					"brann-17-0-3205",
					"brann_fleet",
					68,
				),
				_candidate_data(
					"cand-mira-17-1-4250",
					"mira",
					"pierrot",
					23,
					"pierrot_chaos",
					"mira-17-1-4250",
					"mira_name",
					50,
				),
			],
		},
		{
			"name": "Echo",
			"day": 41,
			"level": 37,
			"rank": "S",
			"snapshot":
			[
				_candidate_data(
					"cand-cassian-41-0-3470",
					"cassian",
					"mage",
					34,
					"mage_elements",
					"cassian-41-0-3470",
					"cassian_crown",
					32,
				),
				_candidate_data(
					"cand-orenna-41-1-7802",
					"orenna",
					"warrior",
					35,
					"warrior_assault",
					"orenna-41-1-7802",
					"orenna_bell",
					38,
				),
			],
		},
	]
	for test_case: Dictionary in test_cases:
		var session = _session_for(test_case.name, test_case.level)
		assert_true(
			RecruitmentServiceClass.ensure_daily_candidates(
				session.party, session.player, test_case.day, test_case.rank
			)
		)
		assert_eq(
			_candidate_snapshot(session.party.candidates),
			test_case.snapshot,
			"%s/day %d/rank %s" % [test_case.name, test_case.day, test_case.rank],
		)


func test_returning_candidate_matches_frozen_stage_six_b_snapshot() -> void:
	var session = _session_for("Powrot", 20)
	var companion := _companion("kael-golden", "kael", "warrior", "kael_garrison")
	companion.relation = -5
	companion.dismissed_day = 1
	session.party.dismissed_companions.append(companion)
	assert_true(
		RecruitmentServiceClass.ensure_daily_candidates(session.party, session.player, 4, "S")
	)
	assert_eq(
		_candidate_snapshot(session.party.candidates),
		[
			_candidate_data(
				"return-kael-golden-4",
				"kael",
				"warrior",
				5,
				"warrior_assault",
				"kael-golden",
				"kael_garrison",
				58,
			),
			_candidate_data(
				"cand-orenna-4-1-6719",
				"orenna",
				"mage",
				23,
				"mage_elements",
				"orenna-4-1-6719",
				"orenna_bell",
				26,
			),
		],
	)


func test_negative_returning_relations_use_python_floor_division() -> void:
	for expectation: Dictionary in [
		{"relation": -1, "roll": 56, "returning_bonus": 11},
		{"relation": -3, "roll": 57, "returning_bonus": 11},
		{"relation": -5, "roll": 58, "returning_bonus": 10},
		{"relation": -9, "roll": 60, "returning_bonus": 9},
	]:
		var session = _session_for("Powrot", 20)
		var companion := _companion(
			"kael-negative-%d" % absi(expectation.relation),
			"kael",
			"warrior",
			"kael_garrison",
		)
		companion.relation = expectation.relation
		companion.dismissed_day = 1
		session.party.dismissed_companions.append(companion)
		RecruitmentServiceClass.ensure_daily_candidates(session.party, session.player, 4, "S")
		var candidate: CandidateClass = session.party.candidates[0]
		assert_true(candidate.returning, "relation %d" % expectation.relation)
		assert_eq(
			candidate.recruitment_roll,
			expectation.roll,
			"recruitment roll for relation %d" % expectation.relation,
		)
		assert_eq(candidate.impression, 0, "impression for relation %d" % expectation.relation)
		candidate.returning = false
		var score_without_returning_bonus := RecruitmentServiceClass.willingness_score(
			candidate, session.player, "F"
		)
		candidate.returning = true
		assert_eq(
			RecruitmentServiceClass.willingness_score(candidate, session.player, "F"),
			score_without_returning_bonus + expectation.returning_bonus,
			"willingness bonus for relation %d" % expectation.relation,
		)


func test_authored_talk_is_single_use_and_recruitment_has_persisted_success_and_failure() -> void:
	var session = _rank_s_session()
	RecruitmentServiceClass.ensure_daily_candidates(session.party, session.player, session.day, "S")
	var success_candidate: CandidateClass = session.party.candidates[0]
	var before := success_candidate.impression
	var talk := RecruitmentServiceClass.talk_to_candidate(success_candidate, 0)
	assert_true(talk.ok)
	assert_gt(success_candidate.impression, before)
	assert_false(RecruitmentServiceClass.talk_to_candidate(success_candidate, 1).ok)
	success_candidate.recruitment_roll = 1
	var recruited := RecruitmentServiceClass.recruit_candidate(
		session.party, success_candidate, session.player, "S"
	)
	assert_true(recruited.ok)
	assert_true(recruited.success)
	assert_eq(session.party.companions.size(), 1)
	assert_eq(session.party.messages.size(), 1)
	assert_eq(session.party.companions[0].relation, success_candidate.impression)

	var failure_candidate: CandidateClass = session.party.candidates[0]
	failure_candidate.recruitment_roll = 100
	var rejected := RecruitmentServiceClass.recruit_candidate(
		session.party, failure_candidate, session.player, "S"
	)
	assert_true(rejected.ok)
	assert_false(rejected.success)
	assert_true(failure_candidate.recruitment_attempted)
	assert_false(
		(
			RecruitmentServiceClass
			. recruit_candidate(session.party, failure_candidate, session.player, "S")
			. ok
		)
	)


func test_roster_limit_blocks_recruitment_without_consuming_attempt() -> void:
	var session = _rank_s_session()
	RecruitmentServiceClass.ensure_daily_candidates(session.party, session.player, 1, "S")
	var candidate: CandidateClass = session.party.candidates[0]
	for index in CompanionServiceClass.MAX_COMPANIONS:
		var definition = CatalogClass.get_definition(CatalogClass.ORDER[index])
		var companion := _companion(
			"full-%d" % index,
			definition.template_id,
			definition.allowed_classes[0],
			StoryCatalogClass.get_story(definition.template_id).arcs[0].arc_id,
		)
		assert_true(CompanionServiceClass.add_companion(session.party, companion).ok)
	var result := RecruitmentServiceClass.recruit_candidate(
		session.party, candidate, session.player, "S"
	)
	assert_false(result.ok)
	assert_false(candidate.recruitment_attempted)


func test_dismissed_companion_keeps_history_and_can_return_only_after_delay() -> void:
	var session = _rank_s_session()
	var companion := _companion("kael-return", "kael", "warrior", "kael_garrison")
	companion.relation = 24
	companion.quest_stage = 1
	companion.memories.assign(["kael_garrison:heard"])
	assert_true(CompanionServiceClass.add_companion(session.party, companion).ok)
	assert_true(
		(
			RecruitmentServiceClass
			. dismiss_companion(session.party, session.player, companion.companion_id, 1)
			. ok
		)
	)
	assert_true(session.party.companions.is_empty())
	assert_eq(session.party.dismissed_companions[0].relation, 24)

	for day in [2, 3]:
		RecruitmentServiceClass.ensure_daily_candidates(session.party, session.player, day, "S")
		assert_false(
			session.party.candidates.any(func(candidate) -> bool: return candidate.returning)
		)
	var returning = null
	for day in range(4, 100):
		RecruitmentServiceClass.ensure_daily_candidates(session.party, session.player, day, "S")
		for candidate in session.party.candidates:
			if candidate.returning:
				returning = candidate
				break
		if returning != null:
			break
	assert_not_null(returning)
	assert_eq(returning.companion.companion_id, "kael-return")
	assert_eq(returning.companion.quest_stage, 1)
	assert_eq(returning.companion.memories, ["kael_garrison:heard"])
	returning.recruitment_roll = 1
	var result := RecruitmentServiceClass.recruit_candidate(
		session.party, returning, session.player, "S"
	)
	assert_true(result.success)
	assert_true(session.party.dismissed_companions.is_empty())


func test_each_personal_arc_applies_relation_and_unique_memory_once() -> void:
	for template_id: String in CatalogClass.ORDER:
		var story = StoryCatalogClass.get_story(template_id)
		for arc in story.arcs:
			var class_code: String = CatalogClass.get_definition(template_id).allowed_classes[0]
			var companion := _companion("%s-test" % arc.arc_id, template_id, class_code, arc.arc_id)
			var result := RelationshipServiceClass.complete_personal_stage(companion, 0)
			assert_true(result.ok, arc.arc_id)
			assert_eq(companion.relation, 3, arc.arc_id)
			assert_eq(companion.memories, ["%s:heard" % arc.arc_id], arc.arc_id)
			assert_eq(companion.quest_stage, 1, arc.arc_id)
			assert_false(RelationshipServiceClass.complete_personal_stage(companion, 0).ok)
			assert_eq(companion.memories.size(), 1, arc.arc_id)


func test_rifts_unlock_next_personal_stage_and_update_relation() -> void:
	var session = _session()
	var companion := _companion("mira-arc", "mira", "pierrot", "mira_deck")
	assert_true(CompanionServiceClass.add_companion(session.party, companion).ok)
	assert_true(RelationshipServiceClass.complete_personal_stage(companion, 1).ok)
	assert_true(RelationshipServiceClass.available_personal_stage(companion).is_empty())
	RelationshipServiceClass.record_rift_together(session.party, [companion.companion_id])
	assert_eq(companion.rifts_together, 1)
	assert_eq(companion.relation, 5)
	assert_false(RelationshipServiceClass.available_personal_stage(companion).is_empty())


func test_daily_messages_unread_lifecycle_and_sixty_message_limit() -> void:
	var session = _session()
	var companion := _companion("elyra-message", "elyra", "mage", "elyra_archive")
	assert_true(CompanionServiceClass.add_companion(session.party, companion).ok)
	var first := RelationshipServiceClass.ensure_daily_party_message(
		session.party, 2, session.player.display_name
	)
	assert_true(first.created)
	assert_false(
		(
			RelationshipServiceClass
			. ensure_daily_party_message(session.party, 2, session.player.display_name)
			. created
		)
	)
	assert_eq(session.party.unread_messages(), 1)
	assert_eq(RelationshipServiceClass.mark_messages_read(session.party), 1)
	assert_eq(session.party.unread_messages(), 0)
	for day in range(3, 70):
		RelationshipServiceClass.ensure_daily_party_message(
			session.party, day, session.player.display_name
		)
	assert_eq(session.party.messages.size(), 60)
	assert_eq(session.party.messages[0].day, 10)


func test_pair_banter_is_one_time_then_falls_back_to_camp_line() -> void:
	var session = _session()
	var elyra := _companion("elyra-banter", "elyra", "mage", "elyra_archive")
	var mira := _companion("mira-banter", "mira", "pierrot", "mira_deck")
	elyra.active = true
	mira.active = true
	assert_true(CompanionServiceClass.add_companion(session.party, elyra).ok)
	assert_true(CompanionServiceClass.add_companion(session.party, mira).ok)
	var first := RelationshipServiceClass.camp_banter(session.party, 7, session.day)
	var second := RelationshipServiceClass.camp_banter(session.party, 7, session.day)
	var fallback := RelationshipServiceClass.camp_banter(session.party, 7, session.day)
	assert_false(first.scene_id.is_empty())
	assert_false(second.scene_id.is_empty())
	assert_ne(first.scene_id, second.scene_id)
	assert_eq(session.party.seen_banter.size(), 2)
	assert_true(fallback.scene_id.is_empty())
	assert_eq(fallback.lines.size(), 1)


func test_schema_thirteen_round_trips_candidates_messages_and_personal_progress() -> void:
	var session = _rank_s_session()
	RecruitmentServiceClass.ensure_daily_candidates(session.party, session.player, 1, "S")
	var candidate: CandidateClass = session.party.candidates[0]
	assert_true(RecruitmentServiceClass.talk_to_candidate(candidate, 2).ok)
	candidate.recruitment_roll = 100
	assert_false(
		(
			RecruitmentServiceClass
			. recruit_candidate(session.party, candidate, session.player, "S")
			. success
		)
	)
	var companion := _companion("save-mira", "mira", "pierrot", "mira_deck")
	assert_true(CompanionServiceClass.add_companion(session.party, companion).ok)
	assert_true(RelationshipServiceClass.complete_personal_stage(companion, 0).ok)
	session.party.messages.append(
		MessageClass.new(1, companion.companion_id, "Mira", "Test", false)
	)
	session.party.seen_banter.assign(["elyra:mira:0"])

	var service := SaveGameServiceClass.new("user://stage_six_b_not_written")
	var payload: Dictionary = service._serialize_session(session)
	assert_eq(payload.schema_version, 13)
	var loaded := service._deserialize_payload(payload, 1)
	assert_true(loaded.ok, loaded.message)
	assert_eq(loaded.session.party.candidates.size(), 2)
	assert_true(loaded.session.party.candidates[0].talked)
	assert_true(loaded.session.party.candidates[0].recruitment_attempted)
	assert_eq(
		loaded.session.party.candidates[0].recruitment_roll,
		candidate.recruitment_roll,
	)
	assert_eq(loaded.session.party.companions[0].quest_stage, 1)
	assert_eq(loaded.session.party.companions[0].memories, ["mira_deck:heard"])
	assert_false(
		RelationshipServiceClass.complete_personal_stage(loaded.session.party.companions[0], 0).ok
	)
	assert_eq(loaded.session.party.companions[0].memories, ["mira_deck:heard"])
	assert_eq(loaded.session.party.unread_messages(), 1)
	assert_eq(loaded.session.party.seen_banter, ["elyra:mira:0"])


func test_party_hub_exposes_candidates_roster_histories_and_messages() -> void:
	var session = _rank_s_session()
	var screen = PARTY_HUB_SCENE.instantiate()
	screen.configure(session)
	add_child_autofree(screen)
	await get_tree().process_frame
	assert_eq(screen.tabs.get_tab_count(), 3)
	assert_eq(screen.candidate_list.item_count, 2)
	assert_false(screen.talk_buttons[0].disabled)
	screen.talk_buttons[0].pressed.emit()
	assert_true(session.party.candidates[0].talked)
	session.party.candidates[0].recruitment_roll = 1
	screen.recruit_button.pressed.emit()
	assert_eq(session.party.companions.size(), 1)
	assert_eq(screen.roster_list.item_count, 1)
	assert_false(screen.personal_title_label.text.is_empty())
	assert_gt(screen.messages_list.item_count, 0)


func _session():
	return NewGameServiceClass.new().create_session("Aria", 1, _rng(1))


func _session_for(display_name: String, level: int):
	var session = NewGameServiceClass.new().create_session(display_name, 1, _rng(1))
	session.player.level = level
	return session


func _rank_s_session():
	var session = _session()
	session.guild_reputation = 4500
	session.player.level = 20
	return session


func _companion(
	companion_id: String, template_id: String, class_code: String, arc_id: String
) -> CompanionStateClass:
	var definition = CatalogClass.get_definition(template_id)
	var companion := CompanionStateClass.new(
		companion_id, template_id, definition.display_name, class_code
	)
	companion.level = 5
	companion.path_id = (
		preload("res://core/progression/talent_catalog.gd").CLASS_PATH_ORDER[class_code][0]
	)
	companion.quest_arc_id = arc_id
	return companion


func _candidate_snapshot(candidates: Array) -> Array:
	return candidates.map(
		func(candidate) -> Dictionary:
			return {
				"candidate_id": candidate.candidate_id,
				"template_id": candidate.companion.template_id,
				"class_code": candidate.companion.class_code,
				"level": candidate.companion.level,
				"path_id": candidate.companion.path_id,
				"companion_id": candidate.companion.companion_id,
				"quest_arc_id": candidate.companion.quest_arc_id,
				"recruitment_roll": candidate.recruitment_roll,
			}
	)


func _candidate_data(
	candidate_id: String,
	template_id: String,
	class_code: String,
	level: int,
	path_id: String,
	companion_id: String,
	quest_arc_id: String,
	recruitment_roll: int
) -> Dictionary:
	return {
		"candidate_id": candidate_id,
		"template_id": template_id,
		"class_code": class_code,
		"level": level,
		"path_id": path_id,
		"companion_id": companion_id,
		"quest_arc_id": quest_arc_id,
		"recruitment_roll": recruitment_roll,
	}


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng
