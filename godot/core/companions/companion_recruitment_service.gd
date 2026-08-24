class_name CompanionRecruitmentService
extends RefCounted

const CandidateClass := preload("res://core/companions/companion_candidate.gd")
const CatalogClass := preload("res://core/companions/companion_catalog.gd")
const CompanionServiceClass := preload("res://core/companions/companion_service.gd")
const CompanionBuildServiceClass := preload("res://core/companions/companion_build_service.gd")
const CompanionEquipmentServiceClass := preload(
	"res://core/companions/companion_equipment_service.gd"
)
const CompanionStateClass := preload("res://core/companions/companion_state.gd")
const MessageClass := preload("res://core/companions/party_message.gd")
const PartyStateClass := preload("res://core/companions/party_state.gd")
const StoryCatalogClass := preload("res://core/companions/companion_story_catalog.gd")
const GuildProgressionServiceClass := preload("res://core/quests/guild_progression_service.gd")
const TalentCatalogClass := preload("res://core/progression/talent_catalog.gd")

const CANDIDATES_PER_DAY := 2
const CANDIDATE_LEVEL_DELTA := 8
const RETURN_DELAY_DAYS := 3
const RETURN_CHANCE := 0.28
const RANK_CODES := ["F", "E", "D", "C", "B", "A", "S"]


static func ensure_daily_candidates(
	party: PartyStateClass, player, current_day: int, guild_rank_code: String
) -> bool:
	if party == null or player == null:
		return false
	var builds_changed := CompanionBuildServiceClass.ensure_party_builds(party)
	if party.candidates_day == current_day:
		return builds_changed
	party.candidates_day = current_day
	party.candidates.clear()
	var rank_index := _rank_index(guild_rank_code)
	var available_templates := []
	for definition in CatalogClass.get_all():
		if _rank_index(definition.minimum_guild_rank) > rank_index:
			continue
		if _party_has_template(party, definition.template_id):
			continue
		available_templates.append(definition)

	var rng := _rng_for(["guild-candidates", player.display_name, current_day, guild_rank_code])
	var returning: Array[CompanionStateClass] = []
	for companion: CompanionStateClass in party.dismissed_companions:
		if not companion.dead and current_day - companion.dismissed_day >= RETURN_DELAY_DAYS:
			returning.append(companion)
	if not returning.is_empty() and rng.randf() < RETURN_CHANCE:
		var companion: CompanionStateClass = returning[rng.randi_range(0, returning.size() - 1)]
		var candidate := (
			CandidateClass
			. new(
				"return-%s-%d" % [companion.companion_id, current_day],
				companion,
				current_day,
				clampi(55 - _floor_divide(companion.relation, 2), 15, 90),
			)
		)
		candidate.impression = maxi(0, _floor_divide(companion.relation, 3))
		candidate.returning = true
		party.candidates.append(candidate)
		available_templates = available_templates.filter(
			func(definition) -> bool: return definition.template_id != companion.template_id
		)

	_shuffle(available_templates, rng)
	while party.candidates.size() < CANDIDATES_PER_DAY and not available_templates.is_empty():
		var definition = available_templates.pop_back()
		(
			party
			. candidates
			. append(
				_generate_new_candidate(
					definition,
					player.display_name,
					player.level,
					current_day,
					party.candidates.size(),
				)
			)
		)
	return true


static func willingness_score(
	candidate: CandidateClass, player, guild_rank_code: String, rifts_closed := 0
) -> int:
	if candidate == null or candidate.companion == null or player == null:
		return 5
	var definition = CatalogClass.get_definition(candidate.companion.template_id)
	if definition == null:
		return 5
	var score: int = definition.base_willingness
	score += _rank_index(guild_rank_code) * 4
	score += mini(12, maxi(0, rifts_closed) * 2)
	score += candidate.impression
	var level_difference: int = candidate.companion.level - player.level
	if level_difference > 0:
		score -= mini(18, level_difference * 2)
	elif level_difference < 0:
		score += mini(6, int(-level_difference / 2.0))
	var path = TalentCatalogClass.get_path_definition(candidate.companion.path_id)
	if path != null and path.requires_book():
		score -= 5
	if candidate.returning:
		score += 12 + mini(12, _floor_divide(candidate.companion.relation, 4))
	return clampi(score, 5, 95)


