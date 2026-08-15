class_name TurnBasedCombatEngine
extends RefCounted

const CombatEffectsClass := preload("res://core/combat/combat_effects.gd")
const FateCombatResolverClass := preload("res://core/combat/fate_combat_resolver.gd")
const CombatHitResolverClass := preload("res://core/combat/combat_hit_resolver.gd")
const CombatProgressionRulesClass := preload("res://core/combat/combat_progression_rules.gd")
const CombatReportFactoryClass := preload("res://core/combat/combat_report_factory.gd")
const EnemyClass := preload("res://core/combat/enemy.gd")
const FateEngineClass := preload("res://core/combat/fate_engine.gd")
const HunterComboCatalogClass := preload("res://core/combat/hunter_combo_catalog.gd")
const HunterComboDefinitionClass := preload("res://core/combat/hunter_combo_definition.gd")
const MathClass := preload("res://core/math/legacy_math.gd")
const PlayerEquipmentClass := preload("res://core/player/equipment.gd")
const PlayerProfileClass := preload("res://core/player/player_profile.gd")
const PassiveProgressionServiceClass := preload(
	"res://core/progression/passive_progression_service.gd"
)
const TalentProgressionServiceClass := preload(
	"res://core/progression/talent_progression_service.gd"
)
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
var fate_resolver: FateCombatResolverClass
var fate_tokens := 0
var pierrot_reflect_ready := false
var hunter_sequence: Array[String] = []
var hunter_phantom_pending: Array[int] = []
var hunter_rain_pending: Array[int] = []
var hunter_explosive_charges := 0
var warrior_retribution_ready := false
var warrior_retribution_ratio := 0.50
var warrior_provoke_ready := false
var warrior_provoke_block_bonus := 0.0
var mage_arcane_weave := 0
var mage_element_sequence: Array[String] = []
var momentum_stacks := 0
var deadly_tempo_ready := false
var second_wind_used := false
var result := ONGOING
var rng: RandomNumberGenerator
var hit_resolver: CombatHitResolverClass


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
	fate_resolver = FateCombatResolverClass.new(self)
	hit_resolver = CombatHitResolverClass.new(player, enemy, effects, rng)


func player_attack() -> Dictionary:
	if result != ONGOING:
		return {}
	var report := _new_report()
	var hunter_pending := _take_hunter_delayed_effects()
	var armor_break_was_active := effects.enemy_defense_reduction_actions > 0
	var attack_power := player.stats.attack
	var attack_multiplier := CombatProgressionRulesClass.basic_attack_multiplier(
		player, momentum_stacks
	)
	if warrior_retribution_ready:
		var defense_power := maxi(
			1, MathClass.python_roundi(player.stats.defense * warrior_retribution_ratio)
		)
		attack_power += defense_power
		report.class_effect_notes.append(
			"ODWET: DEF dodaje +%d siły do tego ataku." % defense_power
		)
	warrior_retribution_ready = false
	warrior_retribution_ratio = 0.50
	var hit := hit_resolver.resolve(attack_power, attack_multiplier, false, false, "physical")
	report.player_damage = hit.damage
	report.enemy_dodged = hit.dodged
	report.player_critical = hit.critical
	if hit.critical and _passive_specialization("attack_speed") == "deadly_tempo":
		deadly_tempo_ready = true
	if armor_break_was_active:
		effects.consume_offensive_action()
	report.turn_consumed = true
	if not enemy.is_alive():
		result = VICTORY
		_update_class_reports(report)
		return report
	var extra_chance := PassiveProgressionServiceClass.attack_speed_extra_hit_chance(player)
	if _passive_specialization("attack_speed") == "flurry":
		extra_chance += 5.0
	if deadly_tempo_ready:
		extra_chance += 15.0
		deadly_tempo_ready = false
		report.class_effect_notes.append("ZABÓJCZE TEMPO: +15 p.p. szansy na dodatkowe uderzenie.")
	if extra_chance > 0.0 and rng.randf() < extra_chance / 100.0:
		var extra_hit := hit_resolver.resolve(player.stats.attack, 1.0, false, false, "physical")
		report.extra_player_damage = extra_hit.damage
		report.extra_player_critical = extra_hit.critical
		if extra_hit.critical and _passive_specialization("attack_speed") == "deadly_tempo":
			deadly_tempo_ready = true
		if not enemy.is_alive():
			result = VICTORY
			_update_class_reports(report)
			return report
	_resolve_hunter_delayed_effects(report, hunter_pending)
	_update_hunter_report(report)
	if not enemy.is_alive():
		result = VICTORY
		_update_class_reports(report)
		return report
	_after_offensive_action()
	_enemy_turn(report)
	_update_class_reports(report)
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
		error = "Umiejętność wymaga odblokowania w drzewku talentów."
	elif error.is_empty() and not skill.is_combat_ready():
		error = "Mechanika tej umiejętności nie została jeszcze przeniesiona."
	elif error.is_empty() and skill.effect == "fate_va_banque" and fate_tokens <= 0:
		error = "Va Banque wymaga przynajmniej 1 Żetonu Losu."
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
		_update_class_reports(report)
		return report
	_resolve_hunter_delayed_effects(report, hunter_pending)
	_update_hunter_report(report)
	if not enemy.is_alive():
		result = VICTORY
		_update_class_reports(report)
		return report
	if skill.is_offensive():
		_after_offensive_action()
	else:
		_break_momentum()
	_enemy_turn(report)
	_update_class_reports(report)
	return report


