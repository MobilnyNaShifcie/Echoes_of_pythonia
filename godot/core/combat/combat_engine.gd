class_name TurnBasedCombatEngine
extends RefCounted

const CombatEffectsClass := preload("res://core/combat/combat_effects.gd")
const EnemyClass := preload("res://core/combat/enemy.gd")
const PlayerEquipmentClass := preload("res://core/player/equipment.gd")
const PlayerProfileClass := preload("res://core/player/player_profile.gd")
const SkillCatalogClass := preload("res://core/skills/skill_catalog.gd")
const SkillDefinitionClass := preload("res://core/skills/skill_definition.gd")
const ONGOING := "ongoing"
const VICTORY := "victory"
const DEFEAT := "defeat"
const FLED := "fled"

var player: PlayerProfileClass
var enemy: EnemyClass
var effects := CombatEffectsClass.new()
var result := ONGOING
var rng: RandomNumberGenerator


func _init(
	player_profile: PlayerProfileClass,
	combat_enemy: EnemyClass,
	random_number_generator: RandomNumberGenerator = null
) -> void:
	player = player_profile
	enemy = combat_enemy
	rng = (
		random_number_generator if random_number_generator != null else RandomNumberGenerator.new()
	)


func player_attack() -> Dictionary:
	if result != ONGOING:
		return {}
	var report := _new_report()
	var armor_break_was_active := effects.enemy_defense_reduction_actions > 0
	if rng.randf() < enemy.dodge / 100.0:
		report.enemy_dodged = true
	else:
		var damage := maxi(1, player.stats.attack - effects.effective_enemy_defense(enemy.defense))
		damage = enemy.reduce_physical_damage(damage)
		report.player_damage = enemy.take_damage(damage)
	if armor_break_was_active:
		effects.consume_offensive_action()
	report.turn_consumed = true
	if not enemy.is_alive():
		result = VICTORY
		return report
	_enemy_turn(report)
	return report


func get_skill_use_error(skill_id: String) -> String:
	var error := ""
	if result != ONGOING:
		error = "Ta walka już się zakończyła."
	var skill: SkillDefinitionClass = SkillCatalogClass.get_definition(skill_id)
	if error.is_empty() and skill == null:
		error = "Nieznana umiejętność."
	elif error.is_empty() and skill.character_class_code != player.character_class_code:
		error = "Ta umiejętność nie jest dostępna dla twojej postaci."
	elif error.is_empty() and player.level < skill.unlock_level:
		error = "Umiejętność odblokowuje się na poziomie %d." % skill.unlock_level
	elif error.is_empty() and not skill.is_combat_ready():
		error = "Mechanika Kości Losu zostanie przeniesiona w osobnym podetapie 3."
	elif error.is_empty():
		error = _get_skill_equipment_error(skill)
	if error.is_empty() and not player.stats.can_spend_mana(skill.mana_cost):
		error = ("Brak Many. Potrzeba %d, masz %d." % [skill.mana_cost, player.stats.current_mana])
	return error


func player_use_skill(skill_id: String) -> Dictionary:
	if result != ONGOING:
		return {}
	var report := _new_report()
	var error := get_skill_use_error(skill_id)
	if not error.is_empty():
		report.error = error
		return report
	var skill: SkillDefinitionClass = SkillCatalogClass.get_definition(skill_id)
	player.stats.spend_mana(skill.mana_cost)
	report.skill_id = skill.skill_id
	report.skill_name = skill.display_name
	report.skill_mana_cost = skill.mana_cost
	report.player_damage_type = skill.damage_type
	report.turn_consumed = true
	var armor_break_was_active := effects.enemy_defense_reduction_actions > 0

	_resolve_skill_hits(skill, report)
	_apply_skill_effect(skill, report)
	if armor_break_was_active and skill.is_offensive():
		effects.consume_offensive_action()

	if not enemy.is_alive():
		result = VICTORY
		return report
	_enemy_turn(report)
	return report


func player_defend() -> Dictionary:
	if result != ONGOING:
		return {}
	var report := _new_report()
	report.player_defended = true
	report.turn_consumed = true
	_enemy_turn(report, true)
	return report


