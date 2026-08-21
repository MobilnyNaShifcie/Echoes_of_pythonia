class_name CompanionRelationshipService
extends RefCounted

const CompanionStateClass := preload("res://core/companions/companion_state.gd")
const MessageClass := preload("res://core/companions/party_message.gd")
const PartyStateClass := preload("res://core/companions/party_state.gd")
const StoryCatalogClass := preload("res://core/companions/companion_story_catalog.gd")

const INJURY_MESSAGES := [
	(
		"Nie próbuj mnie wyciągać z łóżka przed czasem. Mirela zagroziła, "
		+ "że jeśli pękną szwy, zszyje mnie grubszą nicią."
	),
	(
		"Powrót do sił idzie wolniej, niż bym chciał. Nie oznacza to, "
		+ "że macie robić coś głupiego beze mnie."
	),
]
const MESSAGE_LIMIT := 60


static func available_personal_stage(companion: CompanionStateClass) -> Dictionary:
	if companion == null:
		return {}
	var story = StoryCatalogClass.get_story(companion.template_id)
	if story == null:
		return {}
	var arc = story.arc_by_id(companion.quest_arc_id)
	if arc == null or companion.quest_stage >= arc.stages.size():
		return {}
	var stage = arc.stages[companion.quest_stage]
	if companion.rifts_together < stage.unlock_rifts:
		return {}
	return {"arc": arc, "stage": stage}


static func complete_personal_stage(
	companion: CompanionStateClass, choice_index: int
) -> Dictionary:
	var available := available_personal_stage(companion)
	if available.is_empty():
		return _failure("Ten etap historii nie jest jeszcze dostępny.")
	var stage = available.stage
	if choice_index < 0 or choice_index >= stage.choices.size():
		return _failure("Nieprawidłowa odpowiedź.")
	var choice = stage.choices[choice_index]
	companion.relation = clampi(companion.relation + choice.relation_delta, -100, 100)
	if not choice.memory_tag.is_empty() and choice.memory_tag not in companion.memories:
		companion.memories.append(choice.memory_tag)
	companion.quest_stage += 1
	return {
		"ok": true,
		"title": stage.title,
		"message": choice.response,
		"relation_delta": choice.relation_delta,
		"memory_tag": choice.memory_tag,
	}


static func ensure_daily_party_message(
	party: PartyStateClass, current_day: int, player_name: String
) -> Dictionary:
	if party == null or party.last_message_day >= current_day or party.companions.is_empty():
		return {"ok": true, "created": false}
	party.last_message_day = current_day
	var candidates: Array[CompanionStateClass] = []
	for companion: CompanionStateClass in party.companions:
		if not companion.dead:
			candidates.append(companion)
	if candidates.is_empty():
		return {"ok": true, "created": false}
	var rng := _rng_for(["party-message", player_name, current_day, candidates.size()])
	var companion: CompanionStateClass = candidates[rng.randi_range(0, candidates.size() - 1)]
	var source: Array = (
		INJURY_MESSAGES
		if companion.is_injured(current_day)
		else StoryCatalogClass.get_story(companion.template_id).messages
	)
	var message := (
		MessageClass
		. new(
			current_day,
			companion.companion_id,
			companion.display_name,
			str(source[rng.randi_range(0, source.size() - 1)]),
			false,
		)
	)
	party.messages.append(message)
	if party.messages.size() > MESSAGE_LIMIT:
		party.messages = party.messages.slice(party.messages.size() - MESSAGE_LIMIT)
	return {"ok": true, "created": true, "message_value": message}


static func mark_messages_read(party: PartyStateClass) -> int:
	if party == null:
		return 0
	var changed := 0
	for message: MessageClass in party.messages:
		if not message.read:
			message.read = true
			changed += 1
	return changed


static func camp_banter(party: PartyStateClass, seed_value: int, current_day := 0) -> Dictionary:
	if party == null:
		return {"ok": true, "lines": [], "scene_id": ""}
	var active := party.active_companions(current_day)
	if active.size() >= 2:
		var pairs := []
		for first_index in active.size():
			var first: CompanionStateClass = active[first_index]
			for second_index in range(first_index + 1, active.size()):
				var second: CompanionStateClass = active[second_index]
				var scenes := StoryCatalogClass.get_pair_banter(
					first.template_id, second.template_id
				)
				if not scenes.is_empty():
					pairs.append({"first": first, "second": second, "scenes": scenes})
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		_shuffle(pairs, rng)
		for pair: Dictionary in pairs:
			for scene_index in pair.scenes.size():
				var scene_id := (
					"%s:%s:%d" % [pair.first.template_id, pair.second.template_id, scene_index]
				)
				if scene_id in party.seen_banter:
					continue
				party.seen_banter.append(scene_id)
				return {
					"ok": true,
					"lines": Array(pair.scenes[scene_index]),
					"scene_id": scene_id,
				}
	if active.is_empty():
		return {"ok": true, "lines": [], "scene_id": ""}
	var companion_rng := RandomNumberGenerator.new()
	companion_rng.seed = seed_value
	var companion: CompanionStateClass = active[companion_rng.randi_range(0, active.size() - 1)]
	var line_rng := RandomNumberGenerator.new()
	line_rng.seed = seed_value + 1
	var lines = StoryCatalogClass.get_story(companion.template_id).camp_lines
	return {
		"ok": true,
		"lines":
		["%s: %s" % [companion.display_name, lines[line_rng.randi_range(0, lines.size() - 1)]]],
		"scene_id": "",
	}


static func idle_line(companion: CompanionStateClass, seed_value: int) -> String:
	if companion == null:
		return ""
	var lines = StoryCatalogClass.get_story(companion.template_id).idle_lines
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return str(lines[rng.randi_range(0, lines.size() - 1)])


static func record_rift_together(party: PartyStateClass, companion_ids: Array[String]) -> void:
	if party == null:
		return
	for companion: CompanionStateClass in party.companions:
		if companion.companion_id in companion_ids and not companion.dead:
			companion.rifts_together += 1
			companion.relation = mini(100, companion.relation + 3)


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


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
