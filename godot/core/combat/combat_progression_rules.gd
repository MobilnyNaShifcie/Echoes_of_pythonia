class_name CombatProgressionRules
extends RefCounted

const PassiveProgressionServiceClass := preload(
	"res://core/progression/passive_progression_service.gd"
)
const TalentProgressionServiceClass := preload(
	"res://core/progression/talent_progression_service.gd"
)

const MAGE_MASTERY_BY_SKILL := {
	"fire_bolt": "mage_fire_mastery",
	"frost_lance": "mage_frost_mastery",
	"lightning": "mage_storm_mastery",
}


static func basic_attack_multiplier(player, momentum_stacks: int) -> float:
	var result := 1.0
	if player.character_class_code == "warrior":
		result *= (
			1.0 + 0.05 * TalentProgressionServiceClass.talent_rank(player, "warrior_relentless")
		)
	if PassiveProgressionServiceClass.specialization_for(player, "increased_attack") == "momentum":
		result *= 1.0 + 0.03 * momentum_stacks
	return result


static func skill_multiplier(
	player, skill, enemy, hunter_sequence: Array[String], momentum_stacks: int, report: Dictionary
) -> float:
	var result := 1.0
	if skill.character_class_code == "warrior" and skill.hits > 0:
		result *= (
			1.0 + 0.04 * TalentProgressionServiceClass.talent_rank(player, "warrior_battle_fury")
		)
		if (
			skill.skill_id == "blood_strike"
			and TalentProgressionServiceClass.has_talent(player, "warrior_executioner")
			and enemy.current_hp / float(maxi(1, enemy.max_hp)) < 0.35
		):
			result *= 1.30
			report.class_effect_notes.append("EGZEKUTOR: Krwawy Zamach zyskuje +30% obrażeń.")
	var mage_talent_id := str(MAGE_MASTERY_BY_SKILL.get(skill.skill_id, ""))
	if not mage_talent_id.is_empty():
		result *= 1.0 + 0.08 * TalentProgressionServiceClass.talent_rank(player, mage_talent_id)
	if (
		skill.character_class_code == "hunter"
		and not skill.hunter_technique.is_empty()
		and TalentProgressionServiceClass.has_talent(player, "hunter_sequence_mastery")
	):
		var candidate: Array[String] = []
		candidate.assign(hunter_sequence.slice(-2))
		candidate.append(skill.hunter_technique)
		if candidate.size() == 3 and _unique_count(candidate) == 3:
			result *= 1.15
			report.class_effect_notes.append(
				"PERFEKCYJNA SEKWENCJA: trzeci różny strzał zyskuje +15% obrażeń."
			)
	if (
		PassiveProgressionServiceClass.specialization_for(player, "increased_attack") == "momentum"
		and skill.is_offensive()
	):
		result *= 1.0 + 0.03 * momentum_stacks
	return result


static func armor_break_bonus(player) -> int:
	return TalentProgressionServiceClass.talent_rank(player, "warrior_breaker")


static func bleed_bonus(player) -> int:
	return TalentProgressionServiceClass.talent_rank(player, "warrior_deep_wounds")


static func hunter_echo_multiplier(player) -> float:
	return 0.60 + 0.15 * TalentProgressionServiceClass.talent_rank(player, "phantom_echo_mastery")


static func shield_block_bonus(player) -> float:
	return 5.0 * TalentProgressionServiceClass.talent_rank(player, "heavy_shield_mastery")


static func _unique_count(values: Array[String]) -> int:
	var unique := {}
	for value: String in values:
		unique[value] = true
	return unique.size()
