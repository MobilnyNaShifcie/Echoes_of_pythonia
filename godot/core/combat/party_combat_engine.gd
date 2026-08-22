class_name PartyCombatEngine
extends RefCounted

const CombatDamageRulesClass := preload("res://core/combat/combat_damage_rules.gd")
const CombatEffectsClass := preload("res://core/combat/combat_effects.gd")
const CompanionAiContextClass := preload("res://core/companions/companion_ai_context.gd")
const CompanionStateClass := preload("res://core/companions/companion_state.gd")
const CompanionTacticServiceClass := preload("res://core/companions/companion_tactic_service.gd")
const EnemyClass := preload("res://core/combat/enemy.gd")
const FateEngineClass := preload("res://core/combat/fate_engine.gd")
const HunterComboCatalogClass := preload("res://core/combat/hunter_combo_catalog.gd")
const MathClass := preload("res://core/math/legacy_math.gd")
const PartyCombatantClass := preload("res://core/combat/party_combatant.gd")
const PartyCombatRoundResultClass := preload("res://core/combat/party_combat_round_result.gd")
const PlayerProfileClass := preload("res://core/player/player_profile.gd")
const SkillCatalogClass := preload("res://core/skills/skill_catalog.gd")
const SkillDefinitionClass := preload("res://core/skills/skill_definition.gd")
const TalentProgressionServiceClass := preload(
	"res://core/progression/talent_progression_service.gd"
)

const ONGOING := "ongoing"
const VICTORY := "victory"
const DEFEAT := "defeat"

var player: PlayerProfileClass
var companions: Array[CompanionStateClass] = []
var enemy: EnemyClass
var player_fighter: PartyCombatantClass
var companion_fighters: Array[PartyCombatantClass] = []
var effects := CombatEffectsClass.new()
var rng: RandomNumberGenerator
var skill_mana_multiplier := 1.0
var result := ONGOING
var round_number := 1
var taunt_companion_id := ""
var hunter_sequences := {}
var fate_engines := {}


func _init(
	player_profile: PlayerProfileClass,
	companion_states: Array,
	combat_enemy: EnemyClass,
	random_number_generator: RandomNumberGenerator = null,
	mana_multiplier := 1.0,
) -> void:
	player = player_profile
	enemy = combat_enemy
	rng = (
		random_number_generator if random_number_generator != null else RandomNumberGenerator.new()
	)
	skill_mana_multiplier = maxf(0.0, mana_multiplier)
	player_fighter = PartyCombatantClass.from_player(player)
	for value in companion_states:
		var companion: CompanionStateClass = value
		if companion == null or companion.dead:
			continue
		companions.append(companion)
		companion_fighters.append(PartyCombatantClass.from_companion(companion))


func all_fighters() -> Array[PartyCombatantClass]:
	var fighters: Array[PartyCombatantClass] = [player_fighter]
	fighters.append_array(companion_fighters)
	return fighters


func standing_party() -> Array[PartyCombatantClass]:
	var fighters: Array[PartyCombatantClass] = []
	for fighter: PartyCombatantClass in all_fighters():
		if fighter.is_standing():
			fighters.append(fighter)
	return fighters


func enemy_alive() -> bool:
	return enemy != null and enemy.is_alive()


func player_basic_attack() -> PartyCombatRoundResultClass:
	var report := _new_report()
	var error := _player_action_error()
	if not error.is_empty():
		return _reject(report, error)
	report.turn_consumed = true
	var hit := _deal_to_enemy(player_fighter, player.stats.attack, 0.0, true)
	report.lines.append(
		(
			"%s atakuje: %d obrażeń%s."
			% [player.display_name, hit.damage, " krytycznych" if hit.critical else ""]
		)
	)
	if (
		player.character_class_code == "pierrot"
		and player.has_active_equipment_effect("seven_chances")
		and enemy_alive()
	):
		var fate := _fate_engine_for(player_fighter)
		var roll = fate.roll(1)
		var extra := maxi(
			1, MathClass.python_roundi(player.stats.attack * (0.10 + roll.total() * 0.03))
		)
		_apply_enemy_damage(extra)
		report.lines.append(
			"Lanca Siedmiu Przypadków — znak %d: +%d obrażeń." % [roll.total(), extra]
		)
	return _finish_party_round(report)


