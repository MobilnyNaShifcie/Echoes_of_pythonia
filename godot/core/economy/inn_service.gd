class_name InnService
extends RefCounted

const BASE_COST := 25
const LEVEL_COST := 25
const DURATION_HOURS := 6


static func rest_cost(player) -> int:
	return BASE_COST + maxi(0, player.level) * LEVEL_COST


static func get_rest_error(session) -> String:
	if not session.player.stats.needs_restoration():
		return "Nie potrzebujesz teraz noclegu."
	if session.last_inn_rest_day >= session.day:
		return "Pokój był już dziś używany. Nocleg będzie dostępny od dnia %d." % (session.day + 1)
	var cost := rest_cost(session.player)
	if session.player.gold < cost:
		return "Nocleg kosztuje %d złota. Masz %d." % [cost, session.player.gold]
	return ""


static func rest(session) -> Dictionary:
	var error := get_rest_error(session)
	if not error.is_empty():
		return {"ok": false, "message": error}
	var player = session.player
	var cost := rest_cost(player)
	var healed_hp: int = player.stats.max_hp - player.stats.current_hp
	var restored_mana: int = player.stats.max_mana - player.stats.current_mana
	player.gold -= cost
	player.stats.restore_full()
	session.advance_hours(DURATION_HOURS)
	session.last_inn_rest_day = session.day
	return {
		"ok": true,
		"message":
		"Nocleg zakończony: +%d PŻ, +%d Many, -%d złota." % [healed_hp, restored_mana, cost],
		"healed_hp": healed_hp,
		"restored_mana": restored_mana,
		"gold": cost,
		"next_available_day": session.day + 1,
	}
