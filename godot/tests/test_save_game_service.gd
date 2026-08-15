extends GutTest

const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const PlayerEquipmentClass := preload("res://core/player/equipment.gd")
const QuestServiceClass := preload("res://core/quests/quest_service.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")

var _save_root: String
var _service: SaveGameServiceClass


func before_each() -> void:
	_save_root = "user://test_godot_saves_%s" % Crypto.new().generate_random_bytes(8).hex_encode()
	_service = SaveGameServiceClass.new(_save_root)


func after_each() -> void:
	var directory := DirAccess.open(_save_root)
	if directory != null:
		for file_name in directory.get_files():
			DirAccess.remove_absolute(
				ProjectSettings.globalize_path("%s/%s" % [_save_root, file_name])
			)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_save_root))


func test_empty_slots_have_clear_summaries() -> void:
	var summaries := _service.get_slot_summaries()

	assert_eq(summaries.size(), 4)
	assert_false(_service.any_save_exists())
	assert_false(summaries[0].exists)
	assert_false(summaries[0].valid)
	assert_eq(summaries[0].label, "Slot 1 — pusty")


func test_round_trip_preserves_the_current_migrated_state() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 2)
	session.day = 4
	session.hour = 21
	session.prologue_stage = 5
	session.prologue_completed = true
	session.guild_reputation = 17
	session.last_activity = "Powrót z wyprawy."
	session.victories = 3
	session.last_inn_rest_day = 3
	session.quest_log.active[QuestServiceClass.STORY_QUEST_ID] = 1
	session.player.level = 5
	session.player.experience = 12
	session.player.gold = 87
	session.player.rubies = 2
	session.player.unspent_attribute_points = 20
	session.player.carry_upgrade_level = 2
	assert_true(session.player.choose_class("pierrot"))
	assert_true(session.player.attributes.increase("vitality", 2))
	assert_true(session.player.attributes.increase("luck", 3))
	session.player.recalculate_stats()
	session.player.stats.current_hp = 7
	session.player.stats.current_mana = 5
	assert_true(session.player.inventory.add("weak_leather", 4))
	assert_true(session.player.inventory.add("leather_hood"))
	session.player.inventory.equipment_items[0].upgrade_level = 4
	session.guild_storage.inventory.add("weak_leather", 31)
	var stored_item = ItemCatalogClass.create_equipment_item("nature_amulet")
	stored_item.upgrade_level = 6
	session.guild_storage.inventory.add_equipment_instance(stored_item)
	var weapon_instance_id: String = (
		session.player.equipment.get_item(PlayerEquipmentClass.WEAPON).instance_id
	)
	var backpack_instance_id: String = session.player.inventory.equipment_items[0].instance_id

	var save_result := _service.save_session(session)
	var load_result := _service.load_session(2)

	assert_true(save_result.ok, save_result.message)
	assert_true(load_result.ok, load_result.message)
	var loaded = load_result.session
	assert_eq(loaded.save_slot, 2)
	assert_eq(loaded.day, 4)
	assert_eq(loaded.hour, 21)
	assert_true(loaded.prologue_completed)
	assert_eq(loaded.guild_reputation, 17)
	assert_eq(loaded.last_activity, "Powrót z wyprawy.")
	assert_eq(loaded.victories, 3)
	assert_eq(loaded.last_inn_rest_day, 3)
	assert_eq(loaded.quest_log.active[QuestServiceClass.STORY_QUEST_ID], 1)
	assert_eq(loaded.player.display_name, "Aria")
	assert_eq(loaded.player.level, 5)
	assert_eq(loaded.player.experience, 12)
	assert_eq(loaded.player.gold, 87)
	assert_eq(loaded.player.rubies, 2)
	assert_eq(loaded.player.character_class_code, "pierrot")
	assert_eq(loaded.player.carry_upgrade_level, 2)
	assert_eq(loaded.player.attributes.vitality, 2)
	assert_eq(loaded.player.attributes.luck, 3)
	assert_eq(loaded.player.stats.current_hp, 7)
	assert_eq(loaded.player.stats.current_mana, 5)
	assert_eq(loaded.player.inventory.count("weak_leather"), 4)
	assert_eq(loaded.player.inventory.equipment_items[0].upgrade_level, 4)
	assert_eq(loaded.player.inventory.equipment_items[0].instance_id, backpack_instance_id)
	assert_eq(
		loaded.player.equipment.get_item(PlayerEquipmentClass.WEAPON).instance_id,
		weapon_instance_id
	)
	assert_eq(loaded.guild_storage.inventory.count("weak_leather"), 31)
	assert_eq(
		loaded.guild_storage.inventory.equipment_items[0].instance_id, stored_item.instance_id
	)
	assert_eq(loaded.guild_storage.inventory.equipment_items[0].upgrade_level, 6)


func test_corrupt_and_future_saves_are_rejected_without_loading_a_session() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	assert_true(_service.save_session(session).ok)
	var slot_path := "%s/save_1.json" % _save_root
	var file := FileAccess.open(slot_path, FileAccess.WRITE)
	file.store_string("{to nie jest json")
	file.close()

	var corrupt_result := _service.load_session(1)
	assert_false(corrupt_result.ok)
	assert_true(corrupt_result.message.contains("uszkodzony"))

	file = FileAccess.open(slot_path, FileAccess.WRITE)
	(
		file
		. store_string(
			(
				JSON
				. stringify(
					{
						"format_id": SaveGameServiceClass.FORMAT_ID,
						"schema_version": SaveGameServiceClass.SCHEMA_VERSION + 1,
					}
				)
			)
		)
	)
	file.close()
	var future_result := _service.load_session(1)
	assert_false(future_result.ok)
	assert_true(future_result.message.contains("nowszej wersji"))


