extends GutTest

const BuildServiceClass := preload("res://core/companions/companion_build_service.gd")
const CandidateClass := preload("res://core/companions/companion_candidate.gd")
const CatalogClass := preload("res://core/companions/companion_catalog.gd")
const CompanionEquipmentServiceClass := preload(
	"res://core/companions/companion_equipment_service.gd"
)
const RecruitmentServiceClass := preload("res://core/companions/companion_recruitment_service.gd")
const CompanionStateClass := preload("res://core/companions/companion_state.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const PlayerEquipmentClass := preload("res://core/player/equipment.gd")
const EquipmentSaveCodecClass := preload("res://core/save/equipment_save_codec.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")
const TalentProgressionServiceClass := preload(
	"res://core/progression/talent_progression_service.gd"
)
const PARTY_HUB_SCENE := preload("res://ui/screens/party_hub/party_hub.tscn")


func test_initial_build_is_complete_deterministic_and_keeps_terminal_point_rules() -> void:
	var first_session = _session_for("Aria", 0)
	var second_session = _session_for("Aria", 0)
	assert_true(
		RecruitmentServiceClass.ensure_daily_candidates(
			first_session.party, first_session.player, 2, "E"
		)
	)
	assert_true(
		RecruitmentServiceClass.ensure_daily_candidates(
			second_session.party, second_session.player, 2, "E"
		)
	)
	var first = first_session.party.candidates[0].companion
	var second = second_session.party.candidates[0].companion
	assert_eq(_build_snapshot(first), _build_snapshot(second))
	assert_eq(
		EquipmentSaveCodecClass.serialize_equipment(first.equipment.slots),
		EquipmentSaveCodecClass.serialize_equipment(second.equipment.slots),
	)
	assert_eq(
		EquipmentSaveCodecClass.serialize_items(first.personal_storage),
		EquipmentSaveCodecClass.serialize_items(second.personal_storage),
	)
	assert_eq(_attribute_points(first), first.level * 4)
	assert_eq(
		_talent_points(first),
		TalentProgressionServiceClass.total_points_for_level(first.level, true),
	)
	assert_gt(first.equipment.slots.size(), 1)
	assert_eq(
		first.personal_instance_ids.size(),
		first.equipment.slots.size() + first.personal_storage.size(),
	)
	assert_eq(first.current_hp, 0)
	assert_eq(first.current_mana, 0)


func test_same_day_refresh_backfills_pre_six_c_empty_saved_candidates_once() -> void:
	var session = _session_for("Backfill", 10)
	var companion := _companion("legacy-candidate", "nessa", "hunter", 10, "hunter_volley")
	session.party.candidates.append(CandidateClass.new("legacy", companion, 2, 50))
	session.party.candidates_day = 2
	assert_true(
		RecruitmentServiceClass.ensure_daily_candidates(session.party, session.player, 2, "S")
	)
	assert_false(BuildServiceClass.needs_initial_build(companion))
	assert_eq(_attribute_points(companion), 40)
	assert_false(
		RecruitmentServiceClass.ensure_daily_candidates(session.party, session.player, 2, "S")
	)


func test_stage_six_c_build_snapshot_is_frozen_independently_from_stage_six_b() -> void:
	var session = _session_for("Aria", 0)
	RecruitmentServiceClass.ensure_daily_candidates(session.party, session.player, 2, "E")
	assert_eq(
		_build_snapshot(session.party.candidates[0].companion),
		{
			"attributes":
			{
				"strength": 6,
				"vitality": 4,
				"intelligence": 0,
				"dexterity": 8,
				"endurance": 2,
				"luck": 0,
			},
			"talents": {"hunter_frost_arrow": 1},
			"equipment":
			{
				"weapon": ["hunting_bow", 0, null],
				"off_hand": ["simple_quiver", 0, null],
				"chest": ["stitched_armor", 0, null],
				"hands": ["drowned_gauntlets", 0, null],
				"feet": ["spiderstep_boots", 0, null],
				"belt": ["bearhide_belt", 0, null],
				"bracelet": ["nature_bracelet", 0, null],
				"earrings": ["nature_earrings", 0, null],
				"ring": ["witchbone_ring", 0, null],
			},
			"storage": [],
			"personal_instance_ids":
			[
				"npc-dorian-2-0-7939-hunting_bow-0",
				"npc-dorian-2-0-7939-simple_quiver-1",
				"npc-dorian-2-0-7939-stitched_armor-2",
				"npc-dorian-2-0-7939-drowned_gauntlets-3",
				"npc-dorian-2-0-7939-spiderstep_boots-4",
				"npc-dorian-2-0-7939-bearhide_belt-5",
				"npc-dorian-2-0-7939-nature_bracelet-6",
				"npc-dorian-2-0-7939-nature_earrings-7",
				"npc-dorian-2-0-7939-witchbone_ring-8",
			],
		},
	)


func test_class_progression_and_rift_unique_catalog_is_complete() -> void:
	var required_ids := []
	for options in BuildServiceClass.CLASS_WEAPONS.values():
		for option in options:
			required_ids.append(str(option[1]))
	for options in BuildServiceClass.CLASS_OFFHANDS.values():
		for option in options:
			required_ids.append(str(option[1]))
	for item_ids in BuildServiceClass.GENERIC_SLOT_ITEMS.values():
		required_ids.append_array(item_ids)
	for item_ids in BuildServiceClass.RIFT_UNIQUES_BY_CLASS.values():
		required_ids.append_array(item_ids)
	for item_id: String in required_ids:
		var definition = ItemCatalogClass.get_definition(item_id)
		assert_not_null(definition, item_id)
		assert_true(definition.is_equipment(), item_id)
		assert_gt(definition.item_power, 0, item_id)

	var varek := _companion("varek-build", "kael", "warrior", 20, "warrior_assault")
	assert_true(BuildServiceClass.ensure_initial_build(varek))
	var varek_items := varek.equipment.slots.values() + varek.personal_storage
	var sabres = varek_items.filter(func(item) -> bool: return item.item_id == "varek_sabre")
	assert_eq(sabres.size(), 1)
	assert_between(int(sabres[0].average_damage_percent), -8, 22)
	var generated_sabre = ItemCatalogClass.create_equipment_item("varek_sabre", _rng(12))
	assert_between(int(generated_sabre.average_damage_percent), -8, 22)
	var equipment := PlayerEquipmentClass.new()
	equipment.equip_and_return_previous(
		ItemCatalogClass.create_equipment_item("last_guard_plate", _rng(13))
	)
	var warrior_bonuses := equipment.total_bonuses("warrior")
	var hunter_bonuses := equipment.total_bonuses("hunter")
	assert_eq(warrior_bonuses.defense - hunter_bonuses.defense, 7)
	assert_eq(warrior_bonuses.max_hp - hunter_bonuses.max_hp, 80)


func test_player_owned_gear_can_replace_and_restore_personal_gear() -> void:
	var session = _session_for("Gear", 10)
	var companion := _companion("hunter-gear", "nessa", "hunter", 10, "hunter_volley")
	BuildServiceClass.ensure_initial_build(companion)
	var personal_weapon = companion.equipment.get_item("weapon")
	assert_true(companion.owns_item(personal_weapon))
	var player_item = ItemCatalogClass.create_equipment_item("starter_sword", _rng(4))
	var player_item_id: String = player_item.instance_id
	assert_true(session.player.inventory.add_equipment_instance(player_item))

	var equip_result := CompanionEquipmentServiceClass.equip_player_item(
		session.player, companion, 0
	)
	assert_true(equip_result.ok, equip_result.message)
	assert_eq(companion.equipment.get_item("weapon").instance_id, player_item_id)
	assert_false(companion.owns_item(companion.equipment.get_item("weapon")))
	assert_has(companion.personal_storage, personal_weapon)

	var remove_result := CompanionEquipmentServiceClass.remove_player_item(
		session.player, companion, "weapon"
	)
	assert_true(remove_result.ok, remove_result.message)
	assert_eq(session.player.inventory.equipment_items[0].instance_id, player_item_id)
	assert_eq(companion.equipment.get_item("weapon"), personal_weapon)
	assert_true(companion.owns_item(personal_weapon))
	assert_false(
		CompanionEquipmentServiceClass.remove_player_item(session.player, companion, "weapon").ok
	)


func test_equipment_transfer_validates_level_and_class_without_mutation() -> void:
	var session = _session_for("Rules", 10)
	var companion := _companion("hunter-rules", "nessa", "hunter", 5, "hunter_volley")
	BuildServiceClass.ensure_initial_build(companion)
	var mage_item = ItemCatalogClass.create_equipment_item("apprentice_staff", _rng(5))
	session.player.inventory.add_equipment_instance(mage_item)
	var before_weapon = companion.equipment.get_item("weapon")
	var result := CompanionEquipmentServiceClass.equip_player_item(session.player, companion, 0)
	assert_false(result.ok)
	assert_string_contains(result.message, "Mag")
	assert_eq(session.player.inventory.equipment_items.size(), 1)
	assert_eq(companion.equipment.get_item("weapon"), before_weapon)


func test_dismiss_returns_every_player_owned_item_and_restores_personal_slots() -> void:
	var session = _session_for("Dismiss", 20)
	var companion := _companion("dismiss-gear", "kael", "warrior", 20, "warrior_assault")
	BuildServiceClass.ensure_initial_build(companion)
	session.party.companions.append(companion)
	var player_weapon = ItemCatalogClass.create_equipment_item("starter_sword", _rng(6))
	var player_armor = ItemCatalogClass.create_equipment_item("worn_leather_armor", _rng(7))
	var returned_ids := [player_weapon.instance_id, player_armor.instance_id]
	session.player.inventory.add_equipment_instance(player_weapon)
	session.player.inventory.add_equipment_instance(player_armor)
	assert_true(CompanionEquipmentServiceClass.equip_player_item(session.player, companion, 0).ok)
	assert_true(CompanionEquipmentServiceClass.equip_player_item(session.player, companion, 0).ok)

	var result := RecruitmentServiceClass.dismiss_companion(
		session.party, session.player, companion.companion_id, 4
	)
	assert_true(result.ok, result.message)
	assert_eq(result.returned_items.size(), 2)
	assert_true(session.party.companions.is_empty())
	assert_eq(session.party.dismissed_companions.size(), 1)
	var inventory_ids: Array = session.player.inventory.equipment_items.map(
		func(item) -> String: return item.instance_id
	)
	for instance_id: String in returned_ids:
		assert_has(inventory_ids, instance_id)
	for item in companion.equipment.slots.values():
		assert_true(companion.owns_item(item), item.formatted_name())
	for item in companion.personal_storage:
		assert_true(companion.owns_item(item), item.formatted_name())


func test_progression_and_resource_sentinel_match_terminal_semantics() -> void:
	var companion := _companion("leveling", "elyra", "mage", 5, "mage_elements")
	BuildServiceClass.ensure_initial_build(companion)
	var attribute_points := _attribute_points(companion)
	var required := BuildServiceClass.experience_to_next_level(companion.level)
	assert_eq(BuildServiceClass.gain_experience(companion, required), 1)
	assert_eq(companion.level, 6)
	assert_eq(_attribute_points(companion), attribute_points + 4)
	assert_eq(
		_talent_points(companion),
		TalentProgressionServiceClass.total_points_for_level(companion.level, true),
	)
	assert_eq(companion.current_hp, 0)
	assert_eq(companion.current_mana, 0)
	var limits := BuildServiceClass.resource_limits(companion)
	var resources := BuildServiceClass.resolved_resources(companion)
	assert_eq(resources.current_hp, limits.max_hp)
	assert_eq(resources.current_mana, limits.max_mana)
	BuildServiceClass.sync_resources(companion, 7, 3)
	resources = BuildServiceClass.resolved_resources(companion)
	assert_eq(resources.current_hp, 7)
	assert_eq(resources.current_mana, 3)
	companion.dead = true
	assert_eq(BuildServiceClass.gain_experience(companion, required), 0)


func test_full_build_and_mixed_ownership_round_trip_without_schema_bump() -> void:
	var session = _session_for("Save", 20)
	var companion := _companion("save-build", "kael", "warrior", 20, "warrior_assault")
	BuildServiceClass.ensure_initial_build(companion)
	session.party.companions.append(companion)
	var player_item = ItemCatalogClass.create_equipment_item("starter_sword", _rng(8))
	var player_item_id: String = player_item.instance_id
	session.player.inventory.add_equipment_instance(player_item)
	assert_true(CompanionEquipmentServiceClass.equip_player_item(session.player, companion, 0).ok)
	BuildServiceClass.sync_resources(companion, 12, 4)

	var service := SaveGameServiceClass.new("user://stage_six_c_not_written")
	var payload: Dictionary = service._serialize_session(session)
	assert_eq(payload.schema_version, 13)
	var loaded := service._deserialize_payload(payload, 1)
	assert_true(loaded.ok, loaded.message)
	var restored = loaded.session.party.companions[0]
	assert_eq(_build_snapshot(restored), _build_snapshot(companion))
	assert_eq(restored.equipment.get_item("weapon").instance_id, player_item_id)
	assert_false(restored.owns_item(restored.equipment.get_item("weapon")))
	assert_eq(restored.current_hp, 12)
	assert_eq(restored.current_mana, 4)


func test_existing_party_hub_manages_companion_equipment_without_new_route() -> void:
	var session = _session_for("UI", 10)
	var companion := _companion("ui-gear", "nessa", "hunter", 10, "hunter_volley")
	BuildServiceClass.ensure_initial_build(companion)
	session.party.companions.append(companion)
	session.player.inventory.add_equipment_instance(
		ItemCatalogClass.create_equipment_item("starter_sword", _rng(9))
	)
	var screen = PARTY_HUB_SCENE.instantiate()
	screen.configure(session)
	add_child_autofree(screen)
	await get_tree().process_frame
	assert_gt(screen.companion_equipment_list.item_count, 1)
	assert_eq(screen.player_equipment_list.item_count, 1)
	screen.player_equipment_list.select(0)
	screen.player_equipment_list.item_selected.emit(0)
	assert_false(screen.equip_player_item_button.disabled)
	screen.equip_player_item_button.pressed.emit()
	assert_true(session.player.inventory.equipment_items.is_empty())
	assert_eq(companion.equipment.get_item("weapon").item_id, "starter_sword")
	assert_false(screen.return_player_item_button.disabled)
	screen.return_player_item_button.pressed.emit()
	assert_eq(session.player.inventory.equipment_items.size(), 1)
	assert_true(companion.owns_item(companion.equipment.get_item("weapon")))


func _session_for(display_name: String, level: int):
	var session = NewGameServiceClass.new().create_session(display_name, 1, _rng(1))
	session.player.level = level
	return session


func _companion(
	companion_id: String, template_id: String, class_code: String, level: int, path_id: String
) -> CompanionStateClass:
	var definition = CatalogClass.get_definition(template_id)
	var companion := CompanionStateClass.new(
		companion_id, template_id, definition.display_name, class_code
	)
	companion.level = level
	companion.path_id = path_id
	return companion


func _attribute_points(companion: CompanionStateClass) -> int:
	var result := 0
	for value in companion.attributes.as_display_dict().values():
		result += int(value)
	return result


func _talent_points(companion: CompanionStateClass) -> int:
	var result := 0
	for value in companion.talents.values():
		result += int(value)
	return result


func _build_snapshot(companion: CompanionStateClass) -> Dictionary:
	var equipment := {}
	for slot: String in companion.equipment.slots:
		var item = companion.equipment.slots[slot]
		equipment[slot] = [item.item_id, item.upgrade_level, item.average_damage_percent]
	var storage := companion.personal_storage.map(
		func(item) -> Array: return [item.item_id, item.upgrade_level, item.average_damage_percent]
	)
	return {
		"attributes":
		{
			"strength": companion.attributes.strength,
			"vitality": companion.attributes.vitality,
			"intelligence": companion.attributes.intelligence,
			"dexterity": companion.attributes.dexterity,
			"endurance": companion.attributes.endurance,
			"luck": companion.attributes.luck,
		},
		"talents": companion.talents.duplicate(true),
		"equipment": equipment,
		"storage": storage,
		"personal_instance_ids": companion.personal_instance_ids.duplicate(),
	}


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng
