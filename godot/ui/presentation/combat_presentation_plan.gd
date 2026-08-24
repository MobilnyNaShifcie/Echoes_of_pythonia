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
				}
			)
		)

	if bool(report.get("enemy_dodged", false)):
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
