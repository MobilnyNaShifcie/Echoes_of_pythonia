class_name RiftLifecycleService
extends RefCounted

const RiftCatalogClass := preload("res://core/rifts/rift_catalog.gd")
const RiftExpeditionClass := preload("res://core/rifts/rift_expedition.gd")
const RiftInstanceClass := preload("res://core/rifts/rift_instance.gd")
const RiftStateClass := preload("res://core/rifts/rift_state.gd")


static func ensure_state(
	state: RiftStateClass, player_name: String, current_day: int, guild_rank_code: String
) -> Dictionary:
	if state == null or player_name.strip_edges().is_empty() or current_day < 1:
		return _failure("Nieprawidłowy stan świata Szczelin.")
	if not RiftCatalogClass.is_valid_rank(guild_rank_code):
		return _failure("Nieznana ranga Gildii.")
	if state.expedition != null:
		return {"ok": true, "changed": false, "notice": ""}

	var active: RiftInstanceClass = state.active_rift
	if active != null and not active.closed and current_day > active.expires_day:
		var claimed_rng := _rng_for(["rift-claimed", active.rift_id])
		var team: String = RiftCatalogClass.OTHER_SEARCHER_TEAMS[claimed_rng.randi_range(
			0, RiftCatalogClass.OTHER_SEARCHER_TEAMS.size() - 1
		)]
		active.closed = true
		active.closed_by = team
		state.last_resolution_day = current_day
		state.last_notice = (
			"%s zamknęła %s rangi %s, zanim twoja drużyna wyruszyła."
			% [team, active.theme_name, active.rank_code]
		)
		state.active_rift = null
		state.next_spawn_day = current_day + claimed_rng.randi_range(2, 5)
		return {"ok": true, "changed": true, "notice": state.last_notice}

	if state.active_rift == null and current_day >= maxi(1, state.next_spawn_day):
		state.active_rift = _create_rift(player_name, current_day, guild_rank_code)
		var next_rng := _rng_for(["next-rift", state.active_rift.rift_id])
		state.next_spawn_day = current_day + next_rng.randi_range(4, 7)
		active = state.active_rift
		state.last_notice = (
			(
				"ALARM GILDII: wykryto %s rangi %s. "
				+ "Jeśli nikt nie wyruszy, inne drużyny zaczną działać po dniu %d."
			)
			% [active.theme_name, active.rank_code, active.expires_day]
		)
		return {"ok": true, "changed": true, "notice": state.last_notice}
	return {"ok": true, "changed": false, "notice": ""}


static func days_remaining(rift: RiftInstanceClass, current_day: int) -> int:
	if rift == null:
		return 0
	return maxi(0, rift.expires_day - current_day + 1)


static func can_start_rift(
	rift: RiftInstanceClass, active_companions: int, guild_rank_code: String
) -> Dictionary:
	if rift == null or rift.closed:
		return _failure("Nie ma aktywnej Szczeliny.")
	if not RiftCatalogClass.is_valid_rank(guild_rank_code):
		return _failure("Nieznana ranga Gildii.")
	if RiftCatalogClass.rank_index(guild_rank_code) < RiftCatalogClass.rank_index(rift.rank_code):
		return _failure("Wymagana Ranga Gildii: %s." % rift.rank_code)
	var required: int = RiftCatalogClass.MIN_COMPANIONS[rift.rank_code]
	if active_companions < required:
		return _failure("Ta Szczelina wymaga co najmniej %d aktywnych kompanów." % required)
	return {"ok": true, "message": "Drużyna spełnia wymagania Szczeliny."}


