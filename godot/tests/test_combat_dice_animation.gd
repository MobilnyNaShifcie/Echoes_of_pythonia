extends GutTest

const DIE := preload("res://ui/components/combat_die/combat_die.tscn")
const Die := preload("res://ui/components/combat_die/combat_die.gd")
const SCENE := preload("res://ui/screens/combat/combat.tscn")
const NewGame := preload("res://core/game/new_game_service.gd")
const Saves := preload("res://core/save/save_game_service.gd")
const Fate := preload("res://core/combat/fate_engine.gd")
const Plan := preload("res://ui/presentation/combat_presentation_plan.gd")


func test_each_result_has_correct_pips_and_a_fixed_physical_face() -> void:
	var die = _die()
	for result in range(1, 7):
		die.set_value(result)
		var faces: Array = die._visible_faces()
		assert_eq(faces.back()[0], result, "Largest face must show the authoritative result.")
		assert_eq(Die.pip_positions(result).size(), result)
		assert_eq(die.value, result)
		assert_false(die.rolling)
		assert_eq(die.roll_progress, 1.0)
		assert_string_contains(die.tooltip_text, "wynik %d" % result)
		for face: Array in Die.FACES:
			for other: Array in Die.FACES:
				if face[1] == -other[1]:
					assert_eq(face[0] + other[0], 7)
				assert_eq(face[1].length(), 1.0)
				assert_almost_eq(face[1].dot(face[2]), 0.0, 0.0001)


func test_roll_has_rotation_lift_bounce_and_a_stable_final_pose() -> void:
	var die = _die()
	die.set_value(5, false)
	var initial: Basis = die._pose
	die.sample_roll(0.3)
	assert_ne(die._pose, initial)
	assert_gt(die._lift, 10.0)
	assert_eq(die.value, 5, "Presentation never rerolls or changes the stored result.")
	die.sample_roll(0.6)
	assert_almost_eq(die._lift, 0.0, 0.001)
	assert_gt(die._squash, 0.08)
	die.sample_roll(0.725)
	assert_almost_eq(die._lift, 5.0, 0.001)
	die.sample_roll(1.0)
	assert_eq(die._pose, Die.settled_pose(5))
	assert_eq(die._lift, 0.0)
	assert_eq(die._shift, 0.0)
	assert_eq(die._squash, 0.0)
	assert_false(die.rolling)


func test_motion_is_bounded_and_other_dice_do_not_move_in_lockstep() -> void:
	var die = _die()
	var poses: Array[Basis] = []
	for index in 3:
		die.sample_roll(0.25, index)
		poses.append(die._pose)
	assert_ne(poses[0], poses[1])
	assert_ne(poses[1], poses[2])
	for result in range(1, 7):
		die.set_value(result, false)
		for index in 3:
			var inside := true
			for step in 101:
				die.sample_roll(step / 100.0, index)
				var center: Vector2 = (
					die.size * Vector2(0.5, 0.56) + Vector2(die._shift, -die._lift)
				)
				for face: Array in die._visible_faces():
					for corner: Vector2 in [
						Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)
					]:
						var point: Vector2 = die._project(face, corner, center, 25.0)
						inside = (
							inside
							and Rect2(Vector2.ONE, die.size - Vector2.ONE * 2).has_point(point)
						)
			assert_true(
				inside, "Result %d / die %d stays inside its allocated cell." % [result, index]
			)


func test_multiple_dice_finish_in_order_before_outcome_and_preserve_report() -> void:
	var screen = _screen()
	var controller = screen._presentation_controller
	controller.animation_duration_scale = 0.5
	screen.set_reduced_motion(false)
	var report := {"fate_dice": [2, 5, 6], "fate_outcome": "Wynik testu"}
	var frozen := report.duplicate(true)
	var state: Dictionary = controller.resource_snapshot(screen._session.player, screen._enemy)
	controller.present(Plan.from_report(report), state, state, 1)
	assert_eq(screen.fate_outcome_label.text, "KOŚCI W RUCHU…")
	assert_eq(screen.dice_row.get_child_count(), 3)
	await get_tree().create_timer(0.12).timeout
	var first = screen.dice_row.get_child(0)
	var last = screen.dice_row.get_child(2)
	assert_true(first.rolling)
	assert_gt(first.roll_progress, last.roll_progress)
	assert_eq(screen.fate_outcome_label.text, "KOŚCI W RUCHU…")
	await controller.playback_finished
	assert_eq(report, frozen)
	assert_eq(screen.fate_outcome_label.text, "Wynik testu")
	for index in 3:
		var die = screen.dice_row.get_child(index)
		assert_false(die.rolling)
		assert_eq(die.value, report.fate_dice[index])
		assert_eq(die._visible_faces().back()[0], die.value)