func can_double_cast() -> bool:
	return (
		player.character_class_code == "mage"
		and _has_class_mechanic("arcana_double_weave")
		and mage_arcane_weave >= 3
	)


func get_double_cast_cost(first_skill_id: String, second_skill_id: String) -> int:
	var first: SkillDefinitionClass = SkillCatalogClass.get_definition(first_skill_id)
	var second: SkillDefinitionClass = SkillCatalogClass.get_definition(second_skill_id)
	if first == null or second == null:
		return 0
	var second_cost := second.mana_cost
	if _has_class_mechanic("arcana_efficiency"):
		second_cost = maxi(1, MathClass.python_roundi(second_cost * 0.75))
	return first.mana_cost + second_cost


func get_skill_pair_error(first_skill_id: String, second_skill_id: String) -> String:
	var error := ""
	if result != ONGOING:
		error = "Ta walka już się zakończyła."
	elif not can_double_cast():
		error = "Podwójny Splot nie jest jeszcze gotowy."
	var first: SkillDefinitionClass = SkillCatalogClass.get_definition(first_skill_id)
	var second: SkillDefinitionClass = SkillCatalogClass.get_definition(second_skill_id)
	if error.is_empty() and (first == null or second == null):
		error = "Podwójny Splot zawiera nieznane zaklęcie."
	if error.is_empty():
		error = get_skill_use_error(first_skill_id)
	if error.is_empty():
		error = get_skill_use_error(second_skill_id)
	if (
		error.is_empty()
		and (
			first.character_class_code != "mage"
			or second.character_class_code != "mage"
			or not first.is_offensive()
			or not second.is_offensive()
		)
	):
		error = "Podwójny Splot wymaga dwóch ofensywnych zaklęć Maga."
	var total_cost := 0
	if error.is_empty():
		total_cost = get_double_cast_cost(first_skill_id, second_skill_id)
	if error.is_empty() and not player.stats.can_spend_mana(total_cost):
		error = (
			"Brak Many na Podwójny Splot. Potrzeba %d, masz %d."
			% [total_cost, player.stats.current_mana]
		)
	return error


