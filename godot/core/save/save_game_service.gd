class_name SaveGameService
extends RefCounted

const EquipmentItemClass := preload("res://core/items/equipment_item.gd")
const GameSessionClass := preload("res://core/game/game_session.gd")
const HunterComboCatalogClass := preload("res://core/combat/hunter_combo_catalog.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const PlayerAttributesClass := preload("res://core/player/attributes.gd")
const PlayerEquipmentClass := preload("res://core/player/equipment.gd")
const PlayerProfileClass := preload("res://core/player/player_profile.gd")
const QuestServiceClass := preload("res://core/quests/quest_service.gd")
const SkillCatalogClass := preload("res://core/skills/skill_catalog.gd")

const FORMAT_ID := "echoes_of_pythonia_godot_migration"
const SCHEMA_VERSION := 3
const GAME_VERSION := "0.25.0"
const DEFAULT_SAVE_ROOT := "user://godot_migration_saves"
const SLOT_COUNT := NewGameServiceClass.SAVE_SLOT_COUNT
const VALID_CLASS_CODES := ["none", "warrior", "hunter", "mage", "pierrot"]
const VALID_EQUIPMENT_SLOTS := [
	PlayerEquipmentClass.WEAPON,
	PlayerEquipmentClass.HEAD,
	PlayerEquipmentClass.CHEST,
	PlayerEquipmentClass.HANDS,
	PlayerEquipmentClass.FEET,
	PlayerEquipmentClass.BELT,
	PlayerEquipmentClass.NECKLACE,
	PlayerEquipmentClass.BRACELET,
	PlayerEquipmentClass.EARRINGS,
	PlayerEquipmentClass.RING,
	PlayerEquipmentClass.OFF_HAND,
]
const ATTRIBUTE_CODES := [
	PlayerAttributesClass.STRENGTH,
	PlayerAttributesClass.VITALITY,
	PlayerAttributesClass.INTELLIGENCE,
	PlayerAttributesClass.DEXTERITY,
	PlayerAttributesClass.ENDURANCE,
	PlayerAttributesClass.LUCK,
]

var _save_root: String


func _init(custom_save_root := "") -> void:
	_save_root = custom_save_root if not custom_save_root.is_empty() else DEFAULT_SAVE_ROOT


func save_exists(slot: int) -> bool:
	return _is_valid_slot(slot) and FileAccess.file_exists(_slot_path(slot))


func any_save_exists() -> bool:
	for slot in range(1, SLOT_COUNT + 1):
		if save_exists(slot):
			return true
	return false


# Early returns keep malformed save data from reaching object construction.
# gdlint: disable=max-returns
func save_session(session: GameSessionClass) -> Dictionary:
	if session == null or session.player == null:
		return _failure("Brak aktywnej sesji do zapisania.")
	if not _is_valid_slot(session.save_slot):
		return _failure("Nieprawidłowy slot zapisu.")

	var payload := _serialize_session(session)
	var validation := _deserialize_payload(payload, session.save_slot)
	if not validation.ok:
		return _failure("Nie można zapisać sesji: %s" % validation.message)
	var directory_error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(_save_root)
	)
	if directory_error != OK:
		return _failure("Nie udało się utworzyć katalogu zapisów.")

	var final_path := _slot_path(session.save_slot)
	var temporary_path := final_path + ".tmp"
	var backup_path := final_path + ".bak"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return _failure("Nie udało się otworzyć pliku zapisu.")
	file.store_string(JSON.stringify(payload, "\t", false))
	file.flush()
	file.close()

	var replace_result := _replace_file_safely(temporary_path, final_path, backup_path)
	if not replace_result.ok:
		return replace_result
	return {
		"ok": true,
		"message": "Zapisano grę w slocie %d." % session.save_slot,
		"path": final_path,
	}


func load_session(slot: int) -> Dictionary:
	if not _is_valid_slot(slot):
		return _failure("Nieprawidłowy slot zapisu.")
	var path := _slot_path(slot)
	if not FileAccess.file_exists(path):
		return _failure("Slot %d jest pusty." % slot)
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _failure("Nie udało się otworzyć zapisu.")
	var json := JSON.new()
	var parse_error := json.parse(file.get_as_text())
	file.close()
	if parse_error != OK or not json.data is Dictionary:
		return _failure("Plik zapisu jest uszkodzony albo nie jest plikiem JSON.")
	return _deserialize_payload(json.data, slot)


