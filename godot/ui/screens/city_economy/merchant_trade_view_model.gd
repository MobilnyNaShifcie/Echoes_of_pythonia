class_name MerchantTradeViewModel
extends RefCounted

const EconomyServiceClass := preload("res://core/economy/economy_service.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const ItemGridLayoutClass := preload("res://ui/components/inventory_grid/item_grid_layout.gd")


static func build_player_grid_entries(inventory) -> Array[Dictionary]:
	var grid_entries: Array[Dictionary] = []
	var stack_ids: Array[String] = []
	for raw_item_id in inventory.stacks.keys():
		if int(inventory.stacks[raw_item_id]) > 0:
			stack_ids.append(str(raw_item_id))
	stack_ids.sort_custom(
		func(first: String, second: String) -> bool:
			return (
				ItemCatalogClass.get_definition(first).display_name
				< ItemCatalogClass.get_definition(second).display_name
			)
	)
	for item_id: String in stack_ids:
		var definition = ItemCatalogClass.get_definition(item_id)
		(
			grid_entries
			. append(
				{
					"title": definition.display_name,
					"placeholder": _initials(definition.display_name),
					"icon": definition.icon,
					"rarity": definition.rarity,
					"quantity": inventory.count(item_id),
					"tooltip": "%s\n\n%s" % [definition.display_name, definition.description],
					"metadata": {"kind": "player_preview", "item_id": item_id},
					"footprint":
					ItemGridLayoutClass.footprint_for(definition.category, definition.slot),
				}
			)
		)
	for item in inventory.equipment_items:
		var definition = item.definition
		(
			grid_entries
			. append(
				{
					"title": item.formatted_name(),
					"placeholder": _initials(definition.display_name),
					"icon": definition.icon,
					"rarity": definition.rarity,
					"quantity": 0,
					"tooltip": "%s\n\n%s" % [item.formatted_name(), definition.description],
					"metadata": {"kind": "player_preview", "instance_id": item.instance_id},
					"footprint":
					ItemGridLayoutClass.footprint_for(definition.category, definition.slot),
				}
			)
		)
	return grid_entries


static func price_summary(entry: Dictionary, quantity: int) -> String:
	match str(entry.kind):
		"merchant_buy":
			return "Cena: %d złota" % (int(entry.price) * quantity)
		"merchant_sell_stacks":
			return (
				"Wartość sprzedaży: %d złota"
				% (EconomyServiceClass.get_stack_sell_price(entry.item_id) * quantity)
			)
		"merchant_sell_equipment":
			return (
				"Wartość sprzedaży: %d złota"
				% EconomyServiceClass.get_equipment_sell_price(entry.item)
			)
	return ""


static func _initials(display_name: String) -> String:
	var words := display_name.split(" ", false)
	var result := ""
	for word in words:
		result += word.left(1).to_upper()
	return result.left(3)
