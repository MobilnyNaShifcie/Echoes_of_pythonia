class_name FateCombatResolver
extends RefCounted

const FateRollClass := preload("res://core/combat/fate_roll.gd")
const SkillDefinitionClass := preload("res://core/skills/skill_definition.gd")

var combat


func _init(turn_combat) -> void:
	combat = turn_combat


func resolve(skill: SkillDefinitionClass, report: Dictionary) -> void:
	match skill.effect:
		"fate_1d6":
			_resolve_thrust(_roll(1, report), report)
		"fate_2d6":
			_resolve_double(_roll(2, report), report)
		"fate_feint":
			_resolve_feint(_roll(1, report), report)
		"fate_3d6":
			_resolve_grand_gamble(_roll(3, report), report)
		"fate_va_banque":
			_resolve_va_banque(_roll(3, report), report)
	update_report(report)


func token_cap() -> int:
	return (
		6 + mini(4, int(combat.player.attributes.luck / 10.0)) + (2 if _has("fortuna_core") else 0)
	)


func update_report(report: Dictionary) -> void:
	report.fate_tokens = combat.fate_tokens
	report.fate_token_cap = token_cap()
	report.reflect_ready = combat.pierrot_reflect_ready


func _roll(count: int, report: Dictionary) -> FateRollClass:
	var resolution: Dictionary = (
		combat
		. fate
		. roll_with_options(
			count,
			_has("fortuna_loaded_die"),
			_has("fortuna_second_chance") and count == 3,
			_has("fortuna_cheat") and count == 2,
			combat.fate_tokens,
		)
	)
	var roll: FateRollClass = resolution.roll
	combat.fate_tokens = maxi(0, combat.fate_tokens - int(resolution.spent_tokens))
	for note: String in roll.notes:
		report.class_effect_notes.append(note)
	return roll


func _resolve_thrust(roll: FateRollClass, report: Dictionary) -> void:
	var face: int = roll.dice[0]
	var multiplier := 1.0
	var hits := 1
	var outcome := "PEWNE PCHNIĘCIE"
	match face:
		1:
			multiplier = 0.70
			outcome = "PECHOWY NUMER"
			_add_tokens(_bad_luck_tokens(2), report)
		2:
			multiplier = 0.95
			outcome = "FIGIEL"
			combat.enemy.attack = maxi(0, combat.enemy.attack - 1)
			report.skill_notes.append("FIGIEL: ATK przeciwnika -1 do końca walki.")
		3:
			multiplier = 1.15
		4:
			multiplier = 1.10
			outcome = "ZWROT LOSU"
			combat.effects.apply_dodge(15, 1)
			report.skill_notes.append("ZWROT LOSU: UNIK +15 p.p. na następny atak.")
		5:
			multiplier = 0.85
			hits = 2
			outcome = "PODWÓJNY NUMER"
		6:
			multiplier = 1.85
			outcome = "JACKPOT"
			_add_tokens(1, report)
	if _has("pierrot_double_stake") and face in [1, 6]:
		multiplier *= 1.25
		_add_double_stake_note(report)
	multiplier = _favored_multiplier(multiplier)
	_resolve_damage(multiplier, hits, report)
	_set_roll_report(roll, outcome, report)
	if face == 6:
		_maybe_chaos_bonus_roll(report)


