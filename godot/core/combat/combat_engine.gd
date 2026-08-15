class_name TurnBasedCombatEngine
extends RefCounted

const CombatEffectsClass := preload("res://core/combat/combat_effects.gd")
const EnemyClass := preload("res://core/combat/enemy.gd")
const FateEngineClass := preload("res://core/combat/fate_engine.gd")
const FateRollClass := preload("res://core/combat/fate_roll.gd")
const HunterComboCatalogClass := preload("res://core/combat/hunter_combo_catalog.gd")
const HunterComboDefinitionClass := preload("res://core/combat/hunter_combo_definition.gd")
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
var fate: FateEngineClass
var fate_tokens := 0
var pierrot_reflect_ready := false
var hunter_sequence: Array[String] = []
var hunter_phantom_pending: Array[int] = []
var hunter_rain_pending: Array[int] = []
var hunter_explosive_charges := 0
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
	fate = FateEngineClass.new(rng)


func player_attack() -> Dictionary:
	if result != ONGOING:
		return {}
	var report := _new_report()
	var hunter_pending := _take_hunter_delayed_effects()
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
	_resolve_hunter_delayed_effects(report, hunter_pending)
	_update_hunter_report(report)
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
	elif error.is_empty() and not SkillCatalogClass.is_unlocked(player, skill):
		error = "Technika wymaga odblokowania w drzewku talentów Łowcy."
	elif error.is_empty() and not skill.is_combat_ready():
		error = "Mechanika tej umiejętności nie została jeszcze przeniesiona."
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
	var hunter_pending := _take_hunter_delayed_effects()
	player.stats.spend_mana(skill.mana_cost)
	report.skill_id = skill.skill_id
	report.skill_name = skill.display_name
	report.skill_mana_cost = skill.mana_cost
	report.player_damage_type = skill.damage_type
	report.turn_consumed = true
	var armor_break_was_active := effects.enemy_defense_reduction_actions > 0

	if skill.execution_kind == "fate":
		_resolve_fate_skill(skill, report)
	else:
		_execute_standard_skill(skill, report)
	if armor_break_was_active and skill.is_offensive():
		effects.consume_offensive_action()

	if not enemy.is_alive():
		result = VICTORY
		return report
	_resolve_hunter_delayed_effects(report, hunter_pending)
	_update_hunter_report(report)
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


func _execute_standard_skill(skill: SkillDefinitionClass, report: Dictionary) -> void:
	if skill.effect == "delayed_rain":
		hunter_rain_pending.append(_skill_power(skill))
		report.skill_notes.append(
			"DESZCZ STRZAŁ: salwa leci w górę i spadnie po następnej akcji Łowcy."
		)
		_record_hunter_technique(skill, report)
		return
	_resolve_skill_hits(skill, report)
	_resolve_hunter_skill_effect(skill, report)
	_apply_skill_effect(skill, report)
	_record_hunter_technique(skill, report)


func _resolve_player_skill_hit(skill: SkillDefinitionClass, power: int) -> Dictionary:
	if not skill.guaranteed_hit and rng.randf() < enemy.dodge / 100.0:
		return {"damage": 0, "dodged": true}
	var attack_value := maxi(1, _python_roundi(power * skill.multiplier))
	var enemy_defense := effects.effective_enemy_defense(enemy.defense)
	if skill.special_armor_penetration > 0.0:
		var remaining_defense := 1.0 - clampf(skill.special_armor_penetration, 0.0, 90.0) / 100.0
		enemy_defense = maxi(0, _python_roundi(enemy_defense * remaining_defense))
	var magical := skill.scaling == "magic"
	if magical:
		enemy_defense = int(enemy_defense / 2.0)
	var damage := maxi(1, attack_value - enemy_defense)
	if skill.damage_type == "physical" and not magical:
		damage = enemy.reduce_physical_damage(damage)
	return {"damage": enemy.take_damage(damage), "dodged": false}


func _resolve_hunter_skill_effect(skill: SkillDefinitionClass, report: Dictionary) -> void:
	if player.character_class_code != "hunter" or report.enemy_dodged:
		return
	match skill.effect:
		"splitting":
			for _fragment_index in 2:
				if not enemy.is_alive():
					break
				var fragment_damage := _resolve_hunter_guaranteed_hit(
					_skill_power(skill), skill.effect_value / 100.0, "physical"
				)
				report.skill_total_damage += fragment_damage
				report.skill_notes.append("Widmowy odłamek zadaje %d obrażeń." % fragment_damage)
		"phantom_echo":
			hunter_phantom_pending.append(_skill_power(skill))
			report.skill_notes.append("WIDMOWE ECHO: ślad strzały pozostaje przy celu.")
		"explosive_charge":
			hunter_explosive_charges += 1
			report.skill_notes.append("Ładunek Wybuchowy: %d/3." % hunter_explosive_charges)
			if hunter_explosive_charges >= 3 and enemy.is_alive():
				var detonation := _resolve_hunter_guaranteed_hit(_skill_power(skill), 1.55, "fire")
				report.skill_total_damage += detonation
				report.skill_notes.append("DETONACJA 3/3: %d obrażeń." % detonation)
				hunter_explosive_charges = 0


