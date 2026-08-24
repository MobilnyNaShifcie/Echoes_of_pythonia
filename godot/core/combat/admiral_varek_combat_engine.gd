class_name AdmiralVarekCombatEngine
extends "res://core/combat/combat_engine.gd"

# Authored phase announcements intentionally remain readable as complete sentences.
# gdlint: disable=max-line-length

var phase := 1
var cannon_pending := false
var normal_turns_since_salvo := 0
var phase_three_crit_chance := 0.20


func boss_status_lines() -> Array[String]:
	if cannon_pending and phase == 2:
		return [
			"[UWAGA] Kanonierzy celują — nadchodzi Salwa Armatnia!",
			"Obrona znacząco zmniejszy obrażenia salwy.",
		]
	return []


func _enemy_turn(report: Dictionary, defending := false) -> void:
	_update_phase(report)
	if phase == 2 and cannon_pending:
		_fire_cannon_salvo(report, defending)
		return
	if phase >= 3:
		_phase_three_turn(report, defending)
		return
	super._enemy_turn(report, defending)
	if phase == 2 and result == ONGOING:
		normal_turns_since_salvo += 1
		if normal_turns_since_salvo >= 2:
			cannon_pending = true
			(
				report
				. boss_notes
				. append(
					"Kanonierzy Czarnej Floty przygotowują salwę. Następny atak Vareka zostanie zastąpiony ostrzałem."
				)
			)


func _fire_cannon_salvo(report: Dictionary, defending: bool) -> void:
	var original_name := enemy.special_name
	var original_chance := enemy.special_chance
	var original_bonus := enemy.special_attack_bonus
	var original_type := enemy.special_damage_type
	enemy.special_name = "Salwa Armatnia"
	enemy.special_chance = 1.0
	enemy.special_attack_bonus = 24
	enemy.special_damage_type = "physical"
	report.boss_notes.append("SALWA ARMATNIA: działa okrętu flagowego otwierają ogień!")
	super._enemy_turn(report, defending)
	enemy.special_name = original_name
	enemy.special_chance = original_chance
	enemy.special_attack_bonus = original_bonus
	enemy.special_damage_type = original_type
	cannon_pending = false
	normal_turns_since_salvo = 0


func _phase_three_turn(report: Dictionary, defending: bool) -> void:
	var original_attack := enemy.attack
	if rng.randf() < phase_three_crit_chance:
		var bonus := maxi(1, MathClass.python_roundi(original_attack * 0.50))
		enemy.attack += bonus
		report.boss_notes.append(
			"KRYTYCZNE CIĘCIE: desperacki zamach Vareka zyskuje +%d siły." % bonus
		)
	super._enemy_turn(report, defending)
	enemy.attack = original_attack


func _update_phase(report: Dictionary) -> void:
	var hp_ratio := float(enemy.current_hp) / float(enemy.max_hp)
	if phase < 2 and hp_ratio <= 0.60:
		phase = 2
		normal_turns_since_salvo = 0
		(
			report
			. boss_notes
			. append(
				"FAZA II: Dowódca Czarnej Floty — Varek wydaje rozkaz kanonierom. Salwa zostanie wcześniej zapowiedziana."
			)
		)
	if phase < 3 and hp_ratio <= 0.25:
		phase = 3
		cannon_pending = false
		normal_turns_since_salvo = 0
		enemy.attack += 10
		enemy.defense = maxi(0, enemy.defense - 8)
		(
			report
			. boss_notes
			. append(
				"FAZA III: Ostatni Rozkaz — Varek zyskuje +10 ATK, traci 8 DEF i może wykonywać krytyczne cięcia."
			)
		)
