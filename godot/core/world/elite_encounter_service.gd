class_name EliteEncounterService
extends RefCounted

const ElementalResistancesClass := preload("res://core/combat/elemental_resistances.gd")
const EliteCatalogClass := preload("res://core/world/elite_catalog.gd")
const MathClass := preload("res://core/math/legacy_math.gd")
const RegionCatalogClass := preload("res://core/world/region_catalog.gd")
const WeatherServiceClass := preload("res://core/world/weather_service.gd")

const ELITE_MISS_BONUS := 0.02
const MAX_ELITE_CHANCE := 0.95
const ELITE_BASE_HP_MULTIPLIER := 1.40
const ELITE_BASE_ATTACK_MULTIPLIER := 1.10
const ELITE_BASE_DEFENSE_BONUS := 1
const ELITE_BASE_DODGE_BONUS := 3.0


static func elite_encounter_chance(period_code: String, weather_code: String) -> float:
	if weather_code == WeatherServiceClass.AURORA:
		return 0.25
	if period_code == "night":
		return 0.15
	return 0.10


static func elite_chance_with_streak(
	period_code: String, weather_code: String, miss_count: int
) -> float:
	if miss_count < 0:
		return -1.0
	return minf(
		MAX_ELITE_CHANCE,
		elite_encounter_chance(period_code, weather_code) + miss_count * ELITE_MISS_BONUS,
	)


static func can_become_elite(enemy) -> bool:
	return (
		enemy != null
		and enemy.rank == "normal"
		and EliteCatalogClass.COMPATIBILITY.has(enemy.enemy_id)
		and enemy.elite_modifier_id.is_empty()
	)


static func roll_for_region(
	enemy,
	period_code: String,
	weather_code: String,
	region_id: String,
	state,
	rng: RandomNumberGenerator,
) -> Dictionary:
	if rng == null:
		return _failure("Losowanie elity wymaga źródła RNG.")
	if not can_become_elite(enemy):
		return {"ok": true, "modifier_id": "", "chance": 0.0, "eligible": false}
	if state == null or not RegionCatalogClass.is_valid_region_id(region_id):
		return _failure("Nieprawidłowy region licznika elit.")
	if not WeatherServiceClass.is_valid_code(weather_code) or period_code not in ["day", "night"]:
		return _failure("Nieprawidłowy czas albo pogoda losowania elity.")
	var miss_count := int(state.elite_miss_streaks.get(region_id, 0))
	var chance := elite_chance_with_streak(period_code, weather_code, miss_count)
	if chance < 0.0:
		return _failure("Licznik spotkań bez elity nie może być ujemny.")
	var chance_roll := rng.randf()
	# Terminal zużywa kolejne losowanie wyłącznie wtedy, gdy próba elity się powiedzie.
	var modifier_roll := rng.randi() if chance_roll < chance else 0
	return resolve_roll(
		enemy,
		period_code,
		weather_code,
		region_id,
		state,
		chance_roll,
		modifier_roll,
	)


static func resolve_roll(
	enemy,
	period_code: String,
	weather_code: String,
	region_id: String,
	state,
	chance_roll: float,
	modifier_roll: int,
) -> Dictionary:
	if state == null or not RegionCatalogClass.is_valid_region_id(region_id):
		return _failure("Nieprawidłowy region licznika elit.")
	if not WeatherServiceClass.is_valid_code(weather_code) or period_code not in ["day", "night"]:
		return _failure("Nieprawidłowy czas albo pogoda losowania elity.")
	if chance_roll < 0.0 or chance_roll >= 1.0:
		return _failure("Rzut szansy elity musi należeć do zakresu [0, 1).")
	if not can_become_elite(enemy):
		return {"ok": true, "modifier_id": "", "chance": 0.0, "eligible": false}
	var miss_count := int(state.elite_miss_streaks.get(region_id, 0))
	var chance := elite_chance_with_streak(period_code, weather_code, miss_count)
	if chance < 0.0:
		return _failure("Licznik spotkań bez elity nie może być ujemny.")
	if chance_roll >= chance:
		state.elite_miss_streaks[region_id] = miss_count + 1
		return {
			"ok": true,
			"modifier_id": "",
			"chance": chance,
			"eligible": true,
			"previous_miss_count": miss_count,
		}
	var compatible := EliteCatalogClass.compatible_modifier_ids(enemy.enemy_id)
	var modifier_id: String = compatible[posmod(modifier_roll, compatible.size())]
	var applied := apply_modifier(enemy, modifier_id, weather_code)
	if not applied.ok:
		return applied
	state.elite_miss_streaks[region_id] = 0
	return {
		"ok": true,
		"modifier_id": modifier_id,
		"chance": chance,
		"eligible": true,
		"previous_miss_count": miss_count,
	}


