class_name EconomyService
extends RefCounted

const EquipmentItemClass := preload("res://core/items/equipment_item.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const UpgradeServiceClass := preload("res://core/economy/upgrade_service.gd")

const MERCHANT_STOCK := [
	{"item_id": "weak_healing_potion", "buy_price": 25},
	{"item_id": "weak_leather", "buy_price": 30},
	{"item_id": "old_clothes", "buy_price": 20},
	{"item_id": "whetstone", "buy_price": 60},
	{"item_id": "grinding_stone", "buy_price": 160},
	{"item_id": "grandmaster_elixir", "buy_price": 2500},
]
const MATERIAL_SELL_BASE := {
	"common": 4, "uncommon": 10, "rare": 25, "epic": 60, "legendary": 150, "mythic": 350
}
const CONSUMABLE_SELL_BASE := {
	"common": 8,
	"uncommon": 18,
	"rare": 40,
	"epic": 90,
	"legendary": 220,
	"mythic": 500,
}
const EQUIPMENT_SELL_BASE := {
	"common": 15,
	"uncommon": 30,
	"rare": 60,
	"epic": 150,
	"legendary": 400,
	"mythic": 1000,
}


static func get_stock() -> Array[Dictionary]:
	var stock: Array[Dictionary] = []
	for entry: Dictionary in MERCHANT_STOCK:
		stock.append(entry.duplicate(true))
	return stock


static func get_stock_entry(item_id: String) -> Dictionary:
	for entry: Dictionary in MERCHANT_STOCK:
		if entry.item_id == item_id:
			return entry
	return {}


static func buy_item(player, item_id: String, quantity := 1) -> Dictionary:
	var entry := get_stock_entry(item_id)
	if entry.is_empty():
		return {"ok": false, "message": "Tego przedmiotu nie ma w ofercie Orena."}
	if quantity <= 0:
		return {"ok": false, "message": "Ilość zakupu musi być większa od zera."}
	var total_price := int(entry.buy_price) * quantity
	if player.gold < total_price:
		return {
			"ok": false,
			"message": "Brakuje złota. Potrzeba %d, masz %d." % [total_price, player.gold],
		}
	player.gold -= total_price
	player.inventory.add(item_id, quantity)
	return {
		"ok": true,
		"message":
		(
			"Kupiono: %s ×%d za %d złota."
			% [ItemCatalogClass.get_definition(item_id).display_name, quantity, total_price]
		),
		"gold": total_price,
	}


static func get_stack_sell_price(item_id: String) -> int:
	var definition = ItemCatalogClass.get_definition(item_id)
	if definition == null:
		return -1
	if definition.category == "material":
		return int(MATERIAL_SELL_BASE.get(definition.rarity, -1))
	if definition.category == "consumable":
		return int(CONSUMABLE_SELL_BASE.get(definition.rarity, -1))
	return -1


static func get_equipment_sell_price(item: EquipmentItemClass) -> int:
	if item == null or item.definition == null or not item.definition.is_equipment():
		return -1
	var stats := UpgradeServiceClass.effective_stats(item)
	var base := int(EQUIPMENT_SELL_BASE.get(item.definition.rarity, 0))
	var stat_value := (
		int(stats.attack) * 12
		+ int(stats.defense) * 10
		+ int(stats.max_hp) * 2
		+ int(stats.max_mana) * 2
		+ int(float(stats.dodge) * 10.0)
	)
	var upgrade_multiplier := 1.0 + item.upgrade_level * 0.15
	return maxi(1, int((base + stat_value) * upgrade_multiplier))


static func sell_stack(player, item_id: String, quantity := 1) -> Dictionary:
	if quantity <= 0:
		return {"ok": false, "message": "Ilość sprzedaży musi być większa od zera."}
	if not player.inventory.has(item_id, quantity):
		return {"ok": false, "message": "Nie posiadasz tylu sztuk tego przedmiotu."}
	var unit_price := get_stack_sell_price(item_id)
	if unit_price < 0:
		return {"ok": false, "message": "Tego przedmiotu nie można sprzedać jako stosu."}
	var total_price := unit_price * quantity
	player.inventory.remove_item(item_id, quantity)
	player.add_gold(total_price)
	return {
		"ok": true,
		"message":
		(
			"Sprzedano: %s ×%d za %d złota."
			% [ItemCatalogClass.get_definition(item_id).display_name, quantity, total_price]
		),
		"gold": total_price,
	}


static func sell_equipment(player, inventory_index: int) -> Dictionary:
	if inventory_index < 0 or inventory_index >= player.inventory.equipment_items.size():
		return {"ok": false, "message": "Nieprawidłowy przedmiot wyposażenia."}
	var item: EquipmentItemClass = player.inventory.equipment_items[inventory_index]
	var price := get_equipment_sell_price(item)
	if price < 0:
		return {"ok": false, "message": "Tego wyposażenia nie można sprzedać."}
	player.inventory.pop_equipment(inventory_index)
	player.add_gold(price)
	return {
		"ok": true,
		"message": "Sprzedano: %s za %d złota." % [item.formatted_name(), price],
		"gold": price,
		"item": item,
	}