func player_skill(skill_id: String) -> PartyCombatRoundResultClass:
	var report := _new_report()
	var error := _player_action_error()
	if error.is_empty():
		error = _player_skill_error(skill_id)
	if not error.is_empty():
		return _reject(report, error)
	report.turn_consumed = true
	report.player_skill_id = skill_id
	_cast_skill(player_fighter, skill_id, report.lines)
	return _finish_party_round(report)


func player_defend() -> PartyCombatRoundResultClass:
	var report := _new_report()
	var error := _player_action_error()
	if not error.is_empty():
		return _reject(report, error)
	report.turn_consumed = true
	player_fighter.defending = true
	report.lines.append("%s przyjmuje pozycję obronną." % player.display_name)
	return _finish_party_round(report)


func _player_action_error() -> String:
	if result != ONGOING:
		return "Ta walka drużynowa już się zakończyła."
	if not player_fighter.is_standing():
		return "Nie możesz teraz wykonać akcji."
	return ""


func _player_skill_error(skill_id: String) -> String:
	var skill: SkillDefinitionClass = SkillCatalogClass.get_definition(skill_id)
	if skill == null:
		return "Nieznana umiejętność."
	for unlocked: SkillDefinitionClass in SkillCatalogClass.get_unlocked_skills(player):
		if unlocked.skill_id == skill_id:
			return (
				"" if skill.is_combat_ready() else "Mechanika tej umiejętności nie jest dostępna."
			)
	return "Ta umiejętność nie jest dostępna."


func _cast_skill(
	fighter: PartyCombatantClass,
	skill_id: String,
	lines: Array[String],
	power_scale := 1.0,
) -> void:
	var actor: PlayerProfileClass = fighter.profile
	var skill: SkillDefinitionClass = SkillCatalogClass.get_definition(skill_id)
	if skill == null:
		return
	var cost := _skill_cost(skill)
	if actor.stats.current_mana < cost:
		lines.append(
			"%s próbuje użyć %s, ale brakuje Many." % [fighter.display_name, skill.display_name]
		)
		var fallback := _deal_to_enemy(fighter, actor.stats.attack, 0.0, true)
		lines.append(
			(
				"%s atakuje podstawowo: %d%s."
				% [fighter.display_name, fallback.damage, " [KRYTYK]" if fallback.critical else ""]
			)
		)
		return
	actor.stats.spend_mana(cost)
	if _cast_special_skill(fighter, skill, lines, power_scale):
		return
	_cast_damage_skill(fighter, skill, lines, power_scale)


func _cast_special_skill(
	fighter: PartyCombatantClass,
	skill: SkillDefinitionClass,
	lines: Array[String],
	power_scale: float,
) -> bool:
	if skill.effect.begins_with("fate_"):
		_cast_fate(fighter, skill.effect, lines)
		return true
	if skill.effect == "guard":
		fighter.defending = true
		lines.append("%s: %s — przygotowuje obronę." % [fighter.display_name, skill.display_name])
		return true
	if skill.effect == "dodge":
		fighter.defending = true
		lines.append("%s: %s — znika z linii ataku." % [fighter.display_name, skill.display_name])
		return true
	if skill.effect == "provoke":
		taunt_companion_id = fighter.companion_id
		fighter.defending = true
		lines.append("%s używa Prowokacji. Boss skupia na nim uwagę." % fighter.display_name)
		return true
	if skill.effect == "delayed_rain":
		var rain_hit := _deal_to_enemy(
			fighter, _skill_power(fighter.profile, skill) * 0.75 * power_scale, 0.0, true
		)
		(
			lines
			. append(
				(
					"%s: Deszcz Strzał spada pod koniec salwy — %d%s."
					% [
						fighter.display_name,
						rain_hit.damage,
						" [KRYTYK]" if rain_hit.critical else "",
					]
				)
			)
		)
		_record_hunter_sequence(fighter, skill, lines, rain_hit.damage)
		return true
	return false