func player_flee() -> Dictionary:
	if result != ONGOING:
		return {}
	var report := _new_report()
	report.turn_consumed = true
	if rng.randf() < 0.5:
		result = FLED
		return report
	report.flee_failed = true
	_enemy_turn(report)
	return report


func player_use_healing(heal_amount: int) -> Dictionary:
	return player_use_restoration(heal_amount, 0)


func player_use_restoration(heal_amount: int, mana_amount: int) -> Dictionary:
	if result != ONGOING or (heal_amount <= 0 and mana_amount <= 0):
		return {}
	var report := _new_report()
	report.turn_consumed = true
	report.player_healed = player.stats.heal(heal_amount)
	report.player_mana_restored = player.stats.restore_mana(mana_amount)
	_enemy_turn(report)
	return report


func _get_skill_equipment_error(skill: SkillDefinitionClass) -> String:
	if not skill.required_weapon_type.is_empty():
		var weapon = player.equipment.get_item(PlayerEquipmentClass.WEAPON)
		var equipped_weapon_type: String = (
			weapon.definition.equipment_type if weapon != null and weapon.definition != null else ""
		)
		if equipped_weapon_type != skill.required_weapon_type:
			var weapon_names := {"bow": "Łuku", "staff": "Kostura", "fate_lance": "Lancy Losu"}
			return (
				"Ta umiejętność wymaga: %s."
				% weapon_names.get(skill.required_weapon_type, skill.required_weapon_type)
			)
	if not skill.required_offhand_type.is_empty():
		var offhand = player.equipment.get_item(PlayerEquipmentClass.OFF_HAND)
		var equipped_offhand_type: String = (
			offhand.definition.equipment_type
			if offhand != null and offhand.definition != null
			else ""
		)
		if equipped_offhand_type != skill.required_offhand_type:
			var offhand_names := {"shield": "Tarczy", "quiver": "Kołczanu", "artifact": "Artefaktu"}
			return (
				"Ta umiejętność wymaga: %s."
				% offhand_names.get(skill.required_offhand_type, skill.required_offhand_type)
			)
	return ""


func _resolve_skill_hits(skill: SkillDefinitionClass, report: Dictionary) -> void:
	var power := _skill_power(skill)
	for hit_index in skill.hits:
		if not enemy.is_alive():
			break
		var hit := _resolve_player_skill_hit(skill, power)
		report.player_hit_damages.append(hit.damage)
		report.player_hit_dodges.append(hit.dodged)
		report.skill_total_damage += hit.damage
		if hit_index == 0:
			report.player_damage = hit.damage
			report.enemy_dodged = hit.dodged
		else:
			var note := (
				"Trafienie %d: unik." % (hit_index + 1)
				if hit.dodged
				else "Trafienie %d: %d obrażeń." % [hit_index + 1, hit.damage]
			)
			report.skill_notes.append(note)


func _resolve_player_skill_hit(skill: SkillDefinitionClass, power: int) -> Dictionary:
	if not skill.guaranteed_hit and rng.randf() < enemy.dodge / 100.0:
		return {"damage": 0, "dodged": true}
	var attack_value := maxi(1, roundi(power * skill.multiplier))
	var enemy_defense := effects.effective_enemy_defense(enemy.defense)
	var magical := skill.scaling == "magic"
	if magical:
		enemy_defense = int(enemy_defense / 2.0)
	var damage := maxi(1, attack_value - enemy_defense)
	if skill.damage_type == "physical" and not magical:
		damage = enemy.reduce_physical_damage(damage)
	return {"damage": enemy.take_damage(damage), "dodged": false}


func _skill_power(skill: SkillDefinitionClass) -> int:
	match skill.scaling:
		"attack":
			return maxi(1, player.stats.attack)
		"hunter":
			return maxi(1, player.stats.attack + int(player.attributes.dexterity / 2.0))
		"magic":
			return maxi(
				1,
				4 + player.attributes.intelligence * 2 + player.stats.magic_power,
			)
		"shield":
			return maxi(1, player.stats.attack + roundi(player.stats.defense * 0.6))
		"fate":
			return maxi(1, player.stats.attack + int(player.attributes.luck / 2.0))
	return 0