static func start_expedition(
	state: RiftStateClass, current_day: int, companion_ids: Array[String], guild_rank_code: String
) -> Dictionary:
	if state == null or state.active_rift == null or state.active_rift.closed:
		return _failure("Nie ma aktywnej Szczeliny.")
	if state.expedition != null:
		return _failure("Ekspedycja już trwa.")
	if current_day > state.active_rift.expires_day:
		return _failure("Alarm Szczeliny wygasł.")
	var unique_ids := {}
	for companion_id: String in companion_ids:
		if companion_id.is_empty() or unique_ids.has(companion_id):
			return _failure("Skład ekspedycji zawiera nieprawidłowego kompana.")
		unique_ids[companion_id] = true
	var eligibility := can_start_rift(state.active_rift, companion_ids.size(), guild_rank_code)
	if not eligibility.ok:
		return eligibility
	state.expedition = RiftExpeditionClass.new(
		state.active_rift.rift_id, 0, companion_ids, current_day
	)
	return {
		"ok": true,
		"message":
		(
			"Rozpoczęto ekspedycję: %s rangi %s."
			% [state.active_rift.theme_name, state.active_rift.rank_code]
		),
		"expedition": state.expedition,
	}


static func abandon_expedition(state: RiftStateClass, current_day: int) -> Dictionary:
	if state == null or state.expedition == null:
		return _failure("Brak trwającej ekspedycji Szczeliny.")
	state.expedition = null
	if state.active_rift != null and current_day > state.active_rift.expires_day:
		state.active_rift.expires_day = current_day - 1
	return {
		"ok": true,
		"message": "Porzucono ekspedycję. Szczelina znów jest dostępna dla innych drużyn.",
	}


static func _create_rift(
	player_name: String, current_day: int, guild_rank_code: String
) -> RiftInstanceClass:
	var seed_value := _seed_for(["rift", player_name, current_day, guild_rank_code])
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var rank_code := _roll_rank(rng, guild_rank_code)
	var theme_id: String = RiftCatalogClass.THEME_ORDER[rng.randi_range(
		0, RiftCatalogClass.THEME_ORDER.size() - 1
	)]
	var theme: Dictionary = RiftCatalogClass.THEMES[theme_id]
	var rank_index := RiftCatalogClass.rank_index(rank_code)
	var modifier_count := 1 + (1 if rank_index >= 3 else 0) + (1 if rank_index >= 5 else 0)
	var available_modifiers := RiftCatalogClass.MODIFIER_ORDER.duplicate()
	var modifier_ids: Array[String] = []
	for _index in modifier_count:
		var chosen_index := rng.randi_range(0, available_modifiers.size() - 1)
		modifier_ids.append(str(available_modifiers.pop_at(chosen_index)))
	var bosses: Array = theme.bosses
	var boss: Array = bosses[rng.randi_range(0, bosses.size() - 1)]
	var lifetime := rng.randi_range(2, 4)
	return (
		RiftInstanceClass
		. new(
			{
				"rift_id": "rift-%d-%d" % [current_day, seed_value % 1000000],
				"rank_code": rank_code,
				"theme_id": theme_id,
				"theme_name": str(theme.name),
				"modifier_ids": modifier_ids,
				"discovered_day": current_day,
				"expires_day": current_day + lifetime,
				"seed": seed_value,
				"segment_count": int(RiftCatalogClass.SEGMENTS[rank_code]),
				"boss_id": str(boss[0]),
				"boss_name": str(boss[1]),
			}
		)
	)


static func _roll_rank(rng: RandomNumberGenerator, guild_rank_code: String) -> String:
	var max_index := mini(
		RiftCatalogClass.rank_index(guild_rank_code), RiftCatalogClass.RANKS.size() - 1
	)
	var total_weight := 0
	for index in range(max_index + 1):
		total_weight += 1 + index * 2
	var roll := rng.randi_range(1, total_weight)
	var cumulative := 0
	for index in range(max_index + 1):
		cumulative += 1 + index * 2
		if roll <= cumulative:
			return RiftCatalogClass.RANKS[index]
	return RiftCatalogClass.RANKS[max_index]


static func _rng_for(parts: Array) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = _seed_for(parts)
	return rng


static func _seed_for(parts: Array) -> int:
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
	return seed_value


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "changed": false, "message": message, "notice": ""}
