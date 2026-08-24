class_name QuestService
extends RefCounted

const GuildProgressionServiceClass := preload("res://core/quests/guild_progression_service.gd")
const AchievementServiceClass := preload("res://core/progression/achievement_service.gd")
const QuestCatalogClass := preload("res://core/quests/quest_catalog.gd")
const QuestDefinitionClass := preload("res://core/quests/quest_definition.gd")

const STORY_QUEST_ID := "awakening_missing_recruits"


static func has_quest(quest_id: String) -> bool:
	return QuestCatalogClass.has_quest(quest_id)


static func get_quest(quest_id: String) -> QuestDefinitionClass:
	return QuestCatalogClass.get_definition(quest_id)


static func get_all_story_quests() -> Array:
	return QuestCatalogClass.get_all_definitions()


static func get_available_quests(log, player_level: int) -> Array:
	var available: Array = []
	for quest in get_all_story_quests():
		if get_accept_error(log, quest.quest_id, player_level).is_empty():
			available.append(quest)
	return available


static func get_active_quests(log) -> Array:
	_normalize(log)
	var active: Array = []
	for quest in get_all_story_quests():
		if log.is_active(quest.quest_id):
			active.append(quest)
	return active


static func get_accept_error(log, quest_id: String, player_level := -1) -> String:
	_normalize(log)
	var quest := get_quest(quest_id)
	if quest == null:
		return "Nieznane zadanie."
	if log.is_completed(quest_id):
		return "To zadanie zostało już ukończone."
	if log.is_active(quest_id):
		return "To zadanie jest już aktywne."
	if player_level >= 0 and player_level < quest.unlock_level:
		return "Zadanie odblokuje się na poziomie %d." % quest.unlock_level
	if (
		not quest.prerequisite_quest_id.is_empty()
		and not log.is_completed(quest.prerequisite_quest_id)
	):
		var prerequisite := get_quest(quest.prerequisite_quest_id)
		return "Najpierw ukończ zadanie: %s." % prerequisite.title
	return ""


static func accept_quest(log, quest_id: String, player_level := -1) -> Dictionary:
	var error := get_accept_error(log, quest_id, player_level)
	if not error.is_empty():
		return {"ok": false, "message": error}
	var quest := get_quest(quest_id)
	log.active[quest_id] = 0
	return {"ok": true, "message": "Przyjęto zadanie: %s." % quest.title, "quest": quest}


static func objective_progress(player, log, quest) -> int:
	if quest == null or not log.is_active(quest.quest_id):
		return 0
	if quest.objective_type == QuestDefinitionClass.COLLECT:
		return mini(player.inventory.count(quest.target_id), quest.required_count)
	return mini(int(log.active.get(quest.quest_id, 0)), quest.required_count)


static func is_ready_to_turn_in(session, quest_id: String) -> bool:
	var quest := get_quest(quest_id)
	if quest == null or not session.quest_log.is_active(quest_id):
		return false
	return objective_progress(session.player, session.quest_log, quest) >= quest.required_count


static func get_ready_quests(session) -> Array:
	var ready: Array = []
	for quest in get_active_quests(session.quest_log):
		if is_ready_to_turn_in(session, quest.quest_id):
			ready.append(quest)
	return ready


static func record_enemy_kill(log, enemy_id: String) -> Dictionary:
	for quest in get_active_quests(log):
		if quest.objective_type != QuestDefinitionClass.KILL or quest.target_id != enemy_id:
			continue
		var previous := int(log.active.get(quest.quest_id, 0))
		var current := mini(previous + 1, quest.required_count)
		log.active[quest.quest_id] = current
		return {
			"quest_id": quest.quest_id,
			"title": quest.title,
			"current": current,
			"required": quest.required_count,
			"ready": current >= quest.required_count,
		}
	return {}