func test_reduced_motion_is_immediate_static_and_has_the_same_faces() -> void:
	var screen = _screen()
	var controller = screen._presentation_controller
	screen.set_reduced_motion(true)
	var state: Dictionary = controller.resource_snapshot(screen._session.player, screen._enemy)
	controller.present(
		Plan.from_report({"fate_dice": [1, 4, 6], "fate_outcome": "Wynik bez animacji"}),
		state,
		state,
		1
	)
	assert_false(controller.is_busy())
	var poses: Array[Basis] = []
	for die in screen.dice_row.get_children():
		assert_false(die.rolling)
		assert_eq(die._visible_faces().back()[0], die.value)
		poses.append(die._pose)
	await get_tree().create_timer(0.1).timeout
	for index in 3:
		assert_eq(screen.dice_row.get_child(index)._pose, poses[index])
	assert_eq(screen.fate_outcome_label.text, "Wynik bez animacji")


func test_new_minimum_height_never_moves_dice_over_turn_queue_or_resource_hud() -> void:
	for dimensions: Vector2 in [
		Vector2(1280, 720), Vector2(1366, 768), Vector2(1920, 1080), Vector2(2560, 1080)
	]:
		var screen = _screen()
		screen.size = dimensions
		for count in range(1, 4):
			var values: Array[int] = []
			for index in count:
				values.append(index + 2)
			screen.fate_panel.show()
			screen.fate_status_label.text = "LOS 0 • ŻETONY 0/6"
			screen._presentation_controller.render_dice(values, "Czytelny wynik rzutu")
			for frame in 4:
				await get_tree().process_frame
			var rect: Rect2 = screen.fate_panel.get_global_rect()
			assert_true(screen.get_global_rect().encloses(rect))
			for path: String in [
				"Page/Arena/TurnQueueBackdrop", "Page/Arena/PlayerPanel", "Page/Arena/EnemyPanel"
			]:
				assert_false(screen.get_node(path).get_global_rect().intersects(rect), path)
			for die in screen.dice_row.get_children():
				assert_true(rect.encloses(die.get_global_rect()))
				assert_eq(die.mouse_filter, Control.MOUSE_FILTER_IGNORE)
				die.sample_roll(0.3)
			assert_true(screen.fate_outcome_label.get_global_rect().end.y <= rect.end.y)


func test_freeing_screen_during_roll_cancels_the_bound_animation() -> void:
	var screen = _screen()
	var controller = screen._presentation_controller
	screen.set_reduced_motion(false)
	controller.animation_duration_scale = 0.15
	var state: Dictionary = controller.resource_snapshot(screen._session.player, screen._enemy)
	controller.present(Plan.from_report({"fate_dice": [2, 3, 5]}), state, state, 1)
	var die = screen.dice_row.get_child(0)
	screen.queue_free()
	await get_tree().create_timer(0.3).timeout
	assert_false(is_instance_valid(controller))
	assert_false(is_instance_valid(die))


func test_real_one_two_three_die_skills_preserve_simulation_rng_and_saved_data() -> void:
	var fixture = _screen()
	var codec := Saves.new("user://unused-dice-animation")
	var payload: Dictionary = codec._serialize_session(fixture._session)
	for skill_id: String in ["fate_thrust", "double_roll", "grand_gamble"]:
		var states: Array[Dictionary] = []
		for reduced: bool in [true, false]:
			var screen = _screen(payload)
			screen.set_reduced_motion(reduced)
			screen._use_skill_id(skill_id)
			assert_eq(screen._engine.fate.history.size(), 1)
			if not reduced:
				assert_true(screen.attack_button.disabled)
				var hp: int = screen._enemy.current_hp
				screen._use_skill_id(skill_id)
				assert_eq(screen._enemy.current_hp, hp)
				assert_eq(screen._engine.fate.history.size(), 1)
			if screen._presentation_controller.is_busy():
				await screen._presentation_controller.playback_finished
			var state: Dictionary = codec._serialize_session(screen._session)
			state.erase("saved_at_unix")
			state["rng"] = screen._engine.rng.state
			state["enemy_hp"] = screen._enemy.current_hp
			state["dice"] = screen._engine.fate.history[0].dice.duplicate()
			states.append(state)
			for index in screen.dice_row.get_child_count():
				assert_eq(screen.dice_row.get_child(index).value, state.dice[index])
		assert_eq(states[0], states[1], skill_id)


func _die():
	var die = DIE.instantiate()
	add_child_autoqfree(die)
	die.size = Vector2(100, 108)
	return die


func _screen(payload: Dictionary = {}):
	var session
	if payload.is_empty():
		session = NewGame.new().create_session("Aria", 1, null, "female")
		session.player.level = 12
		session.player.choose_class("pierrot")
		session.player.stats.restore_full()
	else:
		var loaded := Saves.new("user://unused-dice-animation")._deserialize_payload(
			payload.duplicate(true), 1
		)
		assert_true(loaded.ok)
		session = loaded.session
	var screen = SCENE.instantiate()
	screen.configure(session, "wolf", "expedition")
	add_child_autoqfree(screen)
	screen.set_anchors_preset(Control.PRESET_TOP_LEFT)
	screen.size = Vector2(1920, 1080)
	screen._enemy.max_hp = 1000
	screen._enemy.current_hp = 1000
	screen._enemy.attack = 0
	screen._enemy.dodge = 0.0
	screen._engine.rng.seed = 907
	screen._presentation_controller.animation_duration_scale = 0.01
	screen._presentation_controller.audio_feedback.set_muted(true)
	screen._render()
	return screen