func _resolve_hunter_guaranteed_hit(
	power: int, multiplier: float, damage_type: String, armor_penetration := 0.0
) -> int:
	var attack_value := maxi(1, _python_roundi(power * multiplier))
	var enemy_defense := effects.effective_enemy_defense(enemy.defense)
	if armor_penetration > 0.0:
		var remaining_defense := 1.0 - clampf(armor_penetration, 0.0, 90.0) / 100.0
		enemy_defense = maxi(0, _python_roundi(enemy_defense * remaining_defense))
	var damage := maxi(1, attack_value - enemy_defense)
	if damage_type == "physical":
		damage = enemy.reduce_physical_damage(damage)
	return enemy.take_damage(damage)


func _take_hunter_delayed_effects() -> Dictionary:
	if player.character_class_code != "hunter":
		return {"echoes": [], "rain": []}
	var echoes: Array[int] = []
	var rain: Array[int] = []
	echoes.assign(hunter_phantom_pending)
	rain.assign(hunter_rain_pending)
	hunter_phantom_pending.clear()
	hunter_rain_pending.clear()
	return {"echoes": echoes, "rain": rain}


func _resolve_hunter_delayed_effects(report: Dictionary, pending: Dictionary) -> void:
	if player.character_class_code != "hunter":
		return
	for power: int in pending.echoes:
		if not enemy.is_alive():
			break
		var damage := _resolve_hunter_guaranteed_hit(power, 0.60, "physical")
		report.skill_total_damage += damage
		report.hunter_delayed_damage += damage
		report.skill_notes.append("WIDMOWE ECHO materializuje się: %d obrażeń." % damage)
	for power: int in pending.rain:
		if not enemy.is_alive():
			break
		var damage := _resolve_hunter_guaranteed_hit(power, 0.65, "physical")
		report.skill_total_damage += damage
		report.hunter_delayed_damage += damage
		report.skill_notes.append("DESZCZ STRZAŁ spada z góry: %d obrażeń." % damage)


func _record_hunter_technique(skill: SkillDefinitionClass, report: Dictionary) -> void:
	if player.character_class_code != "hunter" or skill.hunter_technique.is_empty():
		return
	hunter_sequence.append(skill.hunter_technique)
	if hunter_sequence.size() < 3:
		_update_hunter_report(report)
		return
	var completed_sequence: Array[String] = []
	completed_sequence.assign(hunter_sequence.slice(-3))
	hunter_sequence.clear()
	var combo: HunterComboDefinitionClass = HunterComboCatalogClass.for_sequence(completed_sequence)
	if combo == null:
		report.skill_notes.append(
			"Sekwencja trzech strzałów zakończona — brak nazwanej kombinacji."
		)
		_update_hunter_report(report)
		return
	var first_discovery := combo.combo_id not in player.discovered_hunter_combos
	if first_discovery:
		player.discovered_hunter_combos.append(combo.combo_id)
	report.hunter_combo_id = combo.combo_id
	report.hunter_combo_name = combo.display_name
	report.hunter_combo_discovered = first_discovery
	report.skill_notes.append(
		"KOMBINACJA: %s!%s" % [combo.display_name, " [NOWA]" if first_discovery else ""]
	)
	_resolve_hunter_combo(combo, report)
	_update_hunter_report(report)


func _resolve_hunter_combo(combo: HunterComboDefinitionClass, report: Dictionary) -> void:
	if not enemy.is_alive():
		return
	var multiplier: float = combo.multiplier
	if combo.combo_id == "phantom_detonation":
		multiplier += 0.20 * hunter_explosive_charges
	var damage := _resolve_hunter_guaranteed_hit(
		maxi(1, player.stats.attack + int(player.attributes.dexterity / 2.0)),
		multiplier,
		combo.damage_type,
		combo.armor_penetration,
	)
	report.skill_total_damage += damage
	report.hunter_combo_damage += damage
	report.skill_notes.append("%s: %d obrażeń." % [combo.display_name, damage])
	if combo.bleed_damage > 0:
		effects.apply_bleed(combo.bleed_damage, combo.bleed_duration)
		report.skill_notes.append(
			(
				"Kombinacja pogłębia Krwawienie: %d obrażenia przez %d tury."
				% [combo.bleed_damage, combo.bleed_duration]
			)
		)
	if combo.consumes_explosive_charges:
		hunter_explosive_charges = 0


