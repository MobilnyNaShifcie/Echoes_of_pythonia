class_name PartySaveCodec
extends RefCounted

const CompanionCandidateClass := preload("res://core/companions/companion_candidate.gd")
const CompanionCatalogClass := preload("res://core/companions/companion_catalog.gd")
const CompanionServiceClass := preload("res://core/companions/companion_service.gd")
const CompanionStateClass := preload("res://core/companions/companion_state.gd")
const CompanionStoryCatalogClass := preload("res://core/companions/companion_story_catalog.gd")
const FallenCompanionClass := preload("res://core/companions/fallen_companion.gd")
const PartyMessageClass := preload("res://core/companions/party_message.gd")
const PartyStateClass := preload("res://core/companions/party_state.gd")
const PlayerAttributesClass := preload("res://core/player/attributes.gd")
const EquipmentSaveCodecClass := preload("res://core/save/equipment_save_codec.gd")

const VALID_CLASS_CODES := ["warrior", "hunter", "mage", "pierrot"]
const VALID_RIFT_RANKS := ["", "F", "E", "D", "C", "B", "A", "S"]


static func empty_data() -> Dictionary:
	return {
		"companions": [],
		"dismissed_companions": [],
		"candidates_day": 0,
		"candidates": [],
		"messages": [],
		"last_message_day": 0,
		"seen_banter": [],
		"fallen": [],
	}


static func serialize(party: PartyStateClass) -> Dictionary:
	var data := empty_data()
	for companion: CompanionStateClass in party.companions:
		data.companions.append(_serialize_companion(companion))
	for companion: CompanionStateClass in party.dismissed_companions:
		data.dismissed_companions.append(_serialize_companion(companion))
	for candidate: CompanionCandidateClass in party.candidates:
		data.candidates.append(_serialize_candidate(candidate))
	for message: PartyMessageClass in party.messages:
		data.messages.append(_serialize_message(message))
	for fallen: FallenCompanionClass in party.fallen:
		data.fallen.append(_serialize_fallen(fallen))
	data.candidates_day = party.candidates_day
	data.last_message_day = party.last_message_day
	data.seen_banter = party.seen_banter.duplicate()
	return data


static func deserialize(data: Dictionary, current_day: int) -> Dictionary:
	for array_field: String in [
		"companions",
		"dismissed_companions",
		"candidates",
		"messages",
		"seen_banter",
		"fallen",
	]:
		if not data.get(array_field) is Array:
			return _failure("Zapis nie zawiera prawidłowego pola drużyny: %s." % array_field)
	if (
		not _is_non_negative_integer(data.get("candidates_day"))
		or not _is_non_negative_integer(data.get("last_message_day"))
	):
		return _failure("Zapis zawiera nieprawidłowe dni stanu drużyny.")
	if data.companions.size() > CompanionServiceClass.MAX_COMPANIONS:
		return _failure("Zapis przekracza limit kompanów.")
	if data.candidates.size() > 2:
		return _failure("Zapis przekracza limit dziennych kandydatów.")

	var party := PartyStateClass.new()
	var known_ids := {}
	var active_count := 0
	for companion_data in data.companions:
		var result := _deserialize_companion(companion_data, current_day, false)
		if not result.ok:
			return result
		var companion: CompanionStateClass = result.companion
		if known_ids.has(companion.companion_id):
			return _failure("Zapis zawiera powtórzony identyfikator kompana.")
		known_ids[companion.companion_id] = true
		active_count += 1 if companion.active else 0
		party.companions.append(companion)
	if active_count > CompanionServiceClass.MAX_ACTIVE_COMPANIONS:
		return _failure("Zapis przekracza limit aktywnego składu.")

	for companion_data in data.dismissed_companions:
		var result := _deserialize_companion(companion_data, current_day, true)
		if not result.ok:
			return result
		var companion: CompanionStateClass = result.companion
		if known_ids.has(companion.companion_id):
			return _failure("Zapis zawiera powtórzony identyfikator kompana.")
		known_ids[companion.companion_id] = true
		party.dismissed_companions.append(companion)

	var candidate_ids := {}
	for candidate_data in data.candidates:
		var result := _deserialize_candidate(candidate_data, current_day)
		if not result.ok:
			return result
		var candidate: CompanionCandidateClass = result.candidate
		if candidate_ids.has(candidate.candidate_id):
			return _failure("Zapis zawiera powtórzonego kandydata.")
		candidate_ids[candidate.candidate_id] = true
		party.candidates.append(candidate)

	for message_data in data.messages:
		var result := _deserialize_message(message_data)
		if not result.ok:
			return result
		party.messages.append(result.message_value)
	for fallen_data in data.fallen:
		var result := _deserialize_fallen(fallen_data)
		if not result.ok:
			return result
		party.fallen.append(result.fallen_companion)
	var banter_result := _restore_unique_strings(data.seen_banter, "scenkę między kompanami")
	if not banter_result.ok:
		return banter_result
	party.candidates_day = int(data.candidates_day)
	party.last_message_day = int(data.last_message_day)
	party.seen_banter.assign(banter_result.values)
	return {"ok": true, "party": party}


