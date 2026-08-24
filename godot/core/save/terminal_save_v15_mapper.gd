class_name TerminalSaveV15Mapper
extends RefCounted

const RegionCatalogClass := preload("res://core/world/region_catalog.gd")
const WorldEncounterSaveCodecClass := preload("res://core/save/world_encounter_save_codec.gd")

const TERMINAL_SCHEMA_VERSION := 15
const TERMINAL_GAME_VERSION := "0.24.7"
const WORLD_MILESTONES := [
	"boss:azhar",
	"boss:leviathan_north",
	"dungeon:sunken_order_crypt",
	"dungeon:black_fleet_wreck",
]
const PRESET_IDS := ["solo", "boss", "dungeon", "rift"]


# The mapper only reshapes the terminal payload. SaveGameService remains the
# authority that validates and constructs Godot domain objects.
static func map_to_godot(
	source, target_slot: int, format_id: String, schema_version: int
) -> Dictionary:
	if not source is Dictionary:
		return _failure("Terminalowy zapis nie jest obiektem JSON.")
	if not _is_integer(source.get("schema_version")):
		return _failure("Terminalowy zapis nie zawiera wersji schematu.")
	if int(source.schema_version) != TERMINAL_SCHEMA_VERSION:
		return _failure("Importer obsługuje wyłącznie terminalowy schemat v15.")
	if source.get("game_version") != TERMINAL_GAME_VERSION:
		return _failure("Importer obsługuje wyłącznie terminalową wersję v0.24.7.")
	for field: String in [
		"player",
		"world",
		"quests",
		"contracts",
		"guild",
		"black_market",
		"guild_storage",
		"party",
		"rifts",
		"expedition_preparation",
	]:
		if not source.get(field) is Dictionary:
			return _failure("Terminalowy zapis nie zawiera sekcji: %s." % field)
	if not source.get("adventure_log") is Array:
		return _failure("Terminalowy zapis nie zawiera Dziennika Przygód.")
	var player_result := _map_player(source.player)
	if not player_result.ok:
		return player_result
	var quest_result := _map_quests(source.quests)
	if not quest_result.ok:
		return quest_result
	var contract_result := _map_contracts(source.contracts)
	if not contract_result.ok:
		return contract_result
	var guild_result := _map_guild(source.guild)
	if not guild_result.ok:
		return guild_result
	var party_result := _map_party(source.party)
	if not party_result.ok:
		return party_result
	var preparation_result := _map_preparation(source.expedition_preparation)
	if not preparation_result.ok:
		return preparation_result
	var world_encounter_result := _map_world_encounters(source)
	if not world_encounter_result.ok:
		return world_encounter_result

	var world: Dictionary = source.world
	var session := {
		"save_slot": target_slot,
		"current_location_id": world.get("current_location_id"),
		"known_region_ids": RegionCatalogClass.REGION_ORDER.duplicate(),
		"current_city_id": world.get("current_city_id"),
		"day": world.get("day"),
		"hour": world.get("hour"),
		"is_active": true,
		# Terminal saves are created only after run_prologue() returns.
		"prologue_stage": 5,
		"prologue_completed": true,
		"guild_reputation": source.guild.get("reputation"),
		"guild_milestones": guild_result.world_milestones,
		"adventure_log": source.adventure_log.duplicate(true),
		"black_market": source.black_market.duplicate(true),
		"last_activity": "Zaimportowano kopię zapisu terminalowego v0.24.7.",
		# The terminal runtime does not persist this presentation-only counter.
		"victories": 0,
		"last_inn_rest_day": world.get("last_inn_rest_day", 0),
		"weather_code": world.get("weather"),
		"weather_remaining_hours": world.get("weather_remaining_hours"),
		"camp_rest_available": world.get("camp_rest_available"),
		"guild_storage": source.guild_storage.duplicate(true),
		"party": party_result.party,
		"expedition_preparation": preparation_result.preparation,
		"rifts": source.rifts.duplicate(true),
		"world_encounters": world_encounter_result.data,
		"quest_log": quest_result.quest_log,
		"contracts": contract_result.contracts,
		"player": player_result.player,
	}
	var payload := {
		"format_id": format_id,
		"schema_version": schema_version,
		"game_version": "0.25.0",
		"saved_at_unix": int(Time.get_unix_time_from_system()),
		"session": session,
	}
	return {
		"ok": true,
		"payload": payload,
		"audit": _build_audit(guild_result.normalized_milestones),
	}