func player_use_skill_pair(first_skill_id: String, second_skill_id: String) -> Dictionary:
	var report := _new_report()
	var error := get_skill_pair_error(first_skill_id, second_skill_id)
	if not error.is_empty():
		report.error = error
		return report
	var first: SkillDefinitionClass = SkillCatalogClass.get_definition(first_skill_id)
	var second: SkillDefinitionClass = SkillCatalogClass.get_definition(second_skill_id)
	var total_cost := get_double_cast_cost(first_skill_id, second_skill_id)
	player.stats.spend_mana(total_cost)
	report.skill_id = "%s+%s" % [first.skill_id, second.skill_id]
	report.skill_name = "%s + %s" % [first.display_name, second.display_name]
	report.skill_mana_cost = total_cost
	report.player_damage_type = first.damage_type
	report.turn_consumed = true
	report.mage_double_cast = true
	report.class_effect_notes.append("PODWÓJNY SPLOT: dwa zaklęcia zostają rzucone w jednej turze.")
	var armor_break_was_active := effects.enemy_defense_reduction_actions > 0
	mage_arcane_weave = 0

	var first_damage_before: int = report.skill_total_damage
	_execute_standard_skill(first, report, 1.0, false)
	report.skill_notes.append(
		"%s: %d obrażeń." % [first.display_name, report.skill_total_damage - first_damage_before]
	)
	if enemy.is_alive():
		var second_scale := 0.95 if _has_class_mechanic("arcana_perfect_weave") else 0.80
		var second_damage_before: int = report.skill_total_damage
		_execute_standard_skill(second, report, second_scale, false)
		report.skill_notes.append(
			(
				"%s: %d obrażeń."
				% [second.display_name, report.skill_total_damage - second_damage_before]
			)
		)
		report.class_effect_notes.append(
			(
				"Drugie zaklęcie Splotu działa z %d%% mocy."
				% MathClass.python_roundi(second_scale * 100.0)
			)
		)
	if armor_break_was_active:
		effects.consume_offensive_action()
	if _has_class_mechanic("arcana_mana_cycle"):
		var restored := player.stats.restore_mana(4)
		if restored > 0:
			report.player_mana_restored += restored
			report.class_effect_notes.append("OBIEG MANY: odzyskujesz %d Many." % restored)
	_update_class_reports(report)
	if not enemy.is_alive():
		result = VICTORY
		return report
	_after_offensive_action()
	_enemy_turn(report)
	_update_class_reports(report)
	return report


func player_defend() -> Dictionary:
	if result != ONGOING:
		return {}
	var report := _new_report()
	report.player_defended = true
	report.turn_consumed = true
	_break_momentum()
	var uses_shield := _equipped_type(PlayerEquipmentClass.OFF_HAND) == "shield"
	if (
		_has_class_mechanic("warrior_retribution")
		or (uses_shield and _has_class_mechanic("heavy_knight_core"))
	):
		warrior_retribution_ready = true
		warrior_retribution_ratio = (
			0.75 if uses_shield and _has_class_mechanic("heavy_bastion") else 0.50
		)
		report.class_effect_notes.append(
			(
				"ODWET: następny podstawowy atak wykorzysta %d%% DEF jako dodatkową siłę."
				% MathClass.python_roundi(warrior_retribution_ratio * 100.0)
			)
		)
	_enemy_turn(report, true)
	_update_class_reports(report)
	return report


func player_flee() -> Dictionary:
	if result != ONGOING:
		return {}
	var report := _new_report()
	report.turn_consumed = true
	_break_momentum()
	if rng.randf() < 0.5:
		result = FLED
		return report
	report.flee_failed = true
	_enemy_turn(report)
	return report


func player_use_restoration(heal_amount: int, mana_amount: int) -> Dictionary:
	if result != ONGOING or (heal_amount <= 0 and mana_amount <= 0):
		return {}
	var report := _new_report()
	report.turn_consumed = true
	_break_momentum()
	report.player_healed = player.stats.heal(heal_amount)
	report.player_mana_restored = player.stats.restore_mana(mana_amount)
	_enemy_turn(report)
	return report


func _get_skill_equipment_error(skill: SkillDefinitionClass) -> String:
	if not skill.required_weapon_type.is_empty():
		var equipped_weapon_type := _equipped_type(PlayerEquipmentClass.WEAPON)
		if equipped_weapon_type != skill.required_weapon_type:
			var weapon_names := {"bow": "Łuku", "staff": "Kostura", "fate_lance": "Lancy Losu"}
			return (
				"Ta umiejętność wymaga: %s."
				% weapon_names.get(skill.required_weapon_type, skill.required_weapon_type)
			)
	if not skill.required_offhand_type.is_empty():
		var equipped_offhand_type := _equipped_type(PlayerEquipmentClass.OFF_HAND)
		if equipped_offhand_type != skill.required_offhand_type:
			var offhand_names := {"shield": "Tarczy", "quiver": "Kołczanu", "artifact": "Artefaktu"}
			return (
				"Ta umiejętność wymaga: %s."
				% offhand_names.get(skill.required_offhand_type, skill.required_offhand_type)
			)
	return ""


func _equipped_type(slot: String) -> String:
	var item = player.equipment.get_item(slot)
	return item.definition.equipment_type if item != null and item.definition != null else ""


func _resolve_skill_hits(
	skill: SkillDefinitionClass, report: Dictionary, power_scale := 1.0
) -> void:
	var power := _skill_power(skill)
	for hit_index in skill.hits:
		if not enemy.is_alive():
			break
		var hit := _resolve_player_skill_hit(skill, power, power_scale)
		report.player_hit_damages.append(hit.damage)
		report.player_hit_dodges.append(hit.dodged)
		report.skill_total_damage += hit.damage
		if hit_index == 0:
			report.player_damage = hit.damage
			report.enemy_dodged = hit.dodged
			report.player_critical = hit.critical
		else:
			report.extra_player_critical = report.extra_player_critical or hit.critical
			var note := (
				"Trafienie %d: unik." % (hit_index + 1)
				if hit.dodged
				else (
					"Trafienie %d: %d obrażeń%s."
					% [hit_index + 1, hit.damage, " krytycznych" if hit.critical else ""]
				)
			)
			report.skill_notes.append(note)


func _execute_standard_skill(
	skill: SkillDefinitionClass,
	report: Dictionary,
	power_scale := 1.0,
	build_weave := true,
) -> void:
	if skill.effect == "delayed_rain":
		hunter_rain_pending.append(_skill_power(skill))
		report.skill_notes.append(
			"DESZCZ STRZAŁ: salwa leci w górę i spadnie po następnej akcji Łowcy."
		)
		_record_hunter_technique(skill, report)
		return
	var final_power_scale := (
		power_scale
		* CombatProgressionRulesClass.skill_multiplier(
			player, skill, enemy, hunter_sequence, momentum_stacks, report
		)
	)
	final_power_scale = _record_mage_element(skill, report, final_power_scale)
	_resolve_skill_hits(skill, report, final_power_scale)
	_resolve_hunter_skill_effect(skill, report)
	_apply_skill_effect(skill, report)
	_record_hunter_technique(skill, report)
	if build_weave and player.character_class_code == "mage" and _has_class_mechanic("arcana_core"):
		mage_arcane_weave = mini(3, mage_arcane_weave + 1)
		report.class_effect_notes.append("SPLOT MAGII: %d/3." % mage_arcane_weave)
	_update_mage_report(report)


func _resolve_player_skill_hit(
	skill: SkillDefinitionClass, power: int, power_scale := 1.0
) -> Dictionary:
	return (
		hit_resolver
		. resolve(
			power,
			skill.multiplier * power_scale,
			skill.guaranteed_hit,
			skill.scaling == "magic",
			skill.damage_type,
			skill.special_armor_penetration,
		)
	)


func _record_mage_element(
	skill: SkillDefinitionClass, report: Dictionary, power_scale: float
) -> float:
	if player.character_class_code != "mage" or skill.damage_type not in ["fire", "frost", "wind"]:
		return power_scale
	var candidate: Array[String] = []
	candidate.assign(mage_element_sequence.slice(-2))
	candidate.append(skill.damage_type)
	if (
		_has_class_mechanic("mage_elemental_cycle")
		and candidate.size() == 3
		and _unique_string_count(candidate) == 3
	):
		report.class_effect_notes.append("CYKL ŻYWIOŁÓW: trzeci różny żywioł zyskuje +20% obrażeń.")
		mage_element_sequence.clear()
		return power_scale * 1.20
	mage_element_sequence.append(skill.damage_type)
	if mage_element_sequence.size() > 2:
		mage_element_sequence.pop_front()
	return power_scale


func _unique_string_count(values: Array[String]) -> int:
	var unique := {}
	for value: String in values:
		unique[value] = true
	return unique.size()


func _update_mage_report(report: Dictionary) -> void:
	report.mage_arcane_weave = mage_arcane_weave
	report.mage_element_sequence.assign(mage_element_sequence)
	report.mage_double_weave_ready = can_double_cast()


