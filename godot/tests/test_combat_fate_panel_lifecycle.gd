extends GutTest

const COMBAT_SCENE := preload("res://ui/screens/combat/combat.tscn")
const CombatEngineClass := preload("res://core/combat/combat_engine.gd")
const CombatScreenClass := preload("res://ui/screens/combat/combat.gd")
const FateEngineClass := preload("res://core/combat/fate_engine.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")


func test_initial_pierrot_screen_has_no_pending_roll() -> void:
	var screen := _screen()
	_assert_no_roll(screen)
	assert_string_contains(screen.class_resource_label.text, "ŻETONY")
	assert_eq(screen._engine.fate.history.size(), 0)


func test_basic_attack_victory_never_displays_a_die_in_either_motion_mode() -> void:
	for reduced: bool in [true, false]:
		var screen := _screen()
		screen.set_reduced_motion(reduced)
		screen._enemy.current_hp = 1
		screen.attack_button.pressed.emit()
		_assert_no_roll(screen)
		if screen._presentation_controller.is_busy():
			await screen._presentation_controller.playback_finished
		assert_eq(screen._engine.result, CombatEngineClass.VICTORY)
		assert_true(screen.result_panel.visible)
		assert_eq(screen._engine.fate.history.size(), 0)
		_assert_no_roll(screen)


func test_real_roll_is_visible_during_and_after_an_ongoing_skill() -> void:
	for reduced: bool in [true, false]:
		var screen := _screen()
		screen.set_reduced_motion(reduced)
		_roll(screen)
		assert_true(screen.fate_panel.visible)
		assert_eq(screen.dice_row.get_child_count(), 1)
		if screen._presentation_controller.is_busy():
			await screen._presentation_controller.playback_finished
		assert_eq(screen._engine.result, CombatEngineClass.ONGOING)
		assert_true(screen.fate_panel.visible)
		assert_eq(screen.dice_row.get_child(0).value, 3)
		assert_false(screen.fate_outcome_label.text.is_empty())
		assert_eq(screen._engine.fate.history.size(), 1)


func test_killing_skill_plays_its_real_roll_then_clears_it_on_victory() -> void:
	for reduced: bool in [true, false]:
		var screen := _screen()
		screen.set_reduced_motion(reduced)
		screen._enemy.current_hp = 1
		_roll(screen)
		assert_eq(screen._engine.result, CombatEngineClass.VICTORY)
		if not reduced:
			assert_true(screen._presentation_controller.is_busy())
			assert_false(screen.result_panel.visible)
			assert_true(screen.fate_panel.visible, "The killing skill must still animate its roll.")
			assert_eq(screen.dice_row.get_child_count(), 1)
			await screen._presentation_controller.playback_finished
		assert_true(screen.result_panel.visible)
		assert_eq(screen._engine.fate.history.size(), 1)
		_assert_no_roll(screen)


func test_attack_defend_and_potion_clear_the_previous_skills_dice() -> void:
	for action: String in ["attack", "defend", "potion"]:
		var screen := _screen()
		_roll(screen)
		assert_true(screen.fate_panel.visible)
		screen._session.player.stats.current_hp = 10
		screen._render()
		var button := screen.get(action + "_button") as Button
		assert_false(button.disabled, action)
		button.pressed.emit()
		assert_eq(screen._engine.result, CombatEngineClass.ONGOING)
		assert_eq(screen._round_number, 3, action)
		assert_eq(screen._engine.fate.history.size(), 1, action)
		_assert_no_roll(screen)


func test_a_roll_that_ends_in_defeat_is_cleared() -> void:
	var screen := _screen()
	screen._session.player.stats.current_hp = 1
	screen._session.player.stats.dodge = 0.0
	screen._enemy.attack = 10000
	_roll(screen)
	assert_eq(screen._engine.result, CombatEngineClass.DEFEAT)
	assert_true(screen.result_panel.visible)
	_assert_no_roll(screen)


func test_successful_flee_clears_the_previous_roll() -> void:
	var screen := _screen()
	_roll(screen)
	var probe := RandomNumberGenerator.new()
	for candidate in 100:
		probe.seed = candidate
		if probe.randf() < 0.5:
			screen._engine.rng.seed = candidate
			break
	screen.flee_button.pressed.emit()
	assert_eq(screen._engine.result, CombatEngineClass.FLED)
	assert_true(screen.result_panel.visible)
	_assert_no_roll(screen)


func test_reusing_a_screen_clears_dice_from_the_previous_encounter() -> void:
	var screen := _screen()
	_roll(screen)
	assert_true(screen.fate_panel.visible)
	screen.configure(screen._session, "prologue_scarecrow", "prologue")
	assert_false(screen.result_panel.visible)
	_assert_no_roll(screen)


func _screen() -> CombatScreenClass:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 12
	assert_true(session.player.choose_class("pierrot"))
	session.player.stats.restore_full()
	session.player.inventory.add("weak_healing_potion")
	var screen := COMBAT_SCENE.instantiate() as CombatScreenClass
	screen.configure(session, "prologue_scarecrow", "prologue")
	add_child_autoqfree(screen)
	screen.set_reduced_motion(true)
	screen._presentation_controller.animation_duration_scale = 0.01
	screen._enemy.max_hp = 1000
	screen._enemy.current_hp = 1000
	screen._enemy.defense = 0
	screen._enemy.dodge = 0.0
	screen._enemy.attack = 0
	return screen


func _roll(screen: CombatScreenClass) -> void:
	screen._engine.fate = FateEngineClass.new(screen._engine.rng, func() -> int: return 3)
	screen._use_skill_id("fate_thrust")


func _assert_no_roll(screen: CombatScreenClass) -> void:
	assert_false(screen.fate_panel.visible)
	assert_eq(screen.dice_row.get_child_count(), 0)
	assert_eq(screen.fate_outcome_label.text, "")
	assert_true(screen._last_fate_dice.is_empty())
	assert_eq(screen._last_fate_outcome, "")