func _update_hunter_report(report: Dictionary) -> void:
	report.hunter_sequence.assign(hunter_sequence)
	report.hunter_explosive_charges = hunter_explosive_charges
	report.hunter_pending_echoes = hunter_phantom_pending.size()
	report.hunter_pending_rain = hunter_rain_pending.size()


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
			return maxi(1, player.stats.attack + _python_roundi(player.stats.defense * 0.6))
		"fate":
			return maxi(1, player.stats.attack + int(player.attributes.luck / 2.0))
	return 0


func _resolve_fate_skill(skill: SkillDefinitionClass, report: Dictionary) -> void:
	match skill.effect:
		"fate_1d6":
			_resolve_fate_thrust(fate.roll(1), report)
		"fate_2d6":
			_resolve_double_roll(fate.roll(2), report)
		"fate_feint":
			_resolve_fate_feint(fate.roll(1), report)
		"fate_3d6":
			_resolve_grand_gamble(fate.roll(3), report)
	_update_fate_report(report)


func _resolve_fate_thrust(roll: FateRollClass, report: Dictionary) -> void:
	var face: int = roll.dice[0]
	var multiplier := 1.0
	var hits := 1
	var outcome := "PEWNE PCHNIĘCIE"
	match face:
		1:
			multiplier = 0.70
			outcome = "PECHOWY NUMER"
			_add_fate_tokens(2, report)
		2:
			multiplier = 0.95
			outcome = "FIGIEL"
			enemy.attack = maxi(0, enemy.attack - 1)
			report.skill_notes.append("FIGIEL: ATK przeciwnika -1 do końca walki.")
		3:
			multiplier = 1.15
			outcome = "PEWNE PCHNIĘCIE"
		4:
			multiplier = 1.10
			outcome = "ZWROT LOSU"
			effects.apply_dodge(15, 1)
			report.skill_notes.append("ZWROT LOSU: UNIK +15 p.p. na następny atak.")
		5:
			multiplier = 0.85
			hits = 2
			outcome = "PODWÓJNY NUMER"
		6:
			multiplier = 1.85
			outcome = "JACKPOT"
			_add_fate_tokens(1, report)
	_resolve_fate_damage(multiplier, hits, report)
	_set_fate_roll_report(roll, outcome, report)


func _resolve_double_roll(roll: FateRollClass, report: Dictionary) -> void:
	var total := roll.total()
	var multiplier := 1.10
	var outcome := "RZUT LOSU"
	if roll.dice == [1, 1]:
		multiplier = 0.50
		outcome = "WĘŻOWE OCZY"
		_add_fate_tokens(2, report)
	elif total == 7:
		multiplier = 1.70
		outcome = "SZCZĘŚLIWA SIÓDEMKA"
		_add_fate_tokens(2, report)
	elif roll.dice == [6, 6]:
		multiplier = 2.25
		outcome = "PODWÓJNA SZÓSTKA — JACKPOT"
		_add_fate_tokens(1, report)
	elif roll.is_double():
		multiplier = 1.45
		outcome = "DUBLET"
	elif total <= 4:
		multiplier = 0.80
		outcome = "NISKI RZUT"
		_add_fate_tokens(2, report)
	elif total >= 10:
		multiplier = 1.60
		outcome = "WYSOKI RZUT"
		_add_fate_tokens(1, report)
	_resolve_fate_damage(multiplier, 1, report)
	_set_fate_roll_report(roll, outcome, report)


func _resolve_fate_feint(roll: FateRollClass, report: Dictionary) -> void:
	var face: int = roll.dice[0]
	var outcome := "ZWÓD"
	match face:
		1:
			outcome = "PECH"
			_add_fate_tokens(2, report)
			effects.apply_dodge(10, 1)
			report.skill_notes.append("PECH: UNIK +10 p.p. na następny atak.")
		2, 3:
			outcome = "ZWÓD"
			effects.apply_dodge(20, 2)
			report.skill_notes.append("ZWÓD: UNIK +20 p.p. przez 2 ataki.")
		4, 5:
			outcome = "AKROBACJA"
			effects.apply_dodge(35, 2)
			report.skill_notes.append("AKROBACJA: UNIK +35 p.p. przez 2 ataki.")
		6:
			outcome = "KURTYNA LUSTRZANA"
			pierrot_reflect_ready = true
			report.skill_notes.append(
				"KURTYNA LUSTRZANA: następny bezpośredni cios zostanie odbity."
			)
	_set_fate_roll_report(roll, outcome, report)