func _cast_damage_skill(
	fighter: PartyCombatantClass,
	skill: SkillDefinitionClass,
	lines: Array[String],
	power_scale: float,
) -> void:
	var actor: PlayerProfileClass = fighter.profile
	var power := _skill_power(actor, skill)
	var total := 0
	for _hit_index in maxi(1, skill.hits):
		if not enemy_alive():
			break
		var hit := _deal_to_enemy(
			fighter,
			power * skill.multiplier * power_scale,
			skill.special_armor_penetration,
			not skill.is_offensive(),
		)
		total += int(hit.damage)
		if hit.critical:
			lines.append("  Trafienie krytyczne: %d." % hit.damage)
	lines.append("%s: %s — łącznie %d obrażeń." % [fighter.display_name, skill.display_name, total])
	_apply_skill_effect(fighter, skill, total, lines)
	_record_hunter_sequence(fighter, skill, lines, total)

	if (
		actor.character_class_code == "mage"
		and actor.has_active_equipment_effect("storm_archive_refund")
		and CombatDamageRulesClass.roll_percent(rng, 20.0)
	):
		var restored := actor.stats.restore_mana(3)
		if restored > 0:
			lines.append("Medalion Burzowego Archiwum zwraca %d Many." % restored)


func _apply_skill_effect(
	fighter: PartyCombatantClass,
	skill: SkillDefinitionClass,
	total: int,
	lines: Array[String],
) -> void:
	var actor: PlayerProfileClass = fighter.profile
	if skill.effect == "bleed" and total > 0:
		effects.apply_bleed(skill.effect_value, skill.effect_duration)
		if (
			actor.has_active_equipment_effect("oathbreaker_bleed")
			and skill.skill_id == "blood_strike"
		):
			effects.enemy_bleed_turns += 1
		lines.append(
			(
				"Krwawienie: %d przez %d rund."
				% [effects.enemy_bleed_damage, effects.enemy_bleed_turns]
			)
		)
	elif skill.effect == "armor_break" and total > 0:
		effects.apply_armor_break(skill.effect_value, skill.effect_duration)
		lines.append("DEF przeciwnika spada o %d." % effects.enemy_defense_reduction)
	elif skill.effect == "phantom_echo" and total > 0:
		var echo_scale := 0.72 if actor.has_active_equipment_effect("riftglass_echo") else 0.60
		var echo := maxi(1, MathClass.python_roundi(total * echo_scale))
		_apply_enemy_damage(echo)
		lines.append("Widmowe Echo wraca natychmiast w chaosie Szczeliny: +%d obrażeń." % echo)
	elif skill.effect == "explosive_charge" and total > 0:
		var bonus := maxi(1, MathClass.python_roundi(total * 0.35))
		_apply_enemy_damage(bonus)
		lines.append("Ładunek rezonuje ze Szczeliną: +%d obrażeń." % bonus)
	elif skill.effect == "splitting" and total > 0:
		var extra := maxi(2, MathClass.python_roundi(total * 0.45))
		_apply_enemy_damage(extra)
		lines.append("Odłamki Rozszczepiającej Strzały: +%d obrażeń." % extra)


