class_name AchievementService
extends RefCounted

const AchievementCatalogClass := preload("res://core/progression/achievement_catalog.gd")
const GuildProgressionServiceClass := preload("res://core/quests/guild_progression_service.gd")

const BOSS_ACHIEVEMENTS := {
	"nature_guardian": "nature_breaker",
	"blackwood_executioner": "executioners_end",
	"drowned_mother": "silence_the_mother",
}


static func record_victory(session, enemy_id: String, weather_code: String) -> Array:
	var unlocked: Array = []
	_unlock_into(session, "first_blood", unlocked)
	if BOSS_ACHIEVEMENTS.has(enemy_id):
		_unlock_into(session, str(BOSS_ACHIEVEMENTS[enemy_id]), unlocked)
	if weather_code == "aurora":
		_unlock_into(session, "aurora_hunter", unlocked)
	return unlocked


static func record_upgrade(session, upgrade_level: int) -> Array:
	var unlocked: Array = []
	if upgrade_level >= 10:
		_unlock_into(session, "master_smith", unlocked)
	return unlocked


static func record_guild_rank(session, rank_code: String) -> Array:
	var unlocked: Array = []
	if rank_code == "S":
		_unlock_into(session, "guild_veteran", unlocked)
	return unlocked


static func reconcile_existing_progress(session) -> Array:
	var unlocked: Array = []
	var equipment_items: Array = []
	equipment_items.append_array(session.player.equipment.slots.values())
	equipment_items.append_array(session.player.inventory.equipment_items)
	for item in equipment_items:
		if item != null and item.upgrade_level >= 10:
			_unlock_into(session, "master_smith", unlocked)
			break
	if session.quest_log.completed.has("mother_below"):
		_unlock_into(session, "silence_the_mother", unlocked)
	var rank_code: String = (
		GuildProgressionServiceClass.rank_for_reputation(session.guild_reputation).code
	)
	if rank_code == "S":
		_unlock_into(session, "guild_veteran", unlocked)
	return unlocked


static func equip_title(session, title: String) -> Dictionary:
	if not session.player.achievement_book.equip_title(title):
		return {"ok": false, "message": "Ten tytuł nie został jeszcze odblokowany."}
	var message := "Wybrano tytuł: %s." % title
	session.log_event(message)
	return {"ok": true, "message": message}


static func validate_book(book) -> String:
	var seen := {}
	for achievement_id: String in book.unlocked_ids:
		if not AchievementCatalogClass.is_valid_id(achievement_id) or seen.has(achievement_id):
			return "Zapis zawiera nieznane albo powtórzone osiągnięcie."
		seen[achievement_id] = true
	if book.equipped_title not in book.available_titles():
		return "Zapis wybiera tytuł, który nie został odblokowany."
	return ""


static func _unlock_into(session, achievement_id: String, results: Array) -> void:
	if not session.player.achievement_book.unlock(achievement_id):
		return
	var definition = AchievementCatalogClass.get_definition(achievement_id)
	results.append(definition)
	session.log_event(
		"Osiągnięcie: %s. Odblokowano tytuł „%s”." % [definition.display_name, definition.title]
	)
