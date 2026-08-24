class_name LootPresentation
extends VBoxContainer

const ItemCatalogClass := preload("res://core/items/item_catalog.gd")

@onready var loot_grid: InventoryGridView = %LootGrid


func set_drops(drops: Array) -> void:
	var entries: Array[Dictionary] = []
	for drop: Dictionary in drops:
		var item_id := str(drop.get("item_id", ""))
		var definition = ItemCatalogClass.get_definition(item_id)
		if definition == null:
			continue
		var quantity := maxi(1, int(drop.get("quantity", 1)))
		(
			entries
			. append(
				{
					"title": definition.display_name,
					"placeholder": definition.display_name.left(2).to_upper(),
					"icon": definition.icon,
					"rarity": definition.rarity,
					"quantity": quantity,
					"tooltip":
					"%s ×%d\n\n%s" % [definition.display_name, quantity, definition.description],
					"metadata": {"kind": "loot", "item_id": item_id},
					"footprint": Vector2i.ONE,
				}
			)
		)
	loot_grid.set_entries(entries)
	visible = not entries.is_empty()
