class_name GrandMasterCombatEngine
extends "res://core/combat/combat_engine.gd"

var phase := 1


func _enemy_turn(report: Dictionary, defending := false) -> void:
	_update_phase(report)
	super._enemy_turn(report, defending)
	if phase < 3 or result != ONGOING or not enemy.is_alive() or not player.stats.is_alive():
		return
	var aura_damage := player.stats.elemental_resistances.reduce_damage(2, "water")
	report.boss_aura_damage = player.stats.take_damage(aura_damage)
	if not player.stats.is_alive():
		result = DEFEAT


func _update_phase(report: Dictionary) -> void:
	var hp_ratio := float(enemy.current_hp) / float(enemy.max_hp)
	if phase < 2 and hp_ratio <= 0.60:
		phase = 2
		enemy.attack += 3
		enemy.defense = maxi(0, enemy.defense - 3)
		report.boss_notes.append("FAZA II: Wielki Mistrz roztrzaskuje tarczę — ATK +3, DEF -3.")
	if phase < 3 and hp_ratio <= 0.25:
		phase = 3
		report.boss_notes.append(
			"FAZA III: Klątwa Głębin budzi się — po każdej turze zadaje obrażenia od Wody."
		)