static func _map_player(data: Dictionary) -> Dictionary:
	for field: String in ["attributes", "passives", "achievements", "inventory", "equipment"]:
		if not data.get(field) is Dictionary:
			return _failure("Terminalowy bohater nie zawiera sekcji: %s." % field)
	for field: String in [
		"passive_masteries",
		"unlocked_class_paths",
		"discovered_hunter_combos",
	]:
		if not data.get(field) is Array:
			return _failure("Terminalowy bohater nie zawiera listy: %s." % field)
	if (
		not data.get("passive_specializations") is Dictionary
		or not data.get("talents") is Dictionary
	):
		return _failure("Terminalowy bohater nie zawiera pełnej progresji.")
	return {
		"ok": true,
		"player":
		{
			"display_name": data.get("name"),
			"gender_code": "unspecified",
			"level": data.get("level"),
			"experience": data.get("experience"),
			"gold": data.get("gold"),
			"rubies": data.get("rubies"),
			"unspent_attribute_points": data.get("unspent_attribute_points"),
			"character_class_code": data.get("character_class"),
			"carry_upgrade_level": data.get("carry_upgrade_level", 0),
			# These two collections were compatibility caches in the Godot migration.
			# Runtime unlocks are derived authoritatively from talent_ranks.
			"unlocked_talent_skill_ids": [],
			"unlocked_class_mechanic_ids": [],
			"discovered_hunter_combos": data.discovered_hunter_combos.duplicate(true),
			"talent_ranks": data.talents.duplicate(true),
			"unlocked_class_path_ids": data.unlocked_class_paths.duplicate(true),
			"passive_ranks": data.passives.duplicate(true),
			"unlocked_passive_mastery_ids": data.passive_masteries.duplicate(true),
			"passive_specialization_ids": data.passive_specializations.duplicate(true),
			"achievements": data.achievements.duplicate(true),
			"attributes": data.attributes.duplicate(true),
			"current_hp": data.get("current_hp"),
			"current_mana": data.get("current_mana"),
			"equipment": data.equipment.duplicate(true),
			"inventory": data.inventory.duplicate(true),
		},
	}


static func _map_quests(data: Dictionary) -> Dictionary:
	if not data.get("active") is Dictionary or not data.get("completed") is Array:
		return _failure("Terminalowy dziennik zadań ma nieprawidłową strukturę.")
	var completed := {}
	for quest_id_value in data.completed:
		if not quest_id_value is String:
			return _failure("Terminalowy dziennik zawiera nieprawidłowe ukończone zadanie.")
		completed[str(quest_id_value)] = true
	return {
		"ok": true,
		"quest_log": {"active": data.active.duplicate(true), "completed": completed},
	}


static func _map_contracts(data: Dictionary) -> Dictionary:
	if not data.get("daily_contracts") is Array:
		return _failure("Terminalowa tablica nie zawiera kontraktów dziennych.")
	if not data.get("daily_claimed") is Array or not data.get("progress") is Dictionary:
		return _failure("Terminalowa tablica kontraktów ma nieprawidłowy stan.")
	var contracts := data.duplicate(true)
	var mapped_daily: Array[Dictionary] = []
	for raw in data.daily_contracts:
		var mapped := _map_contract(raw)
		if not mapped.ok:
			return mapped
		mapped_daily.append(mapped.contract)
	contracts["daily_contracts"] = mapped_daily
	var weekly = data.get("weekly_contract")
	if weekly == null:
		contracts["weekly_contract"] = {}
	else:
		var mapped_weekly := _map_contract(weekly)
		if not mapped_weekly.ok:
			return mapped_weekly
		contracts["weekly_contract"] = mapped_weekly.contract
	return {"ok": true, "contracts": contracts}


static func _map_contract(raw) -> Dictionary:
	if not raw is Dictionary or not raw.get("objectives") is Array:
		return _failure("Terminalowy kontrakt ma nieprawidłową strukturę.")
	var contract: Dictionary = raw.duplicate(true)
	contract["reward_item_id"] = "" if raw.get("reward_item_id") == null else raw.reward_item_id
	var objectives: Array[Dictionary] = []
	for objective_value in raw.objectives:
		if not objective_value is Dictionary:
			return _failure("Terminalowy kontrakt zawiera nieprawidłowy cel.")
		var objective: Dictionary = objective_value.duplicate(true)
		objective["target_id"] = "" if objective.get("target_id") == null else objective.target_id
		objectives.append(objective)
	contract["objectives"] = objectives
	return {"ok": true, "contract": contract}


static func _map_guild(data: Dictionary) -> Dictionary:
	if not data.get("milestones") is Array:
		return _failure("Terminalowy stan Gildii nie zawiera kamieni milowych.")
	var world_milestones: Array[String] = []
	var normalized: Array[String] = []
	for milestone_value in data.milestones:
		if not milestone_value is String:
			return _failure("Terminalowy stan Gildii zawiera nieprawidłowy wpis.")
		var milestone_id := str(milestone_value)
		if milestone_id in WORLD_MILESTONES:
			world_milestones.append(milestone_id)
		else:
			normalized.append(milestone_id)
	return {
		"ok": true,
		"world_milestones": world_milestones,
		"normalized_milestones": normalized,
	}