func _deal_to_enemy(
	fighter: PartyCombatantClass,
	power: float,
	armor_penetration := 0.0,
	ignore_skill_damage := false,
) -> Dictionary:
	var actor: PlayerProfileClass = fighter.profile
	var defense := maxi(0, enemy.defense - effects.enemy_defense_reduction)
	defense = CombatDamageRulesClass.apply_armor_penetration(
		defense, actor.stats.armor_penetration + armor_penetration, 95.0
	)
	var attack_value := maxi(0, MathClass.python_roundi(power))
	var damage := CombatDamageRulesClass.calculate_damage(attack_value, defense)
	var critical := CombatDamageRulesClass.roll_percent(rng, 5.0 + actor.stats.crit_chance, 95.0)
	if critical:
		damage = CombatDamageRulesClass.apply_multiplier(
			damage, maxf(1.5, 2.0 + actor.stats.crit_damage / 100.0)
		)
	if actor.stats.skill_damage > 0.0 and not ignore_skill_damage:
		damage = CombatDamageRulesClass.apply_multiplier(
			damage, 1.0 + actor.stats.skill_damage / 100.0
		)
	_apply_enemy_damage(damage)
	return {"damage": damage, "critical": critical}


func _apply_enemy_damage(damage: int) -> void:
	# RiftBattleEngine v0.24.7 reports the calculated hit even on overkill,
	# while only the stored enemy HP is clamped to zero.
	enemy.current_hp = maxi(0, enemy.current_hp - maxi(0, damage))


func _skill_power(actor: PlayerProfileClass, skill: SkillDefinitionClass) -> int:
	match skill.scaling:
		"attack":
			return maxi(1, actor.stats.attack)
		"hunter":
			return maxi(1, actor.stats.attack + int(actor.attributes.dexterity / 2.0))
		"magic":
			return maxi(1, 4 + actor.attributes.intelligence * 2 + actor.stats.magic_power)
		"shield":
			return maxi(1, actor.stats.attack + MathClass.python_roundi(actor.stats.defense * 0.60))
		"fate":
			return maxi(1, actor.stats.attack + int(actor.attributes.luck / 2.0))
	return 0


func _record_hunter_sequence(
	fighter: PartyCombatantClass,
	skill: SkillDefinitionClass,
	lines: Array[String],
	base_damage: int,
) -> void:
	if skill.hunter_technique.is_empty():
		return
	var sequence: Array[String] = []
	sequence.assign(hunter_sequences.get(fighter.fighter_id, []))
	sequence.append(skill.hunter_technique)
	hunter_sequences[fighter.fighter_id] = sequence
	if sequence.size() < 3:
		return
	var completed: Array[String] = []
	completed.assign(sequence.slice(-3))
	var combo = HunterComboCatalogClass.for_sequence(completed)
	var bonus := 0
	if combo != null:
		bonus = maxi(1, MathClass.python_roundi(maxi(1, base_damage) * 0.40))
		lines.append("KOMBINACJA ŁOWCY: %s! +%d obrażeń." % [combo.display_name, bonus])
	elif _unique_string_count(completed) == 3:
		bonus = maxi(1, MathClass.python_roundi(maxi(1, base_damage) * 0.18))
		lines.append("TRZY RÓŻNE TECHNIKI: +%d obrażeń." % bonus)
	if fighter.profile.has_active_equipment_effect("third_echo"):
		var extra := maxi(1, MathClass.python_roundi(maxi(1, base_damage) * 0.15))
		bonus += extra
		lines.append("Trzecie Echo wzmacnia Finisher: +%d." % extra)
	if bonus > 0:
		_apply_enemy_damage(bonus)
	sequence.clear()
	hunter_sequences[fighter.fighter_id] = sequence


