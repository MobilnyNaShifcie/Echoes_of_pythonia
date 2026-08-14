class_name QuestService
extends RefCounted

const STORY_QUEST_ID := "awakening_missing_recruits"
const STORY_QUEST := {
	"quest_id": STORY_QUEST_ID,
	"title": "Ci, którzy nie wrócili",
	"description":
	(
		"Trójka Nowicjuszy miała wrócić ze Zmierzchowych Równin przed zmrokiem. "
		+ "Znaleziono tylko ich wygaszone ognisko i ślady wilków biegnących... w przeciwną stronę. "
		+ "Gildia prosi cię o sprawdzenie okolicy i przepędzenie drapieżników z traktu."
	),
	"recommended_level": 0,
	"objective_type": "kill",
	"target_id": "wolf",
	"required_count": 2,
	"reward_exp": 45,
	"reward_gold": 70,
	"guild_reputation": 40,
	"story_arc": "Akt I — Ślady Przebudzenia",
	"chapter": "Rozdział I — Droga, która ucichła",
	"completion_text":
	(
		"Jeden z zaginionych Nowicjuszy wraca do Gildii sam. Twierdzi, że wilki nie polowały "
		+ "na ich grupę — uciekały przed czymś poruszającym się po równinach po zmroku. "
		+ "Nie potrafi opisać czego."
	),
}


static func accept_story_quest(log) -> bool:
	if log.is_active(STORY_QUEST_ID) or log.is_completed(STORY_QUEST_ID):
		return false
	log.active[STORY_QUEST_ID] = 0
	return true


static func record_enemy_kill(log, enemy_id: String) -> Dictionary:
	if not log.is_active(STORY_QUEST_ID) or enemy_id != STORY_QUEST.target_id:
		return {}
	var old_progress: int = log.active[STORY_QUEST_ID]
	var new_progress := mini(old_progress + 1, STORY_QUEST.required_count)
	log.active[STORY_QUEST_ID] = new_progress
	return {
		"title": STORY_QUEST.title,
		"current": new_progress,
		"required": STORY_QUEST.required_count,
		"ready": new_progress >= STORY_QUEST.required_count,
	}


static func get_progress(log) -> int:
	return mini(log.active.get(STORY_QUEST_ID, 0), STORY_QUEST.required_count)


static func is_ready(log) -> bool:
	return log.is_active(STORY_QUEST_ID) and get_progress(log) >= STORY_QUEST.required_count


static func turn_in_story_quest(session) -> Dictionary:
	var player = session.player
	var log = session.quest_log
	if not is_ready(log):
		return {}
	var levels_gained: int = player.gain_experience(STORY_QUEST.reward_exp)
	player.add_gold(STORY_QUEST.reward_gold)
	session.guild_reputation += STORY_QUEST.guild_reputation
	log.active.erase(STORY_QUEST_ID)
	log.completed[STORY_QUEST_ID] = true
	return {
		"experience": STORY_QUEST.reward_exp,
		"gold": STORY_QUEST.reward_gold,
		"guild_reputation": STORY_QUEST.guild_reputation,
		"levels_gained": levels_gained,
		"completion_text": STORY_QUEST.completion_text,
	}