static func apply_modifier(enemy, modifier_id: String, weather_code: String) -> Dictionary:
	if EliteCatalogClass.get_modifier(modifier_id) == null:
		return _failure("Nieznany modyfikator elity: %s." % modifier_id)
	if not WeatherServiceClass.is_valid_code(weather_code):
		return _failure("Nieznana pogoda dla elity.")
	if not can_become_elite(enemy):
		return _failure("Ten przeciwnik nie może otrzymać losowego modyfikatora elity.")
	if not EliteCatalogClass.is_compatible(enemy.enemy_id, modifier_id):
		return _failure("Modyfikator %s nie pasuje do tego przeciwnika." % modifier_id)

	_apply_elite_baseline(enemy)
	var prefix := ""
	match modifier_id:
		"furious":
			enemy.max_hp = maxi(1, ceili(enemy.max_hp * 1.10))
			enemy.current_hp = enemy.max_hp
			enemy.attack = maxi(1, ceili(enemy.attack * 1.30))
			enemy.defense = maxi(0, enemy.defense - 1)
			prefix = _modifier_prefix(enemy, modifier_id)
			enemy.elite_note = "elitarna baza + PŻ +10%, ATK +30%, DEF -1"
		"armored":
			enemy.max_hp = maxi(1, ceili(enemy.max_hp * 1.35))
			enemy.current_hp = enemy.max_hp
			enemy.defense = maxi(enemy.defense + 2, ceili(enemy.defense * 1.50))
			prefix = _modifier_prefix(enemy, modifier_id)
			enemy.elite_note = "elitarna baza + PŻ +35%, mocno zwiększony DEF"
		"vampiric":
			enemy.max_hp = maxi(1, ceili(enemy.max_hp * 1.25))
			enemy.current_hp = enemy.max_hp
			enemy.life_steal_percent = 40.0
			prefix = _modifier_prefix(enemy, modifier_id)
			enemy.elite_note = "elitarna baza + PŻ +25%, odzyskuje 40% zadanych obrażeń"
		"cursed":
			enemy.max_hp = maxi(1, ceili(enemy.max_hp * 1.20))
			enemy.current_hp = enemy.max_hp
			enemy.special_chance = minf(1.0, maxf(0.30, enemy.special_chance + 0.20))
			enemy.special_attack_bonus += 2
			if enemy.special_name.is_empty():
				enemy.special_name = "Uderzenie Klątwy"
			enemy.status_resistance = 0.50
			prefix = _modifier_prefix(enemy, modifier_id)
			enemy.elite_note = (
				"elitarna baza + PŻ +20%, znacznie silniejsze ataki specjalne, "
				+ "50% odporności na negatywne efekty"
			)
		"elemental":
			enemy.max_hp = maxi(1, ceili(enemy.max_hp * 1.30))
			enemy.current_hp = enemy.max_hp
			enemy.attack = maxi(1, ceili(enemy.attack * 1.15))
			enemy.special_attack_bonus += 2
			var element := _element_for_weather(weather_code)
			prefix = _adjective_form(enemy, element.forms)
			enemy.basic_damage_type = element.damage_type
			enemy.special_damage_type = element.damage_type
			enemy.elemental_resistances = ElementalResistancesClass.new({element.damage_type: 50})
			enemy.elite_note = (
				(
					"elitarna baza + PŻ +30%, mocniejszy ATK, obrażenia: {element}, "
					+ "odporność {element}: 50%"
				)
				. format({"element": ElementalResistancesClass.display_name(element.damage_type)})
			)

	enemy.experience_reward = maxi(1, MathClass.python_roundi(enemy.experience_reward * 1.50))
	enemy.gold_min = maxi(0, MathClass.python_roundi(enemy.gold_min * 1.25))
	enemy.gold_max = maxi(enemy.gold_min, MathClass.python_roundi(enemy.gold_max * 1.25))
	enemy.loot_chance_multiplier = 1.20
	enemy.rank = "elite"
	enemy.elite_modifier_id = modifier_id
	enemy.display_name = "%s %s" % [prefix, enemy.display_name]
	return {"ok": true, "modifier_id": modifier_id}


static func record_discovery(state, enemy) -> String:
	if (
		state == null
		or enemy == null
		or enemy.elite_modifier_id.is_empty()
		or enemy.elite_modifier_id in state.elite_discoveries
	):
		return ""
	state.elite_discoveries.append(enemy.elite_modifier_id)
	return "Po raz pierwszy pokonano typ elity: %s." % enemy.display_name


static func _apply_elite_baseline(enemy) -> void:
	enemy.max_hp = maxi(1, ceili(enemy.max_hp * ELITE_BASE_HP_MULTIPLIER))
	enemy.current_hp = enemy.max_hp
	enemy.attack = maxi(1, ceili(enemy.attack * ELITE_BASE_ATTACK_MULTIPLIER))
	enemy.defense += ELITE_BASE_DEFENSE_BONUS
	enemy.dodge = minf(95.0, enemy.dodge + ELITE_BASE_DODGE_BONUS)


static func _modifier_prefix(enemy, modifier_id: String) -> String:
	var forms := {
		"furious": ["Wściekły", "Wściekła", "Wściekłe"],
		"armored": ["Opancerzony", "Opancerzona", "Opancerzone"],
		"vampiric": ["Wampiryczny", "Wampiryczna", "Wampiryczne"],
		"cursed": ["Przeklęty", "Przeklęta", "Przeklęte"],
	}
	return _adjective_form(enemy, forms[modifier_id])


static func _adjective_form(enemy, forms: Array) -> String:
	if enemy.grammatical_gender == "feminine":
		return str(forms[1])
	if enemy.grammatical_gender == "neuter":
		return str(forms[2])
	return str(forms[0])


static func _element_for_weather(weather_code: String) -> Dictionary:
	match weather_code:
		WeatherServiceClass.STORM:
			return {"damage_type": "wind", "forms": ["Burzowy", "Burzowa", "Burzowe"]}
		WeatherServiceClass.WIND:
			return {"damage_type": "wind", "forms": ["Wichrowy", "Wichrowa", "Wichrowe"]}
		WeatherServiceClass.FROST:
			return {"damage_type": "frost", "forms": ["Mroźny", "Mroźna", "Mroźne"]}
		WeatherServiceClass.AURORA:
			return {"damage_type": "frost", "forms": ["Zorzowy", "Zorzowa", "Zorzowe"]}
	return {"damage_type": "fire", "forms": ["Rozżarzony", "Rozżarzona", "Rozżarzone"]}


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
