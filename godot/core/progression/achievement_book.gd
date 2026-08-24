class_name AchievementBook
extends RefCounted

const AchievementCatalogClass := preload("res://core/progression/achievement_catalog.gd")

var unlocked_ids: Array[String] = []
var equipped_title := AchievementCatalogClass.DEFAULT_TITLE


func unlock(achievement_id: String) -> bool:
	if not AchievementCatalogClass.is_valid_id(achievement_id) or achievement_id in unlocked_ids:
		return false
	unlocked_ids.append(achievement_id)
	return true


func is_unlocked(achievement_id: String) -> bool:
	return achievement_id in unlocked_ids


func available_titles() -> Array[String]:
	var titles: Array[String] = [AchievementCatalogClass.DEFAULT_TITLE]
	for achievement_id: String in AchievementCatalogClass.ORDER:
		if achievement_id not in unlocked_ids:
			continue
		titles.append(AchievementCatalogClass.get_definition(achievement_id).title)
	return titles


func equip_title(title: String) -> bool:
	if title not in available_titles():
		return false
	equipped_title = title
	return true