func _has_class_mechanic(mechanic_id: String) -> bool:
	return (
		mechanic_id in player.unlocked_class_mechanic_ids
		or TalentProgressionServiceClass.has_talent(player, mechanic_id)
	)


func _update_warrior_report(report: Dictionary) -> void:
	report.warrior_retribution_ready = warrior_retribution_ready
	report.warrior_retribution_ratio = warrior_retribution_ratio
	report.warrior_block_chance = warrior_block_chance()
	report.warrior_guard_percent = effects.player_guard_percent
	report.warrior_guard_hits = effects.player_guard_hits


func _update_class_reports(report: Dictionary) -> void:
	_update_warrior_report(report)
	_update_mage_report(report)
	_update_hunter_report(report)
	_update_fate_report(report)
	report.momentum_stacks = momentum_stacks


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
	return (
		hit_resolver.resolve(power, multiplier, true, false, damage_type, armor_penetration).damage
	)


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
		var damage := _resolve_hunter_guaranteed_hit(
			power, CombatProgressionRulesClass.hunter_echo_multiplier(player), "physical"
		)
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
	if TalentProgressionServiceClass.has_talent(player, "phantom_bows") and enemy.is_alive():
		var phantom_damage := _resolve_hunter_guaranteed_hit(
			maxi(1, player.stats.attack + int(player.attributes.dexterity / 2.0)),
			0.35,
			"physical",
		)
		report.hunter_combo_damage += phantom_damage
		report.skill_total_damage += phantom_damage
		report.skill_notes.append(
			"WIDMOWE ŁUKI: dodatkowa strzała zadaje %d obrażeń." % phantom_damage
		)
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
			return maxi(
				1, player.stats.attack + MathClass.python_roundi(player.stats.defense * 0.6)
			)
		"fate":
			return maxi(1, player.stats.attack + int(player.attributes.luck / 2.0))
	return 0


func _resolve_fate_skill(skill: SkillDefinitionClass, report: Dictionary) -> void:
	fate_resolver.resolve(skill, report)


func fate_token_cap() -> int:
	return fate_resolver.token_cap()


func _update_fate_report(report: Dictionary) -> void:
	fate_resolver.update_report(report)