static func turn_in_quest(session, quest_id: String) -> Dictionary:
	var quest := get_quest(quest_id)
	if quest == null:
		return {"ok": false, "message": "Nieznane zadanie."}
	if session.quest_log.is_completed(quest_id):
		return {"ok": false, "message": "To zadanie zostało już ukończone."}
	if not session.quest_log.is_active(quest_id):
		return {"ok": false, "message": "To zadanie nie jest aktywne."}
	if not is_ready_to_turn_in(session, quest_id):
		return {"ok": false, "message": "Warunki zadania nie zostały jeszcze spełnione."}
	if quest.objective_type == QuestDefinitionClass.COLLECT and quest.consume_objective_items:
		if not session.player.inventory.remove_item(quest.target_id, quest.required_count):
			return {"ok": false, "message": "Brakuje przedmiotów wymaganych przez zadanie."}

	var old_rank := GuildProgressionServiceClass.rank_for_reputation(session.guild_reputation)
	var levels_gained: int = session.player.gain_experience(quest.reward_exp)
	session.player.add_gold(quest.reward_gold)
	session.guild_reputation += quest.guild_reputation
	session.quest_log.active.erase(quest_id)
	session.quest_log.completed[quest_id] = true
	_normalize(session.quest_log)
	var new_rank := GuildProgressionServiceClass.rank_for_reputation(session.guild_reputation)
	session.log_event("Ukończono zadanie: %s." % quest.title)
	session.log_event(
		"Reputacja Gildii +%d: zadanie fabularne „%s”." % [quest.guild_reputation, quest.title]
	)
	if old_rank.code != new_rank.code:
		session.log_event("Awans w Gildii: %s." % new_rank.full_name())
	var unlocked_achievements := AchievementServiceClass.record_guild_rank(session, new_rank.code)
	return {
		"ok": true,
		"quest_id": quest_id,
		"title": quest.title,
		"experience": quest.reward_exp,
		"gold": quest.reward_gold,
		"guild_reputation": quest.guild_reputation,
		"levels_gained": levels_gained,
		"attribute_points_gained": levels_gained * 4,
		"completion_text": quest.completion_text,
		"old_rank_code": old_rank.code,
		"new_rank_code": new_rank.code,
		"rank_changed": old_rank.code != new_rank.code,
		"unlocked_achievements": unlocked_achievements,
	}


static func validate_state(log) -> String:
	for quest_id_value in log.active:
		var quest_id := str(quest_id_value)
		var quest := get_quest(quest_id)
		if quest == null:
			return "Zapis zawiera nieobsługiwane aktywne zadanie."
		if log.completed.has(quest_id):
			return "To samo zadanie jest aktywne i ukończone."
		if (
			not quest.prerequisite_quest_id.is_empty()
			and not log.completed.has(quest.prerequisite_quest_id)
		):
			return "Aktywne zadanie omija wymagany rozdział fabuły."
	for quest_id_value in log.completed:
		var quest_id := str(quest_id_value)
		var quest := get_quest(quest_id)
		if quest == null:
			return "Zapis zawiera nieobsługiwane ukończone zadanie."
		if (
			not quest.prerequisite_quest_id.is_empty()
			and not log.completed.has(quest.prerequisite_quest_id)
		):
			return "Ukończone zadanie omija wymagany rozdział fabuły."
	return ""


static func accept_story_quest(log) -> bool:
	return bool(accept_quest(log, STORY_QUEST_ID).ok)


static func get_progress(log) -> int:
	var quest := get_quest(STORY_QUEST_ID)
	return mini(int(log.active.get(STORY_QUEST_ID, 0)), quest.required_count)


static func is_ready(log) -> bool:
	var quest := get_quest(STORY_QUEST_ID)
	return log.is_active(STORY_QUEST_ID) and get_progress(log) >= quest.required_count


static func turn_in_story_quest(session) -> Dictionary:
	return turn_in_quest(session, STORY_QUEST_ID)


static func _normalize(log) -> void:
	for quest_id_value in log.completed:
		log.active.erase(str(quest_id_value))