func _cast_fate(fighter: PartyCombatantClass, effect: String, lines: Array[String]) -> void:
	var actor: PlayerProfileClass = fighter.profile
	var fate := _fate_engine_for(fighter)
	var count := 1 if effect in ["fate_1d6", "fate_feint"] else 2 if effect == "fate_2d6" else 3
	var roll = fate.roll(count)
	var dice_values: Array[String] = []
	for die: int in roll.dice:
		dice_values.append(str(die))
	var dice_text := "+".join(dice_values)
	if effect == "fate_feint":
		fighter.defending = true
		lines.append("%s: Błazeński Unik — [%s]." % [fighter.display_name, dice_text])
		return
	var power := maxi(1, actor.stats.attack + int(actor.attributes.luck / 2.0))
	var multiplier := 0.65 + roll.total() / (6.0 * count)
	if roll.is_double():
		multiplier += 0.25
	if roll.is_triple():
		multiplier += 0.65
	if effect == "fate_va_banque":
		multiplier += 0.45
	if actor.has_active_equipment_effect("ace_less_deck"):
		multiplier = maxf(0.85, multiplier)
		if roll.total() == 6 * count:
			multiplier *= 0.90
	var hit := _deal_to_enemy(fighter, power * multiplier, 0.0, true)
	(
		lines
		. append(
			(
				"%s: Kości Losu [%s] → %d obrażeń%s."
				% [
					fighter.display_name,
					dice_text,
					hit.damage,
					" krytycznych" if hit.critical else "",
				]
			)
		)
	)


func _companion_turns(report: PartyCombatRoundResultClass) -> void:
	for fighter: PartyCombatantClass in companion_fighters:
		if not fighter.is_standing():
			continue
		report.companion_action_order.append(fighter.companion_id)
		var context := _ai_context_for(fighter)
		var skill_id := CompanionTacticServiceClass.choose_skill_id(fighter.companion, context, rng)
		report.companion_skill_ids[fighter.companion_id] = skill_id
		if skill_id.is_empty():
			var hit := _deal_to_enemy(fighter, fighter.profile.stats.attack, 0.0, true)
			report.lines.append(
				(
					"%s atakuje: %d%s."
					% [fighter.display_name, hit.damage, " [KRYTYK]" if hit.critical else ""]
				)
			)
		else:
			_cast_skill(fighter, skill_id, report.lines)
			_maybe_double_weave(fighter, skill_id, report)
		if not enemy_alive():
			return


func _maybe_double_weave(
	fighter: PartyCombatantClass,
	first_skill_id: String,
	report: PartyCombatRoundResultClass,
) -> void:
	if (
		fighter.profile.character_class_code != "mage"
		or not _has_talent(fighter.profile, "arcana_double_weave")
		or not enemy_alive()
	):
		return
	var context := _ai_context_for(fighter)
	var second_id := CompanionTacticServiceClass.choose_skill_id(fighter.companion, context, rng)
	if second_id.is_empty() or second_id == first_skill_id:
		return
	var second: SkillDefinitionClass = SkillCatalogClass.get_definition(second_id)
	if second == null or second.mana_cost > fighter.profile.stats.current_mana:
		return
	var scale := 0.90 if fighter.profile.has_active_equipment_effect("split_weave") else 0.80
	report.lines.append("%s: PODWÓJNY SPLOT!" % fighter.display_name)
	_cast_skill(fighter, second_id, report.lines, scale)


func _ai_context_for(fighter: PartyCombatantClass) -> CompanionAiContextClass:
	var stats = fighter.profile.stats
	var context := CompanionAiContextClass.new(
		stats.current_hp, stats.max_hp, stats.current_mana, stats.max_mana
	)
	for member: PartyCombatantClass in standing_party():
		context.add_standing_member(member.profile.stats.current_hp, member.profile.stats.max_hp)
	return context