func get_slot_summaries() -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []
	for slot in range(1, SLOT_COUNT + 1):
		var summary := {
			"slot": slot,
			"exists": save_exists(slot),
			"valid": false,
			"label": "Slot %d — pusty" % slot,
		}
		if summary.exists:
			var result := load_session(slot)
			if result.ok:
				var session: GameSessionClass = result.session
				summary.valid = true
				summary.label = _format_summary(session, result.saved_at_unix)
			else:
				summary.label = "Slot %d — zapis uszkodzony" % slot
		summaries.append(summary)
	return summaries


func _serialize_session(session: GameSessionClass) -> Dictionary:
	var player := session.player
	return {
		"format_id": FORMAT_ID,
		"schema_version": SCHEMA_VERSION,
		"game_version": GAME_VERSION,
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"session":
		{
			"save_slot": session.save_slot,
			"current_location_id": session.current_location_id,
			"current_city_id": session.current_city_id,
			"day": session.day,
			"hour": session.hour,
			"is_active": session.is_active,
			"prologue_stage": session.prologue_stage,
			"prologue_completed": session.prologue_completed,
			"guild_reputation": session.guild_reputation,
			"last_activity": session.last_activity,
			"victories": session.victories,
			"last_inn_rest_day": session.last_inn_rest_day,
			"guild_storage": _serialize_inventory(session.guild_storage.inventory),
			"quest_log":
			{
				"active": session.quest_log.active.duplicate(true),
				"completed": session.quest_log.completed.duplicate(true),
			},
			"player":
			{
				"display_name": player.display_name,
				"level": player.level,
				"experience": player.experience,
				"gold": player.gold,
				"rubies": player.rubies,
				"unspent_attribute_points": player.unspent_attribute_points,
				"character_class_code": player.character_class_code,
				"carry_upgrade_level": player.carry_upgrade_level,
				"unlocked_talent_skill_ids": player.unlocked_talent_skill_ids.duplicate(),
				"discovered_hunter_combos": player.discovered_hunter_combos.duplicate(),
				"attributes": _serialize_attributes(player.attributes),
				"current_hp": player.stats.current_hp,
				"current_mana": player.stats.current_mana,
				"equipment": _serialize_equipment(player.equipment.slots),
				"inventory": _serialize_inventory(player.inventory),
			},
		},
	}


func _deserialize_payload(payload: Dictionary, expected_slot: int) -> Dictionary:
	if payload.get("format_id", "") != FORMAT_ID:
		return _failure("To nie jest zapis wersji Godot.")
	if not _is_integer(payload.get("schema_version")):
		return _failure("Zapis nie zawiera prawidłowej wersji schematu.")
	var schema_version := int(payload.schema_version)
	if schema_version > SCHEMA_VERSION:
		return _failure("Zapis pochodzi z nowszej wersji gry.")
	if schema_version < SCHEMA_VERSION:
		var migration_result := _migrate_payload(payload)
		if not migration_result.ok:
			return migration_result
		payload = migration_result.payload
	if not payload.get("session") is Dictionary:
		return _failure("Zapis nie zawiera sesji.")

	var session_data: Dictionary = payload.session
	if not _is_integer(session_data.get("save_slot")):
		return _failure("Zapis nie zawiera prawidłowego slotu.")
	var slot := int(session_data.save_slot)
	if slot != expected_slot or not _is_valid_slot(slot):
		return _failure("Numer slotu w pliku nie zgadza się z wybranym slotem.")
	if not session_data.get("player") is Dictionary:
		return _failure("Zapis nie zawiera danych bohatera.")

	var player_result := _deserialize_player(session_data.player)
	if not player_result.ok:
		return player_result
	var session := GameSessionClass.new(slot, player_result.player)
	var session_result := _restore_session_fields(session, session_data)
	if not session_result.ok:
		return session_result
	return {
		"ok": true,
		"message": "Wczytano slot %d." % slot,
		"session": session,
		"saved_at_unix": int(payload.get("saved_at_unix", 0)),
	}


