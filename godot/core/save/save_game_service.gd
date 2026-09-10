class_name SaveGameService
extends RefCounted

const EquipmentItemClass := preload("res://core/items/equipment_item.gd")
const EquipmentAffixServiceClass := preload("res://core/items/equipment_affix_service.gd")
const GameSessionClass := preload("res://core/game/game_session.gd")
const ClassCombatMechanicCatalogClass := preload(
	"res://core/combat/class_combat_mechanic_catalog.gd"
)
const HunterComboCatalogClass := preload("res://core/combat/hunter_combo_catalog.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const PlayerAttributesClass := preload("res://core/player/attributes.gd")
const PlayerEquipmentClass := preload("res://core/player/equipment.gd")
const PlayerProfileClass := preload("res://core/player/player_profile.gd")
const PassiveProgressionServiceClass := preload(
	"res://core/progression/passive_progression_service.gd"
)
const AchievementCatalogClass := preload("res://core/progression/achievement_catalog.gd")
const AchievementServiceClass := preload("res://core/progression/achievement_service.gd")
const QuestServiceClass := preload("res://core/quests/quest_service.gd")
const ContractServiceClass := preload("res://core/quests/contract_service.gd")
const BlackMarketServiceClass := preload("res://core/economy/black_market_service.gd")
const GuildMilestoneServiceClass := preload("res://core/quests/guild_milestone_service.gd")
const RegionCatalogClass := preload("res://core/world/region_catalog.gd")
const SkillCatalogClass := preload("res://core/skills/skill_catalog.gd")
const TalentProgressionServiceClass := preload(
	"res://core/progression/talent_progression_service.gd"
)
const WeatherServiceClass := preload("res://core/world/weather_service.gd")
const EquipmentSaveCodecClass := preload("res://core/save/equipment_save_codec.gd")
const PartySaveCodecClass := preload("res://core/save/party_save_codec.gd")
const ExpeditionPreparationSaveCodecClass := preload(
	"res://core/save/expedition_preparation_save_codec.gd"
)
const RiftSaveCodecClass := preload("res://core/save/rift_save_codec.gd")
const WorldEncounterSaveCodecClass := preload("res://core/save/world_encounter_save_codec.gd")
const StageSixSaveValidatorClass := preload("res://core/save/stage_six_save_validator.gd")

const FORMAT_ID := "echoes_of_pythonia_godot_migration"
const SCHEMA_VERSION := 18
const GAME_VERSION := "0.25.0"
const DEFAULT_SAVE_ROOT := "user://godot_migration_saves"
const SLOT_COUNT := NewGameServiceClass.SAVE_SLOT_COUNT
const VALID_CLASS_CODES := ["none", "warrior", "hunter", "mage", "pierrot"]
const VALID_GENDER_CODES := ["unspecified", "female", "male"]
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


func slot_path(slot: int) -> String:
	return _slot_path(slot) if _is_valid_slot(slot) else ""


# Early returns keep malformed save data from reaching object construction in all
# deserializers below.
# gdlint: disable=max-returns
func save_session(session: GameSessionClass) -> Dictionary:
	if session == null or session.player == null:
		return _failure("Brak aktywnej sesji do zapisania.")
	if not _is_valid_slot(session.save_slot):
		return _failure("Nieprawidłowy slot zapisu.")
	AchievementServiceClass.reconcile_existing_progress(session)

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
			"known_region_ids": session.known_region_ids.duplicate(),
			"current_city_id": session.current_city_id,
			"day": session.day,
			"hour": session.hour,
			"is_active": session.is_active,
			"prologue_stage": session.prologue_stage,
			"prologue_completed": session.prologue_completed,
			"guild_reputation": session.guild_reputation,
			"guild_milestones": session.guild_milestones.duplicate(),
			"adventure_log": session.adventure_log.entries.duplicate(),
			"black_market": BlackMarketServiceClass.serialize(session.black_market),
			"last_activity": session.last_activity,
			"victories": session.victories,
			"last_inn_rest_day": session.last_inn_rest_day,
			"weather_code": session.weather_code,
			"weather_remaining_hours": session.weather_remaining_hours,
			"camp_rest_available": session.camp_rest_available,
			"guild_storage": _serialize_inventory(session.guild_storage.inventory),
			"party": PartySaveCodecClass.serialize(session.party),
			"expedition_preparation":
			ExpeditionPreparationSaveCodecClass.serialize(session.expedition_preparation),
			"rifts": RiftSaveCodecClass.serialize(session.rifts),
			"world_encounters": WorldEncounterSaveCodecClass.serialize(session.world_encounters),
			"quest_log":
			{
				"active": session.quest_log.active.duplicate(true),
				"completed": session.quest_log.completed.duplicate(true),
			},
			"contracts": ContractServiceClass.serialize_board(session.contract_board),
			"player":
			{
				"display_name": player.display_name,
				"gender_code": player.gender_code,
				"level": player.level,
				"experience": player.experience,
				"gold": player.gold,
				"rubies": player.rubies,
				"unspent_attribute_points": player.unspent_attribute_points,
				"character_class_code": player.character_class_code,
				"carry_upgrade_level": player.carry_upgrade_level,
				"unlocked_talent_skill_ids": player.unlocked_talent_skill_ids.duplicate(),
				"unlocked_class_mechanic_ids": player.unlocked_class_mechanic_ids.duplicate(),
				"discovered_hunter_combos": player.discovered_hunter_combos.duplicate(),
				"talent_ranks": player.talent_ranks.duplicate(true),
				"unlocked_class_path_ids": player.unlocked_class_path_ids.duplicate(),
				"passive_ranks": player.passive_ranks.duplicate(true),
				"unlocked_passive_mastery_ids": player.unlocked_passive_mastery_ids.duplicate(),
				"passive_specialization_ids": player.passive_specialization_ids.duplicate(true),
				"achievements":
				{
					"unlocked": player.achievement_book.unlocked_ids.duplicate(),
					"equipped_title": player.achievement_book.equipped_title,
				},
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
	AchievementServiceClass.reconcile_existing_progress(session)
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
	var gender_code := str(data.get("gender_code", ""))
	if gender_code not in VALID_GENDER_CODES:
		return _failure("Zapis zawiera nieprawidłową płeć bohatera.")
	if not data.get("attributes") is Dictionary:
		return _failure("Zapis nie zawiera atrybutów bohatera.")
	if not data.get("achievements") is Dictionary:
		return _failure("Zapis nie zawiera osiągnięć bohatera.")
	if not data.get("equipment") is Dictionary or not data.get("inventory") is Dictionary:
		return _failure("Zapis nie zawiera kompletnego ekwipunku.")

	var player := PlayerProfileClass.new(player_name)
	player.gender_code = gender_code
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
	var class_progression_result := _restore_class_combat_progression(player, data)
	if not class_progression_result.ok:
		return class_progression_result
	var tree_progression_result := _restore_stage_three_f_progression(player, data)
	if not tree_progression_result.ok:
		return tree_progression_result
	var achievement_result := _restore_achievements(player, data.achievements)
	if not achievement_result.ok:
		return achievement_result
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
		"day",
		"hour",
		"prologue_stage",
		"guild_reputation",
		"victories",
		"last_inn_rest_day",
		"weather_remaining_hours",
	]
	for field: String in numeric_fields:
		if not _is_non_negative_integer(data.get(field)):
			return _failure("Nieprawidłowa wartość pola sesji: %s." % field)
	if (
		int(data.day) < 1
		or int(data.hour) > 23
		or int(data.prologue_stage) > 5
		or int(data.weather_remaining_hours) < 1
		or int(data.weather_remaining_hours) > WeatherServiceClass.DURATION_HOURS
	):
		return _failure("Zapis zawiera nieprawidłowy czas albo etap prologu.")
	if (
		not data.get("is_active") is bool
		or not data.get("prologue_completed") is bool
		or not data.get("camp_rest_available") is bool
	):
		return _failure("Zapis zawiera nieprawidłowe flagi sesji.")
	var weather_code := str(data.get("weather_code", ""))
	if not WeatherServiceClass.is_valid_code(weather_code):
		return _failure("Zapis zawiera nieznany stan pogody.")
	if not data.get("quest_log") is Dictionary:
		return _failure("Zapis nie zawiera dziennika zadań.")
	if not data.get("contracts") is Dictionary:
		return _failure("Zapis nie zawiera tablicy kontraktów.")
	if not data.get("guild_milestones") is Array:
		return _failure("Zapis nie zawiera kamieni milowych Gildii.")
	if not data.get("adventure_log") is Array:
		return _failure("Zapis nie zawiera Dziennika Przygód.")
	if not data.get("black_market") is Dictionary:
		return _failure("Zapis nie zawiera stanu Czarnego Rynku.")
	if not data.get("guild_storage") is Dictionary:
		return _failure("Zapis nie zawiera Magazynu Gildii.")
	if not data.get("party") is Dictionary:
		return _failure("Zapis nie zawiera stanu drużyny.")
	if not data.get("expedition_preparation") is Dictionary:
		return _failure("Zapis nie zawiera stanu przygotowania wyprawy.")
	if not data.get("rifts") is Dictionary:
		return _failure("Zapis nie zawiera stanu Szczelin.")
	if not data.get("world_encounters") is Dictionary:
		return _failure("Zapis nie zawiera stanu spotkań otwartego świata.")
	var location_id := str(data.get("current_location_id", ""))
	var city_id := str(data.get("current_city_id", ""))
	if not data.get("known_region_ids") is Array:
		return _failure("Zapis nie zawiera listy znanych regionów.")
	var region_error := RegionCatalogClass.validate_known_region_ids(data.known_region_ids)
	if not region_error.is_empty():
		return _failure(region_error)
	if (
		not RegionCatalogClass.is_valid_region_id(location_id)
		or location_id not in data.known_region_ids
	):
		return _failure("Bieżący region nie znajduje się na liście znanych regionów.")
	if city_id != GameSessionClass.STARTING_CITY_ID:
		return _failure("Zapis wskazuje miasto, które nie zostało jeszcze przeniesione.")
	var quest_result := _restore_quest_log(session, data.quest_log)
	if not quest_result.ok:
		return quest_result
	var contract_error := ContractServiceClass.deserialize_board(
		data.contracts, session.contract_board
	)
	if not contract_error.is_empty():
		return _failure(contract_error)
	var guild_state_result := _restore_guild_stage_five_c(
		session, data.guild_milestones, data.adventure_log
	)
	if not guild_state_result.ok:
		return guild_state_result
	var black_market_error := BlackMarketServiceClass.deserialize(
		data.black_market, session.black_market
	)
	if not black_market_error.is_empty():
		return _failure(black_market_error)
	var storage_result := _restore_inventory_container(
		session.guild_storage.inventory, data.guild_storage
	)
	if not storage_result.ok:
		return _failure("Nieprawidłowa skrytka w karczmie: %s" % storage_result.message)
	if session.guild_storage.used_slots > session.guild_storage.CAPACITY_SLOTS:
		return _failure("Skrytka w karczmie przekracza limit miejsc.")
	var party_result := PartySaveCodecClass.deserialize(data.party, int(data.day))
	if not party_result.ok:
		return _failure("Nieprawidłowy stan drużyny: %s" % party_result.message)
	session.party = party_result.party
	var preparation_result := ExpeditionPreparationSaveCodecClass.deserialize(
		data.expedition_preparation, data.known_region_ids
	)
	if not preparation_result.ok:
		return _failure("Nieprawidłowe przygotowanie wyprawy: %s" % preparation_result.message)
	session.expedition_preparation = preparation_result.state
	var rift_result := RiftSaveCodecClass.deserialize(data.rifts)
	if not rift_result.ok:
		return _failure("Nieprawidłowy stan Szczelin: %s" % rift_result.message)
	session.rifts = rift_result.state
	var world_encounter_result := WorldEncounterSaveCodecClass.deserialize(data.world_encounters)
	if not world_encounter_result.ok:
		return _failure(
			"Nieprawidłowy stan spotkań otwartego świata: %s" % world_encounter_result.message
		)
	session.world_encounters = world_encounter_result.state
	var stage_six_error := StageSixSaveValidatorClass.validate(session, int(data.day))
	if not stage_six_error.is_empty():
		return _failure("Niespójny stan Stage 6: %s" % stage_six_error)

	session.current_location_id = location_id
	session.known_region_ids.assign(data.known_region_ids)
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
	session.weather_code = weather_code
	session.weather_remaining_hours = int(data.weather_remaining_hours)
	session.camp_rest_available = data.camp_rest_available
	session.last_weather_changes.clear()
	return {"ok": true}


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
	var error := ""
	if version < 1 or version >= SCHEMA_VERSION:
		error = "Zapis ma nieobsługiwaną, starszą wersję schematu."
	elif not migrated.get("session") is Dictionary:
		error = "Starszy zapis nie zawiera sesji."
	elif not migrated.session.get("player") is Dictionary:
		error = "Starszy zapis nie zawiera bohatera."
	else:
		var session: Dictionary = migrated.session
		if version <= 1:
			session.player["carry_upgrade_level"] = 0
			session["last_inn_rest_day"] = 0
			session["guild_storage"] = {"stacks": {}, "equipment_items": []}
		if version <= 2:
			session.player["unlocked_talent_skill_ids"] = []
			session.player["discovered_hunter_combos"] = []
		if version <= 3:
			session.player["unlocked_class_mechanic_ids"] = []
		if version <= 4:
			session.player["talent_ranks"] = {}
			session.player["unlocked_class_path_ids"] = []
			session.player["passive_ranks"] = {}
			session.player["unlocked_passive_mastery_ids"] = []
			session.player["passive_specialization_ids"] = {}
		if version <= 5:
			session["known_region_ids"] = RegionCatalogClass.REGION_ORDER.duplicate()
		if version <= 6:
			_backfill_equipment_generation(session.player.get("equipment", {}), false)
			_backfill_equipment_generation(session.player.get("inventory", {}), true)
			_backfill_equipment_generation(session.get("guild_storage", {}), true)
		if version <= 7:
			session["weather_code"] = WeatherServiceClass.SUNNY
			session["weather_remaining_hours"] = WeatherServiceClass.DURATION_HOURS
			session["camp_rest_available"] = true
		if version <= 8:
			session["contracts"] = {
				"daily_date": "",
				"daily_contracts": [],
				"daily_claimed": [],
				"weekly_key": "",
				"weekly_contract": {},
				"weekly_claimed": false,
				"progress": {},
			}
		if version <= 9:
			session["guild_milestones"] = []
			session["adventure_log"] = []
		if version <= 10:
			session["black_market"] = {
				"unlocked": false,
				"informant_last_check_day": 0,
				"informant_failed_checks": 0,
				"informant_present_day": 0,
				"rotation_key": "",
				"offers": [],
				"purchased_offer_ids": [],
				"buy_negotiated_prices": {},
				"sale_negotiated_prices": {},
			}
		if version <= 11:
			session.player["achievements"] = {
				"unlocked": [],
				"equipped_title": AchievementCatalogClass.DEFAULT_TITLE,
			}
		if version <= 12:
			session["party"] = PartySaveCodecClass.empty_data()
		if version <= 13:
			session["expedition_preparation"] = (ExpeditionPreparationSaveCodecClass.empty_data())
		if version <= 14:
			session["rifts"] = RiftSaveCodecClass.empty_data()
		if version <= 15:
			_backfill_companion_resource_initialization(session.get("party", {}))
		if version <= 16:
			session["world_encounters"] = WorldEncounterSaveCodecClass.empty_data()
		if version <= 17:
			session.player["gender_code"] = PlayerProfileClass.GENDER_UNSPECIFIED
		migrated.schema_version = SCHEMA_VERSION
	if not error.is_empty():
		return _failure(error)
	return {"ok": true, "payload": migrated}


func _backfill_companion_resource_initialization(party_data) -> void:
	if not party_data is Dictionary:
		return
	for field: String in ["companions", "dismissed_companions"]:
		var values = party_data.get(field, [])
		if not values is Array:
			continue
		for companion_data in values:
			_backfill_single_companion_resources(companion_data)
	var candidates = party_data.get("candidates", [])
	if not candidates is Array:
		return
	for candidate_data in candidates:
		if candidate_data is Dictionary:
			_backfill_single_companion_resources(candidate_data.get("companion"))


func _backfill_single_companion_resources(companion_data) -> void:
	if not companion_data is Dictionary:
		return
	# Schema v15 and earlier used zero as the sentinel. Preserve that meaning once
	# during migration; schema v16 can then persist a genuinely depleted zero.
	companion_data["hp_initialized"] = int(companion_data.get("current_hp", 0)) > 0
	companion_data["mana_initialized"] = int(companion_data.get("current_mana", 0)) > 0


func _restore_class_combat_progression(player: PlayerProfileClass, data: Dictionary) -> Dictionary:
	if (
		not data.get("unlocked_talent_skill_ids") is Array
		or not data.get("unlocked_class_mechanic_ids") is Array
		or not data.get("discovered_hunter_combos") is Array
	):
		return _failure("Zapis nie zawiera prawidłowej progresji systemów klasowych.")
	var skill_result := _restore_talent_skills(player, data.unlocked_talent_skill_ids)
	if not skill_result.ok:
		return skill_result
	var mechanic_result := _restore_class_mechanics(player, data.unlocked_class_mechanic_ids)
	if not mechanic_result.ok:
		return mechanic_result
	var combo_result := _restore_hunter_combos(player, data.discovered_hunter_combos)
	if not combo_result.ok:
		return combo_result
	return {"ok": true}


func _restore_talent_skills(player: PlayerProfileClass, values: Array) -> Dictionary:
	var seen_skills := {}
	for skill_id_value in values:
		if not skill_id_value is String:
			return _failure("Zapis zawiera nieprawidłową umiejętność talentową.")
		var skill_id := str(skill_id_value)
		if (
			not SkillCatalogClass.is_talent_skill_id_for_class(
				skill_id, player.character_class_code
			)
			or seen_skills.has(skill_id)
		):
			return _failure("Zapis zawiera niedozwoloną umiejętność talentową.")
		seen_skills[skill_id] = true
		player.unlocked_talent_skill_ids.append(skill_id)
	return {"ok": true}


func _restore_class_mechanics(player: PlayerProfileClass, values: Array) -> Dictionary:
	var seen_mechanics := {}
	for mechanic_id_value in values:
		if not mechanic_id_value is String:
			return _failure("Zapis zawiera nieprawidłową mechanikę klasową.")
		var mechanic_id := str(mechanic_id_value)
		if (
			not ClassCombatMechanicCatalogClass.is_valid_for_class(
				mechanic_id, player.character_class_code
			)
			or seen_mechanics.has(mechanic_id)
		):
			return _failure("Zapis zawiera niedozwoloną mechanikę klasową.")
		seen_mechanics[mechanic_id] = true
		player.unlocked_class_mechanic_ids.append(mechanic_id)
	return {"ok": true}


func _restore_hunter_combos(player: PlayerProfileClass, values: Array) -> Dictionary:
	var seen_combos := {}
	for combo_id_value in values:
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


func _restore_stage_three_f_progression(player: PlayerProfileClass, data: Dictionary) -> Dictionary:
	if (
		not data.get("talent_ranks") is Dictionary
		or not data.get("unlocked_class_path_ids") is Array
		or not data.get("passive_ranks") is Dictionary
		or not data.get("unlocked_passive_mastery_ids") is Array
		or not data.get("passive_specialization_ids") is Dictionary
	):
		return _failure("Zapis nie zawiera prawidłowej progresji etapu 3F.")
	player.talent_ranks = data.talent_ranks.duplicate(true)
	player.unlocked_class_path_ids.assign(data.unlocked_class_path_ids)
	player.passive_ranks = data.passive_ranks.duplicate(true)
	player.unlocked_passive_mastery_ids.assign(data.unlocked_passive_mastery_ids)
	player.passive_specialization_ids = data.passive_specialization_ids.duplicate(true)
	var talent_error := TalentProgressionServiceClass.validate_state(player)
	if not talent_error.is_empty():
		return _failure(talent_error)
	var passive_error := PassiveProgressionServiceClass.validate_state(player)
	if not passive_error.is_empty():
		return _failure(passive_error)
	var normalized_talents := {}
	for talent_id_value in player.talent_ranks:
		normalized_talents[str(talent_id_value)] = int(player.talent_ranks[talent_id_value])
	player.talent_ranks = normalized_talents
	var normalized_passives := {}
	for passive_code_value in player.passive_ranks:
		normalized_passives[str(passive_code_value)] = int(player.passive_ranks[passive_code_value])
	player.passive_ranks = normalized_passives
	return {"ok": true}


func _restore_achievements(player: PlayerProfileClass, data: Dictionary) -> Dictionary:
	if not data.get("unlocked") is Array or not data.get("equipped_title") is String:
		return _failure("Zapis nie zawiera prawidłowej kolekcji osiągnięć.")
	for achievement_id_value in data.unlocked:
		if not achievement_id_value is String:
			return _failure("Zapis zawiera nieprawidłowe osiągnięcie.")
		player.achievement_book.unlocked_ids.append(str(achievement_id_value))
	player.achievement_book.equipped_title = str(data.equipped_title)
	var validation_error := AchievementServiceClass.validate_book(player.achievement_book)
	if not validation_error.is_empty():
		return _failure(validation_error)
	return {"ok": true}


func _restore_quest_log(session: GameSessionClass, data: Dictionary) -> Dictionary:
	if not data.get("active") is Dictionary or not data.get("completed") is Dictionary:
		return _failure("Zapis zawiera nieprawidłowy dziennik zadań.")
	for quest_id_value in data.active:
		var quest_id := str(quest_id_value)
		var progress = data.active[quest_id]
		var quest = QuestServiceClass.get_quest(quest_id)
		if (
			quest == null
			or not _is_non_negative_integer(progress)
			or int(progress) > quest.required_count
		):
			return _failure("Zapis zawiera nieobsługiwane aktywne zadanie.")
		session.quest_log.active[quest_id] = int(progress)
	for quest_id_value in data.completed:
		var quest_id := str(quest_id_value)
		if not QuestServiceClass.has_quest(quest_id) or data.completed[quest_id] != true:
			return _failure("Zapis zawiera nieobsługiwane ukończone zadanie.")
		if session.quest_log.active.has(quest_id):
			return _failure("To samo zadanie jest aktywne i ukończone.")
		session.quest_log.completed[quest_id] = true
	var state_error := QuestServiceClass.validate_state(session.quest_log)
	if not state_error.is_empty():
		return _failure(state_error)
	return {"ok": true}


func _restore_guild_stage_five_c(
	session: GameSessionClass, milestone_values: Array, log_values: Array
) -> Dictionary:
	var seen_milestones := {}
	for milestone_value in milestone_values:
		if not milestone_value is String:
			return _failure("Zapis zawiera nieprawidłowy kamień milowy Gildii.")
		var milestone_id := str(milestone_value)
		if (
			not GuildMilestoneServiceClass.is_valid_id(milestone_id)
			or seen_milestones.has(milestone_id)
		):
			return _failure("Zapis zawiera nieznany albo powtórzony kamień milowy Gildii.")
		seen_milestones[milestone_id] = true
		session.guild_milestones.append(milestone_id)
	if log_values.size() > session.adventure_log.MAX_ENTRIES:
		return _failure("Dziennik Przygód przekracza limit wpisów.")
	var restored_entries: Array[String] = []
	for entry_value in log_values:
		if not entry_value is String:
			return _failure("Dziennik Przygód zawiera nieprawidłowy wpis.")
		var entry := str(entry_value).strip_edges()
		if entry.is_empty() or entry.length() > 500:
			return _failure("Dziennik Przygód zawiera nieprawidłowy wpis.")
		restored_entries.append(entry)
	session.adventure_log.replace_entries(restored_entries)
	return {"ok": true}


func _deserialize_equipment_item(data: Dictionary) -> Dictionary:
	return EquipmentSaveCodecClass.deserialize_item(data)


func _backfill_equipment_generation(container: Dictionary, is_inventory: bool) -> void:
	if is_inventory:
		var items = container.get("equipment_items", [])
		if not items is Array:
			return
		for item_data in items:
			if item_data is Dictionary:
				_backfill_equipment_item(item_data)
		return
	for item_data in container.values():
		if item_data is Dictionary:
			_backfill_equipment_item(item_data)


func _backfill_equipment_item(data: Dictionary) -> void:
	var definition = ItemCatalogClass.get_definition(str(data.get("item_id", "")))
	if definition == null or not definition.is_equipment():
		return
	var item = EquipmentAffixServiceClass.deterministic_item(
		definition, int(data.get("upgrade_level", 0)), str(data.get("instance_id", ""))
	)
	data["item_power"] = item.item_power
	data["affixes"] = _serialize_affixes(item.affixes)


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
	return EquipmentSaveCodecClass.serialize_equipment(slots)


func _serialize_equipment_items(items: Array) -> Array[Dictionary]:
	return EquipmentSaveCodecClass.serialize_items(items)


func _serialize_inventory(inventory) -> Dictionary:
	return EquipmentSaveCodecClass.serialize_inventory(inventory)


func _serialize_equipment_item(item: EquipmentItemClass) -> Dictionary:
	return EquipmentSaveCodecClass.serialize_item(item)


func _serialize_affixes(affixes: Array) -> Array[Dictionary]:
	return EquipmentSaveCodecClass.serialize_affixes(affixes)


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
