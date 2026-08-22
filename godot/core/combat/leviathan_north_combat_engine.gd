class_name LeviathanNorthCombatEngine
extends "res://core/combat/combat_engine.gd"

var phase := 1


func _enemy_turn(report: Dictionary, defending := false) -> void:
	_update_phase(report)
	super._enemy_turn(report, defending)


func _update_phase(report: Dictionary) -> void:
	var hp_ratio := float(enemy.current_hp) / float(enemy.max_hp)
	if phase < 2 and hp_ratio <= 0.60:
		phase = 2
		enemy.attack += 4
		enemy.defense += 4
		report.boss_notes.append("FAZA II: Wzburzone Morze — Lewiatan zyskuje +4 ATK i +4 DEF.")
	if phase < 3 and hp_ratio <= 0.25:
		phase = 3
		enemy.attack += 10
		enemy.defense = maxi(0, enemy.defense - 8)
		report.boss_notes.append(
			"FAZA III: Gniew Lewiatana — Lewiatan zyskuje +10 ATK, ale traci 8 DEF."
		)
