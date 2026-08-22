class_name CompanionBuildService
extends RefCounted

const CompanionStateClass := preload("res://core/companions/companion_state.gd")
const EquipmentAffixServiceClass := preload("res://core/items/equipment_affix_service.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const PlayerAttributesClass := preload("res://core/player/attributes.gd")
const PlayerClassCatalogClass := preload("res://core/player/player_class_catalog.gd")
const TalentCatalogClass := preload("res://core/progression/talent_catalog.gd")
const TalentProgressionServiceClass := preload(
	"res://core/progression/talent_progression_service.gd"
)

const ATTRIBUTE_CODES := [
	PlayerAttributesClass.STRENGTH,
	PlayerAttributesClass.VITALITY,
	PlayerAttributesClass.INTELLIGENCE,
	PlayerAttributesClass.DEXTERITY,
	PlayerAttributesClass.ENDURANCE,
	PlayerAttributesClass.LUCK,
]
const CLASS_ATTRIBUTE_WEIGHTS := {
	"warrior": [0.34, 0.24, 0.0, 0.08, 0.34, 0.0],
	"hunter": [0.28, 0.18, 0.0, 0.40, 0.14, 0.0],
	"mage": [0.0, 0.20, 0.50, 0.14, 0.16, 0.0],
	"pierrot": [0.18, 0.16, 0.0, 0.24, 0.06, 0.36],
}
const CLASS_WEAPONS := {
	"warrior":
	[
		[0, "starter_sword"],
		[5, "executioner_axe"],
		[8, "drowned_mother_blade"],
		[14, "azhar_blade"],
		[20, "varek_sabre"],
	],
	"hunter":
	[
		[5, "hunting_bow"],
		[6, "blackwood_longbow"],
		[9, "mireglass_bow"],
		[14, "ashwind_bow"],
		[17, "black_sea_bow"],
	],
	"mage":
	[
		[5, "apprentice_staff"],
		[6, "blackwood_staff"],
		[9, "mire_staff"],
		[14, "ember_staff"],
		[17, "black_sea_staff"],
	],
	"pierrot":
	[
		[5, "caprice_lance"],
		[6, "crooked_fate_lance"],
		[9, "drowned_fate_lance"],
		[14, "ashen_fate_lance"],
		[17, "black_tide_fate_lance"],
	],
}
const CLASS_OFFHANDS := {
	"warrior": [[5, "training_shield"], [14, "hearthguard_shield"]],
	"hunter": [[5, "simple_quiver"], [14, "echo_quiver"]],
	"mage": [[5, "mana_crystal_artifact"], [14, "weave_relic"]],
	"pierrot": [[5, "worn_fate_dice"], [14, "trickster_card_deck"]],
}
const GENERIC_SLOT_ITEMS := {
	"head": ["leather_hood", "rotting_knight_helm", "drowned_mother_crown", "azhar_crown"],
	"chest":
	[
		"worn_leather_armor",
		"stitched_armor",
		"blackwood_mail",
		"sunken_knight_armor",
		"wasteland_armor",
	],
	"hands": ["hunter_gloves", "spiderweave_gloves", "drowned_gauntlets", "hearth_gauntlets"],
	"feet": ["reinforced_boots", "spiderstep_boots", "mirewalker_boots", "northern_trail_boots"],
	"belt": ["leather_belt", "bearhide_belt", "scale_belt", "wasteland_belt"],
	"necklace":
	[
		"wolf_tooth_necklace",
		"cultist_pendant",
		"drowned_mother_medallion",
		"sun_talisman",
	],
	"bracelet": ["nature_bracelet", "order_bracelet", "captain_signet"],
	"earrings": ["nature_earrings", "mist_earrings", "black_pearl_earrings"],
	"ring":
	[
		"nature_ring",
		"dark_sigil_ring",
		"witchbone_ring",
		"abyss_ring",
		"azhar_ring",
		"leviathan_ring",
	],
}
const RIFT_UNIQUES_BY_CLASS := {
	"warrior": ["rift_bastion_shield", "last_guard_plate", "oathbreaker_edge", "warden_chain"],
	"hunter": ["third_echo_quiver", "riftglass_bow", "silent_volley_cloak", "afterimage_ring"],
	"mage": ["split_weave_artifact", "twin_star_staff", "empty_mana_robe", "storm_archive_relic"],
	"pierrot": ["two_lies_dice", "deck_without_ace", "seven_chances_lance", "crooked_smile_mask"],
}


static func ensure_initial_build(companion: CompanionStateClass) -> bool:
	if companion == null or not needs_initial_build(companion):
		return false
	companion.attributes = _attributes_for_level(
		companion.class_code,
		companion.level,
		_rng_for(_build_seed_parts("attributes", companion)),
	)
	companion.talents = _talents_for_build(
		companion.class_code,
		companion.path_id,
		companion.level,
		_rng_for(_build_seed_parts("talents", companion)),
	)
	_generate_personal_equipment(
		companion,
		_rng_for(_build_seed_parts("equipment", companion)),
	)
	# Terminal candidates use zero as a sentinel. The first combat profile resolves
	# it to the freshly calculated maximum; persisted positive values are preserved.
	companion.current_hp = 0
	companion.current_mana = 0
	return true


static func ensure_party_builds(party) -> bool:
	if party == null:
		return false
	var changed := false
	for companion in party.companions:
		changed = ensure_initial_build(companion) or changed
	for companion in party.dismissed_companions:
		changed = ensure_initial_build(companion) or changed
	for candidate in party.candidates:
		changed = ensure_initial_build(candidate.companion) or changed
	return changed


static func needs_initial_build(companion: CompanionStateClass) -> bool:
	if companion == null or not CLASS_ATTRIBUTE_WEIGHTS.has(companion.class_code):
		return false
	var attribute_points := 0
	for code: String in ATTRIBUTE_CODES:
		attribute_points += companion.attributes.get_value(code)
	return (
		attribute_points == 0
		and companion.talents.is_empty()
		and companion.equipment.slots.is_empty()
		and companion.personal_instance_ids.is_empty()
		and companion.personal_storage.is_empty()
	)


static func gain_experience(companion: CompanionStateClass, amount: int) -> int:
	if companion == null or amount <= 0 or companion.dead:
		return 0
	companion.experience += amount
	var levels := 0
	while companion.experience >= experience_to_next_level(companion.level):
		companion.experience -= experience_to_next_level(companion.level)
		companion.level += 1
		levels += 1
	if levels > 0:
		_auto_allocate_level(
			companion,
			levels,
			_rng_for(["companion-level-v1", companion.companion_id, companion.level]),
		)
		companion.current_hp = 0
		companion.current_mana = 0
	return levels


static func experience_to_next_level(level: int) -> int:
	return int(50 * pow(level + 1, 1.5))


static func resource_limits(companion: CompanionStateClass) -> Dictionary:
	if companion == null:
		return {"max_hp": 0, "max_mana": 0, "attack": 0, "defense": 0, "dodge": 0.0}
	var attribute_bonuses := companion.attributes.calculate_bonuses()
	var equipment_bonuses := companion.equipment.total_bonuses(companion.class_code)
	var class_definition = PlayerClassCatalogClass.get_definition(companion.class_code)
	var base_mana: int = class_definition.base_mana if class_definition != null else 0
	return {
		"max_hp": 20 + attribute_bonuses.max_hp + equipment_bonuses.max_hp,
		"max_mana": attribute_bonuses.max_mana + equipment_bonuses.max_mana + base_mana,
		"attack": attribute_bonuses.attack + equipment_bonuses.attack,
		"defense": attribute_bonuses.defense + equipment_bonuses.defense,
		"dodge": attribute_bonuses.dodge + equipment_bonuses.dodge,
		"magic_power": equipment_bonuses.magic_power,
		"average_damage": equipment_bonuses.average_damage,
	}


static func resolved_resources(companion: CompanionStateClass) -> Dictionary:
	var limits := resource_limits(companion)
	return {
		"current_hp":
		(
			int(limits.max_hp)
			if companion != null and companion.current_hp <= 0
			else mini(companion.current_hp, int(limits.max_hp))
		),
		"current_mana":
		(
			int(limits.max_mana)
			if companion != null and companion.current_mana <= 0
			else mini(companion.current_mana, int(limits.max_mana))
		),
		"max_hp": int(limits.max_hp),
		"max_mana": int(limits.max_mana),
	}


static func sync_resources(
	companion: CompanionStateClass, current_hp: int, current_mana: int
) -> void:
	if companion == null:
		return
	companion.current_hp = maxi(0, current_hp)
	companion.current_mana = maxi(0, current_mana)


static func _attributes_for_level(
	class_code: String, level: int, rng: RandomNumberGenerator
) -> PlayerAttributesClass:
	var points := maxi(0, level) * 4
	var weights: Array = CLASS_ATTRIBUTE_WEIGHTS[class_code]
	var jitter := []
	for weight: float in weights:
		jitter.append(maxf(0.0, weight + rng.randf_range(-0.035, 0.035)))
	var total := 0.0
	for value: float in jitter:
		total += value
	if is_zero_approx(total):
		total = 1.0
	var raw := []
	var values := []
	for value: float in jitter:
		var raw_value := points * value / total
		raw.append(raw_value)
		values.append(int(raw_value))
	var assigned := 0
	for value: int in values:
		assigned += value
	var order := range(raw.size())
	order.sort_custom(
		func(first: int, second: int) -> bool:
			return raw[first] - values[first] > raw[second] - values[second]
	)
	for index in points - assigned:
		values[order[index]] += 1
	var attributes := PlayerAttributesClass.new()
	for index in ATTRIBUTE_CODES.size():
		attributes.set(ATTRIBUTE_CODES[index], values[index])
	return attributes


static func _talents_for_build(
	class_code: String, path_id: String, level: int, rng: RandomNumberGenerator
) -> Dictionary:
	var points := TalentProgressionServiceClass.total_points_for_level(level, true)
	var paths: Array = TalentCatalogClass.CLASS_PATH_ORDER[class_code]
	var secondary: String = path_id
	for candidate_path: String in paths:
		if candidate_path != path_id:
			secondary = candidate_path
			break
	var result := {}
	for _point in points:
		var target_path := path_id if rng.randf() < 0.80 else secondary
		var candidates := _eligible_talents(target_path, result)
		if candidates.is_empty() and target_path != path_id:
			candidates = _eligible_talents(path_id, result)
		if candidates.is_empty():
			break
		candidates.sort_custom(
			func(first, second) -> bool:
				var first_key := [
					0 if "core" in first.talent_id else 1,
					0 if not first.active_skill_id.is_empty() else 1,
					first.talent_id,
				]
				var second_key := [
					0 if "core" in second.talent_id else 1,
					0 if not second.active_skill_id.is_empty() else 1,
					second.talent_id,
				]
				return first_key < second_key
		)
		var talent = (
			candidates[0]
			if rng.randf() < 0.70
			else candidates[rng.randi_range(0, candidates.size() - 1)]
		)
		result[talent.talent_id] = int(result.get(talent.talent_id, 0)) + 1
	return result


static func _eligible_talents(path_id: String, ranks: Dictionary) -> Array:
	var result := []
	for talent in TalentCatalogClass.get_talents_for_path(path_id):
		if int(ranks.get(talent.talent_id, 0)) >= talent.max_rank:
			continue
		var prerequisites_met := true
		for required_id: String in talent.prerequisites:
			if int(ranks.get(required_id, 0)) < int(talent.prerequisites[required_id]):
				prerequisites_met = false
				break
		if prerequisites_met:
			result.append(talent)
	return result


static func _generate_personal_equipment(
	companion: CompanionStateClass, rng: RandomNumberGenerator
) -> void:
	companion.equipment.slots.clear()
	companion.personal_instance_ids.clear()
	companion.personal_storage.clear()
	var quality := (
		EquipmentAffixServiceClass.QUALITY_ELITE
		if companion.level < 14
		else EquipmentAffixServiceClass.QUALITY_MINIBOSS
	)
	var upgrade := mini(8, maxi(0, int(companion.level / 4.0) - 1))
	_add_personal_item(
		companion,
		_choose_for_level(CLASS_WEAPONS[companion.class_code], companion.level),
		quality,
		upgrade,
		rng
	)
	_add_personal_item(
		companion,
		_choose_for_level(CLASS_OFFHANDS[companion.class_code], companion.level),
		quality,
		maxi(0, upgrade - 1),
		rng,
	)
	for slot: String in GENERIC_SLOT_ITEMS:
		var valid := _valid_items_for_level(GENERIC_SLOT_ITEMS[slot], companion.level)
		if not valid.is_empty() and rng.randf() < 0.72:
			var item_id: String = (
				valid[-1] if rng.randf() < 0.55 else valid[rng.randi_range(0, valid.size() - 1)]
			)
			_add_personal_item(companion, item_id, quality, maxi(0, upgrade - 2), rng)
	var uniques := _valid_items_for_level(
		RIFT_UNIQUES_BY_CLASS.get(companion.class_code, []), companion.level
	)
	var path = TalentCatalogClass.get_path_definition(companion.path_id)
	var unique_chance := 0.16 if path != null and path.requires_book() else 0.08
	if not uniques.is_empty() and rng.randf() < unique_chance:
		_add_personal_item(
			companion,
			uniques[rng.randi_range(0, uniques.size() - 1)],
			EquipmentAffixServiceClass.QUALITY_BOSS,
			mini(10, upgrade + 2),
			rng,
		)


static func _add_personal_item(
	companion: CompanionStateClass,
	item_id: String,
	quality: String,
	upgrade_level: int,
	rng: RandomNumberGenerator
) -> void:
	var definition = ItemCatalogClass.get_definition(item_id)
	if (
		definition == null
		or not definition.is_equipment()
		or definition.item_power <= 0
		or definition.required_level > companion.level
	):
		return
	var item = EquipmentAffixServiceClass.generate_item(definition, rng, quality)
	item.upgrade_level = upgrade_level
	item.instance_id = (
		"npc-%s-%s-%d" % [companion.companion_id, item_id, companion.personal_instance_ids.size()]
	)
	var previous = companion.equipment.equip_and_return_previous(item)
	if previous != null:
		companion.personal_storage.append(previous)
	companion.personal_instance_ids.append(item.instance_id)


static func _valid_items_for_level(item_ids: Array, level: int) -> Array:
	var result := []
	for item_id_value in item_ids:
		var item_id := str(item_id_value)
		var definition = ItemCatalogClass.get_definition(item_id)
		if (
			definition != null
			and definition.is_equipment()
			and definition.item_power > 0
			and definition.required_level <= level
		):
			result.append(item_id)
	return result


static func _choose_for_level(options: Array, level: int) -> String:
	var chosen := str(options[0][1])
	for option: Array in options:
		if level >= int(option[0]):
			chosen = str(option[1])
	return chosen


static func _auto_allocate_level(
	companion: CompanionStateClass, levels: int, rng: RandomNumberGenerator
) -> void:
	if levels <= 0:
		return
	var weights: Array = CLASS_ATTRIBUTE_WEIGHTS[companion.class_code]
	for _point in levels * 4:
		companion.attributes.increase(ATTRIBUTE_CODES[_weighted_choice(weights, rng)])
	var desired_points := TalentProgressionServiceClass.total_points_for_level(
		companion.level, true
	)
	while _spent_talent_points(companion.talents) < desired_points:
		var options := _eligible_talents(companion.path_id, companion.talents)
		if options.is_empty():
			break
		var talent = options[0]
		companion.talents[talent.talent_id] = (int(companion.talents.get(talent.talent_id, 0)) + 1)


static func _weighted_choice(weights: Array, rng: RandomNumberGenerator) -> int:
	var total := 0.0
	for weight: float in weights:
		total += weight
	var roll := rng.randf() * total
	var cumulative := 0.0
	for index in weights.size():
		cumulative += float(weights[index])
		if roll < cumulative:
			return index
	return weights.size() - 1


static func _spent_talent_points(talents: Dictionary) -> int:
	var result := 0
	for rank_value in talents.values():
		result += maxi(0, int(rank_value))
	return result


static func _build_seed_parts(stream_name: String, companion: CompanionStateClass) -> Array:
	return [
		"companion-build-%s-v1" % stream_name,
		companion.companion_id,
		companion.class_code,
		companion.level,
		companion.path_id,
	]


static func _rng_for(parts: Array) -> RandomNumberGenerator:
	var text_parts: Array[String] = []
	for part in parts:
		text_parts.append(str(part))
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update("|".join(text_parts).to_utf8_buffer())
	var digest := context.finish()
	var seed_value := 0
	# Seven digest bytes keep the seed in Godot's positive signed 64-bit range.
	for index in 7:
		seed_value = (seed_value << 8) | int(digest[index])
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng
