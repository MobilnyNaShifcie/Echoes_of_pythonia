class_name UpgradeService
extends RefCounted

const EquipmentItemClass := preload("res://core/items/equipment_item.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")

const MAX_UPGRADE_LEVEL := 10
const SCALING_PROGRESS := [0.0, 0.07, 0.14, 0.22, 0.31, 0.41, 0.52, 0.64, 0.76, 0.88, 1.0]
const STAT_MAX_BONUS := {
	"attack": 0.90,
	"defense": 0.60,
	"max_hp": 0.85,
	"max_mana": 0.85,
	"dodge": 1.00,
}
const BASE_GOLD_COSTS := [25, 50, 75, 100, 150, 225, 400, 650, 950, 1400]
const ITEM_POWER_GOLD_MULTIPLIER := {1: 1.0, 2: 1.1, 3: 1.25, 4: 1.45, 5: 1.7, 6: 2.0, 7: 2.35}
const MATERIAL_PROFILE_BY_ITEM_POWER := {
	1: {"regional": "common_essence", "elite": "common_essence", "boss": "spark_of_life"},
	2: {"regional": "spider_silk", "elite": "blackwood_heart", "boss": "blackwood_heart"},
	3:
	{
		"regional": "sunken_plate",
		"elite": "silentwater_heart",
		"boss": "silentwater_heart",
	},
	5: {"regional": "salamander_scale", "elite": "hearth_core", "boss": "azhar_sigil"},
	6: {"regional": "ice_chitin", "elite": "cursed_compass", "boss": "leviathan_scale"},
}


static func effective_stats(item: EquipmentItemClass) -> Dictionary:
	var definition = item.definition
	var level := item.upgrade_level
	return {
		"attack":
		(
			definition.attack
			+ _scaled_integer_bonus(definition.attack, level, "attack", int(level / 2.0))
		),
		"defense":
		(
			definition.defense
			+ _scaled_integer_bonus(definition.defense, level, "defense", int(level / 3.0))
		),
		"max_hp":
		definition.max_hp + _scaled_integer_bonus(definition.max_hp, level, "max_hp", level * 2),
		"dodge": definition.dodge + _scaled_dodge_bonus(definition.dodge, level),
		"max_mana":
		(
			definition.max_mana
			+ _scaled_integer_bonus(definition.max_mana, level, "max_mana", level * 2)
		),
		"magic_power":
		(
			definition.magic_power
			+ _scaled_integer_bonus(definition.magic_power, level, "attack", int(level / 2.0))
		),
		"elemental_resistances":
		{
			"fire": definition.fire_resistance,
			"wind": definition.wind_resistance,
			"frost": definition.frost_resistance,
			"earth": definition.earth_resistance,
			"water": definition.water_resistance,
		},
	}


static func get_upgrade_cost(current_level: int, item: EquipmentItemClass) -> Dictionary:
	if current_level < 0 or current_level >= MAX_UPGRADE_LEVEL:
		return {"ok": false, "message": "Tego poziomu nie można dalej ulepszyć."}
	var item_power := maxi(1, item.item_power)
	var profile: Dictionary = MATERIAL_PROFILE_BY_ITEM_POWER.get(
		item_power, MATERIAL_PROFILE_BY_ITEM_POWER[1]
	)
	var materials := _materials_for_level(current_level, profile)
	var multiplier := float(ITEM_POWER_GOLD_MULTIPLIER.get(item_power, 1.0))
	var gold := maxi(25, roundi((BASE_GOLD_COSTS[current_level] * multiplier) / 25.0) * 25)
	return {"ok": true, "gold": gold, "materials": materials}


static func get_upgrade_plan(item: EquipmentItemClass, levels: int) -> Dictionary:
	if item == null or item.definition == null:
		return {"ok": false, "message": "Nie wybrano wyposażenia."}
	if levels <= 0:
		return {"ok": false, "message": "Liczba poziomów musi być dodatnia."}
	if item.upgrade_level + levels > MAX_UPGRADE_LEVEL:
		return {
			"ok": false,
			"message": "Przedmiot można ulepszyć maksymalnie do +%d." % MAX_UPGRADE_LEVEL,
		}
	var gold := 0
	var materials := {}
	for level in range(item.upgrade_level, item.upgrade_level + levels):
		var cost := get_upgrade_cost(level, item)
		gold += int(cost.gold)
		for item_id: String in cost.materials:
			materials[item_id] = materials.get(item_id, 0) + int(cost.materials[item_id])
	return {
		"ok": true,
		"start_level": item.upgrade_level,
		"target_level": item.upgrade_level + levels,
		"levels": levels,
		"gold": gold,
		"materials": materials,
	}


