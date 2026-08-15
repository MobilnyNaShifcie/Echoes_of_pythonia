class_name SkillCatalog
extends RefCounted

const SkillDefinitionClass := preload("res://core/skills/skill_definition.gd")
const TalentProgressionServiceClass := preload(
	"res://core/progression/talent_progression_service.gd"
)
const CLASS_SKILL_ORDER := {
	"warrior": ["power_slash", "armor_break", "defensive_stance", "blood_strike"],
	"hunter": ["precise_shot", "bleeding_shot", "shadow_step", "double_shot"],
	"mage": ["fire_bolt", "frost_lance", "lightning", "mana_burst"],
	"pierrot": ["fate_thrust", "double_roll", "fate_feint", "grand_gamble"],
}
const HUNTER_TECHNIQUE_ORDER := [
	"piercing_arrow",
	"frost_arrow",
	"explosive_arrow",
	"phantom_arrow",
	"rain_of_arrows",
	"splitting_arrow",
]
const WARRIOR_TALENT_SKILL_ORDER := ["shield_bash", "provoke"]
const TALENT_SKILL_ORDER_BY_CLASS := {
	"warrior": WARRIOR_TALENT_SKILL_ORDER,
	"hunter": HUNTER_TECHNIQUE_ORDER + ["thousand_arrows"],
	"pierrot": ["va_banque"],
}
const DEFINITIONS := {
	"power_slash": preload("res://data/skills/power_slash.tres"),
	"armor_break": preload("res://data/skills/armor_break.tres"),
	"defensive_stance": preload("res://data/skills/defensive_stance.tres"),
	"blood_strike": preload("res://data/skills/blood_strike.tres"),
	"shield_bash": preload("res://data/skills/shield_bash.tres"),
	"provoke": preload("res://data/skills/provoke.tres"),
	"precise_shot": preload("res://data/skills/precise_shot.tres"),
	"bleeding_shot": preload("res://data/skills/bleeding_shot.tres"),
	"shadow_step": preload("res://data/skills/shadow_step.tres"),
	"double_shot": preload("res://data/skills/double_shot.tres"),
	"piercing_arrow": preload("res://data/skills/piercing_arrow.tres"),
	"frost_arrow": preload("res://data/skills/frost_arrow.tres"),
	"explosive_arrow": preload("res://data/skills/explosive_arrow.tres"),
	"phantom_arrow": preload("res://data/skills/phantom_arrow.tres"),
	"rain_of_arrows": preload("res://data/skills/rain_of_arrows.tres"),
	"splitting_arrow": preload("res://data/skills/splitting_arrow.tres"),
	"thousand_arrows": preload("res://data/skills/thousand_arrows.tres"),
	"fire_bolt": preload("res://data/skills/fire_bolt.tres"),
	"frost_lance": preload("res://data/skills/frost_lance.tres"),
	"lightning": preload("res://data/skills/lightning.tres"),
	"mana_burst": preload("res://data/skills/mana_burst.tres"),
	"fate_thrust": preload("res://data/skills/fate_thrust.tres"),
	"double_roll": preload("res://data/skills/double_roll.tres"),
	"fate_feint": preload("res://data/skills/fate_feint.tres"),
	"grand_gamble": preload("res://data/skills/grand_gamble.tres"),
	"va_banque": preload("res://data/skills/va_banque.tres"),
}


static func get_definition(skill_id: String) -> SkillDefinitionClass:
	return DEFINITIONS.get(skill_id)


static func get_skills_for_class(class_code: String) -> Array[SkillDefinitionClass]:
	var result: Array[SkillDefinitionClass] = []
	for skill_id: String in CLASS_SKILL_ORDER.get(class_code, []):
		result.append(DEFINITIONS[skill_id])
	return result


static func get_preview_skills_for_class(class_code: String) -> Array[SkillDefinitionClass]:
	var result := get_skills_for_class(class_code)
	for skill_id: String in TALENT_SKILL_ORDER_BY_CLASS.get(class_code, []):
		result.append(DEFINITIONS[skill_id])
	return result


static func get_hunter_techniques() -> Array[SkillDefinitionClass]:
	var result: Array[SkillDefinitionClass] = []
	for skill_id: String in HUNTER_TECHNIQUE_ORDER:
		result.append(DEFINITIONS[skill_id])
	return result


static func get_unlocked_skills(player) -> Array[SkillDefinitionClass]:
	var result: Array[SkillDefinitionClass] = []
	for skill: SkillDefinitionClass in get_skills_for_class(player.character_class_code):
		if player.level >= skill.unlock_level:
			result.append(skill)
	for skill_id: String in TALENT_SKILL_ORDER_BY_CLASS.get(player.character_class_code, []):
		var skill: SkillDefinitionClass = get_definition(skill_id)
		if (
			skill != null
			and skill.character_class_code == player.character_class_code
			and player.level >= skill.unlock_level
			and is_unlocked(player, skill)
			and not result.has(skill)
		):
			result.append(skill)
	return result


static func get_combat_ready_skills(player) -> Array[SkillDefinitionClass]:
	var result: Array[SkillDefinitionClass] = []
	for skill: SkillDefinitionClass in get_unlocked_skills(player):
		if skill.is_combat_ready():
			result.append(skill)
	return result


static func is_unlocked(player, skill: SkillDefinitionClass) -> bool:
	if (
		skill == null
		or skill.character_class_code != player.character_class_code
		or player.level < skill.unlock_level
	):
		return false
	if skill.unlock_source == "talent":
		return (
			skill.skill_id in player.unlocked_talent_skill_ids
			or TalentProgressionServiceClass.has_talent(player, skill.required_talent_id)
		)
	return skill.skill_id in CLASS_SKILL_ORDER.get(player.character_class_code, [])


static func is_hunter_technique_id(skill_id: String) -> bool:
	return skill_id in HUNTER_TECHNIQUE_ORDER


static func is_talent_skill_id_for_class(skill_id: String, class_code: String) -> bool:
	return skill_id in TALENT_SKILL_ORDER_BY_CLASS.get(class_code, [])