func _deserialize_player(data: Dictionary) -> Dictionary:
	var player_name := str(data.get("display_name", "")).strip_edges()
	var name_error := NewGameServiceClass.new().get_player_name_error(player_name)
	if not name_error.is_empty():
		return _failure("Nieprawidłowe imię bohatera: %s" % name_error)
	var numeric_fields := [
		"level",
		"experience",
		"gold",
		"rubies",
		"unspent_attribute_points",
		"carry_upgrade_level",
		"current_hp",
		"current_mana",
	]
	for field: String in numeric_fields:
		if not _is_non_negative_integer(data.get(field)):
			return _failure("Nieprawidłowa wartość pola bohatera: %s." % field)
	var class_code := str(data.get("character_class_code", ""))
	if not class_code in VALID_CLASS_CODES:
		return _failure("Zapis zawiera nieznaną Drogę bohatera.")
	if not data.get("attributes") is Dictionary:
		return _failure("Zapis nie zawiera atrybutów bohatera.")
	if not data.get("equipment") is Dictionary or not data.get("inventory") is Dictionary:
		return _failure("Zapis nie zawiera kompletnego ekwipunku.")

	var player := PlayerProfileClass.new(player_name)
	player.level = int(data.level)
	player.experience = int(data.experience)
	player.gold = int(data.gold)
	player.rubies = int(data.rubies)
	player.unspent_attribute_points = int(data.unspent_attribute_points)
	player.carry_upgrade_level = int(data.carry_upgrade_level)
	if player.carry_upgrade_level > 3:
		return _failure("Zapis zawiera nieprawidłowy poziom ulepszenia udźwigu.")
	player.character_class_code = class_code
	if class_code != PlayerProfileClass.CLASS_NONE and player.level < 5:
		return _failure("Zapis wybiera Drogę przed wymaganym poziomem 5.")
	var attributes_result := _restore_attributes(player, data.attributes)
	if not attributes_result.ok:
		return attributes_result
	if player.attributes.luck > 0 and class_code != PlayerProfileClass.CLASS_PIERROT:
		return _failure("Zapis przyznaje Szczęście postaci, która nie jest Pierrotem.")
	var hunter_progression_result := _restore_hunter_progression(player, data)
	if not hunter_progression_result.ok:
		return hunter_progression_result
	var equipment_result := _restore_equipment(player, data.equipment)
	if not equipment_result.ok:
		return equipment_result
	var inventory_result := _restore_inventory(player, data.inventory)
	if not inventory_result.ok:
		return inventory_result
	player.recalculate_stats()
	if int(data.current_hp) > player.stats.max_hp or int(data.current_mana) > player.stats.max_mana:
		return _failure("Zapis zawiera statystyki przekraczające maksimum bohatera.")
	player.stats.current_hp = int(data.current_hp)
	player.stats.current_mana = int(data.current_mana)
	return {"ok": true, "player": player}


func _restore_session_fields(session: GameSessionClass, data: Dictionary) -> Dictionary:
	var numeric_fields := [
		"day", "hour", "prologue_stage", "guild_reputation", "victories", "last_inn_rest_day"
	]
	for field: String in numeric_fields:
		if not _is_non_negative_integer(data.get(field)):
			return _failure("Nieprawidłowa wartość pola sesji: %s." % field)
	if int(data.day) < 1 or int(data.hour) > 23 or int(data.prologue_stage) > 5:
		return _failure("Zapis zawiera nieprawidłowy czas albo etap prologu.")
	if not data.get("is_active") is bool or not data.get("prologue_completed") is bool:
		return _failure("Zapis zawiera nieprawidłowe flagi sesji.")
	if not data.get("quest_log") is Dictionary:
		return _failure("Zapis nie zawiera dziennika zadań.")
	if not data.get("guild_storage") is Dictionary:
		return _failure("Zapis nie zawiera Magazynu Gildii.")
	var location_id := str(data.get("current_location_id", ""))
	var city_id := str(data.get("current_city_id", ""))
	if location_id != GameSessionClass.STARTING_LOCATION_ID:
		return _failure("Zapis wskazuje region, który nie został jeszcze przeniesiony.")
	if city_id != GameSessionClass.STARTING_CITY_ID:
		return _failure("Zapis wskazuje miasto, które nie zostało jeszcze przeniesione.")
	var quest_result := _restore_quest_log(session, data.quest_log)
	if not quest_result.ok:
		return quest_result
	var storage_result := _restore_inventory_container(
		session.guild_storage.inventory, data.guild_storage
	)
	if not storage_result.ok:
		return _failure("Nieprawidłowy Magazyn Gildii: %s" % storage_result.message)
	if session.guild_storage.used_slots > session.guild_storage.CAPACITY_SLOTS:
		return _failure("Magazyn Gildii przekracza limit miejsc.")

	session.current_location_id = location_id
	session.current_city_id = city_id
	session.day = int(data.day)
	session.hour = int(data.hour)
	session.is_active = data.is_active
	session.prologue_stage = int(data.prologue_stage)
	session.prologue_completed = data.prologue_completed
	session.guild_reputation = int(data.guild_reputation)
	session.last_activity = str(data.get("last_activity", ""))
	session.victories = int(data.victories)
	session.last_inn_rest_day = int(data.last_inn_rest_day)
	return {"ok": true}


