class_name ItemDefinition
extends Resource

@export var item_id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var category := "equipment"
@export var rarity := "common"
@export var slot := ""
@export var item_power := 0
@export var required_level := 0
@export var attack := 0
@export var defense := 0
@export var max_hp := 0
@export var dodge := 0.0
@export var max_mana := 0
@export var magic_power := 0


func is_equipment() -> bool:
	return category == "equipment" and not slot.is_empty()