static func willingness_label(score: int) -> String:
	if score >= 80:
		return "bardzo wysoka"
	if score >= 65:
		return "wysoka"
	if score >= 50:
		return "umiarkowana"
	if score >= 35:
		return "niska"
	return "bardzo niska"


static func talk_to_candidate(candidate: CandidateClass, choice_index: int) -> Dictionary:
	if candidate == null or candidate.companion == null:
		return _failure("Nie znaleziono kandydata.")
	if candidate.talked:
		return _failure("Ta rozmowa odbyła się już dzisiaj.")
	var story = StoryCatalogClass.get_story(candidate.companion.template_id)
	if story == null or choice_index < 0 or choice_index >= story.conversations.size():
		return _failure("Nieprawidłowy wybór rozmowy.")
	var conversation: Dictionary = story.conversations[choice_index]
	candidate.talked = true
	candidate.impression += int(conversation.impression)
	return {
		"ok": true,
		"message": str(conversation.response),
		"impression_delta": int(conversation.impression),
	}


static func recruit_candidate(
	party: PartyStateClass,
	candidate: CandidateClass,
	player,
	guild_rank_code: String,
	rifts_closed := 0,
	composition_locked := false
) -> Dictionary:
	if party == null or candidate == null or candidate.companion == null:
		return _failure("Nie znaleziono kandydata.")
	if composition_locked:
		return _failure("Nie możesz zmieniać składu stałej drużyny w trakcie ekspedycji Szczeliny.")
	if party.companions.size() >= CompanionServiceClass.MAX_COMPANIONS:
		return _failure(
			"Masz już maksymalną liczbę kompanów (%d)." % CompanionServiceClass.MAX_COMPANIONS
		)
	if candidate.recruitment_attempted:
		return _failure("Ten kandydat podjął już dziś decyzję.")
	if candidate not in party.candidates:
		return _failure("Ten kandydat nie jest już dostępny.")
	candidate.recruitment_attempted = true
	var score := willingness_score(candidate, player, guild_rank_code, rifts_closed)
	var story = StoryCatalogClass.get_story(candidate.companion.template_id)
	if score < candidate.recruitment_roll:
		return {
			"ok": true,
			"success": false,
			"score": score,
			"message": story.recruit_fail,
		}

	var companion: CompanionStateClass = candidate.companion
	companion.relation = maxi(companion.relation, candidate.impression)
	companion.active = (
		party.active_companions().size() < CompanionServiceClass.MAX_ACTIVE_COMPANIONS
	)
	companion.dismissed_day = 0
	party.companions.append(companion)
	party.candidates.erase(candidate)
	party.dismissed_companions = party.dismissed_companions.filter(
		func(item: CompanionStateClass) -> bool: return item.companion_id != companion.companion_id
	)
	(
		party
		. messages
		. append(
			(
				MessageClass
				. new(
					candidate.generated_day,
					companion.companion_id,
					companion.display_name,
					story.recruit_success,
				)
			)
		)
	)
	return {
		"ok": true,
		"success": true,
		"score": score,
		"message": story.recruit_success,
		"companion": companion,
	}


