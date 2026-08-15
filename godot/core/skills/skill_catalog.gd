class_name SkillCatalog
extends RefCounted

const SkillDefinitionClass := preload("res://core/skills/skill_definition.gd")
const CLASS_SKILL_ORDER := {
	"warrior": ["power_slash", "armor_break", "defensive_stance", "blood_strike"],
	"hunter": ["precise_shot", "bleeding_shot", "shadow_step", "double_shot"],
	"mage": ["fire_bolt", "frost_lance", "lightning", "mana_burst"],
	"pierrot": ["fate_thrust", "double_roll", "fate_feint", "grand_gamble"],
}
const DEFINITIONS := {
	"power_slash": preload("res://data/skills/power_slash.tres"),
	"armor_break": preload("res://data/skills/armor_break.tres"),
	"defensive_stance": preload("res://data/skills/defensive_stance.tres"),
	"blood_strike": preload("res://data/skills/blood_strike.tres"),
	"precise_shot": preload("res://data/skills/precise_shot.tres"),
	"bleeding_shot": preload("res://data/skills/bleeding_shot.tres"),
	"shadow_step": preload("res://data/skills/shadow_step.tres"),
	"double_shot": preload("res://data/skills/double_shot.tres"),
	"fire_bolt": preload("res://data/skills/fire_bolt.tres"),
	"frost_lance": preload("res://data/skills/frost_lance.tres"),
	"lightning": preload("res://data/skills/lightning.tres"),
	"mana_burst": preload("res://data/skills/mana_burst.tres"),
	"fate_thrust": preload("res://data/skills/fate_thrust.tres"),
	"double_roll": preload("res://data/skills/double_roll.tres"),
	"fate_feint": preload("res://data/skills/fate_feint.tres"),
	"grand_gamble": preload("res://data/skills/grand_gamble.tres"),
}


static func get_definition(skill_id: String) -> SkillDefinitionClass:
	return DEFINITIONS.get(skill_id)


static func get_skills_for_class(class_code: String) -> Array[SkillDefinitionClass]:
	var result: Array[SkillDefinitionClass] = []
	for skill_id: String in CLASS_SKILL_ORDER.get(class_code, []):
		result.append(DEFINITIONS[skill_id])
	return result


static func get_unlocked_skills(player) -> Array[SkillDefinitionClass]:
	var result: Array[SkillDefinitionClass] = []
	for skill: SkillDefinitionClass in get_skills_for_class(player.character_class_code):
		if player.level >= skill.unlock_level:
			result.append(skill)
	return result


static func get_combat_ready_skills(player) -> Array[SkillDefinitionClass]:
	var result: Array[SkillDefinitionClass] = []
	for skill: SkillDefinitionClass in get_unlocked_skills(player):
		if skill.is_combat_ready():
			result.append(skill)
	return result


static func is_unlocked(player, skill: SkillDefinitionClass) -> bool:
	return (
		skill != null
		and skill.character_class_code == player.character_class_code
		and player.level >= skill.unlock_level
	)