# gdlint: enable=max-returns


func _restore_attributes(player: PlayerProfileClass, data: Dictionary) -> Dictionary:
	for attribute_code: String in ATTRIBUTE_CODES:
		if not _is_non_negative_integer(data.get(attribute_code)):
			return _failure("Nieprawidłowy atrybut bohatera: %s." % attribute_code)
	player.attributes.strength = int(data[PlayerAttributesClass.STRENGTH])
	player.attributes.vitality = int(data[PlayerAttributesClass.VITALITY])
	player.attributes.intelligence = int(data[PlayerAttributesClass.INTELLIGENCE])
	player.attributes.dexterity = int(data[PlayerAttributesClass.DEXTERITY])
	player.attributes.endurance = int(data[PlayerAttributesClass.ENDURANCE])
	player.attributes.luck = int(data[PlayerAttributesClass.LUCK])
	return {"ok": true}


func _restore_equipment(player: PlayerProfileClass, data: Dictionary) -> Dictionary:
	for slot_value in data:
		var slot := str(slot_value)
		if not slot in VALID_EQUIPMENT_SLOTS or not data[slot] is Dictionary:
			return _failure("Zapis zawiera nieprawidłowy slot wyposażenia.")
		var item_result := _deserialize_equipment_item(data[slot])
		if not item_result.ok:
			return item_result
		var item: EquipmentItemClass = item_result.item
		if item.slot != slot or player.equipment.get_item(slot) != null:
			return _failure("Przedmiot znajduje się w nieprawidłowym slocie.")
		var equip_error := player.get_item_equip_error(item)
		if not equip_error.is_empty():
			return _failure("Założony przedmiot nie spełnia wymagań: %s" % equip_error)
		player.equipment.equip_and_return_previous(item)
	return {"ok": true}


func _restore_inventory(player: PlayerProfileClass, data: Dictionary) -> Dictionary:
	return _restore_inventory_container(player.inventory, data)


func _restore_inventory_container(inventory, data: Dictionary) -> Dictionary:
	if not data.get("stacks") is Dictionary or not data.get("equipment_items") is Array:
		return _failure("Zapis zawiera nieprawidłowy plecak.")
	for item_id_value in data.stacks:
		var item_id := str(item_id_value)
		var definition = ItemCatalogClass.get_definition(item_id)
		var quantity = data.stacks[item_id]
		if definition == null or definition.is_equipment() or not _is_positive_integer(quantity):
			return _failure("Zapis zawiera nieprawidłowy stos przedmiotów.")
		inventory.stacks[item_id] = int(quantity)
	for item_data in data.equipment_items:
		if not item_data is Dictionary:
			return _failure("Zapis zawiera nieprawidłowy przedmiot w plecaku.")
		var item_result := _deserialize_equipment_item(item_data)
		if not item_result.ok:
			return item_result
		inventory.add_equipment_instance(item_result.item)
	return {"ok": true}


