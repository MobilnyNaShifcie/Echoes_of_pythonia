class_name CampRestService
extends RefCounted

const MathClass := preload("res://core/math/legacy_math.gd")
const WeatherServiceClass := preload("res://core/world/weather_service.gd")

const HP_PERCENT := 0.25
const MANA_PERCENT := 0.35
const DURATION_HOURS := 2


static func get_rest_error(session) -> String:
	if not session.camp_rest_available:
		return (
			"Ognisko nie daje już wytchnienia. "
			+ "Kolejny darmowy odpoczynek odblokuje następna wyprawa lub walka."
		)
	if not session.player.stats.needs_restoration():
		return "Nie potrzebujesz teraz odpoczynku."
	return ""


static func rest(session, rng: RandomNumberGenerator = null) -> Dictionary:
	var error := get_rest_error(session)
	if not error.is_empty():
		return {"ok": false, "message": error}
	var stats = session.player.stats
	var hp_amount := maxi(1, MathClass.python_roundi(stats.max_hp * HP_PERCENT))
	var mana_amount := 0
	if stats.max_mana > 0:
		mana_amount = maxi(1, MathClass.python_roundi(stats.max_mana * MANA_PERCENT))
	var healed_hp: int = stats.heal(hp_amount)
	var restored_mana: int = stats.restore_mana(mana_amount)
	session.camp_rest_available = false
	session.advance_hours(DURATION_HOURS, rng)
	var message := "Odpoczynek przy ognisku: +%d PŻ, +%d Many." % [healed_hp, restored_mana]
	var weather_change := WeatherServiceClass.format_changes(session.last_weather_changes)
	if not weather_change.is_empty():
		message += " " + weather_change
	session.last_activity = message
	session.log_event(message)
	return {
		"ok": true,
		"message": message,
		"healed_hp": healed_hp,
		"restored_mana": restored_mana,
		"weather_changes": session.last_weather_changes.duplicate(true),
	}