static func _serialize_companion(companion: CompanionStateClass) -> Dictionary:
	return {
		"companion_id": companion.companion_id,
		"template_id": companion.template_id,
		"name": companion.display_name,
		"class_code": companion.class_code,
		"level": companion.level,
		"experience": companion.experience,
		"path_id": companion.path_id,
		"talents": companion.talents.duplicate(true),
		"attributes": _serialize_attributes(companion.attributes),
		"equipment": EquipmentSaveCodecClass.serialize_equipment(companion.equipment.slots),
		"personal_instance_ids": companion.personal_instance_ids.duplicate(),
		"personal_storage": EquipmentSaveCodecClass.serialize_items(companion.personal_storage),
		"relation": companion.relation,
		"quest_arc_id": companion.quest_arc_id,
		"quest_stage": companion.quest_stage,
		"memories": companion.memories.duplicate(),
		"rifts_together": companion.rifts_together,
		"injury_until_day": companion.injury_until_day,
		"dead": companion.dead,
		"active": companion.active,
		"tactic": companion.tactic,
		"current_hp": companion.current_hp,
		"current_mana": companion.current_mana,
		"dismissed_day": companion.dismissed_day,
	}


static func _deserialize_companion(data, current_day: int, dismissed: bool) -> Dictionary:
	if not data is Dictionary:
		return _failure("Zapis zawiera nieprawidłowego kompana.")
	for field: String in ["companion_id", "template_id", "name", "class_code"]:
		if not data.get(field) is String or str(data[field]).strip_edges().is_empty():
			return _failure("Kompan nie zawiera prawidłowego pola: %s." % field)
	var template_id := str(data.template_id)
	var class_code := str(data.class_code)
	var definition := CompanionCatalogClass.get_definition(template_id)
	if (
		definition == null
		or class_code not in VALID_CLASS_CODES
		or not definition.allows_class(class_code)
	):
		return _failure("Zapis zawiera nieznany szablon albo klasę kompana.")
	if str(data.name) != definition.display_name:
		return _failure("Imię kompana nie zgadza się z ręcznie napisanym szablonem.")
	for field: String in [
		"level",
		"experience",
		"quest_stage",
		"rifts_together",
		"injury_until_day",
		"current_hp",
		"current_mana",
		"dismissed_day",
	]:
		if not _is_non_negative_integer(data.get(field)):
			return _failure("Kompan zawiera nieprawidłową wartość pola: %s." % field)
	if int(data.level) < 1 or not data.get("relation") is int:
		return _failure("Kompan ma nieprawidłowy poziom albo relację.")
	if not data.get("dead") is bool or not data.get("active") is bool:
		return _failure("Kompan ma nieprawidłowe flagi stanu.")
	if dismissed and data.active:
		return _failure("Były kompan nie może należeć do aktywnego składu.")
	var tactic := str(data.get("tactic", ""))
	if tactic not in CompanionStateClass.VALID_TACTICS:
		return _failure("Zapis zawiera nieznaną taktykę kompana.")
	if (
		not data.get("talents") is Dictionary
		or not data.get("attributes") is Dictionary
		or not data.get("equipment") is Dictionary
		or not data.get("personal_instance_ids") is Array
		or not data.get("personal_storage") is Array
		or not data.get("memories") is Array
	):
		return _failure("Zapis nie zawiera kompletnego stanu kompana.")

	var companion := CompanionStateClass.new(
		str(data.companion_id), template_id, str(data.name), class_code
	)
	var attributes_result := _restore_attributes(companion.attributes, data.attributes)
	if not attributes_result.ok:
		return attributes_result
	var talents_result := _restore_non_negative_map(data.talents, "talent kompana")
	if not talents_result.ok:
		return talents_result
	var equipment_result := EquipmentSaveCodecClass.restore_equipment(
		companion.equipment, data.equipment
	)
	if not equipment_result.ok:
		return equipment_result
	var storage_result := EquipmentSaveCodecClass.restore_items(data.personal_storage)
	if not storage_result.ok:
		return storage_result
	var personal_result := _restore_unique_strings(
		data.personal_instance_ids, "osobisty przedmiot kompana"
	)
	if not personal_result.ok:
		return personal_result
	var memories_result := _restore_unique_strings(data.memories, "wspomnienie kompana")
	if not memories_result.ok:
		return memories_result

	companion.level = int(data.level)
	companion.experience = int(data.experience)
	companion.path_id = str(data.get("path_id", ""))
	companion.talents = talents_result.values
	companion.personal_instance_ids.assign(personal_result.values)
	companion.personal_storage.assign(storage_result.items)
	companion.relation = int(data.relation)
	companion.quest_arc_id = str(data.get("quest_arc_id", ""))
	companion.quest_stage = int(data.quest_stage)
	companion.memories.assign(memories_result.values)
	companion.rifts_together = int(data.rifts_together)
	companion.injury_until_day = int(data.injury_until_day)
	companion.dead = data.dead
	companion.active = data.active
	companion.tactic = tactic
	companion.current_hp = int(data.current_hp)
	companion.current_mana = int(data.current_mana)
	companion.dismissed_day = int(data.dismissed_day)
	var story = CompanionStoryCatalogClass.get_story(companion.template_id)
	if not companion.quest_arc_id.is_empty():
		var arc = story.arc_by_id(companion.quest_arc_id) if story != null else null
		if arc == null or companion.quest_stage > arc.stages.size():
			return _failure("Kompan zawiera nieprawidłowy postęp historii osobistej.")
		var valid_memories: Array[String] = []
		for stage in arc.stages:
			for choice in stage.choices:
				if not choice.memory_tag.is_empty() and choice.memory_tag not in valid_memories:
					valid_memories.append(choice.memory_tag)
		for memory: String in companion.memories:
			if memory not in valid_memories:
				return _failure("Kompan zawiera nieznane wspomnienie historii osobistej.")
	elif companion.quest_stage != 0 or not companion.memories.is_empty():
		return _failure("Kompan ma postęp historii bez przypisanego wątku osobistego.")
	if companion.active and not companion.can_join_party(current_day):
		return _failure("Martwy albo ciężko ranny kompan nie może być aktywny.")
	var ownership_error := _validate_item_ownership(companion)
	if not ownership_error.is_empty():
		return _failure(ownership_error)
	return {"ok": true, "companion": companion}


