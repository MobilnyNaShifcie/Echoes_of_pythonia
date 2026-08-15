class_name PassiveProgressionService
extends RefCounted

const BASIC_MAX_RANK := 5
const MASTERY_MAX_RANK := 10
const POINT_EVERY_LEVELS := 2
const PASSIVE_ORDER := ["attack_speed", "critical_damage", "health_regen", "increased_attack"]
const PASSIVE_NAMES := {
	"attack_speed": "Szybkość ataku",
	"critical_damage": "Obrażenia krytyczne",
	"health_regen": "Regeneracja zdrowia",
	"increased_attack": "Zwiększenie ataku",
}
const SPECIALIZATION_ORDER := {
	"health_regen": ["iron_will", "second_wind"],
	"attack_speed": ["flurry", "deadly_tempo"],
	"critical_damage": ["precision", "execution"],
	"increased_attack": ["raw_strength", "momentum"],
}
const SPECIALIZATIONS := {
	"iron_will":
	{
		"name": "Żelazna Wola",
		"description": "Przy 40% PŻ lub mniej regeneracja rośnie o 50%.",
	},
	"second_wind":
	{
		"name": "Drugi Oddech",
		"description": "Raz na walkę przy 25% PŻ odzyskujesz 20% maks. PŻ.",
	},
	"flurry":
	{
		"name": "Nawałnica Ciosów",
		"description": "Szansa na dodatkowe uderzenie rośnie o 5 p.p.",
	},
	"deadly_tempo":
	{
		"name": "Zabójcze Tempo",
		"description": "Krytyk przygotowuje +15 p.p. do dodatkowego uderzenia.",
	},
	"precision":
	{
		"name": "Precyzja",
		"description": "+3 p.p. stałej szansy na trafienie krytyczne.",
	},
	"execution":
	{
		"name": "Egzekucja",
		"description": "Krytyki przeciw celom poniżej 30% PŻ zadają +20% obrażeń.",
	},
	"raw_strength":
	{
		"name": "Surowa Siła",
		"description": "+5 stałego ATK.",
	},
	"momentum":
	{
		"name": "Rozpęd",
		"description": "Ofensywne akcje budują do 3 ładunków po +3% obrażeń.",
	},
}


static func total_points_for_level(level: int) -> int:
	return maxi(0, floori(level / float(POINT_EVERY_LEVELS)))


static func spent_points(player) -> int:
	var result := 0
	for passive_code: String in PASSIVE_ORDER:
		result += rank(player, passive_code)
	return result


static func available_points(player) -> int:
	return maxi(0, total_points_for_level(player.level) - spent_points(player))


static func rank(player, passive_code: String) -> int:
	return maxi(0, int(player.passive_ranks.get(passive_code, 0)))


static func max_rank(player, passive_code: String) -> int:
	return (
		MASTERY_MAX_RANK if passive_code in player.unlocked_passive_mastery_ids else BASIC_MAX_RANK
	)


static func get_spend_error(player, passive_code: String, amount := 1) -> String:
	if passive_code not in PASSIVE_ORDER:
		return "Nieznana pasywka."
	if amount <= 0:
		return "Liczba punktów musi być większa od zera."
	if amount > available_points(player):
		return "Brak tylu wolnych punktów pasywnych."
	if rank(player, passive_code) + amount > max_rank(player, passive_code):
		return "Obecny limit tej pasywki to %d." % max_rank(player, passive_code)
	return ""


static func spend(player, passive_code: String, amount := 1) -> Dictionary:
	var error := get_spend_error(player, passive_code, amount)
	if not error.is_empty():
		return {"ok": false, "message": error}
	player.passive_ranks[passive_code] = rank(player, passive_code) + amount
	player.recalculate_stats()
	return {
		"ok": true,
		"rank": rank(player, passive_code),
		"message":
		(
			"%s: %d/%d."
			% [
				PASSIVE_NAMES[passive_code],
				rank(player, passive_code),
				max_rank(player, passive_code)
			]
		),
	}


static func get_specialization_error(
	player, passive_code: String, specialization_id: String
) -> String:
	if passive_code not in PASSIVE_ORDER:
		return "Nieznana pasywka."
	if (
		passive_code not in player.unlocked_passive_mastery_ids
		or rank(player, passive_code) < MASTERY_MAX_RANK
	):
		return "Specjalizacja wymaga Mistrzostwa i rangi 10/10."
	if player.passive_specialization_ids.has(passive_code):
		return "Specjalizacja tej pasywki została już wybrana."
	if specialization_id not in SPECIALIZATION_ORDER[passive_code]:
		return "Nieprawidłowa specjalizacja tej pasywki."
	return ""


