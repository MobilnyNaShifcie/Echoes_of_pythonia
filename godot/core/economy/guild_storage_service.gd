class_name GuildStorageService
extends RefCounted

const GuildStorageClass := preload("res://core/economy/guild_storage.gd")


static func deposit_stack(
	player, storage: GuildStorageClass, item_id: String, quantity: int
) -> Dictionary:
	if quantity <= 0:
		return {"ok": false, "message": "Ilość musi być większa od zera."}
	if not player.inventory.has(item_id, quantity):
		return {"ok": false, "message": "Nie masz tylu sztuk tego przedmiotu."}
	if not storage.can_accept_stack(item_id):
		return {"ok": false, "message": "Magazyn Gildii jest pełny."}
	player.inventory.remove_item(item_id, quantity)
	storage.inventory.add(item_id, quantity)
	return {"ok": true, "message": "Odłożono do magazynu: ×%d." % quantity}


static func withdraw_stack(
	player, storage: GuildStorageClass, item_id: String, quantity: int
) -> Dictionary:
	if quantity <= 0:
		return {"ok": false, "message": "Ilość musi być większa od zera."}
	if not storage.inventory.has(item_id, quantity):
		return {"ok": false, "message": "W magazynie nie ma tylu sztuk tego przedmiotu."}
	storage.inventory.remove_item(item_id, quantity)
	player.inventory.add(item_id, quantity)
	return {"ok": true, "message": "Odebrano z magazynu: ×%d." % quantity}


static func deposit_equipment(player, storage: GuildStorageClass, index: int) -> Dictionary:
	if index < 0 or index >= player.inventory.equipment_items.size():
		return {"ok": false, "message": "Nieprawidłowy przedmiot wyposażenia."}
	if not storage.can_accept_equipment():
		return {"ok": false, "message": "Magazyn Gildii jest pełny."}
	var item = player.inventory.pop_equipment(index)
	storage.inventory.add_equipment_instance(item)
	return {"ok": true, "message": "Odłożono: %s." % item.formatted_name(), "item": item}


static func withdraw_equipment(player, storage: GuildStorageClass, index: int) -> Dictionary:
	if index < 0 or index >= storage.inventory.equipment_items.size():
		return {"ok": false, "message": "Nieprawidłowy przedmiot w magazynie."}
	var item = storage.inventory.pop_equipment(index)
	player.inventory.add_equipment_instance(item)
	return {"ok": true, "message": "Odebrano: %s." % item.formatted_name(), "item": item}
