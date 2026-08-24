class_name ItemDefinition
extends Resource

@export var item_id := ""
@export var display_name := ""
@export_multiline var description := ""
@export var icon: Texture2D
@export var category := "equipment"
@export var rarity := "common"
@export var stackable := false
@export var slot := ""
@export var equipment_type := ""
@export var item_power := 0
@export var required_level := 0
@export var required_class_code := ""
@export var required_class_name := ""
@export var attack := 0
@export var defense := 0
@export var max_hp := 0
@export var dodge := 0.0
@export var max_mana := 0
@export var magic_power := 0
@export var heal_hp := 0
@export var heal_hp_percent := 0.0
@export var restore_mana := 0
@export var restore_mana_percent := 0.0
@export var set_id := ""
@export var class_effect_id := ""
@export var class_bonus_class_code := ""
@export var class_bonus_attack := 0
@export var class_bonus_defense := 0
@export var class_bonus_max_hp := 0
@export var class_bonus_max_mana := 0
@export var class_bonus_dodge := 0.0
@export var fire_resistance := 0
@export var wind_resistance := 0
@export var frost_resistance := 0
@export var earth_resistance := 0
@export var water_resistance := 0


func is_equipment() -> bool:
	return category == "equipment" and not slot.is_empty()
