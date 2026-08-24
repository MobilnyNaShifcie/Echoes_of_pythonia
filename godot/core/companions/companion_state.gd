class_name CompanionState
extends RefCounted

const PlayerAttributesClass := preload("res://core/player/attributes.gd")
const PlayerEquipmentClass := preload("res://core/player/equipment.gd")
const EquipmentItemClass := preload("res://core/items/equipment_item.gd")

const TACTIC_AGGRESSIVE := "aggressive"
const TACTIC_BALANCED := "balanced"
const TACTIC_CAUTIOUS := "cautious"
const TACTIC_DEFENSIVE := "defensive"
const VALID_TACTICS := [
	TACTIC_AGGRESSIVE,
	TACTIC_BALANCED,
	TACTIC_CAUTIOUS,
	TACTIC_DEFENSIVE,
]

var companion_id := ""
var template_id := ""
var display_name := ""
var class_code := "none"
var level := 1
var experience := 0
var path_id := ""
var talents := {}
var attributes := PlayerAttributesClass.new()
var equipment := PlayerEquipmentClass.new()
var personal_instance_ids: Array[String] = []
var personal_storage: Array[EquipmentItemClass] = []
var relation := 0
var quest_arc_id := ""
var quest_stage := 0
var memories: Array[String] = []
var rifts_together := 0
var injury_until_day := 0
var dead := false
var active := false
var tactic := TACTIC_BALANCED
var current_hp := 1
var current_mana := 0
# Zero is a valid depleted resource. These flags distinguish it from the
# terminal-compatible sentinel used by a freshly generated or levelled build.
var hp_initialized := true
var mana_initialized := true
var dismissed_day := 0


func _init(
	initial_companion_id := "",
	initial_template_id := "",
	initial_display_name := "",
	initial_class_code := "none"
) -> void:
	companion_id = initial_companion_id
	template_id = initial_template_id
	display_name = initial_display_name
	class_code = initial_class_code


func is_injured(current_day: int) -> bool:
	return injury_until_day > current_day


func can_join_party(current_day: int) -> bool:
	return not dead and not is_injured(current_day)


func owns_item(item: EquipmentItemClass) -> bool:
	return item != null and item.instance_id in personal_instance_ids


static func tactic_display_name(tactic_code: String) -> String:
	match tactic_code:
		TACTIC_AGGRESSIVE:
			return "Agresywna"
		TACTIC_CAUTIOUS:
			return "Ostrożna"
		TACTIC_DEFENSIVE:
			return "Obronna"
		_:
			return "Zrównoważona"