static func _map_party(data: Dictionary) -> Dictionary:
	for field: String in [
		"companions",
		"dismissed_companions",
		"candidates",
		"messages",
		"seen_banter",
		"fallen",
	]:
		if not data.get(field) is Array:
			return _failure("Terminalowy stan drużyny nie zawiera listy: %s." % field)
	var party := data.duplicate(true)
	for field: String in ["companions", "dismissed_companions"]:
		var mapped_companions: Array[Dictionary] = []
		for companion_value in data[field]:
			var mapped := _map_companion(companion_value)
			if not mapped.ok:
				return mapped
			mapped_companions.append(mapped.companion)
		party[field] = mapped_companions
	var candidates: Array[Dictionary] = []
	for candidate_value in data.candidates:
		if not candidate_value is Dictionary:
			return _failure("Terminalowy kandydat ma nieprawidłową strukturę.")
		var candidate: Dictionary = candidate_value.duplicate(true)
		var mapped := _map_companion(candidate.get("companion"))
		if not mapped.ok:
			return mapped
		candidate["companion"] = mapped.companion
		candidates.append(candidate)
	party["candidates"] = candidates
	var fallen: Array[Dictionary] = []
	for fallen_value in data.fallen:
		if not fallen_value is Dictionary:
			return _failure("Terminalowa Tablica Poległych ma nieprawidłowy wpis.")
		var memorial: Dictionary = fallen_value.duplicate(true)
		memorial["rift_rank"] = "" if memorial.get("rift_rank") == null else memorial.rift_rank
		fallen.append(memorial)
	party["fallen"] = fallen
	return {"ok": true, "party": party}


static func _map_companion(value) -> Dictionary:
	if not value is Dictionary:
		return _failure("Terminalowy kompan ma nieprawidłową strukturę.")
	var companion: Dictionary = value.duplicate(true)
	var hp = companion.get("current_hp")
	var mana = companion.get("current_mana")
	# Terminal v15 uses <= 0 as the first-combat initialization sentinel.
	companion["hp_initialized"] = _is_integer(hp) and int(hp) > 0
	companion["mana_initialized"] = _is_integer(mana) and int(mana) > 0
	return {"ok": true, "companion": companion}


static func _map_preparation(data: Dictionary) -> Dictionary:
	if not data.get("presets") is Dictionary:
		return _failure("Terminalowe przygotowanie wyprawy nie zawiera presetów.")
	var preparation := data.duplicate(true)
	var presets := {}
	for preset_id: String in PRESET_IDS:
		var raw = data.presets.get(preset_id)
		if not raw is Dictionary:
			return _failure("Terminalowy zapis nie zawiera presetu %s." % preset_id)
		var preset: Dictionary = raw.duplicate(true)
		preset["preset_id"] = preset_id
		presets[preset_id] = preset
	preparation["presets"] = presets
	return {"ok": true, "preparation": preparation}


static func _map_world_encounters(source: Dictionary) -> Dictionary:
	var data := {
		"elite_discoveries": source.get("elite_discoveries"),
		"elite_miss_streaks": source.get("elite_miss_streaks"),
		"region_boss_respawns": source.get("region_boss_respawns"),
	}
	var result := WorldEncounterSaveCodecClass.deserialize(data)
	if not result.ok:
		return _failure("Nieprawidłowy stan spotkań otwartego świata: %s" % result.message)
	return {"ok": true, "data": WorldEncounterSaveCodecClass.serialize(result.state)}


static func _build_audit(normalized_milestones: Array[String]) -> Dictionary:
	return {
		"mapped_sections":
		[
			"player",
			"world",
			"quests",
			"contracts",
			"guild",
			"black_market",
			"guild_storage",
			"adventure_log",
			"party",
			"expedition_preparation",
			"rifts",
			"world_encounters",
		],
		"normalized":
		[
			{
				"field": "guild.milestones",
				"reason":
				"Wpisy quest:/contract: są reprezentowane przez dzienniki i zachowaną reputację.",
				"values": normalized_milestones,
			},
			{
				"field": "player talent compatibility caches",
				"reason": "Godot wyprowadza umiejętności i mechaniki z talent_ranks.",
			},
		],
		"defaults":
		[
			{
				"field": "session.prologue_completed",
				"value": true,
				"reason": "Terminal zapisuje grę dopiero po ukończeniu prologu.",
			},
			{
				"field": "session.victories",
				"value": 0,
				"reason": "Terminal v15 nie przechowuje tego pomocniczego licznika Godota.",
			},
		],
		"not_migrated": [],
	}


static func _is_integer(value) -> bool:
	return (value is int or value is float) and is_equal_approx(float(value), floorf(float(value)))


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
