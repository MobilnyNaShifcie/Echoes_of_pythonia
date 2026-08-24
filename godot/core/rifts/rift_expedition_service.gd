class_name RiftExpeditionService
extends RefCounted

const CompanionBuildServiceClass := preload("res://core/companions/companion_build_service.gd")
const CompanionCasualtyServiceClass := preload(
	"res://core/companions/companion_casualty_service.gd"
)
const CompanionRelationshipServiceClass := preload(
	"res://core/companions/companion_relationship_service.gd"
)
const CompanionStateClass := preload("res://core/companions/companion_state.gd")
const EquipmentAffixServiceClass := preload("res://core/items/equipment_affix_service.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const MathClass := preload("res://core/math/legacy_math.gd")
const PartyCombatEngineClass := preload("res://core/combat/party_combat_engine.gd")
const PartyCombatRoundResultClass := preload("res://core/combat/party_combat_round_result.gd")
const RiftCatalogClass := preload("res://core/rifts/rift_catalog.gd")
const RiftCompletionRewardClass := preload("res://core/rifts/rift_completion_reward.gd")
const RiftSegmentServiceClass := preload("res://core/rifts/rift_segment_service.gd")

const OUTCOME_ONGOING := "ongoing"
const OUTCOME_SEGMENT_COMPLETED := "segment_completed"
const OUTCOME_RIFT_COMPLETED := "rift_completed"
const OUTCOME_DEFEAT := "defeat"


static func current_segment(session) -> Dictionary:
	var error := _state_error(session)
	if not error.is_empty():
		return _failure(error)
	var rift = session.rifts.active_rift
	var expedition = session.rifts.expedition
	if expedition.segment_index >= rift.segment_count:
		return _failure("Postęp ekspedycji wykracza poza długość Szczeliny.")
	var kind := RiftSegmentServiceClass.segment_kind(rift, expedition.segment_index)
	var result := {
		"ok": true,
		"kind": kind,
		"kind_name": segment_kind_name(kind),
		"segment_index": expedition.segment_index,
		"segment_number": expedition.segment_index + 1,
		"segment_count": rift.segment_count,
		"title": "%s — RANGA %s" % [rift.theme_name, rift.rank_code],
		"description": "",
	}
	if kind == "event":
		var event := RiftSegmentServiceClass.event_text(rift, expedition.segment_index)
		result.description = "%s\n\n%s" % [event.title, event.text]
	elif kind == "camp":
		result.description = (
			"Drużyna znajduje skrawek stabilnej przestrzeni. "
			+ "Na kilka chwil można opuścić broń."
		)
	elif kind == "boss":
		result.description = (
			"W sercu Szczeliny czeka %s. Pokonanie Władcy zamknie tę Szczelinę na zawsze."
			% rift.boss_name
		)
	else:
		var enemy = RiftSegmentServiceClass.create_enemy(
			rift, session.player.level, expedition.segment_index, kind
		)
		result.description = "Drogę zagradza: %s." % enemy.display_name
	return result


static func bound_companions(session) -> Array[CompanionStateClass]:
	var companions: Array[CompanionStateClass] = []
	if session == null or session.rifts.expedition == null:
		return companions
	var wanted := {}
	for companion_id: String in session.rifts.expedition.party_companion_ids:
		wanted[companion_id] = true
	for companion: CompanionStateClass in session.party.companions:
		if (
			wanted.has(companion.companion_id)
			and not companion.dead
			and not companion.is_injured(session.day)
		):
			companions.append(companion)
	return companions


static func resolve_event(session) -> Dictionary:
	var segment := current_segment(session)
	if not segment.ok:
		return segment
	if segment.kind != "event":
		return _failure("Bieżący segment nie jest wydarzeniem.")
	var event := RiftSegmentServiceClass.event_text(
		session.rifts.active_rift, session.rifts.expedition.segment_index
	)
	session.rifts.expedition.segment_index += 1
	return {
		"ok": true,
		"outcome": OUTCOME_SEGMENT_COMPLETED,
		"title": event.title,
		"message":
		(
			(
				"%s\n\nSzczelina nie daje wam pewności, czy to wspomnienie, ostrzeżenie "
				+ "czy zwykłe kłamstwo przestrzeni."
			)
			% event.text
		),
	}


static func resolve_camp(session) -> Dictionary:
	var segment := current_segment(session)
	if not segment.ok:
		return segment
	if segment.kind != "camp":
		return _failure("Bieżący segment nie jest obozowiskiem.")
	var rift = session.rifts.active_rift
	var expedition = session.rifts.expedition
	var player_hp := _restore_stat(session.player.stats, "hp", 0.25)
	var player_mana := _restore_stat(session.player.stats, "mana", 0.25)
	var companion_restored := {}
	for companion: CompanionStateClass in bound_companions(session):
		var limits := CompanionBuildServiceClass.resource_limits(companion)
		var resources := CompanionBuildServiceClass.resolved_resources(companion)
		var hp_before := int(resources.current_hp)
		var mana_before := int(resources.current_mana)
		var hp_after := mini(
			int(limits.max_hp),
			hp_before + maxi(1, MathClass.python_roundi(int(limits.max_hp) * 0.25)),
		)
		var mana_after := mana_before
		if int(limits.max_mana) > 0:
			mana_after = mini(
				int(limits.max_mana),
				mana_before + maxi(1, MathClass.python_roundi(int(limits.max_mana) * 0.25)),
			)
		CompanionBuildServiceClass.sync_resources(companion, hp_after, mana_after)
		companion_restored[companion.companion_id] = {
			"hp": hp_after - hp_before,
			"mana": mana_after - mana_before,
		}
	var banter := CompanionRelationshipServiceClass.camp_banter(
		session.party, rift.seed + expedition.segment_index, session.day
	)
	expedition.camp_visits += 1
	expedition.segment_index += 1
	return {
		"ok": true,
		"outcome": OUTCOME_SEGMENT_COMPLETED,
		"message": "Odpoczynek przywraca 25% PŻ i Many żyjącym członkom ekspedycji.",
		"player_hp": player_hp,
		"player_mana": player_mana,
		"companions": companion_restored,
		"banter_lines": banter.lines,
	}


static func start_combat(session) -> Dictionary:
	var segment := current_segment(session)
	if not segment.ok:
		return segment
	if segment.kind not in ["battle", "elite", "miniboss", "boss"]:
		return _failure("Bieżący segment nie zawiera walki.")
	var rift = session.rifts.active_rift
	var index: int = session.rifts.expedition.segment_index
	var enemy = RiftSegmentServiceClass.create_enemy(
		rift, session.player.level, index, segment.kind
	)
	if enemy == null:
		return _failure("Nie udało się utworzyć przeciwnika Szczeliny.")
	var engine := (
		PartyCombatEngineClass
		. new(
			session.player,
			bound_companions(session),
			enemy,
			RiftSegmentServiceClass.combat_rng(rift, index),
			RiftSegmentServiceClass.mana_cost_multiplier(rift),
			rift.rank_code,
		)
	)
	return {"ok": true, "engine": engine, "kind": segment.kind, "enemy": enemy}


static func apply_combat_round(
	session, engine: PartyCombatEngineClass, report: PartyCombatRoundResultClass
) -> Dictionary:
	var error := _state_error(session)
	if not error.is_empty():
		return _failure(error)
	if engine == null or report == null:
		return _failure("Brak wyniku walki drużynowej.")
	var rift = session.rifts.active_rift
	var expedition = session.rifts.expedition
	var kind := RiftSegmentServiceClass.segment_kind(rift, expedition.segment_index)
	var expected_enemy_id := "%s-%d-%s" % [rift.rift_id, expedition.segment_index, kind]
	if engine.enemy == null or engine.enemy.enemy_id != expected_enemy_id:
		return _failure("Wynik walki nie pasuje do bieżącego segmentu Szczeliny.")
	var casualty_result := (
		CompanionCasualtyServiceClass
		. apply_round_result(
			session.party,
			session.player,
			report,
			session.day,
			engine.enemy.display_name,
			rift.rank_code,
			_named_rng(rift.seed, "casualties", expedition.segment_index, report.round_number),
		)
	)
	if not casualty_result.ok:
		return casualty_result
	if report.defeat:
		if session.player.stats.current_hp <= 0:
			session.player.stats.current_hp = 1
		session.rifts.expedition = null
		var defeat_message := (
			(
				"Ekspedycja w Szczelinie rangi %s zakończyła się porażką. "
				+ "Jeśli alarm nadal obowiązuje, drużyna może przygotować nową próbę."
			)
			% rift.rank_code
		)
		session.log_event(defeat_message)
		return {
			"ok": true,
			"outcome": OUTCOME_DEFEAT,
			"message": defeat_message,
			"casualties": casualty_result,
		}
	if not report.victory:
		return {
			"ok": true,
			"outcome": OUTCOME_ONGOING,
			"message": "Runda zakończona.",
			"casualties": casualty_result,
		}
	var segment_experience := _grant_segment_experience(session, kind, rift.rank_code)
	if kind == "boss":
		var completion := _resolve_completion(session)
		if not completion.ok:
			return completion
		completion.casualties = casualty_result
		completion.segment_experience = segment_experience
		return completion
	expedition.segment_index += 1
	return {
		"ok": true,
		"outcome": OUTCOME_SEGMENT_COMPLETED,
		"message": "Segment ukończony. Drużyna może ruszyć głębiej.",
		"segment_experience": segment_experience,
		"casualties": casualty_result,
	}


static func segment_kind_name(kind: String) -> String:
	match kind:
		"battle":
			return "STARCIE"
		"elite":
			return "ELITA"
		"event":
			return "ZDARZENIE"
		"camp":
			return "OBOZOWISKO"
		"miniboss":
			return "MINIBOSS"
		"boss":
			return "SERCE SZCZELINY"
	return kind.to_upper()


static func _grant_segment_experience(session, kind: String, rank_code: String) -> Dictionary:
	var amount := (
		18
		+ RiftCatalogClass.rank_index(rank_code) * 8
		+ (18 if kind == "elite" else 0)
		+ (35 if kind == "miniboss" else 0)
	)
	var gained := {}
	for companion: CompanionStateClass in bound_companions(session):
		var levels := CompanionBuildServiceClass.gain_experience(companion, amount)
		gained[companion.companion_id] = {"experience": amount, "levels": levels}
		if levels > 0:
			session.log_event(
				"%s awansuje na poziom %d." % [companion.display_name, companion.level]
			)
	return gained


static func _resolve_completion(session) -> Dictionary:
	var rift = session.rifts.active_rift
	var expedition = session.rifts.expedition
	if rift == null or expedition == null:
		return _failure("Brak aktywnej ekspedycji.")
	var companion_ids: Array[String] = expedition.party_companion_ids.duplicate()
	var rng := _named_rng(rift.seed, "completion", expedition.segment_index, 0)
	var reward_range: Array = RiftCatalogClass.GOLD_REWARDS[rift.rank_code]
	var reward := (
		RiftCompletionRewardClass
		. new(
			rng.randi_range(int(reward_range[0]), int(reward_range[1])),
			int(RiftCatalogClass.EXPERIENCE_REWARDS[rift.rank_code]),
		)
	)
	var unique_chance := minf(0.80, 0.28 + RiftCatalogClass.rank_index(rift.rank_code) * 0.07)
	if rng.randf() < unique_chance:
		var pool: Array = RiftCatalogClass.UNIQUE_POOLS.get(session.player.character_class_code, [])
		if not pool.is_empty():
			reward.unique_item_id = str(pool[rng.randi_range(0, pool.size() - 1)])
			var item = ItemCatalogClass.create_equipment_item(
				reward.unique_item_id, rng, EquipmentAffixServiceClass.QUALITY_BOSS
			)
			if item == null or not session.player.inventory.add_equipment_instance(item):
				return _failure("Nie udało się przyznać Unikatu Szczeliny.")
			reward.unique_item_name = item.display_name
	session.player.add_gold(reward.gold)
	reward.player_levels_gained = session.player.gain_experience(reward.experience)
	var companion_reward := maxi(50, MathClass.python_roundi(reward.experience * 0.60))
	for companion_id: String in companion_ids:
		var companion: CompanionStateClass = session.party.companion_by_id(companion_id)
		if companion == null or companion.dead:
			continue
		var levels := CompanionBuildServiceClass.gain_experience(companion, companion_reward)
		reward.companion_levels_gained[companion_id] = levels
		if levels > 0:
			session.log_event(
				"%s awansuje na poziom %d." % [companion.display_name, companion.level]
			)
	CompanionRelationshipServiceClass.record_rift_together(session.party, companion_ids)
	var rift_name: String = rift.theme_name
	var rank_code: String = rift.rank_code
	var boss_name: String = rift.boss_name
	var started_day: int = expedition.started_day
	rift.closed = true
	rift.closed_by = session.player.display_name
	session.rifts.completed_total += 1
	session.rifts.completed_by_rank[rank_code] = (
		int(session.rifts.completed_by_rank.get(rank_code, 0)) + 1
	)
	session.rifts.last_resolution_day = started_day
	session.rifts.last_notice = (
		"%s rangi %s została zamknięta przez twoją drużynę." % [rift_name, rank_code]
	)
	session.rifts.expedition = null
	session.rifts.active_rift = null
	session.rifts.next_spawn_day = maxi(
		session.rifts.next_spawn_day, started_day + rng.randi_range(3, 6)
	)
	session.log_event("Zamknięto Szczelinę rangi %s: %s." % [rank_code, rift_name])
	return {
		"ok": true,
		"outcome": OUTCOME_RIFT_COMPLETED,
		"message":
		(
			(
				"%s został pokonany. Przestrzeń wokół drużyny składa się do środka. "
				+ "Szczelina znika i nie będzie można wejść do niej ponownie."
			)
			% boss_name
		),
		"reward": reward,
		"rift_name": rift_name,
		"rank_code": rank_code,
		"boss_name": boss_name,
	}


static func _restore_stat(stats, resource: String, fraction: float) -> int:
	if resource == "hp":
		return stats.heal(maxi(1, MathClass.python_roundi(stats.max_hp * fraction)))
	if stats.max_mana <= 0:
		return 0
	return stats.restore_mana(maxi(1, MathClass.python_roundi(stats.max_mana * fraction)))


static func _named_rng(
	rift_seed: int, substream: String, segment_index: int, sequence: int
) -> RandomNumberGenerator:
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(
		(
			("rift-expedition-v1|%d|%s|%d|%d" % [rift_seed, substream, segment_index, sequence])
			. to_utf8_buffer()
		)
	)
	var digest := context.finish()
	var seed_value := 0
	for index in 7:
		seed_value = (seed_value << 8) | int(digest[index])
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


static func _state_error(session) -> String:
	if session == null or session.player == null:
		return "Brak aktywnej sesji."
	if session.rifts == null or session.rifts.active_rift == null:
		return "Brak aktywnej Szczeliny."
	if session.rifts.expedition == null:
		return "Brak aktywnej ekspedycji."
	return ""


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "outcome": "", "message": message}
