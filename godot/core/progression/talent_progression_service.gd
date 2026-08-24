class_name TalentProgressionService
extends RefCounted

const TalentCatalogClass := preload("res://core/progression/talent_catalog.gd")
const TalentDefinitionClass := preload("res://core/progression/talent_definition.gd")

const CORE_SPECIALIZATION_PATHS := {
	"heavy_knight_core": "warrior_heavy_knight",
	"phantom_archer_core": "hunter_phantom_archer",
	"arcana_core": "mage_arcana",
	"fortuna_core": "pierrot_fortuna",
}


static func total_points_for_level(level: int, has_class: bool) -> int:
	if not has_class or level < 5:
		return 0
	return 1 + maxi(0, floori((level - 4) / 2.0))


static func spent_points(player) -> int:
	var result := 0
	for rank_value in player.talent_ranks.values():
		result += maxi(0, int(rank_value))
	return result


static func available_points(player) -> int:
	return maxi(
		0,
		(
			total_points_for_level(player.level, player.character_class_code != "none")
			- spent_points(player)
		),
	)


static func talent_rank(player, talent_id: String) -> int:
	return maxi(0, int(player.talent_ranks.get(talent_id, 0)))


static func has_talent(player, talent_id: String, required_rank := 1) -> bool:
	return talent_rank(player, talent_id) >= required_rank


static func path_is_unlocked(player, path_id: String) -> bool:
	var path = TalentCatalogClass.get_path_definition(path_id)
	if path == null or path.character_class_code != player.character_class_code:
		return false
	return not path.requires_book() or path_id in player.unlocked_class_path_ids


static func get_learn_error(player, talent_id: String) -> String:
	var talent: TalentDefinitionClass = TalentCatalogClass.get_talent(talent_id)
	if talent == null:
		return "Nieznany talent."
	if talent.character_class_code != player.character_class_code:
		return "Talent nie należy do twojej klasy."
	if not path_is_unlocked(player, talent.path_id):
		return "Ta ścieżka wymaga Księgi Ścieżki."
	var current := talent_rank(player, talent_id)
	if current >= talent.max_rank:
		return "Talent ma już maksymalną rangę."
	if available_points(player) <= 0:
		return "Brak wolnych punktów drzewka."
	for required_id: String in talent.prerequisites:
		var required_rank := int(talent.prerequisites[required_id])
		if talent_rank(player, required_id) < required_rank:
			var required: TalentDefinitionClass = TalentCatalogClass.get_talent(required_id)
			return "Wymaga: %s %d/%d." % [required.display_name, required_rank, required.max_rank]
	return ""


static func learn(player, talent_id: String) -> Dictionary:
	var error := get_learn_error(player, talent_id)
	if not error.is_empty():
		return {"ok": false, "message": error}
	var talent: TalentDefinitionClass = TalentCatalogClass.get_talent(talent_id)
	var new_rank := talent_rank(player, talent_id) + 1
	player.talent_ranks[talent_id] = new_rank
	player.recalculate_stats()
	return {
		"ok": true,
		"rank": new_rank,
		"message": "%s: ranga %d/%d." % [talent.display_name, new_rank, talent.max_rank],
	}


static func reset_cost(player) -> int:
	return 1000 + spent_points(player) * 250


static func reset(player) -> Dictionary:
	var spent := spent_points(player)
	if spent <= 0:
		return {"ok": false, "message": "Nie wydano jeszcze żadnych punktów drzewka."}
	var cost := reset_cost(player)
	if player.gold < cost:
		return {
			"ok": false,
			"message": "Brakuje złota. Potrzeba %d, masz %d." % [cost, player.gold],
		}
	player.gold -= cost
	player.talent_ranks.clear()
	player.recalculate_stats()
	return {
		"ok": true,
		"cost": cost,
		"refunded_points": spent,
		"message": "Zresetowano drzewko za %d złota." % cost,
	}


static func specialization_name(player) -> String:
	for talent_id: String in CORE_SPECIALIZATION_PATHS:
		if has_talent(player, talent_id):
			var path = TalentCatalogClass.get_path_definition(CORE_SPECIALIZATION_PATHS[talent_id])
			return path.specialization_name
	return ""


static func validate_state(player) -> String:
	if not player.talent_ranks is Dictionary:
		return "Zapis zawiera nieprawidłowe rangi talentów."
	var unlocked_paths := {}
	for path_id_value in player.unlocked_class_path_ids:
		var path_id := str(path_id_value)
		var path = TalentCatalogClass.get_path_definition(path_id)
		if (
			path == null
			or path.character_class_code != player.character_class_code
			or not path.requires_book()
			or unlocked_paths.has(path_id)
		):
			return "Zapis zawiera niedozwoloną odblokowaną ścieżkę klasy."
		unlocked_paths[path_id] = true
	var validated_ranks := {}
	for talent_id_value in player.talent_ranks:
		var talent_id := str(talent_id_value)
		var talent: TalentDefinitionClass = TalentCatalogClass.get_talent(talent_id)
		var rank_value = player.talent_ranks[talent_id_value]
		if (
			talent == null
			or talent.character_class_code != player.character_class_code
			or not _is_integer(rank_value)
			or int(rank_value) < 1
			or int(rank_value) > talent.max_rank
		):
			return "Zapis zawiera niedozwolony talent albo rangę."
		if (
			TalentCatalogClass.get_path_definition(talent.path_id).requires_book()
			and not unlocked_paths.has(talent.path_id)
		):
			return "Zapis rozwija talent z nieodblokowanej ścieżki."
		validated_ranks[talent_id] = int(rank_value)
	for talent_id: String in validated_ranks:
		var talent: TalentDefinitionClass = TalentCatalogClass.get_talent(talent_id)
		for required_id: String in talent.prerequisites:
			if int(validated_ranks.get(required_id, 0)) < int(talent.prerequisites[required_id]):
				return "Zapis omija wymagania talentu."
	if (
		spent_points(player)
		> total_points_for_level(player.level, player.character_class_code != "none")
	):
		return "Zapis wydaje zbyt wiele punktów drzewka."
	return ""


static func _is_integer(value) -> bool:
	return value is int or (value is float and is_equal_approx(value, floor(value)))