static func get_upgrade_error(player, item: EquipmentItemClass, levels: int) -> String:
	var plan := get_upgrade_plan(item, levels)
	if not plan.ok:
		return plan.message
	if player.gold < int(plan.gold):
		return "Brakuje złota. Potrzeba %d, masz %d." % [plan.gold, player.gold]
	for item_id: String in plan.materials:
		var required := int(plan.materials[item_id])
		var owned: int = player.inventory.count(item_id)
		if owned < required:
			return (
				"Brakuje materiału: %s %d/%d."
				% [
					ItemCatalogClass.get_definition(item_id).display_name,
					owned,
					required,
				]
			)
	return ""


static func upgrade_item(player, item: EquipmentItemClass, levels := 1) -> Dictionary:
	var error := get_upgrade_error(player, item, levels)
	if not error.is_empty():
		return {"ok": false, "message": error}
	var plan := get_upgrade_plan(item, levels)
	for item_id: String in plan.materials:
		player.inventory.remove_item(item_id, int(plan.materials[item_id]))
	player.gold -= int(plan.gold)
	item.upgrade_level = int(plan.target_level)
	player.recalculate_stats()
	return {
		"ok": true,
		"message": "Ulepszono %s do +%d." % [item.display_name, item.upgrade_level],
		"plan": plan,
	}


static func max_affordable_levels(player, item: EquipmentItemClass) -> int:
	var affordable := 0
	for levels in range(1, MAX_UPGRADE_LEVEL - item.upgrade_level + 1):
		if not get_upgrade_error(player, item, levels).is_empty():
			break
		affordable = levels
	return affordable


static func _scaled_integer_bonus(
	base_value: int, level: int, stat_name: String, legacy_bonus: int
) -> int:
	if base_value <= 0:
		return 0
	var scaled := roundi(base_value * float(STAT_MAX_BONUS[stat_name]) * SCALING_PROGRESS[level])
	return maxi(legacy_bonus, scaled)


static func _scaled_dodge_bonus(base_value: float, level: int) -> float:
	if base_value <= 0.0:
		return 0.0
	var scaled: float = base_value * float(STAT_MAX_BONUS.dodge) * SCALING_PROGRESS[level]
	return maxf(level * 0.5, scaled)


static func _materials_for_level(current_level: int, profile: Dictionary) -> Dictionary:
	var materials := {}
	match current_level:
		0, 1:
			_add_material(materials, "whetstone", 1)
		2:
			_add_material(materials, "whetstone", 2)
		3:
			_add_material(materials, "grinding_stone", 1)
			_add_material(materials, profile.regional, 1)
		4:
			_add_material(materials, "grinding_stone", 1)
			_add_material(materials, profile.regional, 2)
		5:
			_add_material(materials, "grinding_stone", 2)
			_add_material(materials, profile.regional, 2)
			_add_material(materials, "common_essence", 1)
		6:
			_add_material(materials, "grinding_stone", 2)
			_add_material(materials, profile.regional, 3)
			_add_material(materials, "common_essence", 2)
		7:
			_add_material(materials, "grinding_stone", 2)
			_add_material(materials, profile.regional, 2)
			_add_material(materials, profile.elite, 1)
		8:
			_add_material(materials, "grinding_stone", 3)
			_add_material(materials, profile.regional, 2)
			_add_material(materials, profile.elite, 2)
		9:
			_add_material(materials, "grinding_stone", 4)
			_add_material(materials, profile.elite, 1)
			_add_material(materials, profile.boss, 1)
	return materials


static func _add_material(materials: Dictionary, item_id: String, quantity: int) -> void:
	if quantity > 0:
		materials[item_id] = materials.get(item_id, 0) + quantity