func _apply_skill_effect(skill: SkillDefinitionClass, report: Dictionary) -> void:
	match skill.effect:
		"armor_break":
			effects.apply_armor_break(skill.effect_value, skill.effect_duration)
			report.skill_notes.append(
				(
					"DEF przeciwnika -%d na %d ofensywne akcje."
					% [skill.effect_value, skill.effect_duration]
				)
			)
		"bleed":
			effects.apply_bleed(skill.effect_value, skill.effect_duration)
			report.skill_notes.append(
				(
					"Krwawienie: %d obrażeń przez %d tury."
					% [skill.effect_value, skill.effect_duration]
				)
			)
		"guard":
			effects.apply_guard(skill.effect_value, skill.effect_duration)
			report.skill_notes.append(
				(
					"Redukcja obrażeń %d%% przez %d ataki przeciwnika."
					% [skill.effect_value, skill.effect_duration]
				)
			)
		"dodge":
			effects.apply_dodge(skill.effect_value, skill.effect_duration)
			report.skill_notes.append(
				(
					"UNIK +%d p.p. przez %d ataki przeciwnika."
					% [skill.effect_value, skill.effect_duration]
				)
			)


func _enemy_turn(report: Dictionary, defending := false) -> void:
	report.enemy_acted = true
	var attack_value := enemy.attack
	if enemy.attacks_made == 0:
		attack_value += enemy.first_attack_bonus
	if not enemy.special_name.is_empty() and rng.randf() < enemy.special_chance:
		attack_value += enemy.special_attack_bonus
		report.enemy_special_name = enemy.special_name
	enemy.attacks_made += 1
	report.enemy_damage = _resolve_enemy_hit(attack_value, defending, report, false)
	if not player.stats.is_alive():
		result = DEFEAT
		return
	if enemy.extra_attack_chance > 0.0 and rng.randf() < enemy.extra_attack_chance:
		report.enemy_extra_damage = _resolve_enemy_hit(enemy.attack, false, report, true)
		if not player.stats.is_alive():
			result = DEFEAT
			return
	var bleed_damage := effects.tick_bleed()
	if bleed_damage > 0:
		report.enemy_bleed_damage = enemy.take_damage(bleed_damage)
		if not enemy.is_alive():
			result = VICTORY
			return
	if player.stats.health_regen > 0:
		report.player_regenerated = player.stats.heal(player.stats.health_regen)


func _resolve_enemy_hit(
	attack_value: int, defending: bool, report: Dictionary, is_extra_hit: bool
) -> int:
	var dodge_chance := player.stats.dodge + effects.current_dodge_bonus()
	var dodged := rng.randf() < dodge_chance / 100.0
	effects.consume_dodge_hit()
	if dodged:
		if not is_extra_hit:
			report.player_dodged = true
		effects.consume_guard_hit()
		return 0
	var damage := maxi(1, attack_value - player.stats.defense)
	if defending:
		damage = int(damage / 2.0)
	damage = effects.reduce_damage_by_guard(damage)
	effects.consume_guard_hit()
	return player.stats.take_damage(damage)


func _new_report() -> Dictionary:
	return {
		"player_damage": 0,
		"player_hit_damages": [],
		"player_hit_dodges": [],
		"player_damage_type": "physical",
		"skill_id": "",
		"skill_name": "",
		"skill_mana_cost": 0,
		"skill_total_damage": 0,
		"skill_notes": [],
		"player_healed": 0,
		"player_mana_restored": 0,
		"player_regenerated": 0,
		"enemy_damage": 0,
		"enemy_extra_damage": 0,
		"enemy_bleed_damage": 0,
		"enemy_dodged": false,
		"player_dodged": false,
		"player_defended": false,
		"flee_failed": false,
		"enemy_special_name": "",
		"enemy_acted": false,
		"turn_consumed": false,
		"error": "",
	}
