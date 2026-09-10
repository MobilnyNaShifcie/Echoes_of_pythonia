class_name CarryWeightService
extends RefCounted

const ItemCatalogClass := preload("res://core/items/item_catalog.gd")

const BASE_CAPACITY_KG := 50.0
const STRENGTH_KG_PER_POINT := 0.5
const ENDURANCE_KG_PER_POINT := 1.5
const UPGRADE_BONUSES_KG := [0.0, 10.0, 20.0, 35.0]
const UPGRADE_COSTS_GOLD := [0, 8000, 18000, 35000]
const UPGRADE_REQUIRED_RANKS := ["F", "E", "D", "C"]
const UPGRADE_NAMES := [
	"Brak ulepszenia",
	"Plecak Poszukiwacza I",
	"Plecak Poszukiwacza II",
	"Plecak Poszukiwacza III",
]
const GUILD_RANKS := [
	{"code": "F", "reputation": 0},
	{"code": "E", "reputation": 100},
	{"code": "D", "reputation": 300},
	{"code": "C", "reputation": 700},
	{"code": "B", "reputation": 1400},
	{"code": "A", "reputation": 2600},
	{"code": "S", "reputation": 4500},
]
const EQUIPMENT_SLOT_WEIGHT_KG := {
	"weapon": 3.5,
	"head": 2.0,
	"chest": 6.0,
	"hands": 1.0,
	"feet": 1.5,
	"belt": 0.5,
	"necklace": 0.2,
	"bracelet": 0.2,
	"earrings": 0.1,
	"ring": 0.1,
	"off_hand": 2.0,
}
const EQUIPMENT_TYPE_WEIGHT_KG := {
	"sword": 3.5,
	"bow": 2.5,
	"staff": 3.0,
	"fate_lance": 4.0,
	"shield": 4.0,
	"quiver": 1.0,
	"artifact": 1.0,
	"fate_dice": 0.5,
	"fate_cards": 0.4,
}
const STACK_UNIT_WEIGHT_KG := {
	"material": 0.05,
	"consumable": 0.30,
	"key": 0.20,
	"book": 0.50,
}


static func item_unit_weight(item_id: String) -> float:
	var definition = ItemCatalogClass.get_definition(item_id)
	if definition == null:
		return 0.0
	if definition.is_equipment():
		if EQUIPMENT_TYPE_WEIGHT_KG.has(definition.equipment_type):
			return float(EQUIPMENT_TYPE_WEIGHT_KG[definition.equipment_type])
		return float(EQUIPMENT_SLOT_WEIGHT_KG.get(definition.slot, 1.0))
	return float(STACK_UNIT_WEIGHT_KG.get(definition.category, 0.0))


static func stack_weight(item_id: String, quantity: int) -> float:
	if quantity <= 0:
		return 0.0
	return snappedf(item_unit_weight(item_id) * quantity, 0.01)


static func inventory_weight(inventory) -> float:
	var total := 0.0
	for item_id: String in inventory.stacks:
		total += stack_weight(item_id, int(inventory.stacks[item_id]))
	for item in inventory.equipment_items:
		total += item_unit_weight(item.item_id)
	return snappedf(total, 0.01)


static func carry_capacity(player) -> float:
	var level := clampi(player.carry_upgrade_level, 0, UPGRADE_BONUSES_KG.size() - 1)
	return snappedf(
		(
			BASE_CAPACITY_KG
			+ player.attributes.strength * STRENGTH_KG_PER_POINT
			+ player.attributes.endurance * ENDURANCE_KG_PER_POINT
			+ UPGRADE_BONUSES_KG[level]
		),
		0.01
	)


static func carry_status(player) -> Dictionary:
	var current := inventory_weight(player.inventory)
	var capacity := carry_capacity(player)
	var ratio := 0.0 if capacity <= 0.0 else current / capacity
	var code := "free"
	var display_name := "Swobodny"
	if current > capacity + 0.000000001:
		code = "overloaded"
		display_name = "Przeciążony"
	elif ratio >= 0.75:
		code = "burdened"
		display_name = "Obciążony"
	return {
		"code": code,
		"display_name": display_name,
		"current_kg": current,
		"capacity_kg": capacity,
		"ratio": ratio,
		"overloaded": code == "overloaded",
	}


static func guild_rank_for_reputation(reputation: int) -> String:
	var result := "F"
	for rank: Dictionary in GUILD_RANKS:
		if reputation >= int(rank.reputation):
			result = rank.code
		else:
			break
	return result


static func next_upgrade(player) -> Dictionary:
	var next_level: int = player.carry_upgrade_level + 1
	if next_level >= UPGRADE_BONUSES_KG.size():
		return {}
	return {
		"level": next_level,
		"name": UPGRADE_NAMES[next_level],
		"bonus_kg": UPGRADE_BONUSES_KG[next_level],
		"gold": UPGRADE_COSTS_GOLD[next_level],
		"required_rank": UPGRADE_REQUIRED_RANKS[next_level],
	}


static func purchase_upgrade(player, guild_reputation: int) -> Dictionary:
	var upgrade := next_upgrade(player)
	if upgrade.is_empty():
		return {"ok": false, "message": "Masz już najlepszy plecak Poszukiwacza."}
	var current_rank := guild_rank_for_reputation(guild_reputation)
	if _rank_index(current_rank) < _rank_index(upgrade.required_rank):
		return {
			"ok": false,
			"message":
			"Wymagana ranga Gildii: %s. Twoja ranga: %s." % [upgrade.required_rank, current_rank],
		}
	if player.gold < int(upgrade.gold):
		return {
			"ok": false,
			"message": "Brakuje złota. Potrzeba %d, masz %d." % [upgrade.gold, player.gold],
		}
	player.gold -= int(upgrade.gold)
	player.carry_upgrade_level = int(upgrade.level)
	return {"ok": true, "message": "Kupiono: %s." % upgrade.name, "upgrade": upgrade}


static func _rank_index(code: String) -> int:
	for index in GUILD_RANKS.size():
		if GUILD_RANKS[index].code == code:
			return index
	return -1
