class_name AzharCombatEngine
extends "res://core/combat/combat_engine.gd"

var phase := 1


func _enemy_turn(report: Dictionary, defending := false) -> void:
	_update_phase(report)
	super._enemy_turn(report, defending)


func _update_phase(report: Dictionary) -> void:
	var hp_ratio := float(enemy.current_hp) / float(enemy.max_hp)
	if phase < 2 and hp_ratio <= 0.60:
		phase = 2
		enemy.attack += 2
		enemy.dodge = minf(95.0, enemy.dodge + 10.0)
		report.boss_notes.append("FAZA II: Burza Piaskowa — Azhar zyskuje +2 ATK i +10 p.p. Uniku.")
	if phase < 3 and hp_ratio <= 0.25:
		phase = 3
		enemy.attack += 6
		enemy.defense = maxi(0, enemy.defense - 4)
		report.boss_notes.append(
			"FAZA III: Gniew Pustkowi — Azhar zyskuje +6 ATK, ale traci 4 DEF."
		)
