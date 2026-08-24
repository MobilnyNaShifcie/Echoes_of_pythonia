class_name HunterComboDefinition
extends RefCounted

var combo_id := ""
var display_name := ""
var sequence: Array[String] = []
var description := ""
var multiplier := 0.0
var damage_type := "physical"
var armor_penetration := 0.0
var bleed_damage := 0
var bleed_duration := 0
var consumes_explosive_charges := false


func _init(data: Dictionary) -> void:
	combo_id = str(data.get("combo_id", ""))
	display_name = str(data.get("display_name", combo_id))
	sequence.assign(data.get("sequence", []))
	description = str(data.get("description", ""))
	multiplier = float(data.get("multiplier", 0.0))
	damage_type = str(data.get("damage_type", "physical"))
	armor_penetration = float(data.get("armor_penetration", 0.0))
	bleed_damage = int(data.get("bleed_damage", 0))
	bleed_duration = int(data.get("bleed_duration", 0))
	consumes_explosive_charges = bool(data.get("consumes_explosive_charges", false))