func _migrate_payload(payload: Dictionary) -> Dictionary:
	var migrated := payload.duplicate(true)
	var version := int(migrated.schema_version)
	if version == 1:
		if not migrated.get("session") is Dictionary:
			return _failure("Starszy zapis nie zawiera sesji.")
		var session: Dictionary = migrated.session
		if not session.get("player") is Dictionary:
			return _failure("Starszy zapis nie zawiera bohatera.")
		session.player["carry_upgrade_level"] = 0
		session["last_inn_rest_day"] = 0
		session["guild_storage"] = {"stacks": {}, "equipment_items": []}
		migrated.schema_version = 2
		version = 2
	if version == 2:
		if not migrated.get("session") is Dictionary:
			return _failure("Starszy zapis nie zawiera sesji.")
		var session: Dictionary = migrated.session
		if not session.get("player") is Dictionary:
			return _failure("Starszy zapis nie zawiera bohatera.")
		session.player["unlocked_talent_skill_ids"] = []
		session.player["discovered_hunter_combos"] = []
		migrated.schema_version = 3
		version = 3
	if version != SCHEMA_VERSION:
		return _failure("Zapis ma nieobsługiwaną, starszą wersję schematu.")
	return {"ok": true, "payload": migrated}


func _restore_hunter_progression(player: PlayerProfileClass, data: Dictionary) -> Dictionary:
	if (
		not data.get("unlocked_talent_skill_ids") is Array
		or not data.get("discovered_hunter_combos") is Array
	):
		return _failure("Zapis nie zawiera prawidłowej progresji technik Łowcy.")
	var seen_skills := {}
	for skill_id_value in data.unlocked_talent_skill_ids:
		if not skill_id_value is String:
			return _failure("Zapis zawiera nieprawidłową technikę Łowcy.")
		var skill_id := str(skill_id_value)
		if (
			player.character_class_code != "hunter"
			or not SkillCatalogClass.is_hunter_technique_id(skill_id)
			or seen_skills.has(skill_id)
		):
			return _failure("Zapis zawiera niedozwoloną technikę Łowcy.")
		seen_skills[skill_id] = true
		player.unlocked_talent_skill_ids.append(skill_id)
	var seen_combos := {}
	for combo_id_value in data.discovered_hunter_combos:
		if not combo_id_value is String:
			return _failure("Zapis zawiera nieprawidłową kombinację Łowcy.")
		var combo_id := str(combo_id_value)
		if (
			player.character_class_code != "hunter"
			or not HunterComboCatalogClass.is_valid_combo_id(combo_id)
			or seen_combos.has(combo_id)
		):
			return _failure("Zapis zawiera niedozwoloną kombinację Łowcy.")
		seen_combos[combo_id] = true
		player.discovered_hunter_combos.append(combo_id)
	return {"ok": true}


func _restore_quest_log(session: GameSessionClass, data: Dictionary) -> Dictionary:
	if not data.get("active") is Dictionary or not data.get("completed") is Dictionary:
		return _failure("Zapis zawiera nieprawidłowy dziennik zadań.")
	for quest_id_value in data.active:
		var quest_id := str(quest_id_value)
		var progress = data.active[quest_id]
		if (
			quest_id != QuestServiceClass.STORY_QUEST_ID
			or not _is_non_negative_integer(progress)
			or int(progress) > int(QuestServiceClass.STORY_QUEST.required_count)
		):
			return _failure("Zapis zawiera nieobsługiwane aktywne zadanie.")
		session.quest_log.active[quest_id] = int(progress)
	for quest_id_value in data.completed:
		var quest_id := str(quest_id_value)
		if quest_id != QuestServiceClass.STORY_QUEST_ID or data.completed[quest_id] != true:
			return _failure("Zapis zawiera nieobsługiwane ukończone zadanie.")
		if session.quest_log.active.has(quest_id):
			return _failure("To samo zadanie jest aktywne i ukończone.")
		session.quest_log.completed[quest_id] = true
	return {"ok": true}


