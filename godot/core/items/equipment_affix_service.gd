class_name EquipmentAffixService
extends RefCounted

const EquipmentAffixClass := preload("res://core/items/equipment_affix.gd")
const EquipmentItemClass := preload("res://core/items/equipment_item.gd")
const MathClass := preload("res://core/math/legacy_math.gd")
const SignatureWeaponServiceClass := preload("res://core/items/signature_weapon_service.gd")

const QUALITY_NORMAL := "normal"
const QUALITY_ELITE := "elite"
const QUALITY_MINIBOSS := "miniboss"
const QUALITY_DUNGEON := "dungeon"
const QUALITY_BOSS := "boss"

const AFFIX_COUNTS := {
	"common": 0,
	"uncommon": 1,
	"rare": 2,
	"epic": 3,
	"legendary": 4,
	"mythic": 4,
}
const TIER_WEIGHTS := {
	QUALITY_NORMAL: [35, 30, 20, 10, 5],
	QUALITY_ELITE: [25, 28, 24, 15, 8],
	QUALITY_MINIBOSS: [18, 25, 27, 20, 10],
	QUALITY_DUNGEON: [12, 20, 28, 25, 15],
	QUALITY_BOSS: [8, 15, 25, 28, 24],
}
const TIER_FACTORS := {1: 0.2, 2: 0.4, 3: 0.6, 4: 0.8, 5: 1.0}
const DEFENSIVE_AFFIXES := [
	"max_hp",
	"defense",
	"dodge",
	"health_regen",
	"fire_resistance",
	"wind_resistance",
	"frost_resistance",
	"earth_resistance",
	"water_resistance",
]
const OFFENSIVE_AFFIXES := [
	"attack",
	"max_mana",
	"crit_chance",
	"crit_damage",
	"skill_damage",
	"armor_penetration",
	"damage_vs_elite",
	"damage_vs_boss",
]
const FLAT_T5 := {
	"max_hp": [12, 18, 24, 30],
	"attack": [2, 3, 4, 5],
	"defense": [2, 2, 3, 4],
	"max_mana": [6, 8, 10, 12],
	"health_regen": [1, 1, 1, 1],
}
const PERCENT_T5 := {
	"dodge": [1.5, 2.0, 2.5, 3.0],
	"crit_chance": [2.5, 3.0, 3.5, 4.0],
	"crit_damage": [8.0, 10.0, 12.0, 15.0],
	"skill_damage": [3.0, 4.0, 5.0, 6.0],
	"armor_penetration": [2.0, 3.0, 4.0, 5.0],
	"damage_vs_elite": [5.0, 6.0, 8.0, 10.0],
	"damage_vs_boss": [5.0, 6.0, 8.0, 10.0],
	"fire_resistance": [5.0, 6.0, 7.0, 8.0],
	"wind_resistance": [5.0, 6.0, 7.0, 8.0],
	"frost_resistance": [5.0, 6.0, 7.0, 8.0],
	"earth_resistance": [5.0, 6.0, 7.0, 8.0],
	"water_resistance": [5.0, 6.0, 7.0, 8.0],
}
const PERCENT_ENDGAME := {
	"dodge": [5.0, 0.25],
	"crit_chance": [10.0, 0.75],
	"crit_damage": [30.0, 2.0],
	"skill_damage": [12.0, 0.75],
	"armor_penetration": [10.0, 0.625],
	"damage_vs_elite": [20.0, 1.25],
	"damage_vs_boss": [20.0, 1.25],
	"fire_resistance": [15.0, 0.875],
	"wind_resistance": [15.0, 0.875],
	"frost_resistance": [15.0, 0.875],
	"earth_resistance": [15.0, 0.875],
	"water_resistance": [15.0, 0.875],
}
const DISPLAY_NAMES := {
	"max_hp": "Maks. PŻ",
	"attack": "Atak",
	"defense": "Obrona",
	"max_mana": "Maks. mana",
	"health_regen": "Regeneracja PŻ",
	"dodge": "Unik",
	"crit_chance": "Szansa na trafienie krytyczne",
	"crit_damage": "Obrażenia krytyczne",
	"skill_damage": "Obrażenia umiejętności",
	"armor_penetration": "Przebicie pancerza",
	"damage_vs_elite": "Obrażenia przeciw elitom",
	"damage_vs_boss": "Obrażenia przeciw bossom",
	"fire_resistance": "Odporność na ogień",
	"wind_resistance": "Odporność na wiatr",
	"frost_resistance": "Odporność na mróz",
	"earth_resistance": "Odporność na ziemię",
	"water_resistance": "Odporność na wodę",
}
const PERCENT_AFFIXES := [
	"dodge",
	"crit_chance",
	"crit_damage",
	"skill_damage",
	"armor_penetration",
	"damage_vs_elite",
	"damage_vs_boss",
	"fire_resistance",
	"wind_resistance",
	"frost_resistance",
	"earth_resistance",
	"water_resistance",
]
const RESISTANCE_AFFIXES := [
	"fire_resistance",
	"wind_resistance",
	"frost_resistance",
	"earth_resistance",
	"water_resistance",
]


static func generate_item(definition, rng: RandomNumberGenerator = null, quality := QUALITY_NORMAL):
	if definition == null or not definition.is_equipment():
		return null
	var actual_rng := rng
	if actual_rng == null:
		actual_rng = RandomNumberGenerator.new()
		actual_rng.randomize()
	var affixes := roll_affixes(definition, actual_rng, quality)
	return (
		EquipmentItemClass
		. new(
			definition,
			0,
			affixes,
			definition.item_power,
			SignatureWeaponServiceClass.roll_average_damage_percent(definition.item_id, actual_rng),
		)
	)


