class_name AdventureService
extends RefCounted

const EnemyCatalogClass := preload("res://core/combat/enemy_catalog.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const QuestServiceClass := preload("res://core/quests/quest_service.gd")
const RegionCatalogClass := preload("res://core/world/region_catalog.gd")
const CarryWeightServiceClass := preload("res://core/economy/carry_weight_service.gd")
const LOOT_TABLES := {
	"wild_dog": [{"item_id": "weak_leather", "chance": 0.7}],
	"slime":
	[
		{"item_id": "slime_gel", "chance": 0.7},
		{"item_id": "weak_healing_potion", "chance": 0.1},
	],
	"wolf":
	[
		{"item_id": "wolf_fur", "chance": 0.7},
		{"item_id": "wolf_fang", "chance": 0.4},
		{"item_id": "wolf_tooth_necklace", "chance": 0.2},
	],
	"boar":
	[
		{"item_id": "raw_boar_meat", "chance": 1.0},
		{"item_id": "truffle", "chance": 0.1},
	],
	"bandit":
	[
		{"item_id": "whetstone", "chance": 0.3},
		{"item_id": "leather_hood", "chance": 0.2},
		{"item_id": "grinding_stone", "chance": 0.1},
	],
	"cursed_scarecrow":
	[
		{"item_id": "old_clothes", "chance": 0.5},
		{"item_id": "spark_of_life", "chance": 0.2},
	],
	"plains_spirit": [{"item_id": "common_essence", "chance": 0.6}],
	"night_guard":
	[
		{"item_id": "hard_wood", "chance": 0.4},
		{"item_id": "worn_strap", "chance": 0.3},
		{"item_id": "metal_buckle", "chance": 0.15},
	],
	"hunter":
	[
		{"item_id": "hunter_gloves", "chance": 0.2},
		{"item_id": "reinforced_boots", "chance": 0.15},
		{"item_id": "leather_belt", "chance": 0.1},
	],
	"nature_guardian":
	[
		{"item_id": "nature_amulet", "chance": 0.3},
		{"item_id": "nature_ring", "chance": 0.2},
		{"item_id": "nature_bracelet", "chance": 0.2},
		{"item_id": "nature_earrings", "chance": 0.2},
	],
}


static func explore_twilight_plains(session, rng: RandomNumberGenerator) -> Dictionary:
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
	var result := _roll_exploration(period, rng.randf(), rng.randi(), rng.randi())
	session.advance_hours(1)
	if result.enemy_id.is_empty():
		session.last_activity = result.message
	return result


static func _roll_exploration(
	period_code: String, encounter_roll: float, enemy_roll: int, quiet_roll: int
) -> Dictionary:
	var region = RegionCatalogClass.get_definition("twilight_plains")
	if encounter_roll >= region.encounter_chance:
		var quiet_index := posmod(quiet_roll, region.quiet_events.size())
		return {"enemy_id": "", "message": region.quiet_events[quiet_index]}
	var table := region.encounters_for(period_code)
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
	for entry: Dictionary in LOOT_TABLES.get(enemy.enemy_id, []):
		if rng.randf() >= entry.chance:
			continue
		var item_id: String = entry.item_id
		session.player.inventory.add(item_id)
		loot_names.append(ItemCatalogClass.get_definition(item_id).display_name)
	var quest_update := QuestServiceClass.record_enemy_kill(session.quest_log, enemy.enemy_id)
	var summary := {
		"experience": enemy.experience_reward,
		"gold": gold,
		"levels_gained": levels_gained,
		"loot_names": loot_names,
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
