class_name AdventureService
extends RefCounted

const EnemyCatalogClass := preload("res://core/combat/enemy_catalog.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const LootCatalogClass := preload("res://core/items/loot_catalog.gd")
const QuestServiceClass := preload("res://core/quests/quest_service.gd")
const RegionCatalogClass := preload("res://core/world/region_catalog.gd")
const CarryWeightServiceClass := preload("res://core/economy/carry_weight_service.gd")


static func explore_twilight_plains(session, rng: RandomNumberGenerator) -> Dictionary:
	return explore_region(session, "twilight_plains", rng)


static func explore_region(session, region_id: String, rng: RandomNumberGenerator) -> Dictionary:
	var region = RegionCatalogClass.get_definition(region_id)
	if region == null or region_id not in session.known_region_ids:
		return {
			"enemy_id": "",
			"message": "Nie możesz wyruszyć do nieznanego regionu.",
			"blocked": true,
		}
	session.current_location_id = region_id
	var load := CarryWeightServiceClass.carry_status(session.player)
	if load.overloaded:
		var message := (
			"Nie możesz rozpocząć wyprawy: plecak jest przeciążony "
			+ (
				"(%.1f/%.1f kg). Odłóż przedmioty u Kwatermistrza."
				% [load.current_kg, load.capacity_kg]
			)
		)
		session.last_activity = message
		return {"enemy_id": "", "message": message, "blocked": true}
	var period: String = session.period_code()
	var result := _roll_region_exploration(region_id, period, rng.randf(), rng.randi(), rng.randi())
	session.advance_hours(1)
	if result.enemy_id.is_empty():
		session.last_activity = result.message
	return result


static func _roll_exploration(
	period_code: String, encounter_roll: float, enemy_roll: int, quiet_roll: int
) -> Dictionary:
	return _roll_region_exploration(
		"twilight_plains", period_code, encounter_roll, enemy_roll, quiet_roll
	)


static func _roll_region_exploration(
	region_id: String,
	period_code: String,
	encounter_roll: float,
	enemy_roll: int,
	quiet_roll: int,
) -> Dictionary:
	var region = RegionCatalogClass.get_definition(region_id)
	if region == null:
		return {"enemy_id": "", "message": "Nieznany region.", "blocked": true}
	if encounter_roll >= region.encounter_chance:
		var quiet_index := posmod(quiet_roll, region.quiet_events.size())
		return {"enemy_id": "", "message": region.quiet_events[quiet_index]}
	var table := region.encounters_for(period_code)
	if table.is_empty():
		return {"enemy_id": "", "message": "Droga pozostaje niepokojąco pusta."}
	var total_weight := 0
	for weight: int in table.values():
		total_weight += weight
	var target := posmod(enemy_roll, total_weight)
	var cumulative := 0
	for enemy_id: String in table:
		cumulative += table[enemy_id]
		if target < cumulative:
			return {
				"enemy_id": enemy_id,
				"region_id": region_id,
				"message":
				"Na szlaku pojawia się: %s." % EnemyCatalogClass.display_name_for(enemy_id),
			}
	return {"enemy_id": "", "message": "Droga pozostaje niepokojąco pusta."}


static func resolve_victory(session, enemy, rng: RandomNumberGenerator) -> Dictionary:
	var levels_gained: int = session.player.gain_experience(enemy.experience_reward)
	var gold := rng.randi_range(enemy.gold_min, enemy.gold_max)
	session.player.add_gold(gold)
	session.victories += 1
	var loot_names: Array[String] = []
	var loot_drops := LootCatalogClass.roll_loot(enemy.enemy_id, rng)
	for drop: Dictionary in loot_drops:
		var item_id: String = drop.item_id
		var quantity := int(drop.quantity)
		if not session.player.inventory.add(item_id, quantity):
			continue
		var definition = ItemCatalogClass.get_definition(item_id)
		var display_name: String = definition.display_name
		loot_names.append(display_name if quantity == 1 else "%s ×%d" % [display_name, quantity])
	var quest_update := QuestServiceClass.record_enemy_kill(session.quest_log, enemy.enemy_id)
	var summary := {
		"experience": enemy.experience_reward,
		"gold": gold,
		"levels_gained": levels_gained,
		"loot_names": loot_names,
		"loot_drops": loot_drops,
		"quest_update": quest_update,
	}
	session.last_activity = _format_victory(enemy.display_name, summary)
	return summary


static func resolve_defeat(session, enemy_name: String) -> Dictionary:
	session.player.stats.restore_full()
	session.last_activity = (
		"Porażka z %s. Nie tracisz złota ani EXP; ratownicy odstawili cię do Varenhold."
		% enemy_name
	)
	return {"message": session.last_activity}


static func _format_victory(enemy_name: String, summary: Dictionary) -> String:
	var text := "Pokonano %s: +%d EXP, +%d złota." % [enemy_name, summary.experience, summary.gold]
	if not summary.loot_names.is_empty():
		text += " Łup: %s." % ", ".join(summary.loot_names)
	if not summary.quest_update.is_empty():
		text += " Misja: %d/%d." % [summary.quest_update.current, summary.quest_update.required]
	return text