func _deserialize_equipment_item(data: Dictionary) -> Dictionary:
	var item_id := str(data.get("item_id", ""))
	var definition = ItemCatalogClass.get_definition(item_id)
	if definition == null or not definition.is_equipment():
		return _failure("Zapis zawiera nieznany przedmiot wyposażenia.")
	if not _is_non_negative_integer(data.get("upgrade_level")):
		return _failure("Zapis zawiera nieprawidłowy poziom ulepszenia.")
	var upgrade_level := int(data.upgrade_level)
	if upgrade_level > EquipmentItemClass.MAX_UPGRADE_LEVEL:
		return _failure("Poziom ulepszenia przekracza dozwolone maksimum.")
	var instance_id := str(data.get("instance_id", ""))
	if instance_id.is_empty():
		return _failure("Przedmiot nie ma identyfikatora instancji.")
	var item := EquipmentItemClass.new(definition, upgrade_level)
	item.instance_id = instance_id
	return {"ok": true, "item": item}


func _serialize_attributes(attributes: PlayerAttributesClass) -> Dictionary:
	return {
		PlayerAttributesClass.STRENGTH: attributes.strength,
		PlayerAttributesClass.VITALITY: attributes.vitality,
		PlayerAttributesClass.INTELLIGENCE: attributes.intelligence,
		PlayerAttributesClass.DEXTERITY: attributes.dexterity,
		PlayerAttributesClass.ENDURANCE: attributes.endurance,
		PlayerAttributesClass.LUCK: attributes.luck,
	}


func _serialize_equipment(slots: Dictionary) -> Dictionary:
	var result := {}
	for slot in slots:
		result[slot] = _serialize_equipment_item(slots[slot])
	return result


func _serialize_equipment_items(items: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item: EquipmentItemClass in items:
		result.append(_serialize_equipment_item(item))
	return result


func _serialize_inventory(inventory) -> Dictionary:
	return {
		"stacks": inventory.stacks.duplicate(true),
		"equipment_items": _serialize_equipment_items(inventory.equipment_items),
	}


func _serialize_equipment_item(item: EquipmentItemClass) -> Dictionary:
	return {
		"item_id": item.item_id,
		"upgrade_level": item.upgrade_level,
		"instance_id": item.instance_id,
	}


func _replace_file_safely(
	temporary_path: String, final_path: String, backup_path: String
) -> Dictionary:
	var temporary_absolute := ProjectSettings.globalize_path(temporary_path)
	var final_absolute := ProjectSettings.globalize_path(final_path)
	var backup_absolute := ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(backup_path):
		DirAccess.remove_absolute(backup_absolute)
	var had_previous_save := FileAccess.file_exists(final_path)
	if had_previous_save:
		var backup_error := DirAccess.rename_absolute(final_absolute, backup_absolute)
		if backup_error != OK:
			DirAccess.remove_absolute(temporary_absolute)
			return _failure("Nie udało się zabezpieczyć poprzedniego zapisu.")
	var replace_error := DirAccess.rename_absolute(temporary_absolute, final_absolute)
	if replace_error != OK:
		if had_previous_save:
			DirAccess.rename_absolute(backup_absolute, final_absolute)
		DirAccess.remove_absolute(temporary_absolute)
		return _failure("Nie udało się zastąpić pliku zapisu.")
	if had_previous_save:
		DirAccess.remove_absolute(backup_absolute)
	return {"ok": true}


func _format_summary(session: GameSessionClass, saved_at_unix: int) -> String:
	var saved_at := ""
	if saved_at_unix > 0:
		var date := Time.get_datetime_dict_from_unix_time(saved_at_unix)
		saved_at = (
			"  •  %02d.%02d.%04d %02d:%02d"
			% [date.day, date.month, date.year, date.hour, date.minute]
		)
	return (
		"Slot %d — %s  •  poziom %d  •  dzień %d%s"
		% [
			session.save_slot,
			session.player.display_name,
			session.player.level,
			session.day,
			saved_at,
		]
	)


func _slot_path(slot: int) -> String:
	return "%s/save_%d.json" % [_save_root.trim_suffix("/"), slot]


func _is_valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= SLOT_COUNT


func _is_integer(value) -> bool:
	return (value is int or value is float) and is_equal_approx(float(value), floorf(float(value)))


func _is_non_negative_integer(value) -> bool:
	return _is_integer(value) and int(value) >= 0


func _is_positive_integer(value) -> bool:
	return _is_integer(value) and int(value) > 0


func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
