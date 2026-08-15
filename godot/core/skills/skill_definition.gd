class_name SkillDefinition
extends Resource

@export var skill_id := ""
@export var display_name := ""
@export var character_class_code := ""
@export var unlock_level := 0
@export var mana_cost := 0
@export_multiline var description := ""
@export var scaling := "none"
@export var multiplier := 0.0
@export var damage_type := "physical"
@export var hits := 0
@export var effect := ""
@export var effect_value := 0
@export var effect_duration := 0
@export var guaranteed_hit := false
@export var required_weapon_type := ""
@export var required_offhand_type := ""
@export var execution_kind := "generic"
@export var unlock_source := "level"
@export var required_talent_id := ""
@export var hunter_technique := ""
@export var special_armor_penetration := 0.0


func is_offensive() -> bool:
	return (
		hits > 0
		or effect == "delayed_rain"
		or (effect.begins_with("fate_") and effect != "fate_feint")
	)


func is_combat_ready() -> bool:
	return execution_kind in ["generic", "fate"]
