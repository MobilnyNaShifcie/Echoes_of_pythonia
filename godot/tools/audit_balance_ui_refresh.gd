extends SceneTree
## Deterministic combat smoke audit. Fresh synthetic profiles, never player saves.
const Factory := preload("res://core/player/player_factory.gd")
const Regions := preload("res://core/world/region_catalog.gd")
const Enemies := preload("res://core/combat/enemy_catalog.gd")
const Items := preload("res://core/items/item_catalog.gd")
const Skills := preload("res://core/skills/skill_catalog.gd")
const BattleEngine := preload("res://core/combat/combat_engine.gd")
const TRIALS := 100
var battles := 0
var invalid_results := 0
var _gear_cache: Dictionary = {}


func _init() -> void:
	call_deferred("_audit")


func _audit() -> void:
	var rows: Array[Dictionary] = []
	for region in Regions.get_all_definitions():
		for level in [region.recommended_level_min, region.recommended_level_max]:
			var classes: Array = ["none"] if level < 5 else ["warrior", "hunter", "mage", "pierrot"]
			for code: String in classes:
				for equipped in [false, true]:
					for period in ["day", "night"]:
						var wins := 0
						var turns := 0
						var hp_remaining := 0.0
						var timeouts := 0
						var ids: Array = region.encounters_for(period).keys()
						var weights: Dictionary = region.encounters_for(period)
						for seed_value in TRIALS:
							var rng := RandomNumberGenerator.new()
							var roll := seed_value
							var enemy_id: String = ids.back()
							for candidate: String in ids:
								roll -= int(weights[candidate])
								if roll < 0:
									enemy_id = candidate
									break
								rng.seed = 90210 + seed_value
							var player = _profile(level, code, equipped, region.danger_rating, rng)
							var engine = BattleEngine.new(
								player, Enemies.create_enemy(enemy_id), rng
							)
							var count := 0
							while engine.result == "ongoing" and count < 150:
								_take_turn(engine)
								count += 1
							battles += 1
							turns += count
							wins += 1 if engine.result == "victory" else 0
							timeouts += 1 if engine.result == "ongoing" else 0
							hp_remaining += float(player.stats.current_hp) / player.stats.max_hp
							if engine.result == "defeat" and player.stats.current_hp > 0:
								invalid_results += 1
							if engine.result == "victory" and engine.enemy.current_hp > 0:
								invalid_results += 1
							engine.fate_resolver = null  # Break the engine/resolver ownership cycle.
						rows.append(
							{
								"region": region.region_id,
								"level": level,
								"class": code,
								"gear": "eligible_nonunique" if equipped else "starter",
								"period": period,
								"wins_percent": wins,
								"mean_turns": turns / float(TRIALS),
								"mean_hp_percent": snappedf(hp_remaining, 0.01),
								"timeouts": timeouts
							}
						)
		print("AUDITED ", region.region_id)
	var output := {
		"battles": battles,
		"invalid_terminal_states": invalid_results,
		"trials_per_profile": TRIALS,
		"rows": rows,
		"method":
		(
			"Deterministic exact 100-point day/night encounter weights; independent "
			+ "full-resource fights. Four points/level: 2 primary, 1 vitality, 1 endurance. "
			+ "No consumables, talents, upgrades, elites, weather or multi-fight attrition. "
			+ "Starter gear vs optimistic eligible non-unique loadout; "
			+ "not a player win-rate prediction."
		)
	}
	var file := FileAccess.open(
		"res://../output/ui_refresh_20260907/balance_audit.json", FileAccess.WRITE
	)
	file.store_string(JSON.stringify(output, "\t"))
	print("BALANCE AUDIT COMPLETE: ", battles, " battles; invalid states: ", invalid_results)
	quit(0 if invalid_results == 0 else 1)


func _profile(level: int, code: String, equipped: bool, tier: int, rng: RandomNumberGenerator):
	var player = Factory.create_player("Balance QA")
	while player.level < level:
		player.gain_experience(player.experience_remaining_to_next_level())
	if code != "none":
		player.choose_class(code)
	var primary: String = {"mage": "intelligence", "hunter": "dexterity", "pierrot": "luck"}.get(
		code, "strength"
	)
	if level > 0:
		player.spend_attribute_points(primary, level * 2)
		player.spend_attribute_points("vitality", level)
		player.spend_attribute_points("endurance", level)
	if equipped:
		var key := "%s_%d_%d" % [code, level, tier]
		if not _gear_cache.has(key):
			_gear_cache[key] = _eligible_gear(player, tier)
		for item_id: String in _gear_cache[key]:
			player.equipment.equip_and_return_previous(Items.create_equipment_item(item_id, rng))
		player.recalculate_stats()
	player.stats.restore_full()
	return player


func _eligible_gear(player, tier: int) -> Array[String]:
	var chosen := {}
	var scores := {}
	var weapon_type: String = {"mage": "staff", "hunter": "bow", "pierrot": "fate_lance"}.get(
		player.character_class_code, ""
	)
	for item in Items.get_all_definitions():
		if (
			not item.is_equipment()
			or item.required_level > player.level
			or item.item_power > tier * 2
		):
			continue
		if item.rarity not in ["common", "uncommon", "rare"] or not item.class_effect_id.is_empty():
			continue
		if (
			not item.required_class_code.is_empty()
			and item.required_class_code != player.character_class_code
		):
			continue
		if (
			item.slot == "weapon"
			and not weapon_type.is_empty()
			and item.equipment_type != weapon_type
		):
			continue
		if item.slot == "offhand" and player.equipment.slots.has("offhand"):
			if item.equipment_type != player.equipment.slots.offhand.definition.equipment_type:
				continue
		var score: float = (
			item.attack * 2
			+ item.magic_power * (2 if weapon_type == "staff" else 0)
			+ item.defense * 3
			+ item.max_hp * 0.35
			+ item.max_mana * 0.2
			+ item.dodge * 0.5
		)
		if score > float(scores.get(item.slot, -1)):
			scores[item.slot] = score
			chosen[item.slot] = item.item_id
	var result: Array[String] = []
	result.assign(chosen.values())
	return result


func _take_turn(engine) -> void:
	var best := ""
	var best_score: float = engine.player.stats.attack
	for skill in Skills.get_combat_ready_skills(engine.player):
		if not skill.is_offensive() or not engine.get_skill_use_error(skill.skill_id).is_empty():
			continue
		var score: float = engine._skill_power(skill) * skill.multiplier * skill.hits
		if skill.execution_kind == "fate":
			score = engine._skill_power(skill) * 1.5
		if score > best_score:
			best_score = score
			best = skill.skill_id
	if best.is_empty():
		engine.player_attack()
	else:
		engine.player_use_skill(best)