func _resolve_double(roll: FateRollClass, report: Dictionary) -> void:
	var total := roll.total()
	var multiplier := 1.10
	var outcome := "RZUT LOSU"
	if roll.dice == [1, 1]:
		multiplier = 0.50
		outcome = "WĘŻOWE OCZY"
		_add_tokens(_bad_luck_tokens(2), report)
	elif total == 7:
		multiplier = 1.70
		outcome = "SZCZĘŚLIWA SIÓDEMKA"
		_add_tokens(2, report)
	elif roll.dice == [6, 6]:
		multiplier = 2.25
		outcome = "PODWÓJNA SZÓSTKA — JACKPOT"
		_add_tokens(1, report)
	elif roll.is_double():
		multiplier = 1.45
		outcome = "DUBLET"
	elif total <= 4:
		multiplier = 0.80
		outcome = "NISKI RZUT"
		_add_tokens(2, report)
	elif total >= 10:
		multiplier = 1.60
		outcome = "WYSOKI RZUT"
		_add_tokens(1, report)
	_apply_double_talents(roll, report)
	if _has("pierrot_double_stake") and (total <= 4 or total >= 10):
		multiplier *= 1.25
		_add_double_stake_note(report)
	multiplier = _favored_multiplier(multiplier)
	_resolve_damage(multiplier, 1, report)
	_set_roll_report(roll, outcome, report)
	if multiplier >= 1.70:
		_maybe_chaos_bonus_roll(report)


func _resolve_feint(roll: FateRollClass, report: Dictionary) -> void:
	var face: int = roll.dice[0]
	var outcome := "ZWÓD"
	match face:
		1:
			outcome = "PECH"
			_add_tokens(_bad_luck_tokens(2), report)
			combat.effects.apply_dodge(10, 1)
			report.skill_notes.append("PECH: UNIK +10 p.p. na następny atak.")
		2, 3:
			combat.effects.apply_dodge(20, 2)
			report.skill_notes.append("ZWÓD: UNIK +20 p.p. przez 2 ataki.")
		4, 5:
			outcome = "AKROBACJA"
			combat.effects.apply_dodge(35, 2)
			report.skill_notes.append("AKROBACJA: UNIK +35 p.p. przez 2 ataki.")
		6:
			outcome = "KURTYNA LUSTRZANA"
			combat.pierrot_reflect_ready = true
			report.skill_notes.append("Następny bezpośredni cios zostanie odbity.")
	_set_roll_report(roll, outcome, report)


func _resolve_grand_gamble(roll: FateRollClass, report: Dictionary) -> void:
	var total := roll.total()
	var multiplier := 0.85 + total * 0.055
	var outcome := "WIELKI ZAKŁAD"
	if roll.is_triple():
		multiplier = 2.55
		outcome = "TRÓJKA"
		_add_tokens(2, report)
	elif total <= 5:
		multiplier = 0.60
		outcome = "KATASTROFA"
		_add_tokens(_bad_luck_tokens(3), report)
	elif total >= 16:
		multiplier = 2.15
		outcome = "WIELKI JACKPOT"
		_add_tokens(2, report)
	elif roll.is_double():
		multiplier = 1.55
		outcome = "DUBLET WZMACNIA ZAKŁAD"
	_apply_double_talents(roll, report)
	if _has("pierrot_double_stake") and (total <= 5 or total >= 16):
		multiplier *= 1.25
		_add_double_stake_note(report)
	multiplier = _favored_multiplier(multiplier)
	_resolve_damage(multiplier, 1, report)
	_set_roll_report(roll, outcome, report)
	if multiplier >= 1.70:
		_maybe_chaos_bonus_roll(report)


func _resolve_va_banque(roll: FateRollClass, report: Dictionary) -> void:
	var wager: int = combat.fate_tokens
	combat.fate_tokens = 0
	var multiplier := 0.55 + roll.total() * 0.075 + wager * 0.14
	if roll.is_triple():
		multiplier += 0.75
	_apply_double_talents(roll, report)
	if _has("pierrot_double_stake") and (roll.total() <= 5 or roll.total() >= 16):
		multiplier *= 1.25
		_add_double_stake_note(report)
	multiplier = _favored_multiplier(multiplier)
	_resolve_damage(multiplier, 1, report)
	_set_roll_report(roll, "VA BANQUE", report)
	report.skill_notes.append("VA BANQUE: stawka %d Żetonów Losu." % wager)
	if multiplier >= 1.70:
		_maybe_chaos_bonus_roll(report)


