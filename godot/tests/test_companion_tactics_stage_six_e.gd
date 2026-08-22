extends GutTest

const CompanionAiContextClass := preload("res://core/companions/companion_ai_context.gd")
const CompanionCatalogClass := preload("res://core/companions/companion_catalog.gd")
const CompanionStateClass := preload("res://core/companions/companion_state.gd")
const CompanionTacticServiceClass := preload("res://core/companions/companion_tactic_service.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const PartyStateClass := preload("res://core/companions/party_state.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")
const SkillCatalogClass := preload("res://core/skills/skill_catalog.gd")
const PARTY_HUB_SCENE := preload("res://ui/screens/party_hub/party_hub.tscn")


func test_tactic_service_sets_known_value_and_rejects_invalid_input() -> void:
	var party := PartyStateClass.new()
	var companion := _companion("warrior", 12)
	party.companions.append(companion)

	var changed := CompanionTacticServiceClass.set_tactic(
		party, companion.companion_id, CompanionStateClass.TACTIC_AGGRESSIVE
	)
	assert_true(changed.ok)
	assert_true(changed.changed)
	assert_eq(companion.tactic, CompanionStateClass.TACTIC_AGGRESSIVE)

	var unchanged := CompanionTacticServiceClass.set_tactic(
		party, companion.companion_id, CompanionStateClass.TACTIC_AGGRESSIVE
	)
	assert_true(unchanged.ok)
	assert_false(unchanged.changed)
	assert_false(CompanionTacticServiceClass.set_tactic(party, "missing", "balanced").ok)
	assert_false(
		CompanionTacticServiceClass.set_tactic(party, companion.companion_id, "berserk").ok
	)
	assert_eq(companion.tactic, CompanionStateClass.TACTIC_AGGRESSIVE)


func test_aggressive_uses_strongest_affordable_offensive_skill() -> void:
	var companion := _companion("warrior", 12, CompanionStateClass.TACTIC_AGGRESSIVE)
	assert_eq(
		CompanionTacticServiceClass.choose_skill_id(companion, _context(100, 100, 20, 20), _rng(1)),
		"blood_strike",
	)
	assert_eq(
		CompanionTacticServiceClass.choose_skill_id(companion, _context(100, 100, 7, 20), _rng(1)),
		"power_slash",
	)


func test_balanced_uses_class_identity_and_strongest_fallback() -> void:
	var mage := _companion("mage", 12, CompanionStateClass.TACTIC_BALANCED)
	assert_eq(
		CompanionTacticServiceClass.choose_skill_id(mage, _context(100, 100, 20, 20), _rng(2)),
		"mana_burst",
	)

	var hunter := _companion("hunter", 9, CompanionStateClass.TACTIC_BALANCED)
	hunter.talents = {"hunter_piercing_arrow": 1, "hunter_frost_arrow": 1}
	var first := CompanionTacticServiceClass.choose_skill_id(
		hunter, _context(100, 100, 20, 20), _rng(917)
	)
	var second := CompanionTacticServiceClass.choose_skill_id(
		hunter, _context(100, 100, 20, 20), _rng(917)
	)
	assert_eq(first, second)
	assert_has(["piercing_arrow", "frost_arrow"], first)


func test_cautious_defends_below_half_hp_and_conserves_low_mana() -> void:
	var companion := _companion("warrior", 12, CompanionStateClass.TACTIC_CAUTIOUS)
	assert_eq(
		CompanionTacticServiceClass.choose_skill_id(companion, _context(49, 100, 20, 20), _rng(3)),
		"defensive_stance",
	)
	assert_eq(
		CompanionTacticServiceClass.choose_skill_id(companion, _context(80, 100, 4, 20), _rng(3)),
		"",
	)
	assert_eq(
		CompanionTacticServiceClass.choose_skill_id(companion, _context(50, 100, 20, 20), _rng(3)),
		"blood_strike",
	)


func test_defensive_reacts_below_eighty_percent_but_not_at_boundary() -> void:
	var companion := _companion("warrior", 12, CompanionStateClass.TACTIC_DEFENSIVE)
	assert_eq(
		CompanionTacticServiceClass.choose_skill_id(companion, _context(79, 100, 20, 20), _rng(4)),
		"defensive_stance",
	)
	assert_eq(
		CompanionTacticServiceClass.choose_skill_id(companion, _context(80, 100, 20, 20), _rng(4)),
		"blood_strike",
	)


func test_heavy_knight_prioritizes_provoke_when_party_is_in_danger() -> void:
	for tactic: String in [
		CompanionStateClass.TACTIC_BALANCED, CompanionStateClass.TACTIC_DEFENSIVE
	]:
		var companion := _companion("warrior", 12, tactic)
		companion.talents = {"heavy_knight_core": 1, "heavy_provoke": 1}
		var context := _context(100, 100, 20, 20)
		context.add_standing_member(34, 100)
		assert_eq(
			CompanionTacticServiceClass.choose_skill_id(companion, context, _rng(5)),
			"provoke",
			tactic,
		)


func test_party_danger_uses_strict_thirty_five_percent_threshold() -> void:
	var companion := _companion("warrior", 12, CompanionStateClass.TACTIC_BALANCED)
	companion.talents = {"heavy_knight_core": 1, "heavy_provoke": 1}
	var safe_boundary := _context(100, 100, 20, 20)
	safe_boundary.add_standing_member(35, 100)
	assert_eq(
		CompanionTacticServiceClass.choose_skill_id(companion, safe_boundary, _rng(6)),
		"blood_strike",
	)


func test_pierrot_fate_choice_is_deterministic_for_injected_rng() -> void:
	var companion := _companion("pierrot", 12, CompanionStateClass.TACTIC_BALANCED)
	var first := CompanionTacticServiceClass.choose_skill_id(
		companion, _context(100, 100, 20, 20), _rng(771)
	)
	var second := CompanionTacticServiceClass.choose_skill_id(
		companion, _context(100, 100, 20, 20), _rng(771)
	)
	assert_eq(first, second)
	assert_has(["fate_thrust", "double_roll", "fate_feint", "grand_gamble"], first)


func test_no_affordable_skill_falls_back_to_basic_attack_contract() -> void:
	var companion := _companion("mage", 12, CompanionStateClass.TACTIC_AGGRESSIVE)
	assert_eq(
		CompanionTacticServiceClass.choose_skill_id(companion, _context(100, 100, 0, 20), _rng(7)),
		"",
	)


func test_talent_skills_are_unlocked_from_companion_build_without_player_adapter() -> void:
	var companion := _companion("warrior", 12)
	companion.talents = {"heavy_provoke": 1}
	var skill_ids: Array[String] = []
	for skill in SkillCatalogClass.get_unlocked_skills_for_companion(companion):
		skill_ids.append(skill.skill_id)
	assert_has(skill_ids, "provoke")
	assert_does_not_have(skill_ids, "shield_bash")


func test_tactic_round_trip_keeps_schema_fourteen() -> void:
	var session = _session()
	var companion := _companion("hunter", 9, CompanionStateClass.TACTIC_CAUTIOUS)
	session.party.companions.append(companion)
	var service := SaveGameServiceClass.new("user://stage_six_e_not_written")
	var payload: Dictionary = service._serialize_session(session)
	assert_eq(payload.schema_version, 15)
	var loaded := service._deserialize_payload(payload, 1)
	assert_true(loaded.ok, loaded.message)
	assert_eq(loaded.session.party.companions[0].tactic, CompanionStateClass.TACTIC_CAUTIOUS)


func test_existing_party_hub_changes_tactic_through_domain_service() -> void:
	var session = _session()
	var companion := _companion("warrior", 12)
	session.party.companions.append(companion)
	var screen = PARTY_HUB_SCENE.instantiate()
	screen.configure(session)
	add_child_autofree(screen)
	await get_tree().process_frame
	watch_signals(screen)
	assert_eq(screen.tactic_option.item_count, 4)
	assert_false(screen.tactic_option.disabled)

	var aggressive_index := _option_index(screen.tactic_option, "aggressive")
	assert_gte(aggressive_index, 0)
	screen.tactic_option.select(aggressive_index)
	screen.tactic_option.item_selected.emit(aggressive_index)
	assert_eq(companion.tactic, CompanionStateClass.TACTIC_AGGRESSIVE)
	assert_signal_emitted(screen, "state_changed")
	assert_string_contains(screen.tactic_description_label.text, "ofensywne")


func _session():
	return NewGameServiceClass.new().create_session("Taktyk", 1, _rng(1))


func _companion(
	class_code: String, level: int, tactic := CompanionStateClass.TACTIC_BALANCED
) -> CompanionStateClass:
	var template_id: String = (
		{
			"warrior": "kael",
			"hunter": "nessa",
			"mage": "elyra",
			"pierrot": "mira",
		}
		. get(class_code, "kael")
	)
	var definition = CompanionCatalogClass.get_definition(template_id)
	var companion := CompanionStateClass.new(
		"stage-6e-%s" % class_code, template_id, definition.display_name, class_code
	)
	companion.level = level
	companion.path_id = (
		{
			"warrior": "warrior_assault",
			"hunter": "hunter_volley",
			"mage": "mage_destruction",
			"pierrot": "pierrot_caprice",
		}
		. get(class_code, "")
	)
	companion.tactic = tactic
	return companion


func _context(
	current_hp: int, max_hp: int, current_mana: int, max_mana: int
) -> CompanionAiContextClass:
	var context := CompanionAiContextClass.new(current_hp, max_hp, current_mana, max_mana)
	context.add_standing_member(current_hp, max_hp)
	return context


func _rng(seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng


func _option_index(option: OptionButton, metadata: String) -> int:
	for index in option.item_count:
		if str(option.get_item_metadata(index)) == metadata:
			return index
	return -1