static func dismiss_companion(
	party: PartyStateClass,
	player,
	companion_id: String,
	current_day: int,
	composition_locked := false
) -> Dictionary:
	if party == null or player == null:
		return _failure("Brak stanu drużyny.")
	if composition_locked:
		return _failure("Nie możesz rozstać się z kompanem w trakcie ekspedycji Szczeliny.")
	var companion := party.companion_by_id(companion_id)
	if companion == null:
		return _failure("Nie znaleziono kompana.")
	var gear_result := CompanionEquipmentServiceClass.return_player_owned_gear(player, companion)
	if not gear_result.ok:
		return gear_result
	var story = StoryCatalogClass.get_story(companion.template_id)
	companion.active = false
	companion.dismissed_day = current_day
	party.companions.erase(companion)
	party.dismissed_companions = party.dismissed_companions.filter(
		func(item: CompanionStateClass) -> bool: return item.companion_id != companion_id
	)
	party.dismissed_companions.append(companion)
	return {
		"ok": true,
		"message": story.farewell,
		"companion": companion,
		"returned_items": gear_result.returned_items,
	}


static func rank_code_for_reputation(reputation: int) -> String:
	return GuildProgressionServiceClass.rank_for_reputation(reputation).code


static func _generate_new_candidate(
	definition, player_name: String, player_level: int, current_day: int, slot_index: int
) -> CandidateClass:
	var rng := _rng_for(["candidate", player_name, current_day, slot_index, definition.template_id])
	var class_code: String = definition.allowed_classes[rng.randi_range(
		0, definition.allowed_classes.size() - 1
	)]
	var low := maxi(5, player_level - 6)
	var high := maxi(low, player_level + CANDIDATE_LEVEL_DELTA)
	var level := clampi(roundi(_triangular(rng, low, high, player_level)), 5, high)
	var path_order: Array = TalentCatalogClass.CLASS_PATH_ORDER[class_code]
	var rare := rng.randf() < (0.18 + (0.04 if definition.base_willingness < 50 else 0.0))
	var path_id: String = path_order[1] if rare else path_order[0]
	var companion_id := (
		"%s-%d-%d-%d"
		% [
			definition.template_id,
			current_day,
			slot_index,
			rng.randi_range(1000, 9998),
		]
	)
	var companion := CompanionStateClass.new(
		companion_id, definition.template_id, definition.display_name, class_code
	)
	companion.level = level
	companion.path_id = path_id
	var story = StoryCatalogClass.get_story(definition.template_id)
	var arc = story.arcs[rng.randi_range(0, story.arcs.size() - 1)]
	companion.quest_arc_id = arc.arc_id
	var candidate := (
		CandidateClass
		. new(
			"cand-%s" % companion_id,
			companion,
			current_day,
			rng.randi_range(20, 92),
		)
	)
	# Build generation deliberately happens after every frozen Stage 6B draw.
	# Its three named RNG substreams cannot alter identity, arc or recruitment roll.
	CompanionBuildServiceClass.ensure_initial_build(companion)
	return candidate


static func _party_has_template(party: PartyStateClass, template_id: String) -> bool:
	for companion: CompanionStateClass in party.companions:
		if companion.template_id == template_id:
			return true
	return false


static func _rank_index(rank_code: String) -> int:
	return maxi(0, RANK_CODES.find(rank_code))


static func _floor_divide(numerator: int, denominator: int) -> int:
	assert(denominator != 0, "Floor division requires a non-zero denominator.")
	var quotient := int(float(numerator) / float(denominator))
	if numerator % denominator != 0 and (numerator < 0) != (denominator < 0):
		quotient -= 1
	return quotient


static func _rng_for(parts: Array) -> RandomNumberGenerator:
	var text_parts: Array[String] = []
	for part in parts:
		text_parts.append(str(part))
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update("|".join(text_parts).to_utf8_buffer())
	var digest := context.finish()
	var seed_value := 0
	for index in 7:
		seed_value = (seed_value << 8) | int(digest[index])
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


static func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var other := rng.randi_range(0, index)
		var value = values[index]
		values[index] = values[other]
		values[other] = value


static func _triangular(rng: RandomNumberGenerator, low: float, high: float, mode: float) -> float:
	if is_equal_approx(low, high):
		return low
	var draw := rng.randf()
	var split := (mode - low) / (high - low)
	if draw > split:
		return high - sqrt((1.0 - draw) * (high - low) * (high - mode))
	return low + sqrt(draw * (high - low) * (mode - low))


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
