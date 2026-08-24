class_name PartyCombatant
extends RefCounted

const CompanionBuildServiceClass := preload("res://core/companions/companion_build_service.gd")
const CompanionStateClass := preload("res://core/companions/companion_state.gd")
const PlayerAttributesClass := preload("res://core/player/attributes.gd")
const PlayerProfileClass := preload("res://core/player/player_profile.gd")

var fighter_id := ""
var companion_id := ""
var display_name := ""
var profile: PlayerProfileClass
var companion: CompanionStateClass
var player_controlled := false
var defending := false
var downed_timer := 0
var removed := false
var lethal_downed := false


static func from_player(player: PlayerProfileClass):
	var fighter := PartyCombatant.new()
	fighter.fighter_id = "player"
	fighter.display_name = player.display_name
	fighter.profile = player
	fighter.player_controlled = true
	return fighter


static func from_companion(source: CompanionStateClass):
	var fighter := PartyCombatant.new()
	fighter.fighter_id = source.companion_id
	fighter.companion_id = source.companion_id
	fighter.display_name = source.display_name
	fighter.companion = source
	fighter.profile = _profile_from_companion(source)
	return fighter


func is_standing() -> bool:
	return not removed and downed_timer <= 0 and profile != null and profile.stats.current_hp > 0


func is_downed() -> bool:
	return not removed and downed_timer > 0


func sync_source_resources() -> void:
	if companion == null or profile == null:
		return
	CompanionBuildServiceClass.sync_resources(
		companion, profile.stats.current_hp, profile.stats.current_mana
	)


static func _profile_from_companion(source: CompanionStateClass) -> PlayerProfileClass:
	var actor := PlayerProfileClass.new(source.display_name)
	actor.level = source.level
	actor.experience = source.experience
	actor.character_class_code = source.class_code
	actor.attributes = _copy_attributes(source.attributes)
	actor.talent_ranks = source.talents.duplicate(true)
	actor.equipment = source.equipment
	if not source.path_id.is_empty():
		actor.unlocked_class_path_ids.append(source.path_id)
	actor.recalculate_stats()
	var resources := CompanionBuildServiceClass.resolved_resources(source)
	actor.stats.current_hp = int(resources.current_hp)
	actor.stats.current_mana = int(resources.current_mana)
	return actor


static func _copy_attributes(source: PlayerAttributesClass) -> PlayerAttributesClass:
	var result := PlayerAttributesClass.new()
	result.strength = source.strength
	result.vitality = source.vitality
	result.intelligence = source.intelligence
	result.dexterity = source.dexterity
	result.endurance = source.endurance
	result.luck = source.luck
	return result