static func choose_specialization(
	player, passive_code: String, specialization_id: String
) -> Dictionary:
	var error := get_specialization_error(player, passive_code, specialization_id)
	if not error.is_empty():
		return {"ok": false, "message": error}
	player.passive_specialization_ids[passive_code] = specialization_id
	player.recalculate_stats()
	return {
		"ok": true,
		"message": "Wybrano specjalizację: %s." % SPECIALIZATIONS[specialization_id].name,
	}


static func specialization_for(player, passive_code: String) -> String:
	return str(player.passive_specialization_ids.get(passive_code, ""))


static func attack_speed_extra_hit_chance(player) -> float:
	var level := rank(player, "attack_speed")
	if level <= BASIC_MAX_RANK:
		return level * 5.0
	return BASIC_MAX_RANK * 5.0 + (level - BASIC_MAX_RANK) * 2.0


static func critical_chance(player) -> float:
	var level := rank(player, "critical_damage")
	return 0.0 if level <= 0 else 5.0 + level - 1.0


static func critical_multiplier(player) -> float:
	var level := rank(player, "critical_damage")
	if level <= BASIC_MAX_RANK:
		return 1.5 + level * 0.25
	return 2.75 + (level - BASIC_MAX_RANK) * 0.05


static func health_regeneration(player) -> int:
	var level := rank(player, "health_regen")
	if level <= BASIC_MAX_RANK:
		return level * 3
	return BASIC_MAX_RANK * 3 + (level - BASIC_MAX_RANK) * 4


static func attack_bonus(player) -> int:
	var level := rank(player, "increased_attack")
	var result := 0
	if level <= BASIC_MAX_RANK:
		result = level * 2
	else:
		result = BASIC_MAX_RANK * 2 + (level - BASIC_MAX_RANK) * 3
	if specialization_for(player, "increased_attack") == "raw_strength":
		result += 5
	return result


static func effect_description(player, passive_code: String) -> String:
	match passive_code:
		"attack_speed":
			return "%.0f%% szansy na dodatkowe uderzenie" % attack_speed_extra_hit_chance(player)
		"critical_damage":
			return (
				"%.0f%% szansy na krytyk, mnożnik ×%.2f"
				% [critical_chance(player), critical_multiplier(player)]
			)
		"health_regen":
			return "+%d PŻ regeneracji po turze przeciwnika" % health_regeneration(player)
		"increased_attack":
			return "+%d ATK" % attack_bonus(player)
	return ""


static func validate_state(player) -> String:
	if (
		not player.passive_ranks is Dictionary
		or not player.passive_specialization_ids is Dictionary
	):
		return "Zapis zawiera nieprawidłową progresję pasywną."
	var masteries := {}
	for passive_code_value in player.unlocked_passive_mastery_ids:
		var passive_code := str(passive_code_value)
		if passive_code not in PASSIVE_ORDER or masteries.has(passive_code):
			return "Zapis zawiera nieprawidłowe Mistrzostwo pasywne."
		masteries[passive_code] = true
	for passive_code_value in player.passive_ranks:
		var passive_code := str(passive_code_value)
		var rank_value = player.passive_ranks[passive_code_value]
		var cap := MASTERY_MAX_RANK if masteries.has(passive_code) else BASIC_MAX_RANK
		if (
			passive_code not in PASSIVE_ORDER
			or not _is_integer(rank_value)
			or int(rank_value) < 0
			or int(rank_value) > cap
		):
			return "Zapis zawiera niedozwoloną rangę pasywki."
	if spent_points(player) > total_points_for_level(player.level):
		return "Zapis wydaje zbyt wiele punktów pasywnych."
	for passive_code_value in player.passive_specialization_ids:
		var passive_code := str(passive_code_value)
		var specialization_id := str(player.passive_specialization_ids[passive_code_value])
		if (
			passive_code not in PASSIVE_ORDER
			or specialization_id not in SPECIALIZATION_ORDER[passive_code]
			or not masteries.has(passive_code)
			or rank(player, passive_code) < MASTERY_MAX_RANK
		):
			return "Zapis zawiera niedozwoloną specjalizację pasywną."
	return ""


static func _is_integer(value) -> bool:
	return value is int or (value is float and is_equal_approx(value, floor(value)))
