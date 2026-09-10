class_name CombatPresentationPlan
extends RefCounted


static func from_report(report: Dictionary) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	var fate_dice: Array = report.get("fate_dice", [])
	if not fate_dice.is_empty():
		(
			events
			. append(
				{
					"kind": "fate_roll",
					"dice": fate_dice.duplicate(),
					"outcome": str(report.get("fate_outcome", "")),
					"mana_cost":
					(
						int(report.get("skill_mana_cost", 0))
						if str(report.get("skill_id", "")) == "fate_thrust"
						else 0
					),
				}
			)
		)

	if str(report.get("skill_id", "")) == "fate_thrust":
		_append_fate_thrust(events, report)
	elif bool(report.get("enemy_dodged", false)):
		events.append(_feedback("enemy", "UNIK", "dodge"))
	else:
		var player_damage := _player_damage_total(report)
		if player_damage > 0:
			(
				events
				. append(
					_damage(
						"player",
						"enemy",
						player_damage,
						(
							bool(report.get("player_critical", false))
							or bool(report.get("extra_player_critical", false))
						),
					)
				)
			)

	_append_restore_events(events, report)
	if bool(report.get("enemy_acted", false)):
		events.append({"kind": "turn", "actor": "enemy"})
		if bool(report.get("player_dodged", false)):
			events.append(_feedback("player", "UNIK", "dodge"))
		elif bool(report.get("shield_blocked", false)):
			var blocked_damage := int(report.get("enemy_damage", 0))
			(
				events
				. append(
					_feedback(
						"player",
						"BLOK" if blocked_damage <= 0 else "BLOK  •  -%d" % blocked_damage,
						"block",
					)
				)
			)
		elif int(report.get("enemy_damage", 0)) > 0:
			events.append(_damage("enemy", "player", int(report.enemy_damage), false))
		else:
			events.append(_feedback("player", "0", "block"))
		if int(report.get("enemy_extra_damage", 0)) > 0:
			events.append(_damage("enemy", "player", int(report.enemy_extra_damage), false))
		if int(report.get("warrior_counter_damage", 0)) > 0:
			events.append(
				_damage("player", "enemy", int(report.warrior_counter_damage), false, "KONTRA")
			)
		if int(report.get("boss_aura_damage", 0)) > 0:
			events.append(_damage("enemy", "player", int(report.boss_aura_damage), false, "AURA"))

	if int(report.get("reflected_damage", 0)) > 0:
		events.append(_damage("player", "enemy", int(report.reflected_damage), false, "ODBICIE"))
	if int(report.get("enemy_bleed_damage", 0)) > 0:
		events.append(
			_damage("player", "enemy", int(report.enemy_bleed_damage), false, "KRWAWIENIE")
		)
	if int(report.get("enemy_healed", 0)) > 0:
		events.append(_restore("enemy", int(report.enemy_healed), 0))
	if int(report.get("player_regenerated", 0)) > 0:
		events.append(_restore("player", int(report.player_regenerated), 0))

	events.append({"kind": "turn", "actor": "player"})
	return events


static func _append_fate_thrust(events: Array[Dictionary], report: Dictionary) -> void:
	if bool(report.get("enemy_dodged", false)):
		events.append(_feedback("enemy", "UNIK", "dodge"))
		return
	# Use recorded hits, never split the total into invented/rounded damage values.
	var hits: Array = report.get("player_hit_damages", []).duplicate()
	var recorded := 0
	for amount in hits:
		recorded += int(amount)
	var remainder := _player_damage_total(report) - recorded
	if remainder > 0:
		# Chaos talents can add an extra hit after the primary roll.
		hits.append(remainder)
	if hits.is_empty():
		hits.append(0)
	var dice: Array = report.get("fate_dice", [])
	var exact_hits: Array = report.get("fate_hits", [])
	for index in hits.size():
		var critical_key := "player_critical" if index == 0 else "extra_player_critical"
		var critical := bool(report.get(critical_key, false))
		if index < exact_hits.size():
			critical = bool(exact_hits[index].get("critical", false))
		var event := _damage("player", "enemy", int(hits[index]), critical)
		event["vfx"] = "fate_thrust"
		event["fate_face"] = int(dice[0]) if not dice.is_empty() else 0
		event["hit_index"] = index
		event["hit_count"] = hits.size()
		events.append(event)


static func _player_damage_total(report: Dictionary) -> int:
	var skill_total := int(report.get("skill_total_damage", 0))
	if skill_total > 0:
		return skill_total
	return int(report.get("player_damage", 0)) + int(report.get("extra_player_damage", 0))


static func _append_restore_events(events: Array[Dictionary], report: Dictionary) -> void:
	var healed := int(report.get("player_healed", 0))
	var mana := int(report.get("player_mana_restored", 0))
	if healed > 0 or mana > 0:
		events.append(_restore("player", healed, mana))


static func _damage(
	actor: String,
	target: String,
	amount: int,
	critical: bool,
	prefix := "",
) -> Dictionary:
	return {
		"kind": "damage",
		"actor": actor,
		"target": target,
		"amount": amount,
		"critical": critical,
		"prefix": prefix,
	}


static func _restore(target: String, health: int, mana: int) -> Dictionary:
	return {
		"kind": "restore",
		"target": target,
		"health": health,
		"mana": mana,
	}


static func _feedback(target: String, text: String, tone: String) -> Dictionary:
	return {
		"kind": "feedback",
		"target": target,
		"text": text,
		"tone": tone,
	}