func _apply_double_talents(roll: FateRollClass, report: Dictionary) -> void:
	if not roll.is_double():
		return
	if _has("pierrot_crooked_mirror"):
		combat.pierrot_reflect_ready = true
		report.class_effect_notes.append(
			"KRZYWE ZWIERCIADŁO: dublet przygotowuje odbicie następnego ataku."
		)
	if _has("two_lies"):
		_add_tokens(1, report)
		report.class_effect_notes.append("DWA KŁAMSTWA: dublet daje dodatkowy Żeton Losu.")


func _maybe_chaos_bonus_roll(report: Dictionary) -> void:
	if not _has("pierrot_wild_roll") or not combat.enemy.is_alive():
		return
	if _has("pierrot_domino") and combat.rng.randf() >= 0.50:
		return
	var roll: FateRollClass = combat.fate.roll(1)
	var multiplier: float = 0.20 + roll.dice[0] * 0.08
	var hit: Dictionary = combat.hit_resolver.resolve(
		_fate_power(), multiplier, true, false, "physical", 0.0, 0.0, true
	)
	report.skill_total_damage += hit.damage
	report.extra_player_critical = report.extra_player_critical or hit.critical
	report.class_effect_notes.append(
		(
			"EFEKT DOMINA: dodatkowy rzut k6 (%d) zadaje %d obrażeń%s."
			% [roll.dice[0], hit.damage, " krytycznych" if hit.critical else ""]
		)
	)


func _resolve_damage(multiplier: float, hits: int, report: Dictionary) -> void:
	for hit_index in hits:
		if not combat.enemy.is_alive():
			break
		var hit: Dictionary = combat.hit_resolver.resolve(
			_fate_power(), multiplier, true, false, "physical", 0.0, 0.0, true
		)
		report.player_hit_damages.append(hit.damage)
		report.player_hit_dodges.append(false)
		report.skill_total_damage += hit.damage
		if hit_index == 0:
			report.player_critical = hit.critical
		else:
			report.extra_player_critical = report.extra_player_critical or hit.critical
	report.player_damage = report.skill_total_damage
	report.enemy_dodged = false


func _fate_power() -> int:
	return maxi(1, combat.player.stats.attack + int(combat.player.attributes.luck / 2.0))


func _set_roll_report(roll: FateRollClass, outcome: String, report: Dictionary) -> void:
	report.fate_dice.assign(roll.dice)
	report.fate_total = roll.total()
	report.fate_outcome = outcome
	report.skill_notes.append("KOŚCI LOSU: %s — %s." % [_dice_text(roll.dice), outcome])


func _add_tokens(amount: int, report: Dictionary) -> void:
	var previous: int = combat.fate_tokens
	combat.fate_tokens = clampi(combat.fate_tokens + maxi(0, amount), 0, token_cap())
	var gained: int = combat.fate_tokens - previous
	if gained > 0:
		report.fate_tokens_gained += gained
		report.skill_notes.append(
			"ŻETONY LOSU: +%d (%d/%d)." % [gained, combat.fate_tokens, token_cap()]
		)


func _favored_multiplier(multiplier: float) -> float:
	if _has("fortuna_favored") and multiplier >= 1.50:
		return multiplier * (1.0 + minf(0.20, combat.player.attributes.luck * 0.004))
	return multiplier


func _bad_luck_tokens(base_amount: int) -> int:
	return base_amount + (1 if _has("fortuna_favored") else 0)


func _add_double_stake_note(report: Dictionary) -> void:
	report.class_effect_notes.append("PODWÓJNA STAWKA: skrajny wynik ma o 25% silniejszy skutek.")


func _has(mechanic_id: String) -> bool:
	return combat._has_class_mechanic(mechanic_id)


func _dice_text(dice: Array[int]) -> String:
	var values: Array[String] = []
	for value: int in dice:
		values.append(str(value))
	return "[" + ", ".join(values) + "]"
