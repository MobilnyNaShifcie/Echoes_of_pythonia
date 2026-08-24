class_name RiftSaveCodec
extends RefCounted

const RiftCatalogClass := preload("res://core/rifts/rift_catalog.gd")
const RiftExpeditionClass := preload("res://core/rifts/rift_expedition.gd")
const RiftInstanceClass := preload("res://core/rifts/rift_instance.gd")
const RiftStateClass := preload("res://core/rifts/rift_state.gd")


static func empty_data() -> Dictionary:
	return {
		"active_rift": null,
		"expedition": null,
		"next_spawn_day": 2,
		"last_resolution_day": 0,
		"completed_total": 0,
		"completed_by_rank": {},
		"last_notice": "",
	}


static func serialize(state: RiftStateClass) -> Dictionary:
	return {
		"active_rift": _serialize_rift(state.active_rift),
		"expedition": _serialize_expedition(state.expedition),
		"next_spawn_day": state.next_spawn_day,
		"last_resolution_day": state.last_resolution_day,
		"completed_total": state.completed_total,
		"completed_by_rank": state.completed_by_rank.duplicate(true),
		"last_notice": state.last_notice,
	}


# Guard clauses keep malformed save data away from runtime state.
# gdlint: disable=max-returns
static func deserialize(data: Dictionary) -> Dictionary:
	if not _is_non_negative_integer(data.get("next_spawn_day")):
		return _failure("Nieprawidłowy termin kolejnego alarmu Szczeliny.")
	if not _is_non_negative_integer(data.get("last_resolution_day")):
		return _failure("Nieprawidłowy dzień rozstrzygnięcia Szczeliny.")
	if not _is_non_negative_integer(data.get("completed_total")):
		return _failure("Nieprawidłowa liczba zamkniętych Szczelin.")
	if not data.get("completed_by_rank") is Dictionary or not data.get("last_notice") is String:
		return _failure("Nieprawidłowa historia Szczelin.")

	var completed_by_rank := {}
	var counted_total := 0
	for rank_value in data.completed_by_rank:
		var rank_code := str(rank_value)
		var count_value = data.completed_by_rank[rank_value]
		if (
			not RiftCatalogClass.is_valid_rank(rank_code)
			or not _is_non_negative_integer(count_value)
		):
			return _failure("Nieprawidłowa historia rang Szczelin.")
		completed_by_rank[rank_code] = int(count_value)
		counted_total += int(count_value)
	if counted_total != int(data.completed_total):
		return _failure("Historia rang nie zgadza się z liczbą zamkniętych Szczelin.")

	var rift_result := _deserialize_rift(data.get("active_rift"))
	if not rift_result.ok:
		return rift_result
	var expedition_result := _deserialize_expedition(data.get("expedition"))
	if not expedition_result.ok:
		return expedition_result
	var active: RiftInstanceClass = rift_result.rift
	var expedition: RiftExpeditionClass = expedition_result.expedition
	if expedition != null:
		if active == null or expedition.rift_id != active.rift_id:
			return _failure("Ekspedycja nie pasuje do aktywnej Szczeliny.")
		if expedition.segment_index >= active.segment_count:
			return _failure("Postęp ekspedycji wykracza poza długość Szczeliny.")
		var minimum_companions: int = RiftCatalogClass.MIN_COMPANIONS[active.rank_code]
		if (
			expedition.party_companion_ids.size() < minimum_companions
			or expedition.party_companion_ids.size() > 3
		):
			return _failure("Zapis zawiera nieprawidłowy rozmiar drużyny Szczeliny.")
		var passed_camps := 0
		for camp_index: int in [4, 9, 14, 19]:
			if camp_index < expedition.segment_index and camp_index < active.segment_count - 1:
				passed_camps += 1
		if expedition.camp_visits > passed_camps:
			return _failure("Liczba obozowisk wykracza poza postęp ekspedycji.")

	var state := RiftStateClass.new()
	state.active_rift = active
	state.expedition = expedition
	state.next_spawn_day = int(data.next_spawn_day)
	state.last_resolution_day = int(data.last_resolution_day)
	state.completed_total = int(data.completed_total)
	state.completed_by_rank = completed_by_rank
	state.last_notice = str(data.last_notice)
	return {"ok": true, "state": state}


static func _serialize_rift(rift: RiftInstanceClass):
	if rift == null:
		return null
	return {
		"rift_id": rift.rift_id,
		"rank_code": rift.rank_code,
		"theme_id": rift.theme_id,
		"theme_name": rift.theme_name,
		"modifier_ids": rift.modifier_ids.duplicate(),
		"discovered_day": rift.discovered_day,
		"expires_day": rift.expires_day,
		"seed": rift.seed,
		"segment_count": rift.segment_count,
		"boss_id": rift.boss_id,
		"boss_name": rift.boss_name,
		"closed": rift.closed,
		"closed_by": rift.closed_by,
	}