func _resolve_grand_gamble(roll: FateRollClass, report: Dictionary) -> void:
	var total := roll.total()
	var multiplier := 0.85 + total * 0.055
	var outcome := "WIELKI ZAKŁAD"
	if roll.is_triple():
		multiplier = 2.55
		outcome = "TRÓJKA"
		_add_fate_tokens(2, report)
	elif total <= 5:
		multiplier = 0.60
		outcome = "KATASTROFA"
		_add_fate_tokens(3, report)
	elif total >= 16:
		multiplier = 2.15
		outcome = "WIELKI JACKPOT"
		_add_fate_tokens(2, report)
	elif roll.is_double():
		multiplier = 1.55
		outcome = "DUBLET WZMACNIA ZAKŁAD"
	_resolve_fate_damage(multiplier, 1, report)
	_set_fate_roll_report(roll, outcome, report)


func _resolve_fate_damage(multiplier: float, hits: int, report: Dictionary) -> void:
	var attack_value := maxi(1, _python_roundi(_fate_power() * multiplier))
	for _hit_index in hits:
		if not enemy.is_alive():
			break
		var damage := maxi(1, attack_value - effects.effective_enemy_defense(enemy.defense))
		damage = enemy.reduce_physical_damage(damage)
		var damage_taken := enemy.take_damage(damage)
		report.player_hit_damages.append(damage_taken)
		report.player_hit_dodges.append(false)
		report.skill_total_damage += damage_taken
	report.player_damage = report.skill_total_damage
	report.enemy_dodged = false


func _fate_power() -> int:
	return maxi(1, player.stats.attack + int(player.attributes.luck / 2.0))


func _set_fate_roll_report(roll: FateRollClass, outcome: String, report: Dictionary) -> void:
	report.fate_dice.assign(roll.dice)
	report.fate_total = roll.total()
	report.fate_outcome = outcome
	report.skill_notes.append("KOŚCI LOSU: %s — %s." % [_dice_text(roll.dice), outcome])


func _dice_text(dice: Array[int]) -> String:
	var values: Array[String] = []
	for value: int in dice:
		values.append(str(value))
	return "[" + ", ".join(values) + "]"


func fate_token_cap() -> int:
	return 6 + mini(4, int(player.attributes.luck / 10.0))


func _add_fate_tokens(amount: int, report: Dictionary) -> void:
	var previous := fate_tokens
	fate_tokens = clampi(fate_tokens + maxi(0, amount), 0, fate_token_cap())
	var gained := fate_tokens - previous
	if gained > 0:
		report.fate_tokens_gained += gained
		report.skill_notes.append(
			"ŻETONY LOSU: +%d (%d/%d)." % [gained, fate_tokens, fate_token_cap()]
		)


func _update_fate_report(report: Dictionary) -> void:
	report.fate_tokens = fate_tokens
	report.fate_token_cap = fate_token_cap()
	report.reflect_ready = pierrot_reflect_ready


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
	if not enemy.is_alive():
		result = VICTORY
		return
	if not player.stats.is_alive():
		result = DEFEAT
		return
	if enemy.extra_attack_chance > 0.0 and rng.randf() < enemy.extra_attack_chance:
		report.enemy_extra_damage = _resolve_enemy_hit(enemy.attack, false, report, true)
		if not enemy.is_alive():
			result = VICTORY
			return
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
	if pierrot_reflect_ready and damage > 0:
		pierrot_reflect_ready = false
		var reflected := enemy.take_damage(damage)
		report.reflected_damage += reflected
		report.reflect_ready = false
		return 0
	return player.stats.take_damage(damage)


func _python_roundi(value: float) -> int:
	var lower := floori(value)
	var fraction := value - lower
	if fraction < 0.5 and not is_equal_approx(fraction, 0.5):
		return lower
	if fraction > 0.5 and not is_equal_approx(fraction, 0.5):
		return lower + 1
	return lower if lower % 2 == 0 else lower + 1


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
		"fate_dice": [],
		"fate_total": 0,
		"fate_outcome": "",
		"fate_tokens_gained": 0,
		"fate_tokens": fate_tokens,
		"fate_token_cap": fate_token_cap(),
		"reflect_ready": pierrot_reflect_ready,
		"reflected_damage": 0,
		"hunter_sequence": hunter_sequence.duplicate(),
		"hunter_combo_id": "",
		"hunter_combo_name": "",
		"hunter_combo_discovered": false,
		"hunter_combo_damage": 0,
		"hunter_delayed_damage": 0,
		"hunter_explosive_charges": hunter_explosive_charges,
		"hunter_pending_echoes": hunter_phantom_pending.size(),
		"hunter_pending_rain": hunter_rain_pending.size(),
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