func _enemy_turn(report: PartyCombatRoundResultClass) -> void:
	if not enemy_alive():
		return
	var bleed_damage := effects.tick_bleed()
	if bleed_damage > 0:
		report.enemy_bleed_damage = bleed_damage
		_apply_enemy_damage(bleed_damage)
		report.lines.append("Krwawienie zadaje %d obrażeń." % report.enemy_bleed_damage)
		if not enemy_alive():
			return

	var standing := standing_party()
	if standing.is_empty():
		return
	var target: PartyCombatantClass
	if not taunt_companion_id.is_empty():
		for fighter: PartyCombatantClass in standing:
			if fighter.companion_id == taunt_companion_id:
				target = fighter
				break
	taunt_companion_id = ""
	if target == null:
		target = standing[rng.randi_range(0, standing.size() - 1)]

	var attacks := 1
	if enemy.rank == "boss" and enemy.current_hp <= enemy.max_hp * 0.35:
		attacks = 2
		report.enemy_frenzy = true
		report.lines.append("%s wpada w FURIĘ — wykonuje dwa ataki!" % enemy.display_name)
	for _attack_index in attacks:
		if not target.is_standing():
			standing = standing_party()
			if standing.is_empty():
				break
			target = standing[rng.randi_range(0, standing.size() - 1)]
		if CombatDamageRulesClass.roll_percent(rng, target.profile.stats.dodge, 70.0):
			report.enemy_target_ids.append(target.fighter_id)
			report.lines.append("%s unika ataku %s." % [target.display_name, enemy.display_name])
			continue
		var defense := target.profile.stats.defense
		if (
			target.profile.has_active_equipment_effect("last_guard")
			and target.profile.stats.current_hp <= target.profile.stats.max_hp * 0.35
		):
			defense = MathClass.python_roundi(defense * 1.20)
		var damage := CombatDamageRulesClass.calculate_damage(enemy.attack, maxi(0, defense))
		if target.defending:
			damage = CombatDamageRulesClass.apply_defend_reduction(damage)
			if target.profile.has_active_equipment_effect("warden_afterguard"):
				damage = MathClass.python_roundi(damage * 0.85)
		target.defending = false
		var taken := target.profile.stats.take_damage(damage)
		report.add_enemy_damage(target.fighter_id, taken)
		report.lines.append(
			"%s trafia %s: %d obrażeń." % [enemy.display_name, target.display_name, taken]
		)


func _finish_party_round(report: PartyCombatRoundResultClass) -> PartyCombatRoundResultClass:
	if not enemy_alive():
		return _finish_victory(report)
	_companion_turns(report)
	if not enemy_alive():
		return _finish_victory(report)
	_enemy_turn(report)
	if not enemy_alive():
		return _finish_victory(report)
	if not player_fighter.is_standing() or standing_party().is_empty():
		result = DEFEAT
		report.defeat = true
	_sync_companions()
	report.enemy_hp_after = enemy.current_hp
	round_number += 1
	return report


func _finish_victory(report: PartyCombatRoundResultClass) -> PartyCombatRoundResultClass:
	result = VICTORY
	report.victory = true
	_sync_companions()
	report.enemy_hp_after = enemy.current_hp
	return report


func _sync_companions() -> void:
	for fighter: PartyCombatantClass in companion_fighters:
		fighter.sync_source_resources()


func _skill_cost(skill: SkillDefinitionClass) -> int:
	if skill.mana_cost <= 0:
		return 0
	return maxi(1, MathClass.python_roundi(skill.mana_cost * skill_mana_multiplier))


func _fate_engine_for(fighter: PartyCombatantClass) -> FateEngineClass:
	var engine: FateEngineClass = fate_engines.get(fighter.fighter_id)
	if engine == null:
		engine = FateEngineClass.new(rng)
		fate_engines[fighter.fighter_id] = engine
	return engine


func _has_talent(actor: PlayerProfileClass, talent_id: String) -> bool:
	return TalentProgressionServiceClass.has_talent(actor, talent_id)


func _unique_string_count(values: Array[String]) -> int:
	var unique := {}
	for value: String in values:
		unique[value] = true
	return unique.size()


func _new_report() -> PartyCombatRoundResultClass:
	var report := PartyCombatRoundResultClass.new()
	report.round_number = round_number
	report.enemy_hp_before = enemy.current_hp if enemy != null else 0
	report.enemy_hp_after = report.enemy_hp_before
	return report


func _reject(report: PartyCombatRoundResultClass, message: String) -> PartyCombatRoundResultClass:
	report.error = message
	report.lines.append(message)
	return report
