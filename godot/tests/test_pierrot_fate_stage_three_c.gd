extends GutTest

const COMBAT_SCENE := preload("res://ui/screens/combat/combat.tscn")
const CombatEnemyClass := preload("res://core/combat/enemy.gd")
const CombatEngineClass := preload("res://core/combat/combat_engine.gd")
const CombatScreenClass := preload("res://ui/screens/combat/combat.gd")
const FateEngineClass := preload("res://core/combat/fate_engine.gd")
const FateRollClass := preload("res://core/combat/fate_roll.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const PlayerEquipmentClass := preload("res://core/player/equipment.gd")
const PlayerFactoryClass := preload("res://core/player/player_factory.gd")
const PlayerProfileClass := preload("res://core/player/player_profile.gd")


func test_fate_roll_tracks_values_total_doubles_triples_and_history() -> void:
	var values: Array[int] = [2, 2, 2]
	var fate := FateEngineClass.new(RandomNumberGenerator.new(), _roller(values))
	var roll: FateRollClass = fate.roll(3)

	assert_eq(roll.dice, [2, 2, 2])
	assert_eq(roll.original_dice, [2, 2, 2])
	assert_eq(roll.total(), 6)
	assert_true(roll.is_double())
	assert_true(roll.is_triple())
	assert_eq(fate.history.size(), 1)
	assert_same(fate.history[0], roll)


func test_fate_thrust_preserves_every_one_die_damage_table_result() -> void:
	var expected_damage := {1: 4, 2: 5, 3: 6, 4: 6, 5: 8, 6: 9}
	var expected_tokens := {1: 2, 2: 0, 3: 0, 4: 0, 5: 0, 6: 1}
	for face: int in range(1, 7):
		var combat := _combat(5, 100, 0, 0)
		_rig_dice(combat, [face])

		var report := combat.player_use_skill("fate_thrust")

		assert_eq(report.fate_dice, [face], "Nieprawidłowy rzut dla ścianki %d." % face)
		assert_eq(report.player_damage, expected_damage[face], "Nieprawidłowe obrażenia.")
		assert_eq(report.fate_tokens_gained, expected_tokens[face], "Nieprawidłowe żetony.")
		if face == 5:
			assert_eq(report.player_hit_damages, [4, 4])


func test_double_roll_preserves_special_totals_doubles_and_ranges() -> void:
	var cases := [
		{"dice": [1, 1], "damage": 2, "tokens": 2, "outcome": "WĘŻOWE OCZY"},
		{"dice": [3, 4], "damage": 8, "tokens": 2, "outcome": "SZCZĘŚLIWA SIÓDEMKA"},
		{"dice": [6, 6], "damage": 11, "tokens": 1, "outcome": "PODWÓJNA SZÓSTKA"},
		{"dice": [4, 4], "damage": 7, "tokens": 0, "outcome": "DUBLET"},
		{"dice": [1, 3], "damage": 4, "tokens": 2, "outcome": "NISKI RZUT"},
		{"dice": [4, 6], "damage": 8, "tokens": 1, "outcome": "WYSOKI RZUT"},
		{"dice": [3, 5], "damage": 6, "tokens": 0, "outcome": "RZUT LOSU"},
	]
	for test_case: Dictionary in cases:
		var combat := _combat(7, 100, 0, 0)
		_rig_dice(combat, test_case.dice)

		var report := combat.player_use_skill("double_roll")

		assert_eq(report.fate_dice, test_case.dice)
		assert_eq(report.player_damage, test_case.damage)
		assert_eq(report.fate_tokens_gained, test_case.tokens)
		assert_string_contains(report.fate_outcome, test_case.outcome)


func test_grand_gamble_preserves_triples_extremes_doubles_and_normal_formula() -> void:
	var cases := [
		{"dice": [2, 2, 2], "damage": 13, "tokens": 2, "outcome": "TRÓJKA"},
		{"dice": [1, 1, 3], "damage": 3, "tokens": 3, "outcome": "KATASTROFA"},
		{"dice": [6, 5, 5], "damage": 11, "tokens": 2, "outcome": "WIELKI JACKPOT"},
		{"dice": [3, 3, 4], "damage": 8, "tokens": 0, "outcome": "DUBLET"},
		{"dice": [2, 3, 4], "damage": 7, "tokens": 0, "outcome": "WIELKI ZAKŁAD"},
	]
	for test_case: Dictionary in cases:
		var combat := _combat(12, 100, 0, 0)
		_rig_dice(combat, test_case.dice)

		var report := combat.player_use_skill("grand_gamble")

		assert_eq(report.fate_dice, test_case.dice)
		assert_eq(report.player_damage, test_case.damage)
		assert_eq(report.fate_tokens_gained, test_case.tokens)
		assert_string_contains(report.fate_outcome, test_case.outcome)


func test_fate_feint_ranges_and_mirror_are_encounter_local() -> void:
	var feint_cases := [
		{"face": 1, "remaining_dodge_hits": 0, "tokens": 2, "outcome": "PECH"},
		{"face": 2, "remaining_dodge_hits": 1, "tokens": 0, "outcome": "ZWÓD"},
		{"face": 4, "remaining_dodge_hits": 1, "tokens": 0, "outcome": "AKROBACJA"},
	]
	for test_case: Dictionary in feint_cases:
		var combat := _combat(9, 100, 0, 0)
		_rig_dice(combat, [test_case.face])
		var report := combat.player_use_skill("fate_feint")
		assert_eq(combat.effects.player_dodge_bonus_hits, test_case.remaining_dodge_hits)
		assert_eq(report.fate_tokens_gained, test_case.tokens)
		assert_eq(report.fate_outcome, test_case.outcome)

	var mirror_combat := _combat(9, 20, 10, 0)
	mirror_combat.player.stats.dodge = 0.0
	var hp_before: int = mirror_combat.player.stats.current_hp
	_rig_dice(mirror_combat, [6])
	var mirror_report := mirror_combat.player_use_skill("fate_feint")

	assert_eq(mirror_report.enemy_damage, 0)
	assert_eq(mirror_report.reflected_damage, 8)
	assert_eq(mirror_combat.player.stats.current_hp, hp_before)
	assert_false(mirror_combat.pierrot_reflect_ready)


func test_reflection_can_end_combat_before_an_extra_enemy_attack() -> void:
	var combat := _combat(9, 5, 10, 0)
	combat.player.stats.dodge = 0.0
	combat.enemy.extra_attack_chance = 1.0
	_rig_dice(combat, [6])

	var report := combat.player_use_skill("fate_feint")

	assert_eq(report.reflected_damage, 5)
	assert_eq(combat.result, CombatEngineClass.VICTORY)
	assert_eq(combat.enemy.attacks_made, 1)
	assert_eq(report.enemy_extra_damage, 0)


func test_fate_token_cap_scales_with_luck_and_clamps_actual_gain() -> void:
	var combat := _combat(5, 100, 0, 0)
	combat.player.attributes.luck = 45
	combat.fate_tokens = 9
	_rig_dice(combat, [1])

	var report := combat.player_use_skill("fate_thrust")

	assert_eq(combat.fate_token_cap(), 10)
	assert_eq(combat.fate_tokens, 10)
	assert_eq(report.fate_tokens_gained, 1)
	assert_eq(report.fate_token_cap, 10)


func test_invalid_fate_skill_spends_neither_mana_nor_turn_and_rolls_no_dice() -> void:
	var player := _pierrot(5)
	player.unequip_to_inventory(PlayerEquipmentClass.WEAPON)
	var combat := CombatEngineClass.new(player, _enemy(100, 4, 0))
	var mana_before: int = player.stats.current_mana

	var missing_lance := combat.player_use_skill("fate_thrust")

	assert_string_contains(missing_lance.error, "Lancy Losu")
	assert_eq(player.stats.current_mana, mana_before)
	assert_eq(combat.enemy.attacks_made, 0)
	assert_eq(combat.fate.history.size(), 0)

	var no_mana_player := _pierrot(5)
	no_mana_player.stats.current_mana = 0
	var no_mana_combat := CombatEngineClass.new(no_mana_player, _enemy(100, 4, 0))
	var no_mana := no_mana_combat.player_use_skill("fate_thrust")
	assert_string_contains(no_mana.error, "Brak Many")
	assert_false(no_mana.turn_consumed)
	assert_eq(no_mana_combat.enemy.attacks_made, 0)
	assert_eq(no_mana_combat.fate.history.size(), 0)


func test_python_half_even_rounding_is_preserved_for_existing_and_fate_skills() -> void:
	var warrior = PlayerFactoryClass.create_player("Tester")
	warrior.level = 5
	assert_true(warrior.choose_class("warrior"))
	warrior.stats.attack = 3
	warrior.stats.current_mana = warrior.stats.max_mana
	var warrior_combat := CombatEngineClass.new(warrior, _enemy(100, 0, 0))

	var power_slash := warrior_combat.player_use_skill("power_slash")

	assert_eq(power_slash.player_damage, 4, "Python zaokrągla 4.5 do parzystej liczby 4.")
	var fate_combat := _combat(7, 100, 0, 0)
	_rig_dice(fate_combat, [1, 1])
	assert_eq(fate_combat.player_use_skill("double_roll").player_damage, 2)


func test_pierrot_combat_panel_adapts_to_one_two_and_three_dice() -> void:
	for test_case: Dictionary in [
		{"skill_id": "fate_thrust", "dice": [3]},
		{"skill_id": "double_roll", "dice": [3, 4]},
		{"skill_id": "grand_gamble", "dice": [2, 3, 4]},
	]:
		var session = NewGameServiceClass.new().create_session("Aria", 1)
		session.player.level = 5
		assert_true(session.player.choose_class("pierrot"))
		session.player.level = 12
		session.player.stats.restore_full()
		var screen := COMBAT_SCENE.instantiate() as CombatScreenClass
		screen.configure(session, "prologue_scarecrow", "prologue")
		add_child_autofree(screen)
		# Test the dice layout during combat; a killing roll is cleared on the result screen.
		screen._enemy.max_hp = 1000
		screen._enemy.current_hp = 1000
		_rig_dice(screen._engine, test_case.dice)
		_select_skill(screen, test_case.skill_id)

		screen.skill_button.pressed.emit()

		assert_eq(screen._engine.result, CombatEngineClass.ONGOING)
		assert_true(screen.fate_panel.visible)
		assert_eq(screen.dice_row.get_child_count(), test_case.dice.size())
		assert_false(screen.fate_outcome_label.text.is_empty())
		screen.queue_free()


func test_pierrot_fate_panel_fits_the_720p_combat_header() -> void:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_child(host)
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 5
	assert_true(session.player.choose_class("pierrot"))
	session.player.level = 12
	var screen := COMBAT_SCENE.instantiate() as CombatScreenClass
	screen.configure(session, "prologue_scarecrow", "prologue")
	host.add_child(screen)
	await get_tree().process_frame

	assert_false(screen.fate_panel.visible)
	screen.set_reduced_motion(true)
	_rig_dice(screen._engine, [3])
	_select_skill(screen, "fate_thrust")
	screen.skill_button.pressed.emit()
	await get_tree().process_frame

	assert_true(screen.fate_panel.visible)
	assert_lte(screen.fate_panel.get_global_rect().end.x, screen.get_global_rect().end.x)
	var arena: Control = screen.get_node("Page/Arena")
	assert_gte(
		screen.fate_panel.get_global_rect().position.y,
		arena.get_global_rect().position.y,
	)
	assert_lte(
		screen.fate_panel.get_global_rect().end.y,
		arena.get_global_rect().end.y,
	)
	host.free()


func _combat(level: int, enemy_hp: int, enemy_attack: int, enemy_defense: int) -> CombatEngineClass:
	var player := _pierrot(level)
	return CombatEngineClass.new(player, _enemy(enemy_hp, enemy_attack, enemy_defense))


func _pierrot(level: int) -> PlayerProfileClass:
	var player = PlayerFactoryClass.create_player("Tester")
	player.level = 5
	assert_true(player.choose_class("pierrot"))
	player.level = level
	player.stats.restore_full()
	return player


func _enemy(hp: int, attack: int, defense: int) -> CombatEnemyClass:
	return (
		CombatEnemyClass
		. new(
			{
				"enemy_id": "fate_target",
				"display_name": "Cel Losu",
				"max_hp": hp,
				"attack": attack,
				"defense": defense,
				"dodge": 0.0,
			}
		)
	)


func _rig_dice(combat: CombatEngineClass, values: Array) -> void:
	var typed_values: Array[int] = []
	typed_values.assign(values)
	combat.fate = FateEngineClass.new(combat.rng, _roller(typed_values))


func _roller(values: Array[int]) -> Callable:
	return func() -> int: return values.pop_front()


func _select_skill(screen: CombatScreenClass, skill_id: String) -> void:
	for index in screen.skill_selector.item_count:
		if str(screen.skill_selector.get_item_metadata(index)) == skill_id:
			screen.skill_selector.select(index)
			screen.skill_selector.item_selected.emit(index)
			return
	fail_test("Nie znaleziono umiejętności w panelu walki: %s" % skill_id)
