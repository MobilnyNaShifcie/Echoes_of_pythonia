class_name WorldEncounterSaveCodec
extends RefCounted

const OpenWorldEncounterStateClass := preload("res://core/world/open_world_encounter_state.gd")
const RegionCatalogClass := preload("res://core/world/region_catalog.gd")


static func empty_data() -> Dictionary:
	return {
		"elite_discoveries": [],
		"elite_miss_streaks": {},
		"region_boss_respawns": {},
	}


static func serialize(state: OpenWorldEncounterStateClass) -> Dictionary:
	return {
		"elite_discoveries": state.elite_discoveries.duplicate(),
		"elite_miss_streaks": state.elite_miss_streaks.duplicate(true),
		"region_boss_respawns": state.region_boss_respawns.duplicate(true),
	}


static func deserialize(data: Dictionary) -> Dictionary:
	if not data.get("elite_discoveries") is Array:
		return _failure("Rejestr odkrytych elit ma nieprawidłową strukturę.")
	if not data.get("elite_miss_streaks") is Dictionary:
		return _failure("Liczniki spotkań bez elity mają nieprawidłową strukturę.")
	if not data.get("region_boss_respawns") is Dictionary:
		return _failure("Liczniki odrodzenia bossów regionów mają nieprawidłową strukturę.")

	var discoveries: Array[String] = []
	for modifier_value in data.elite_discoveries:
		if (
			not modifier_value is String
			or not str(modifier_value) in OpenWorldEncounterStateClass.ELITE_MODIFIER_IDS
			or str(modifier_value) in discoveries
		):
			return _failure("Rejestr zawiera nieznany albo powtórzony typ elity.")
		discoveries.append(str(modifier_value))

	var miss_streaks := {}
	for region_value in data.elite_miss_streaks:
		if not region_value is String or not RegionCatalogClass.is_valid_region_id(region_value):
			return _failure("Licznik spotkań bez elity wskazuje nieznany region.")
		var streak_value = data.elite_miss_streaks[region_value]
		if not _is_non_negative_integer(streak_value):
			return _failure("Licznik spotkań bez elity musi być nieujemną liczbą całkowitą.")
		miss_streaks[str(region_value)] = int(streak_value)

	var boss_respawns := {}
	for boss_value in data.region_boss_respawns:
		if (
			not boss_value is String
			or not str(boss_value) in OpenWorldEncounterStateClass.REGION_BOSS_IDS
		):
			return _failure("Licznik odrodzenia wskazuje nieznanego bossa regionu.")
		var counter_value = data.region_boss_respawns[boss_value]
		if not _is_non_negative_integer(counter_value):
			return _failure("Licznik odrodzenia bossa musi być nieujemną liczbą całkowitą.")
		boss_respawns[str(boss_value)] = int(counter_value)

	var state := OpenWorldEncounterStateClass.new()
	state.elite_discoveries.assign(discoveries)
	state.elite_miss_streaks = miss_streaks
	state.region_boss_respawns = boss_respawns
	return {"ok": true, "state": state}


static func _is_integer(value) -> bool:
	return (value is int or value is float) and is_equal_approx(float(value), floorf(float(value)))


static func _is_non_negative_integer(value) -> bool:
	return _is_integer(value) and int(value) >= 0


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