static func _deserialize_rift(data) -> Dictionary:
	if data == null:
		return {"ok": true, "rift": null}
	if not data is Dictionary:
		return _failure("Nieprawidłowa Szczelina w zapisie.")
	var rank_code := str(data.get("rank_code", ""))
	var theme_id := str(data.get("theme_id", ""))
	var theme = RiftCatalogClass.get_theme(theme_id)
	if not RiftCatalogClass.is_valid_rank(rank_code) or theme == null:
		return _failure("Nieprawidłowa Szczelina w zapisie.")
	if not data.get("modifier_ids") is Array:
		return _failure("Szczelina nie zawiera prawidłowych anomalii.")
	var modifier_ids: Array[String] = []
	for modifier_value in data.modifier_ids:
		if (
			not modifier_value is String
			or RiftCatalogClass.get_modifier(str(modifier_value)) == null
			or str(modifier_value) in modifier_ids
		):
			return _failure("Nieznany albo powtórzony modyfikator Szczeliny w zapisie.")
		modifier_ids.append(str(modifier_value))
	var rank_index := RiftCatalogClass.rank_index(rank_code)
	var expected_modifiers := 1 + (1 if rank_index >= 3 else 0) + (1 if rank_index >= 5 else 0)
	if modifier_ids.size() != expected_modifiers:
		return _failure("Liczba anomalii nie pasuje do rangi Szczeliny.")
	if (
		not _is_positive_integer(data.get("discovered_day"))
		or not _is_positive_integer(data.get("expires_day"))
		or int(data.expires_day) < int(data.discovered_day)
		or not _is_integer(data.get("seed"))
		or not _is_positive_integer(data.get("segment_count"))
		or int(data.segment_count) != int(RiftCatalogClass.SEGMENTS[rank_code])
	):
		return _failure("Nieprawidłowy czas lub długość Szczeliny.")
	if (
		not data.get("rift_id") is String
		or not data.get("theme_name") is String
		or not data.get("boss_id") is String
		or not data.get("boss_name") is String
		or not data.get("closed") is bool
		or not data.get("closed_by") is String
	):
		return _failure("Szczelina ma nieprawidłową strukturę.")
	if str(data.rift_id).strip_edges().is_empty():
		return _failure("Szczelina nie ma identyfikatora.")
	if bool(data.closed) or not str(data.closed_by).is_empty():
		return _failure("Zamknięta Szczelina nie może pozostać aktywnym alarmem.")
	if str(data.theme_name) != str(theme.name):
		return _failure("Nazwa motywu Szczeliny nie zgadza się z katalogiem.")
	var matching_boss := false
	for boss_value in theme.bosses:
		var boss: Array = boss_value
		if str(boss[0]) == str(data.boss_id) and str(boss[1]) == str(data.boss_name):
			matching_boss = true
			break
	if not matching_boss:
		return _failure("Władca Szczeliny nie pasuje do jej motywu.")
	return {
		"ok": true,
		"rift":
		(
			RiftInstanceClass
			. new(
				{
					"rift_id": str(data.rift_id),
					"rank_code": rank_code,
					"theme_id": theme_id,
					"theme_name": str(data.theme_name),
					"modifier_ids": modifier_ids,
					"discovered_day": int(data.discovered_day),
					"expires_day": int(data.expires_day),
					"seed": int(data.seed),
					"segment_count": int(data.segment_count),
					"boss_id": str(data.boss_id),
					"boss_name": str(data.boss_name),
					"closed": bool(data.closed),
					"closed_by": str(data.closed_by),
				}
			)
		),
	}


static func _serialize_expedition(expedition: RiftExpeditionClass):
	if expedition == null:
		return null
	return {
		"rift_id": expedition.rift_id,
		"segment_index": expedition.segment_index,
		"party_companion_ids": expedition.party_companion_ids.duplicate(),
		"secured_rewards": expedition.secured_rewards.duplicate(true),
		"pending_unique_item_id":
		null if expedition.pending_unique_item_id.is_empty() else expedition.pending_unique_item_id,
		"started_day": expedition.started_day,
		"camp_visits": expedition.camp_visits,
		"defeated": expedition.defeated,
	}


static func _deserialize_expedition(data) -> Dictionary:
	if data == null:
		return {"ok": true, "expedition": null}
	if not data is Dictionary:
		return _failure("Nieprawidłowy stan ekspedycji Szczeliny.")
	if (
		not data.get("rift_id") is String
		or not _is_non_negative_integer(data.get("segment_index"))
		or not data.get("party_companion_ids") is Array
		or not data.get("secured_rewards") is Dictionary
		or not _is_positive_integer(data.get("started_day"))
		or not _is_non_negative_integer(data.get("camp_visits"))
		or not data.get("defeated") is bool
	):
		return _failure("Nieprawidłowy stan ekspedycji Szczeliny.")
	var companion_ids: Array[String] = []
	var seen_ids := {}
	for companion_value in data.party_companion_ids:
		if not companion_value is String:
			return _failure("Ekspedycja zawiera nieprawidłowy skład.")
		var companion_id := str(companion_value)
		if companion_id.is_empty() or seen_ids.has(companion_id):
			return _failure("Ekspedycja zawiera pustego albo powtórzonego kompana.")
		seen_ids[companion_id] = true
		companion_ids.append(companion_id)
	var rewards := {}
	for reward_key in data.secured_rewards:
		var quantity = data.secured_rewards[reward_key]
		if not reward_key is String or not _is_non_negative_integer(quantity):
			return _failure("Ekspedycja zawiera nieprawidłowe zabezpieczone nagrody.")
		rewards[str(reward_key)] = int(quantity)
	var pending_value = data.get("pending_unique_item_id")
	if pending_value != null and not pending_value is String:
		return _failure("Ekspedycja zawiera nieprawidłowy oczekujący Unikat.")
	var expedition := (
		RiftExpeditionClass
		. new(
			str(data.rift_id),
			int(data.segment_index),
			companion_ids,
			int(data.started_day),
		)
	)
	expedition.secured_rewards = rewards
	expedition.pending_unique_item_id = "" if pending_value == null else str(pending_value)
	expedition.camp_visits = int(data.camp_visits)
	expedition.defeated = bool(data.defeated)
	return {"ok": true, "expedition": expedition}


static func _is_integer(value) -> bool:
	return (value is int or value is float) and is_equal_approx(float(value), floorf(float(value)))


static func _is_non_negative_integer(value) -> bool:
	return _is_integer(value) and int(value) >= 0


static func _is_positive_integer(value) -> bool:
	return _is_integer(value) and int(value) > 0


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
