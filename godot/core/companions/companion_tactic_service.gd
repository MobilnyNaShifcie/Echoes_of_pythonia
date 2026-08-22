class_name CompanionTacticService
extends RefCounted

const CompanionAiContextClass := preload("res://core/companions/companion_ai_context.gd")
const CompanionStateClass := preload("res://core/companions/companion_state.gd")
const PartyStateClass := preload("res://core/companions/party_state.gd")
const SkillCatalogClass := preload("res://core/skills/skill_catalog.gd")
const SkillDefinitionClass := preload("res://core/skills/skill_definition.gd")

const TACTIC_ORDER := [
	CompanionStateClass.TACTIC_AGGRESSIVE,
	CompanionStateClass.TACTIC_BALANCED,
	CompanionStateClass.TACTIC_CAUTIOUS,
	CompanionStateClass.TACTIC_DEFENSIVE,
]
const TACTIC_DESCRIPTIONS := {
	CompanionStateClass.TACTIC_AGGRESSIVE:
	"Priorytetem są najmocniejsze dostępne umiejętności ofensywne.",
	CompanionStateClass.TACTIC_BALANCED:
	"Kompan zachowuje styl swojej klasy i reaguje na zagrożenie drużyny.",
	CompanionStateClass.TACTIC_CAUTIOUS:
	"Kompan oszczędza Manę i broni się dopiero przy realnym zagrożeniu.",
	CompanionStateClass.TACTIC_DEFENSIVE:
	"Kompan aktywnie osłania siebie i rannych członków drużyny.",
}
const DEFENSIVE_EFFECTS := ["guard", "dodge", "provoke"]


static func set_tactic(
	party: PartyStateClass, companion_id: String, tactic_code: String
) -> Dictionary:
	if party == null:
		return _failure("Brak stanu drużyny.")
	var companion: CompanionStateClass = party.companion_by_id(companion_id)
	if companion == null:
		return _failure("Nie znaleziono kompana.")
	if tactic_code not in CompanionStateClass.VALID_TACTICS:
		return _failure("Nieznana taktyka kompana.")
	if companion.tactic == tactic_code:
		return {"ok": true, "changed": false, "message": "Taktyka nie wymaga zmiany."}
	companion.tactic = tactic_code
	return {
		"ok": true,
		"changed": true,
		"message":
		(
			"%s: taktyka %s."
			% [companion.display_name, CompanionStateClass.tactic_display_name(tactic_code)]
		),
	}


static func description(tactic_code: String) -> String:
	return str(TACTIC_DESCRIPTIONS.get(tactic_code, TACTIC_DESCRIPTIONS["balanced"]))


## Zwraca identyfikator skilla albo pusty String, który w silniku 6F oznacza
## atak podstawowy. Funkcja nie mutuje walki ani kompana i nie zależy od UI.
static func choose_skill_id(
	companion: CompanionStateClass, context: CompanionAiContextClass, rng: RandomNumberGenerator
) -> String:
	if companion == null or context == null:
		return ""
	var skills: Array[SkillDefinitionClass] = []
	for skill: SkillDefinitionClass in SkillCatalogClass.get_unlocked_skills_for_companion(
		companion
	):
		if skill.mana_cost <= context.current_mana:
			skills.append(skill)
	if skills.is_empty():
		return ""

	var tactic := (
		companion.tactic
		if companion.tactic in CompanionStateClass.VALID_TACTICS
		else CompanionStateClass.TACTIC_BALANCED
	)
	var offensive: Array[SkillDefinitionClass] = []
	var defensive: Array[SkillDefinitionClass] = []
	for skill: SkillDefinitionClass in skills:
		if skill.is_offensive():
			offensive.append(skill)
		if skill.effect in DEFENSIVE_EFFECTS:
			defensive.append(skill)
	var ally_in_danger := context.has_party_member_in_danger()

	if (
		tactic == CompanionStateClass.TACTIC_DEFENSIVE
		and not defensive.is_empty()
		and (context.hp_ratio() < 0.80 or ally_in_danger)
	):
		if companion.class_code == "warrior" and _has_talent(companion, "heavy_knight_core"):
			var provoke: SkillDefinitionClass = _find_skill(defensive, "provoke")
			if provoke != null:
				return provoke.skill_id
		return defensive[0].skill_id

	if tactic == CompanionStateClass.TACTIC_CAUTIOUS:
		if not defensive.is_empty() and context.hp_ratio() < 0.50:
			return defensive[0].skill_id
		if context.mana_ratio() < 0.25:
			return ""

	if (
		tactic == CompanionStateClass.TACTIC_BALANCED
		and companion.class_code == "warrior"
		and _has_talent(companion, "heavy_knight_core")
		and ally_in_danger
	):
		var provoke: SkillDefinitionClass = _find_skill(skills, "provoke")
		if provoke != null:
			return provoke.skill_id

	if tactic == CompanionStateClass.TACTIC_AGGRESSIVE and not offensive.is_empty():
		return _strongest_skill(offensive).skill_id

	if companion.class_code == "hunter":
		var techniques: Array[SkillDefinitionClass] = []
		for skill: SkillDefinitionClass in offensive:
			if not skill.hunter_technique.is_empty():
				techniques.append(skill)
		if not techniques.is_empty():
			return _random_skill(techniques, rng).skill_id
	if companion.class_code == "pierrot":
		var fate_skills: Array[SkillDefinitionClass] = []
		for skill: SkillDefinitionClass in skills:
			if skill.effect.begins_with("fate_"):
				fate_skills.append(skill)
		if not fate_skills.is_empty():
			return _random_skill(fate_skills, rng).skill_id
	return _strongest_skill(offensive if not offensive.is_empty() else skills).skill_id


static func _find_skill(
	skills: Array[SkillDefinitionClass], skill_id: String
) -> SkillDefinitionClass:
	for skill: SkillDefinitionClass in skills:
		if skill.skill_id == skill_id:
			return skill
	return null


static func _strongest_skill(skills: Array[SkillDefinitionClass]) -> SkillDefinitionClass:
	var strongest: SkillDefinitionClass = skills[0]
	var strongest_power := strongest.multiplier * maxi(1, strongest.hits)
	for index in range(1, skills.size()):
		var candidate: SkillDefinitionClass = skills[index]
		var candidate_power := candidate.multiplier * maxi(1, candidate.hits)
		if candidate_power > strongest_power:
			strongest = candidate
			strongest_power = candidate_power
	return strongest


static func _random_skill(
	skills: Array[SkillDefinitionClass], rng: RandomNumberGenerator
) -> SkillDefinitionClass:
	if rng == null or skills.size() == 1:
		return skills[0]
	return skills[rng.randi_range(0, skills.size() - 1)]


static func _has_talent(companion: CompanionStateClass, talent_id: String) -> bool:
	return int(companion.talents.get(talent_id, 0)) > 0


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "changed": false, "message": message}
