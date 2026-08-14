class_name GuildStorage
extends RefCounted

const PlayerInventoryClass := preload("res://core/player/inventory.gd")
const CAPACITY_SLOTS := 200

var inventory := PlayerInventoryClass.new()

var used_slots: int:
	get:
		return inventory.stacks.size() + inventory.equipment_items.size()

var free_slots: int:
	get:
		return maxi(0, CAPACITY_SLOTS - used_slots)


func can_accept_stack(item_id: String) -> bool:
	return inventory.stacks.has(item_id) or used_slots < CAPACITY_SLOTS


func can_accept_equipment() -> bool:
	return used_slots < CAPACITY_SLOTS