static func deterministic_item(definition, upgrade_level: int, instance_id: String):
	if definition == null or not definition.is_equipment():
		return null
	var rng := RandomNumberGenerator.new()
	rng.seed = absi(("%s:%s:%d" % [definition.item_id, instance_id, definition.item_power]).hash())
	var affixes := roll_affixes(definition, rng, QUALITY_NORMAL)
	var item = EquipmentItemClass.new(definition, upgrade_level, affixes, definition.item_power)
	item.instance_id = instance_id
	item.average_damage_percent = SignatureWeaponServiceClass.deterministic_average_damage_percent(
		definition.item_id, instance_id
	)
	return item


static func roll_affixes(definition, rng: RandomNumberGenerator, quality: String) -> Array:
	var result: Array[EquipmentAffixClass] = []
	var count: int = AFFIX_COUNTS.get(definition.rarity, 0)
	var pool: Array = _pool_for_slot(definition.slot)
	for _index in mini(count, pool.size()):
		var pool_index := rng.randi_range(0, pool.size() - 1)
		var affix_id: String = pool.pop_at(pool_index)
		var tier := _roll_tier(rng, quality)
		result.append(
			EquipmentAffixClass.new(
				affix_id, tier, value_for(affix_id, definition.item_power, tier, definition.slot)
			)
		)
	return result


static func value_for(affix_id: String, item_power: int, tier: int, slot: String) -> float:
	var normalized_power := maxi(item_power, 1)
	var factor: float = TIER_FACTORS.get(clampi(tier, 1, 5), 0.2)
	var tier_five_value := 0.0
	if FLAT_T5.has(affix_id):
		var values: Array = FLAT_T5[affix_id]
		if normalized_power <= 4:
			tier_five_value = float(values[normalized_power - 1])
		else:
			tier_five_value = float(values[3]) * pow(1.75, normalized_power - 4)
		var flat_value := maxi(
			1, MathClass.python_roundi(tier_five_value * factor * _slot_multiplier(slot))
		)
		return float(flat_value)
	if PERCENT_T5.has(affix_id):
		var percent_values: Array = PERCENT_T5[affix_id]
		if normalized_power <= 4:
			tier_five_value = float(percent_values[normalized_power - 1])
		else:
			var growth: Array = PERCENT_ENDGAME[affix_id]
			tier_five_value = minf(
				float(growth[0]),
				float(percent_values[3]) + float(growth[1]) * (normalized_power - 4)
			)
		var raw_percent := tier_five_value * factor * _slot_multiplier(slot)
		if affix_id in RESISTANCE_AFFIXES:
			return float(maxi(1, MathClass.python_roundi(raw_percent)))
		var percent_value := maxf(0.1, raw_percent)
		return snappedf(percent_value, 0.1)
	return 0.0


static func validate(definition, affixes: Array) -> String:
	if definition == null or not definition.is_equipment():
		return "Nieprawidłowa definicja przedmiotu."
	var expected_count: int = AFFIX_COUNTS.get(definition.rarity, 0)
	if affixes.size() != expected_count:
		return "Nieprawidłowa liczba afiksów."
	var pool := _pool_for_slot(definition.slot)
	var seen := {}
	for affix in affixes:
		if affix == null or not affix.affix_id in pool or seen.has(affix.affix_id):
			return "Nieprawidłowy lub powtórzony afiks."
		if affix.tier < 1 or affix.tier > 5:
			return "Nieprawidłowy poziom afiksu."
		var expected := value_for(
			affix.affix_id, definition.item_power, affix.tier, definition.slot
		)
		if not is_equal_approx(float(affix.value), expected):
			return "Nieprawidłowa wartość afiksu."
		seen[affix.affix_id] = true
	return ""


static func bonuses_for(item) -> Dictionary:
	var bonuses := {}
	if item == null:
		return bonuses
	for affix in item.affixes:
		bonuses[affix.affix_id] = bonuses.get(affix.affix_id, 0.0) + affix.value
	return bonuses


static func formatted_affix(affix) -> String:
	if affix == null:
		return ""
	var suffix := "%" if affix.affix_id in PERCENT_AFFIXES else ""
	var value_text := (
		"%.1f" % affix.value
		if not is_equal_approx(affix.value, roundf(affix.value))
		else str(roundi(affix.value))
	)
	return (
		"T%d • %s +%s%s"
		% [affix.tier, DISPLAY_NAMES.get(affix.affix_id, affix.affix_id), value_text, suffix]
	)


static func _pool_for_slot(slot: String) -> Array:
	if slot in ["head", "chest", "hands", "feet"]:
		return DEFENSIVE_AFFIXES.duplicate()
	if slot in ["weapon", "necklace", "bracelet", "earrings", "ring"]:
		return OFFENSIVE_AFFIXES.duplicate()
	var mixed := DEFENSIVE_AFFIXES.duplicate()
	mixed.append_array(OFFENSIVE_AFFIXES)
	return mixed


static func _roll_tier(rng: RandomNumberGenerator, quality: String) -> int:
	var weights: Array = TIER_WEIGHTS.get(quality, TIER_WEIGHTS[QUALITY_NORMAL])
	var roll := rng.randi_range(1, 100)
	var cumulative := 0
	for index in weights.size():
		cumulative += int(weights[index])
		if roll <= cumulative:
			return index + 1
	return 1


static func _slot_multiplier(slot: String) -> float:
	return 0.75 if slot == "belt" else 1.0