func _apply_skill_effect(skill: SkillDefinitionClass, report: Dictionary) -> void:
	if (
		skill.effect in ["armor_break", "bleed"]
		and enemy.status_resistance > 0.0
		and rng.randf() < enemy.status_resistance
	):
		report.skill_notes.append("%s odpiera negatywny efekt." % enemy.display_name)
		return
	match skill.effect:
		"armor_break":
			var armor_break := skill.effect_value
			if player.character_class_code == "warrior":
				armor_break += CombatProgressionRulesClass.armor_break_bonus(player)
			effects.apply_armor_break(armor_break, skill.effect_duration)
			report.skill_notes.append(
				"DEF przeciwnika -%d na %d ofensywne akcje." % [armor_break, skill.effect_duration]
			)
		"bleed":
			var bleed_damage := skill.effect_value
			if player.character_class_code == "warrior":
				bleed_damage += CombatProgressionRulesClass.bleed_bonus(player)
			effects.apply_bleed(bleed_damage, skill.effect_duration)
			report.skill_notes.append(
				"Krwawienie: %d obrażeń przez %d tury." % [bleed_damage, skill.effect_duration]
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
		"provoke":
			warrior_provoke_ready = true
			warrior_provoke_block_bonus = float(skill.effect_value)
			report.skill_notes.append(
				(
					"PROWOKACJA: przeciwnik odpowie zwykłym atakiem; "
					+ "+%d p.p. Bloku na tę wymianę." % skill.effect_value
				)
			)


func _enemy_turn(report: Dictionary, defending := false) -> void:
	report.enemy_acted = true
	var attack_value := enemy.attack
	var damage_type := enemy.basic_damage_type
	var provoked := warrior_provoke_ready
	warrior_provoke_ready = false
	if enemy.attacks_made == 0:
		attack_value += enemy.first_attack_bonus
	if not provoked and not enemy.special_name.is_empty() and rng.randf() < enemy.special_chance:
		attack_value += enemy.special_attack_bonus
		report.enemy_special_name = enemy.special_name
		if not enemy.special_damage_type.is_empty():
			damage_type = enemy.special_damage_type
	report.enemy_damage_type = damage_type
	enemy.attacks_made += 1
	report.enemy_damage = _resolve_enemy_hit(attack_value, damage_type, defending, report, false)
	warrior_provoke_block_bonus = 0.0
	if not enemy.is_alive():
		result = VICTORY
		return
	if not player.stats.is_alive():
		result = DEFEAT
		return
	if not provoked and enemy.extra_attack_chance > 0.0 and rng.randf() < enemy.extra_attack_chance:
		report.enemy_extra_damage = _resolve_enemy_hit(
			enemy.attack, enemy.basic_damage_type, false, report, true
		)
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
	_maybe_second_wind(report)
	var regeneration := (
		PassiveProgressionServiceClass.health_regeneration(player) + player.stats.health_regen
	)
	if regeneration > 0:
		if (
			_passive_specialization("health_regen") == "iron_will"
			and player.stats.current_hp <= player.stats.max_hp * 0.40
		):
			regeneration = MathClass.python_roundi(regeneration * 1.50)
			report.class_effect_notes.append("ŻELAZNA WOLA: regeneracja zwiększona o 50%.")
		report.player_regenerated = player.stats.heal(regeneration)


func _resolve_enemy_hit(
	attack_value: int,
	damage_type: String,
	defending: bool,
	report: Dictionary,
	is_extra_hit: bool,
) -> int:
	var dodge_chance := player.stats.dodge + effects.current_dodge_bonus()
	var dodged := rng.randf() < dodge_chance / 100.0
	effects.consume_dodge_hit()
	if dodged:
		if not is_extra_hit:
			report.player_dodged = true
		effects.consume_guard_hit()
		return 0
	var block_chance := warrior_block_chance()
	if block_chance > 0.0 and rng.randf() < block_chance / 100.0:
		report.shield_blocked = true
		report.class_effect_notes.append("BLOK TARCZĄ! (%.0f%% szansy)" % block_chance)
		effects.consume_guard_hit()
		if _has_class_mechanic("heavy_counter") and enemy.is_alive():
			var counter := maxi(1, MathClass.python_roundi(player.stats.defense * 0.70))
			report.warrior_counter_damage += enemy.take_damage(counter)
			report.class_effect_notes.append(
				"ŻELAZNA KONTRA: przeciwnik otrzymuje %d obrażeń." % report.warrior_counter_damage
			)
		return 0
	var damage := maxi(1, attack_value - player.stats.defense)
	damage = player.stats.elemental_resistances.reduce_damage(damage, damage_type)
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


func warrior_block_chance() -> float:
	if (
		player.character_class_code != "warrior"
		or _equipped_type(PlayerEquipmentClass.OFF_HAND) != "shield"
	):
		return 0.0
	return minf(
		75.0,
		5.0 + CombatProgressionRulesClass.shield_block_bonus(player) + warrior_provoke_block_bonus,
	)


func _passive_specialization(passive_code: String) -> String:
	return PassiveProgressionServiceClass.specialization_for(player, passive_code)


func _after_offensive_action() -> void:
	if _passive_specialization("increased_attack") == "momentum":
		momentum_stacks = mini(3, momentum_stacks + 1)


func _break_momentum() -> void:
	if _passive_specialization("increased_attack") == "momentum":
		momentum_stacks = 0


func _maybe_second_wind(report: Dictionary) -> void:
	if second_wind_used or _passive_specialization("health_regen") != "second_wind":
		return
	if not player.stats.is_alive():
		return
	if player.stats.current_hp <= player.stats.max_hp * 0.25:
		second_wind_used = true
		var healed := player.stats.heal(
			maxi(1, MathClass.python_roundi(player.stats.max_hp * 0.20))
		)
		if healed > 0:
			report.player_healed += healed
			report.class_effect_notes.append("DRUGI ODDECH: odzyskujesz %d PŻ." % healed)


func _new_report() -> Dictionary:
	return CombatReportFactoryClass.create(self)
