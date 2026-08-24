class_name CompanionEquipmentService
extends RefCounted

const CompanionStateClass := preload("res://core/companions/companion_state.gd")


static func equip_player_item(
	player, companion: CompanionStateClass, inventory_index: int
) -> Dictionary:
	if player == null or companion == null:
		return _failure("Brak gracza albo kompana.")
	if inventory_index < 0 or inventory_index >= player.inventory.equipment_items.size():
		return _failure("Nieprawidłowy indeks wyposażenia.")
	var item = player.inventory.equipment_items[inventory_index]
	var error := get_equip_error(companion, item)
	if not error.is_empty():
		return _failure(error)

	item = player.inventory.pop_equipment(inventory_index)
	var previous = companion.equipment.equip_and_return_previous(item)
	if previous != null:
		if companion.owns_item(previous):
			companion.personal_storage.append(previous)
		else:
			player.inventory.add_equipment_instance(previous)
	return {
		"ok": true,
		"item": item,
		"previous": previous,
		"message": "%s korzysta teraz z: %s." % [companion.display_name, item.formatted_name()],
	}


static func remove_player_item(player, companion: CompanionStateClass, slot: String) -> Dictionary:
	if player == null or companion == null:
		return _failure("Brak gracza albo kompana.")
	var item = companion.equipment.get_item(slot)
	if item == null:
		return _failure("Ten slot jest pusty.")
	if companion.owns_item(item):
		return _failure("To osobisty przedmiot kompana. Nie możesz go zabrać.")
	var removed = companion.equipment.unequip(slot)
	player.inventory.add_equipment_instance(removed)
	_restore_personal_slot(companion, slot)
	return {
		"ok": true,
		"item": removed,
		"message": "Przedmiot wrócił do plecaka: %s." % removed.formatted_name(),
	}


static func return_player_owned_gear(player, companion: CompanionStateClass) -> Dictionary:
	if player == null or companion == null:
		return _failure("Brak gracza albo kompana.")
	var returned := []
	var occupied_slots: Array = companion.equipment.slots.keys()
	for slot_value in occupied_slots:
		var slot := str(slot_value)
		var item = companion.equipment.get_item(slot)
		if item == null or companion.owns_item(item):
			continue
		var removed = companion.equipment.unequip(slot)
		player.inventory.add_equipment_instance(removed)
		returned.append(removed)
		_restore_personal_slot(companion, slot)
	return {
		"ok": true,
		"returned_items": returned,
		"message": "Zwrócono przedmioty gracza: %d." % returned.size(),
	}


static func get_equip_error(companion: CompanionStateClass, item) -> String:
	if item == null or item.definition == null or not item.definition.is_equipment():
		return "Tego przedmiotu nie można przekazać kompanowi."
	if item.definition.required_level > companion.level:
		return "Kompan potrzebuje poziomu %d." % item.definition.required_level
	if (
		not item.definition.required_class_code.is_empty()
		and item.definition.required_class_code != companion.class_code
	):
		return "Ten przedmiot wymaga klasy: %s." % item.definition.required_class_name
	return ""


static func _restore_personal_slot(companion: CompanionStateClass, slot: String) -> void:
	var candidates := companion.personal_storage.filter(
		func(item) -> bool: return item != null and item.slot == slot
	)
	if candidates.is_empty():
		return
	candidates.sort_custom(
		func(first, second) -> bool:
			if first.item_power != second.item_power:
				return first.item_power > second.item_power
			return first.upgrade_level > second.upgrade_level
	)
	var personal_item = candidates[0]
	companion.personal_storage.erase(personal_item)
	companion.equipment.equip_and_return_previous(personal_item)


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
