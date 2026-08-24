class_name CompanionCasualtyService
extends RefCounted

const CompanionEquipmentServiceClass := preload(
	"res://core/companions/companion_equipment_service.gd"
)
const CompanionRelationshipServiceClass := preload(
	"res://core/companions/companion_relationship_service.gd"
)
const CompanionStateClass := preload("res://core/companions/companion_state.gd")
const FallenCompanionClass := preload("res://core/companions/fallen_companion.gd")
const PartyMessageClass := preload("res://core/companions/party_message.gd")
const PartyStateClass := preload("res://core/companions/party_state.gd")
const PartyCombatRoundResultClass := preload("res://core/combat/party_combat_round_result.gd")
const PlayerProfileClass := preload("res://core/player/player_profile.gd")

const MIN_INJURY_DAYS := 2
const MAX_INJURY_DAYS := 5


static func apply_round_result(
	party: PartyStateClass,
	player: PlayerProfileClass,
	report: PartyCombatRoundResultClass,
	current_day: int,
	enemy_name: String,
	rift_rank_code: String,
	rng: RandomNumberGenerator = null,
) -> Dictionary:
	if party == null or player == null or report == null:
		return _failure("Brak stanu potrzebnego do rozliczenia skutków walki.")
	if report.casualties_applied:
		return {
			"ok": true,
			"changed": false,
			"injured": [],
			"fallen": [],
			"returned_items": [],
		}
	report.casualties_applied = true
	var injury_rng := rng if rng != null else RandomNumberGenerator.new()
	var injured: Array[CompanionStateClass] = []
	var fallen: Array[FallenCompanionClass] = []
	var returned_items := []

	# Egzekucja jest rozliczana wyłącznie na podstawie jawnego wyniku licznika.
	# Ten przebieg celowo nie korzysta z RNG.
	for companion_id: String in report.killed:
		var companion := party.companion_by_id(companion_id)
		if companion == null:
			continue
		var kill_result := kill_companion(
			party,
			player,
			companion,
			current_day,
			"Egzekucja %s po pozostawieniu w stanie Powalenia." % enemy_name,
			rift_rank_code,
		)
		fallen.append(kill_result.memorial)
		returned_items.append_array(kill_result.returned_items)

	for companion_id: String in report.critically_injured:
		var companion := party.companion_by_id(companion_id)
		if companion == null:
			continue
		var days := injury_rng.randi_range(MIN_INJURY_DAYS, MAX_INJURY_DAYS)
		critically_injure(companion, current_day, days)
		(
			CompanionRelationshipServiceClass
			. append_message(
				party,
				(
					PartyMessageClass
					. new(
						current_day,
						companion.companion_id,
						companion.display_name,
						(
							(
								"Mirela kazała mi leżeć. Powrót do sił: około %d dni Pythonii. "
								+ "Spróbujcie nie zamknąć świata beze mnie."
							)
							% days
						),
						false,
					)
				),
			)
		)
		injured.append(companion)
	return {
		"ok": true,
		"changed": not injured.is_empty() or not fallen.is_empty(),
		"injured": injured,
		"fallen": fallen,
		"returned_items": returned_items,
	}


static func critically_injure(companion: CompanionStateClass, current_day: int, days: int) -> void:
	if companion == null:
		return
	companion.active = false
	companion.injury_until_day = maxi(companion.injury_until_day, current_day + maxi(1, days))
	companion.current_hp = 1
	companion.hp_initialized = true


static func kill_companion(
	party: PartyStateClass,
	player: PlayerProfileClass,
	companion: CompanionStateClass,
	current_day: int,
	cause: String,
	rift_rank_code: String = "",
) -> Dictionary:
	if party == null or player == null or companion == null:
		return _failure("Brak stanu potrzebnego do zapisania poległego kompana.")
	var gear_result := CompanionEquipmentServiceClass.return_player_owned_gear(player, companion)
	if not gear_result.ok:
		return gear_result
	companion.dead = true
	companion.active = false
	var memorial := (
		FallenCompanionClass
		. new(
			companion.companion_id,
			companion.display_name,
			companion.class_code,
			companion.level,
			current_day,
			cause,
			rift_rank_code,
		)
	)
	party.fallen.append(memorial)
	party.companions.erase(companion)
	var survivors := party.living_companions()
	if not survivors.is_empty():
		var sender: CompanionStateClass = survivors[0]
		(
			CompanionRelationshipServiceClass
			. append_message(
				party,
				(
					PartyMessageClass
					. new(
						current_day,
						sender.companion_id,
						sender.display_name,
						(
							(
								"Nie mogę przestać myśleć o %s. Mieliśmy czas zareagować. "
								+ "Następnym razem nie możemy pozwolić, żeby cisza trwała "
								+ "o jedną rundę za długo."
							)
							% companion.display_name
						),
						false,
					)
				),
			)
		)
	return {
		"ok": true,
		"memorial": memorial,
		"returned_items": gear_result.returned_items,
	}


static func refresh_injuries(party: PartyStateClass, current_day: int) -> Array[String]:
	var healed: Array[String] = []
	if party == null:
		return healed
	for companion: CompanionStateClass in party.companions:
		if companion.injury_until_day > 0 and current_day >= companion.injury_until_day:
			companion.injury_until_day = 0
			healed.append(companion.display_name)
	return healed


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
