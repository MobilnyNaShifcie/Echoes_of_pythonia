class_name PlayerInventory
extends RefCounted

const EquipmentItemClass := preload("res://core/items/equipment_item.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")

var stacks := {}
var equipment_items: Array[EquipmentItemClass] = []


func add(
	item_id: String, quantity := 1, rng: RandomNumberGenerator = null, equipment_quality := "normal"
) -> bool:
	if quantity <= 0:
		return false
	var definition := ItemCatalogClass.get_definition(item_id)
	if definition == null:
		return false
	if definition.is_equipment():
		for _item_number in quantity:
			equipment_items.append(
				ItemCatalogClass.create_equipment_item(item_id, rng, equipment_quality)
			)
		return true
	stacks[item_id] = stacks.get(item_id, 0) + quantity
	return true


func add_equipment_instance(item: EquipmentItemClass) -> bool:
	if item == null or item.definition == null or not item.definition.is_equipment():
		return false
	equipment_items.append(item)
	return true


func count(item_id: String) -> int:
	var definition := ItemCatalogClass.get_definition(item_id)
	if definition == null:
		return 0
	if definition.is_equipment():
		return (
			equipment_items
			. filter(func(item: EquipmentItemClass) -> bool: return item.item_id == item_id)
			. size()
		)
	return stacks.get(item_id, 0)


func has(item_id: String, quantity := 1) -> bool:
	return quantity > 0 and count(item_id) >= quantity


func remove_item(item_id: String, quantity := 1) -> bool:
	if quantity <= 0 or count(item_id) < quantity:
		return false
	var definition := ItemCatalogClass.get_definition(item_id)
	if not definition.is_equipment():
		var remaining: int = stacks[item_id] - quantity
		if remaining == 0:
			stacks.erase(item_id)
		else:
			stacks[item_id] = remaining
		return true

	var remaining_to_remove := quantity
	for index in range(equipment_items.size() - 1, -1, -1):
		if equipment_items[index].item_id != item_id:
			continue
		equipment_items.remove_at(index)
		remaining_to_remove -= 1
		if remaining_to_remove == 0:
			break
	return true


func pop_equipment(index: int) -> EquipmentItemClass:
	if index < 0 or index >= equipment_items.size():
		return null
	return equipment_items.pop_at(index)


func is_empty() -> bool:
	return stacks.is_empty() and equipment_items.is_empty()
