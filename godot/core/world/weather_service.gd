class_name WeatherService
extends RefCounted

const MathClass := preload("res://core/math/legacy_math.gd")

const SUNNY := "sunny"
const STORM := "storm"
const FROST := "frost"
const WIND := "wind"
const AURORA := "aurora"
const DURATION_HOURS := 6
const VALID_CODES := [SUNNY, STORM, FROST, WIND, AURORA]
const DISPLAY_NAMES := {
	SUNNY: "SŁONECZNIE",
	STORM: "BURZA",
	FROST: "MRÓZ",
	WIND: "WICHURA",
	AURORA: "ZORZA POLARNA",
}
const DESCRIPTIONS := {
	SUNNY: "Brak dodatkowych modyfikatorów walki.",
	STORM: "Minibossowie zyskują 20% PŻ, +2 ATK i obrażenia wiatru.",
	FROST: "Minibossowie zyskują 20% PŻ, +2 DEF i obrażenia mrozu.",
	WIND: "Minibossowie zyskują +1 ATK, +10% uniku i obrażenia wiatru.",
	AURORA: "Wszyscy przeciwnicy są silniejsi; EXP, złoto i szansa łupu rosną o 50%.",
}


static func is_valid_code(weather_code: String) -> bool:
	return weather_code in VALID_CODES


static func display_name_for(weather_code: String) -> String:
	return str(DISPLAY_NAMES.get(weather_code, weather_code.to_upper()))


static func description_for(weather_code: String) -> String:
	return str(DESCRIPTIONS.get(weather_code, "Nieznany stan pogody."))


static func roll_weather_code(rng: RandomNumberGenerator = null) -> String:
	return roll_weather_from_value(_get_rng(rng).randi_range(1, 100))


static func roll_weather_from_value(weighted_roll: int) -> String:
	var roll := clampi(weighted_roll, 1, 100)
	if roll <= 30:
		return SUNNY
	if roll <= 50:
		return STORM
	if roll <= 70:
		return FROST
	if roll <= 90:
		return WIND
	return AURORA


static func initialize(session, rng: RandomNumberGenerator = null) -> void:
	session.weather_code = roll_weather_code(rng)
	session.weather_remaining_hours = DURATION_HOURS
	session.last_weather_changes.clear()


static func advance(session, hours: int, rng: RandomNumberGenerator = null) -> Array[Dictionary]:
	var changes: Array[Dictionary] = []
	if hours < 0:
		return changes
	var remaining := hours
	var weather_rng := _get_rng(rng)
	while remaining > 0:
		if remaining < session.weather_remaining_hours:
			session.weather_remaining_hours -= remaining
			break
		remaining -= session.weather_remaining_hours
		var old_code: String = session.weather_code
		session.weather_code = roll_weather_code(weather_rng)
		session.weather_remaining_hours = DURATION_HOURS
		changes.append({"from": old_code, "to": session.weather_code})
	session.last_weather_changes.assign(changes)
	return changes


static func format_status(session) -> String:
	return (
		"%s  •  zmiana za %d godz."
		% [display_name_for(session.weather_code), session.weather_remaining_hours]
	)


static func format_changes(changes: Array) -> String:
	var lines: Array[String] = []
	for change: Dictionary in changes:
		lines.append("Pogoda zmienia się: %s." % display_name_for(str(change.to)))
	return " ".join(lines)


static func apply_to_enemy(enemy, weather_code: String) -> void:
	if enemy == null or not is_valid_code(weather_code) or enemy.weather_applied:
		return
	enemy.weather_code = weather_code
	enemy.weather_applied = true
	if weather_code == AURORA:
		enemy.max_hp = maxi(1, MathClass.python_roundi(enemy.max_hp * 1.25))
		enemy.current_hp = enemy.max_hp
		enemy.attack += 2
		enemy.defense += 1
		enemy.dodge = minf(95.0, enemy.dodge + 5.0)
		enemy.weather_note = "Wzmocniony przez Zorzę Polarną"
		if enemy.rank == "miniboss":
			enemy.basic_damage_type = "frost"
		return
	if enemy.rank != "miniboss":
		return
	match weather_code:
		STORM:
			enemy.max_hp = maxi(1, MathClass.python_roundi(enemy.max_hp * 1.20))
			enemy.current_hp = enemy.max_hp
			enemy.attack += 2
			enemy.basic_damage_type = "wind"
			enemy.weather_note = "Wzmocniony przez Burzę"
		FROST:
			enemy.max_hp = maxi(1, MathClass.python_roundi(enemy.max_hp * 1.20))
			enemy.current_hp = enemy.max_hp
			enemy.defense += 2
			enemy.basic_damage_type = "frost"
			enemy.weather_note = "Wzmocniony przez Mróz"
		WIND:
			enemy.attack += 1
			enemy.dodge = minf(95.0, enemy.dodge + 10.0)
			enemy.basic_damage_type = "wind"
			enemy.weather_note = "Wzmocniony przez Wichurę"


static func reward_multiplier(weather_code: String) -> float:
	return 1.5 if weather_code == AURORA else 1.0


static func drop_chance_multiplier(weather_code: String) -> float:
	return 1.5 if weather_code == AURORA else 1.0


static func _get_rng(rng: RandomNumberGenerator) -> RandomNumberGenerator:
	if rng != null:
		return rng
	var fallback := RandomNumberGenerator.new()
	fallback.randomize()
	return fallback
