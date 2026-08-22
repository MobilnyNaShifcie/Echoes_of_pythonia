extends GutTest

const CompanionCandidateClass := preload("res://core/companions/companion_candidate.gd")
const CompanionCatalogClass := preload("res://core/companions/companion_catalog.gd")
const CompanionServiceClass := preload("res://core/companions/companion_service.gd")
const CompanionStateClass := preload("res://core/companions/companion_state.gd")
const FallenCompanionClass := preload("res://core/companions/fallen_companion.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const PartyMessageClass := preload("res://core/companions/party_message.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")
const PARTY_HUB_SCENE := preload("res://ui/screens/party_hub/party_hub.tscn")
const APP_SCENE := preload("res://scenes/app/app.tscn")


func test_catalog_matches_all_twelve_terminal_templates() -> void:
	assert_eq(
		CompanionCatalogClass.ORDER,
		[
			"elyra",
			"kael",
			"nessa",
			"mira",
			"dorian",
			"sylvi",
			"orenna",
			"veyn",
			"talia",
			"cassian",
			"lumi",
			"brann",
		],
	)
	var expected := {
		"elyra": [["mage"], "D", 58],
		"kael": [["warrior"], "E", 64],
		"nessa": [["hunter"], "D", 55],
		"mira": [["pierrot"], "C", 52],
		"dorian": [["warrior", "hunter"], "E", 61],
		"sylvi": [["mage", "hunter"], "D", 60],
		"orenna": [["warrior", "mage"], "C", 50],
		"veyn": [["hunter", "pierrot"], "C", 47],
		"talia": [["warrior", "hunter"], "E", 66],
		"cassian": [["mage"], "B", 42],
		"lumi": [["pierrot", "mage"], "B", 44],
		"brann": [["warrior", "hunter"], "E", 68],
	}
	for template_id: String in CompanionCatalogClass.ORDER:
		var definition = CompanionCatalogClass.get_definition(template_id)
		assert_eq(definition.allowed_classes, expected[template_id][0])
		assert_eq(definition.minimum_guild_rank, expected[template_id][1])
		assert_eq(definition.base_willingness, expected[template_id][2])
		assert_false(definition.origin.is_empty())
		assert_false(definition.voice.is_empty())


func test_roster_and_active_party_limits_match_terminal_rules() -> void:
	var session = _session()
	var companions := [
		_companion("kael-a", "kael", "warrior"),
		_companion("nessa-a", "nessa", "hunter"),
		_companion("elyra-a", "elyra", "mage"),
		_companion("mira-a", "mira", "pierrot"),
	]
	for companion in companions:
		assert_true(CompanionServiceClass.add_companion(session.party, companion, session.day).ok)
	assert_eq(session.party.companions.size(), 4)
	assert_false(
		(
			CompanionServiceClass
			. add_companion(session.party, _companion("talia-a", "talia", "warrior"), session.day)
			. ok
		)
	)
	for index in 3:
		assert_true(
			(
				CompanionServiceClass
				. set_active(session.party, companions[index].companion_id, true, session.day)
				. ok
			)
		)
	var fourth := CompanionServiceClass.set_active(
		session.party, companions[3].companion_id, true, session.day
	)
	assert_false(fourth.ok)
	assert_string_contains(fourth.message, "maksymalnie 3")
	assert_eq(session.party.active_companions(session.day).size(), 3)
	var solo := CompanionServiceClass.set_solo(session.party)
	assert_true(solo.ok)
	assert_eq(solo.changed, 3)
	assert_true(session.party.active_companions(session.day).is_empty())


func test_injured_dead_and_locked_composition_cannot_be_activated() -> void:
	var session = _session()
	var kael := _companion("kael-a", "kael", "warrior")
	assert_true(CompanionServiceClass.add_companion(session.party, kael, session.day).ok)
	kael.injury_until_day = session.day + 2
	assert_false(
		CompanionServiceClass.set_active(session.party, kael.companion_id, true, session.day).ok
	)
	kael.injury_until_day = session.day
	kael.dead = true
	assert_false(
		CompanionServiceClass.set_active(session.party, kael.companion_id, true, session.day).ok
	)
	kael.dead = false
	var locked := CompanionServiceClass.set_active(
		session.party, kael.companion_id, true, session.day, true
	)
	assert_false(locked.ok)
	assert_string_contains(locked.message, "zablokowany")


func test_schema_thirteen_round_trips_full_party_state() -> void:
	var session = _session()
	var kael := _companion("kael-a", "kael", "warrior")
	kael.active = true
	kael.level = 8
	kael.experience = 123
	kael.path_id = "warrior_heavy_knight"
	kael.talents = {"heavy_knight_core": 1}
	kael.attributes.strength = 5
	kael.attributes.vitality = 4
	kael.relation = 17
	kael.quest_arc_id = "kael_garrison"
	kael.quest_stage = 1
	kael.memories.assign(["kael_garrison:heard"])
	kael.rifts_together = 2
	kael.current_hp = 34
	kael.current_mana = 6
	var sword = ItemCatalogClass.create_equipment_item("starter_sword", _rng(3))
	var armor = ItemCatalogClass.create_equipment_item("worn_leather_armor", _rng(4))
	kael.equipment.equip_and_return_previous(sword)
	kael.personal_storage.append(armor)
	kael.personal_instance_ids.assign([sword.instance_id, armor.instance_id])
	assert_true(CompanionServiceClass.add_companion(session.party, kael, session.day).ok)

	var candidate_companion := _companion("nessa-candidate", "nessa", "hunter")
	var candidate := CompanionCandidateClass.new("candidate-1", candidate_companion, 1, 47)
	candidate.impression = 3
	candidate.talked = true
	session.party.candidates.append(candidate)
	session.party.candidates_day = 1
	session.party.messages.append(
		PartyMessageClass.new(1, kael.companion_id, kael.display_name, "Gotowy.")
	)
	session.party.last_message_day = 1
	session.party.seen_banter.assign(["kael:mira:0"])
	session.party.fallen.append(
		FallenCompanionClass.new("old-a", "Aren", "hunter", 12, 1, "Egzekucja", "B")
	)

	var service := SaveGameServiceClass.new("user://stage_six_a_not_written")
	var payload: Dictionary = service._serialize_session(session)
	assert_eq(payload.schema_version, 17)
	var loaded := service._deserialize_payload(payload, 1)
	assert_true(loaded.ok, loaded.message)
	assert_eq(loaded.session.party.companions.size(), 1)
	var restored = loaded.session.party.companions[0]
	assert_eq(restored.display_name, "Kael")
	assert_true(restored.active)
	assert_eq(restored.tactic, CompanionStateClass.TACTIC_BALANCED)
	assert_eq(restored.attributes.strength, 5)
	assert_eq(restored.equipment.get_item("weapon").instance_id, sword.instance_id)
	assert_eq(restored.personal_storage[0].instance_id, armor.instance_id)
	assert_eq(restored.personal_instance_ids.size(), 2)
	assert_eq(loaded.session.party.candidates[0].recruitment_roll, 47)
	assert_eq(loaded.session.party.unread_messages(), 1)
	assert_eq(loaded.session.party.seen_banter, ["kael:mira:0"])
	assert_eq(loaded.session.party.fallen[0].cause, "Egzekucja")


func test_schema_twelve_migrates_to_an_empty_party() -> void:
	var service := SaveGameServiceClass.new("user://stage_six_a_legacy_not_written")
	var payload: Dictionary = service._serialize_session(_session())
	payload.schema_version = 12
	payload.session.erase("party")
	var loaded := service._deserialize_payload(payload, 1)
	assert_true(loaded.ok, loaded.message)
	assert_true(loaded.session.party.companions.is_empty())
	assert_true(loaded.session.party.candidates.is_empty())


func test_save_rejects_invalid_party_tactic_and_active_injury() -> void:
	var session = _session()
	var kael := _companion("kael-a", "kael", "warrior")
	kael.active = true
	assert_true(CompanionServiceClass.add_companion(session.party, kael, session.day).ok)
	var service := SaveGameServiceClass.new("user://stage_six_a_invalid_not_written")
	var payload: Dictionary = service._serialize_session(session)
	payload.session.party.companions[0].tactic = "random"
	var invalid_tactic := service._deserialize_payload(payload, 1)
	assert_false(invalid_tactic.ok)
	assert_string_contains(invalid_tactic.message, "taktykę")

	payload = service._serialize_session(session)
	payload.session.party.companions[0].injury_until_day = 4
	var invalid_injury := service._deserialize_payload(payload, 1)
	assert_false(invalid_injury.ok)
	assert_string_contains(invalid_injury.message, "ciężko ranny")


func test_party_screen_and_app_route_work_without_terminal() -> void:
	var session = _session()
	var kael := _companion("kael-a", "kael", "warrior")
	assert_true(CompanionServiceClass.add_companion(session.party, kael, session.day).ok)
	var screen = PARTY_HUB_SCENE.instantiate()
	screen.configure(session)
	add_child_autofree(screen)
	await get_tree().process_frame
	assert_eq(screen.roster_list.item_count, 1)
	assert_string_contains(screen.summary_label.text, "aktywny skład 0/3")
	screen.toggle_button.pressed.emit()
	assert_true(kael.active)
	assert_string_contains(screen.summary_label.text, "aktywny skład 1/3")

	var app = APP_SCENE.instantiate()
	add_child_autofree(app)
	session.prologue_completed = true
	app._on_session_created(session)
	app._show_party_hub()
	await get_tree().process_frame
	assert_eq(app.screen_host.get_child(0).roster_list.item_count, 1)


func _session():
	return NewGameServiceClass.new().create_session("Aria", 1, _rng(1))


func _companion(
	companion_id: String, template_id: String, class_code: String
) -> CompanionStateClass:
	var definition = CompanionCatalogClass.get_definition(template_id)
	var companion := CompanionStateClass.new(
		companion_id, template_id, definition.display_name, class_code
	)
	companion.level = 5
	companion.path_id = (
		{
			"warrior": "warrior_assault",
			"hunter": "hunter_volley",
			"mage": "mage_destruction",
			"pierrot": "pierrot_caprice",
		}
		. get(class_code, "")
	)
	companion.current_hp = 20
	companion.current_mana = 10 if class_code in ["mage", "pierrot"] else 0
	return companion


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng
