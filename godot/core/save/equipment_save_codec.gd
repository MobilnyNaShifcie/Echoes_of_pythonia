class_name EquipmentSaveCodec
extends RefCounted

const EquipmentItemClass := preload("res://core/items/equipment_item.gd")
const EquipmentAffixClass := preload("res://core/items/equipment_affix.gd")
const EquipmentAffixServiceClass := preload("res://core/items/equipment_affix_service.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const PlayerEquipmentClass := preload("res://core/player/equipment.gd")

const VALID_SLOTS := [
	PlayerEquipmentClass.WEAPON,
	PlayerEquipmentClass.HEAD,
	PlayerEquipmentClass.CHEST,
	PlayerEquipmentClass.HANDS,
	PlayerEquipmentClass.FEET,
	PlayerEquipmentClass.BELT,
	PlayerEquipmentClass.NECKLACE,
	PlayerEquipmentClass.BRACELET,
	PlayerEquipmentClass.EARRINGS,
	PlayerEquipmentClass.RING,
	PlayerEquipmentClass.OFF_HAND,
]


static func serialize_equipment(slots: Dictionary) -> Dictionary:
	var result := {}
	for slot in slots:
		result[slot] = serialize_item(slots[slot])
	return result


static func serialize_items(items: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item: EquipmentItemClass in items:
		result.append(serialize_item(item))
	return result


static func serialize_inventory(inventory) -> Dictionary:
	return {
		"stacks": inventory.stacks.duplicate(true),
		"equipment_items": serialize_items(inventory.equipment_items),
	}


static func serialize_item(item: EquipmentItemClass) -> Dictionary:
	return {
		"item_id": item.item_id,
		"upgrade_level": item.upgrade_level,
		"instance_id": item.instance_id,
		"item_power": item.item_power,
		"affixes": serialize_affixes(item.affixes),
	}


static func serialize_affixes(affixes: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for affix in affixes:
		result.append({"affix_id": affix.affix_id, "tier": affix.tier, "value": affix.value})
	return result


static func deserialize_item(data: Dictionary) -> Dictionary:
	var item_id := str(data.get("item_id", ""))
	var definition = ItemCatalogClass.get_definition(item_id)
	if definition == null or not definition.is_equipment():
		return _failure("Zapis zawiera nieznany przedmiot wyposażenia.")
	if not _is_non_negative_integer(data.get("upgrade_level")):
		return _failure("Zapis zawiera nieprawidłowy poziom ulepszenia.")
	var upgrade_level := int(data.upgrade_level)
	if upgrade_level > EquipmentItemClass.MAX_UPGRADE_LEVEL:
		return _failure("Poziom ulepszenia przekracza dozwolone maksimum.")
	var instance_id := str(data.get("instance_id", ""))
	if instance_id.is_empty():
		return _failure("Przedmiot nie ma identyfikatora instancji.")
	if not _is_positive_integer(data.get("item_power")):
		return _failure("Przedmiot nie ma prawidłowego Item Power.")
	var item_power := int(data.item_power)
	if item_power != definition.item_power:
		return _failure("Item Power przedmiotu nie zgadza się z katalogiem.")
	if not data.get("affixes") is Array:
		return _failure("Przedmiot nie zawiera prawidłowej listy afiksów.")
	var affixes: Array[EquipmentAffixClass] = []
	for affix_data in data.affixes:
		if not affix_data is Dictionary or not _is_positive_integer(affix_data.get("tier")):
			return _failure("Zapis zawiera nieprawidłowy afiks.")
		var value = affix_data.get("value")
		if not value is int and not value is float:
			return _failure("Zapis zawiera nieprawidłową wartość afiksu.")
		affixes.append(
			EquipmentAffixClass.new(
				str(affix_data.get("affix_id", "")), int(affix_data.tier), float(value)
			)
		)
	var affix_error := EquipmentAffixServiceClass.validate(definition, affixes)
	if not affix_error.is_empty():
		return _failure("Nieprawidłowe afiksy przedmiotu: %s" % affix_error)
	var item := EquipmentItemClass.new(definition, upgrade_level, affixes, item_power)
	item.instance_id = instance_id
	return {"ok": true, "item": item}


static func restore_equipment(equipment: PlayerEquipmentClass, data: Dictionary) -> Dictionary:
	for slot_value in data:
		var slot := str(slot_value)
		if not slot in VALID_SLOTS or not data[slot] is Dictionary:
			return _failure("Zapis zawiera nieprawidłowy slot wyposażenia.")
		var item_result := deserialize_item(data[slot])
		if not item_result.ok:
			return item_result
		var item: EquipmentItemClass = item_result.item
		if item.slot != slot or equipment.get_item(slot) != null:
			return _failure("Przedmiot znajduje się w nieprawidłowym slocie.")
		equipment.equip_and_return_previous(item)
	return {"ok": true}


static func restore_items(data: Array) -> Dictionary:
	var restored: Array[EquipmentItemClass] = []
	for item_data in data:
		if not item_data is Dictionary:
			return _failure("Zapis zawiera nieprawidłowy przedmiot.")
		var item_result := deserialize_item(item_data)
		if not item_result.ok:
			return item_result
		restored.append(item_result.item)
	return {"ok": true, "items": restored}


static func _is_non_negative_integer(value) -> bool:
	return (value is int or value is float and value == floor(value)) and value >= 0


static func _is_positive_integer(value) -> bool:
	return _is_non_negative_integer(value) and int(value) > 0


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
