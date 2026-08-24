class_name PartyState
extends RefCounted

const CompanionStateClass := preload("res://core/companions/companion_state.gd")
const CompanionCandidateClass := preload("res://core/companions/companion_candidate.gd")
const PartyMessageClass := preload("res://core/companions/party_message.gd")
const FallenCompanionClass := preload("res://core/companions/fallen_companion.gd")

var companions: Array[CompanionStateClass] = []
var dismissed_companions: Array[CompanionStateClass] = []
var candidates_day := 0
var candidates: Array[CompanionCandidateClass] = []
var messages: Array[PartyMessageClass] = []
var last_message_day := 0
var seen_banter: Array[String] = []
var fallen: Array[FallenCompanionClass] = []


func living_companions() -> Array[CompanionStateClass]:
	return companions.filter(
		func(companion: CompanionStateClass) -> bool: return not companion.dead
	)


func active_companions(current_day := 0) -> Array[CompanionStateClass]:
	return companions.filter(
		func(companion: CompanionStateClass) -> bool:
			return companion.active and companion.can_join_party(current_day)
	)


func companion_by_id(companion_id: String) -> CompanionStateClass:
	for companion: CompanionStateClass in companions:
		if companion.companion_id == companion_id:
			return companion
	return null


func unread_messages() -> int:
	return messages.filter(func(message: PartyMessageClass) -> bool: return not message.read).size()