static func _serialize_candidate(candidate: CompanionCandidateClass) -> Dictionary:
	return {
		"candidate_id": candidate.candidate_id,
		"companion": _serialize_companion(candidate.companion),
		"generated_day": candidate.generated_day,
		"recruitment_roll": candidate.recruitment_roll,
		"impression": candidate.impression,
		"talked": candidate.talked,
		"recruitment_attempted": candidate.recruitment_attempted,
		"returning": candidate.returning,
	}


static func _deserialize_candidate(data, current_day: int) -> Dictionary:
	if not data is Dictionary or str(data.get("candidate_id", "")).is_empty():
		return _failure("Zapis zawiera nieprawidłowego kandydata.")
	if (
		not _is_non_negative_integer(data.get("generated_day"))
		or not _is_positive_integer(data.get("recruitment_roll"))
		or int(data.recruitment_roll) > 100
		or not data.get("impression") is int
		or not data.get("talked") is bool
		or not data.get("recruitment_attempted") is bool
		or not data.get("returning") is bool
	):
		return _failure("Kandydat zawiera nieprawidłowy stan rekrutacji.")
	var companion_result := _deserialize_companion(data.get("companion"), current_day, true)
	if not companion_result.ok:
		return companion_result
	var candidate := (
		CompanionCandidateClass
		. new(
			str(data.candidate_id),
			companion_result.companion,
			int(data.generated_day),
			int(data.recruitment_roll),
		)
	)
	candidate.impression = int(data.impression)
	candidate.talked = data.talked
	candidate.recruitment_attempted = data.recruitment_attempted
	candidate.returning = data.returning
	return {"ok": true, "candidate": candidate}


static func _serialize_message(message: PartyMessageClass) -> Dictionary:
	return {
		"day": message.day,
		"sender_id": message.sender_id,
		"sender_name": message.sender_name,
		"text": message.text,
		"read": message.read,
	}


static func _deserialize_message(data) -> Dictionary:
	if not data is Dictionary or not _is_non_negative_integer(data.get("day")):
		return _failure("Zapis zawiera nieprawidłową wiadomość drużyny.")
	for field: String in ["sender_id", "sender_name", "text"]:
		if not data.get(field) is String or str(data[field]).strip_edges().is_empty():
			return _failure("Wiadomość drużyny jest niekompletna.")
	if not data.get("read") is bool:
		return _failure("Wiadomość drużyny ma nieprawidłowy stan odczytu.")
	return {
		"ok": true,
		"message_value":
		PartyMessageClass.new(
			int(data.day), str(data.sender_id), str(data.sender_name), str(data.text), data.read
		),
	}


