class_name EnemyCatalog
extends RefCounted

const EnemyClass := preload("res://core/combat/enemy.gd")
const RegionalEnemyCatalogClass := preload("res://core/combat/regional_enemy_catalog.gd")
const DATA := {
	"prologue_scarecrow":
	{
		"display_name": "Przeklęty Strach na Wróble",
		"max_hp": 7,
		"attack": 1,
		"defense": 0,
		"dodge": 0.0,
		"experience_reward": 0,
		"gold_min": 0,
		"gold_max": 0,
		"rank": "story",
	},
	"wild_dog":
	{
		"display_name": "Dziki Pies",
		"max_hp": 6,
		"attack": 2,
		"defense": 0,
		"dodge": 0.0,
		"experience_reward": 8,
		"gold_min": 5,
		"gold_max": 5,
		"extra_attack_chance": 0.2,
	},
	"slime":
	{
		"display_name": "Slime",
		"max_hp": 8,
		"attack": 2,
		"defense": 1,
		"dodge": 0.0,
		"experience_reward": 10,
		"gold_min": 8,
		"gold_max": 8,
	},
	"wolf":
	{
		"display_name": "Wilk",
		"max_hp": 9,
		"attack": 3,
		"defense": 1,
		"dodge": 5.0,
		"experience_reward": 14,
		"gold_min": 10,
		"gold_max": 10,
	},
	"boar":
	{
		"display_name": "Spaczony Dzik",
		"max_hp": 12,
		"attack": 4,
		"defense": 1,
		"dodge": 0.0,
		"experience_reward": 18,
		"gold_min": 16,
		"gold_max": 16,
		"first_attack_bonus": 2,
	},
	"bandit":
	{
		"display_name": "Bandyta",
		"max_hp": 11,
		"attack": 4,
		"defense": 1,
		"dodge": 5.0,
		"experience_reward": 22,
		"gold_min": 20,
		"gold_max": 20,
		"special_name": "Sprytne Cięcie",
		"special_chance": 0.2,
		"special_attack_bonus": 1,
	},
	"cursed_scarecrow":
	{
		"display_name": "Przeklęty Strach na Wróble",
		"max_hp": 14,
		"attack": 3,
		"defense": 2,
		"dodge": 0.0,
		"experience_reward": 26,
		"gold_min": 30,
		"gold_max": 30,
		"physical_damage_reduction": 1,
		"special_name": "Płonąca Słoma",
		"special_chance": 0.2,
		"special_attack_bonus": 2,
		"special_damage_type": "fire",
	},
	"plains_spirit":
	{
		"display_name": "Duch Równin",
		"max_hp": 10,
		"attack": 4,
		"defense": 1,
		"dodge": 25.0,
		"experience_reward": 24,
		"gold_min": 20,
		"gold_max": 20,
	},
	"night_guard":
	{
		"display_name": "Nocny Strażnik",
		"max_hp": 14,
		"attack": 4,
		"defense": 1,
		"dodge": 0.0,
		"experience_reward": 28,
		"gold_min": 35,
		"gold_max": 35,
	},
	"hunter":
	{
		"display_name": "Myśliwy",
		"max_hp": 12,
		"attack": 5,
		"defense": 1,
		"dodge": 10.0,
		"experience_reward": 35,
		"gold_min": 50,
		"gold_max": 50,
		"special_name": "Celny Strzał",
		"special_chance": 0.25,
		"special_attack_bonus": 2,
	},
	"nature_guardian":
	{
		"display_name": "Strażnik Natury",
		"max_hp": 24,
		"attack": 6,
		"defense": 2,
		"dodge": 5.0,
		"experience_reward": 100,
		"gold_min": 100,
		"gold_max": 180,
		"rank": "miniboss",
		"special_name": "Gniew Korzeni",
		"special_chance": 0.25,
		"special_attack_bonus": 2,
		"special_damage_type": "earth",
	},
}


static func create_enemy(enemy_id: String) -> EnemyClass:
	var data := get_data(enemy_id)
	if data.is_empty():
		return null
	data.enemy_id = enemy_id
	return EnemyClass.new(data)


static func display_name_for(enemy_id: String) -> String:
	return get_data(enemy_id).get("display_name", enemy_id)


static func get_data(enemy_id: String) -> Dictionary:
	if DATA.has(enemy_id):
		return DATA[enemy_id].duplicate(true)
	return RegionalEnemyCatalogClass.DATA.get(enemy_id, {}).duplicate(true)


static func has_enemy(enemy_id: String) -> bool:
	return DATA.has(enemy_id) or RegionalEnemyCatalogClass.DATA.has(enemy_id)