func test_save_uses_a_dedicated_godot_directory() -> void:
	assert_eq(SaveGameServiceClass.DEFAULT_SAVE_ROOT, "user://godot_migration_saves")
	assert_eq(SaveGameServiceClass.SCHEMA_VERSION, 4)


func test_round_trip_preserves_hunter_techniques_and_discovered_combos() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 5
	assert_true(session.player.choose_class("hunter"))
	session.player.unlocked_talent_skill_ids.assign(["phantom_arrow", "frost_arrow"])
	session.player.discovered_hunter_combos.assign(["phantom_parade", "brittle_burst"])

	var save_result := _service.save_session(session)
	var load_result := _service.load_session(1)

	assert_true(save_result.ok, save_result.message)
	assert_true(load_result.ok, load_result.message)
	assert_eq(
		load_result.session.player.unlocked_talent_skill_ids,
		["phantom_arrow", "frost_arrow"],
	)
	assert_eq(
		load_result.session.player.discovered_hunter_combos,
		["phantom_parade", "brittle_burst"],
	)


func test_schema_two_save_migrates_with_empty_hunter_progression() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	assert_true(_service.save_session(session).ok)
	var slot_path := "%s/save_1.json" % _save_root
	var file := FileAccess.open(slot_path, FileAccess.READ)
	var payload: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	payload.schema_version = 2
	payload.session.player.erase("unlocked_talent_skill_ids")
	payload.session.player.erase("discovered_hunter_combos")
	file = FileAccess.open(slot_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(payload))
	file.close()

	var result := _service.load_session(1)

	assert_true(result.ok, result.message)
	assert_true(result.session.player.unlocked_talent_skill_ids.is_empty())
	assert_true(result.session.player.unlocked_class_mechanic_ids.is_empty())
	assert_true(result.session.player.discovered_hunter_combos.is_empty())


func test_save_rejects_hunter_progression_on_another_class() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 5
	assert_true(session.player.choose_class("warrior"))
	session.player.unlocked_talent_skill_ids.append("phantom_arrow")

	var result := _service.save_session(session)

	assert_false(result.ok)
	assert_string_contains(result.message, "niedozwoloną umiejętność talentową")


func test_round_trip_preserves_warrior_skills_and_class_mechanics() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 5
	assert_true(session.player.choose_class("warrior"))
	session.player.unlocked_talent_skill_ids.assign(["shield_bash", "provoke"])
	session.player.unlocked_class_mechanic_ids.assign(
		["heavy_knight_core", "heavy_counter", "heavy_bastion"]
	)

	var save_result := _service.save_session(session)
	var load_result := _service.load_session(1)

	assert_true(save_result.ok, save_result.message)
	assert_true(load_result.ok, load_result.message)
	assert_eq(
		load_result.session.player.unlocked_talent_skill_ids,
		["shield_bash", "provoke"],
	)
	assert_eq(
		load_result.session.player.unlocked_class_mechanic_ids,
		["heavy_knight_core", "heavy_counter", "heavy_bastion"],
	)


func test_schema_three_save_migrates_with_empty_class_mechanics() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	assert_true(_service.save_session(session).ok)
	var slot_path := "%s/save_1.json" % _save_root
	var file := FileAccess.open(slot_path, FileAccess.READ)
	var payload: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	payload.schema_version = 3
	payload.session.player.erase("unlocked_class_mechanic_ids")
	file = FileAccess.open(slot_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(payload))
	file.close()

	var result := _service.load_session(1)

	assert_true(result.ok, result.message)
	assert_true(result.session.player.unlocked_class_mechanic_ids.is_empty())


func test_schema_one_save_migrates_with_safe_economy_defaults() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	assert_true(_service.save_session(session).ok)
	var slot_path := "%s/save_1.json" % _save_root
	var file := FileAccess.open(slot_path, FileAccess.READ)
	var payload: Dictionary = JSON.parse_string(file.get_as_text())
	file.close()
	payload.schema_version = 1
	payload.session.erase("last_inn_rest_day")
	payload.session.erase("guild_storage")
	payload.session.player.erase("carry_upgrade_level")
	file = FileAccess.open(slot_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(payload))
	file.close()

	var result := _service.load_session(1)
	assert_true(result.ok, result.message)
	assert_eq(result.session.last_inn_rest_day, 0)
	assert_eq(result.session.player.carry_upgrade_level, 0)
	assert_true(result.session.guild_storage.inventory.is_empty())


func test_save_rejects_invalid_class_progression_and_equipped_requirements() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.character_class_code = "hunter"
	var early_class_result := _service.save_session(session)
	assert_false(early_class_result.ok)
	assert_string_contains(early_class_result.message, "poziomem 5")

	session.player.level = 5
	session.player.character_class_code = "warrior"
	var illegal_bow = ItemCatalogClass.create_equipment_item("hunting_bow")
	session.player.equipment.equip_and_return_previous(illegal_bow)
	session.player.recalculate_stats()
	var illegal_equipment_result := _service.save_session(session)
	assert_false(illegal_equipment_result.ok)
	assert_string_contains(illegal_equipment_result.message, "wymaga klasy: Łowca")