static func _serialize_fallen(fallen: FallenCompanionClass) -> Dictionary:
	return {
		"companion_id": fallen.companion_id,
		"name": fallen.display_name,
		"class_code": fallen.class_code,
		"level": fallen.level,
		"day": fallen.day,
		"cause": fallen.cause,
		"rift_rank": fallen.rift_rank,
	}


static func _deserialize_fallen(data) -> Dictionary:
	if not data is Dictionary:
		return _failure("Zapis zawiera nieprawidłowy wpis Tablicy Poległych.")
	for field: String in ["companion_id", "name", "class_code", "cause"]:
		if not data.get(field) is String or str(data[field]).strip_edges().is_empty():
			return _failure("Wpis Tablicy Poległych jest niekompletny.")
	if (
		str(data.class_code) not in VALID_CLASS_CODES
		or not _is_positive_integer(data.get("level"))
		or not _is_non_negative_integer(data.get("day"))
		or str(data.get("rift_rank", "")) not in VALID_RIFT_RANKS
	):
		return _failure("Wpis Tablicy Poległych zawiera nieprawidłowe dane.")
	return {
		"ok": true,
		"fallen_companion":
		(
			FallenCompanionClass
			. new(
				str(data.companion_id),
				str(data.name),
				str(data.class_code),
				int(data.level),
				int(data.day),
				str(data.cause),
				str(data.get("rift_rank", "")),
			)
		),
	}


static func _serialize_attributes(attributes: PlayerAttributesClass) -> Dictionary:
	return {
		PlayerAttributesClass.STRENGTH: attributes.strength,
		PlayerAttributesClass.VITALITY: attributes.vitality,
		PlayerAttributesClass.INTELLIGENCE: attributes.intelligence,
		PlayerAttributesClass.DEXTERITY: attributes.dexterity,
		PlayerAttributesClass.ENDURANCE: attributes.endurance,
		PlayerAttributesClass.LUCK: attributes.luck,
	}


static func _restore_attributes(attributes: PlayerAttributesClass, data: Dictionary) -> Dictionary:
	for code: String in [
		PlayerAttributesClass.STRENGTH,
		PlayerAttributesClass.VITALITY,
		PlayerAttributesClass.INTELLIGENCE,
		PlayerAttributesClass.DEXTERITY,
		PlayerAttributesClass.ENDURANCE,
		PlayerAttributesClass.LUCK,
	]:
		if not _is_non_negative_integer(data.get(code)):
			return _failure("Kompan ma nieprawidłowy atrybut: %s." % code)
		attributes.set(code, int(data[code]))
	return {"ok": true}


static func _restore_non_negative_map(data: Dictionary, label: String) -> Dictionary:
	var values := {}
	for key_value in data:
		if not key_value is String or str(key_value).is_empty():
			return _failure("Zapis zawiera nieprawidłowy %s." % label)
		if not _is_non_negative_integer(data[key_value]):
			return _failure("Zapis zawiera nieprawidłowy %s." % label)
		values[str(key_value)] = int(data[key_value])
	return {"ok": true, "values": values}


static func _restore_unique_strings(data: Array, label: String) -> Dictionary:
	var values: Array[String] = []
	for value in data:
		if not value is String or str(value).strip_edges().is_empty() or value in values:
			return _failure("Zapis zawiera nieprawidłowy albo powtórzony %s." % label)
		values.append(str(value))
	return {"ok": true, "values": values}


static func _validate_item_ownership(companion: CompanionStateClass) -> String:
	var item_ids := {}
	for item in companion.equipment.slots.values() + companion.personal_storage:
		if item_ids.has(item.instance_id):
			return "Wyposażenie kompana zawiera powtórzony przedmiot."
		item_ids[item.instance_id] = true
	for personal_id: String in companion.personal_instance_ids:
		if not item_ids.has(personal_id):
			return "Osobisty przedmiot kompana nie znajduje się w jego wyposażeniu ani schowku."
	for item in companion.personal_storage:
		if item.instance_id not in companion.personal_instance_ids:
			return "Prywatny schowek zawiera przedmiot nienależący do kompana."
	return ""


static func _is_non_negative_integer(value) -> bool:
	return (value is int or value is float and value == floor(value)) and value >= 0


static func _is_positive_integer(value) -> bool:
	return _is_non_negative_integer(value) and int(value) > 0


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
