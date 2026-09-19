extends GutTest

const SCENE := preload("res://ui/screens/combat/combat.tscn")
const NewGame := preload("res://core/game/new_game_service.gd")
const Saves := preload("res://core/save/save_game_service.gd")
const Plan := preload("res://ui/presentation/combat_presentation_plan.gd")
const Effect := preload("res://ui/presentation/combat_hit_effect.gd")


func test_partial_block_keeps_real_damage_in_plan_without_mutating_report() -> void:
	var report := {"enemy_acted": true, "shield_blocked": true, "enemy_damage": 3}
	var frozen := report.duplicate(true)
	var events := Plan.from_report(report)
	assert_eq(report, frozen)
	assert_eq(events[1].kind, "feedback")
	assert_eq(events[1].text, "BLOK  •  -3")
	assert_eq(events[1].amount, 3)
	assert_eq(Plan.from_report({"enemy_acted": true, "shield_blocked": true})[1].amount, 0)


func test_damage_and_partial_block_change_hp_and_text_only_at_impact() -> void:
	for report: Dictionary in [
		{"player_damage": 4}, {"enemy_acted": true, "shield_blocked": true, "enemy_damage": 3}
	]:
		var screen = _screen()
		var controller = screen._presentation_controller
		screen.set_reduced_motion(false)
		controller.animation_duration_scale = 0.35
		var before: Dictionary = controller.resource_snapshot(screen._session.player, screen._enemy)
		var after := before.duplicate()
		after.enemy_hp -= int(report.get("player_damage", 0))
		after.player_hp -= int(report.get("enemy_damage", 0))
		var impacts: Array[Dictionary] = []
		controller.impact_presented.connect(func(event: Dictionary) -> void: impacts.append(event))
		controller.present(Plan.from_report(report), before, after, 1)
		assert_eq(screen.enemy_hp_bar.value, float(before.enemy_hp))
		assert_eq(screen.player_hp_bar.value, float(before.player_hp))
		assert_true(controller.last_feedback_texts.is_empty())
		await controller.impact_presented
		assert_true(controller.is_busy())
		assert_eq(screen.enemy_hp_bar.value, float(after.enemy_hp))
		assert_eq(screen.player_hp_bar.value, float(after.player_hp))
		assert_eq(controller._feedback_labels.size(), 1)
		assert_false(controller.last_feedback_texts.is_empty())
		await controller.playback_finished
		assert_eq(impacts.size(), 1)
		assert_eq(screen.player_visual.rotation, 0.0)
		assert_eq(screen.enemy_visual.rotation, 0.0)


func test_reactions_have_distinct_motion_one_impact_and_restore_both_poses() -> void:
	var screen = _screen()
	var angles: Dictionary = {}
	for tone: String in ["damage", "critical", "dodge", "block"]:
		var effect := _effect(screen, {"tone": tone})
		var hits: Array[int] = []
		effect.impact.connect(func() -> void: hits.append(1))
		effect._sample(0.29)
		assert_true(hits.is_empty())
		assert_gt(screen.player_visual.rotation, 0.0, "Attacker leans toward the target.")
		effect._sample(0.30)
		assert_eq(hits.size(), 1)
		effect._sample(0.5)
		angles[tone] = screen.enemy_visual.rotation
		assert_gt(screen.enemy_visual.rotation, 0.0, "Target recoils away from the attacker.")
		assert_eq(hits.size(), 1)
		effect.cancel()
		for visual in [screen.player_visual, screen.enemy_visual]:
			assert_eq(visual.rotation, 0.0)
			assert_eq(visual.pivot_offset, Vector2.ZERO)
			assert_eq(visual.modulate, Color.WHITE)
		effect.free()
	assert_gt(angles.critical, angles.damage)
	assert_gt(angles.dodge, angles.damage)
	assert_lt(angles.block, angles.damage)


func test_passive_damage_does_not_invent_another_attack() -> void:
	var screen = _screen()
	var events := Plan.from_report(
		{
			"enemy_acted": true,
			"boss_aura_damage": 1,
			"reflected_damage": 2,
			"enemy_bleed_damage": 3,
			"warrior_counter_damage": 4
		}
	)
	for event: Dictionary in events:
		if event.kind != "damage":
			continue
		if event.prefix == "KONTRA":
			assert_true(event.direct_attack)
			continue
		assert_false(event.direct_attack)
		var effect := _effect(screen, event)
		effect._sample(0.2)
		assert_eq(effect._actor, null)
		assert_eq(screen.player_visual.rotation, 0.0)
		assert_eq(screen.enemy_visual.rotation, 0.0)
		effect.free()


func test_removing_effect_mid_animation_restores_original_transforms() -> void:
	var screen = _screen()
	screen.player_visual.rotation = 0.01
	screen.enemy_visual.pivot_offset = Vector2(6, 9)
	var effect := _effect(screen, {})
	effect._sample(0.5)
	effect.free()
	assert_almost_eq(screen.player_visual.rotation, 0.01, 0.000001)
	assert_eq(screen.enemy_visual.rotation, 0.0)
	assert_eq(screen.enemy_visual.pivot_offset, Vector2(6, 9))


func test_reduced_feedback_is_static_bounded_readable_and_outside_hud() -> void:
	var screen = _screen()
	var controller = screen._presentation_controller
	screen.set_reduced_motion(true)
	for dimensions: Vector2 in [
		Vector2(1280, 720), Vector2(1366, 768), Vector2(1920, 1080), Vector2(2560, 1080)
	]:
		screen.size = dimensions
		await _settle()
		var state: Dictionary = controller.resource_snapshot(screen._session.player, screen._enemy)
		controller.present(
			Plan.from_report(
				{
					"player_damage": 4,
					"player_critical": true,
					"reflected_damage": 2,
					"enemy_bleed_damage": 1,
					"enemy_acted": true,
					"shield_blocked": true,
					"enemy_damage": 3
				}
			),
			state,
			state,
			1
		)
		await _settle()
		assert_false(controller.is_busy())
		assert_eq(controller._feedback_labels.size(), 4)
		for label in controller._feedback_labels:
			var rect: Rect2 = label.get_global_rect()
			assert_true(screen.get_global_rect().encloses(rect), str(dimensions))
			assert_false(label.hud.get_global_rect().intersects(rect), "HUD must remain readable.")
			assert_gte(label.get_theme_font_size("font_size"), 32)
			assert_eq(label.mouse_filter, Control.MOUSE_FILTER_IGNORE)
			var origin: Vector2 = label.position
			label._process(0.2)
			assert_almost_eq(
				label.position,
				origin,
				Vector2(0.001, 0.001),
				"Reduced feedback must not float or fade."
			)
			assert_eq(label.modulate.a, 1.0)
			for other in controller._feedback_labels:
				if other != label and other.target == label.target:
					assert_false(
						other.get_global_rect().intersects(rect), "Feedback lanes overlap."
					)
		assert_eq(screen.player_visual.rotation, 0.0)
		assert_eq(screen.enemy_visual.rotation, 0.0)
		controller.clear_feedback()
		assert_true(controller._feedback_labels.is_empty())


func test_feedback_expires_and_new_turn_and_result_clear_old_labels() -> void:
	var screen = _screen()
	var controller = screen._presentation_controller
	screen.set_reduced_motion(true)
	controller._show_floating_text(screen.player_visual, "UNIK", "dodge")
	var label = controller._feedback_labels[0]
	label._process(1.7)
	await get_tree().process_frame
	assert_false(is_instance_valid(label))
	controller._show_floating_text(screen.player_visual, "BLOK", "block")
	var state: Dictionary = controller.resource_snapshot(screen._session.player, screen._enemy)
	controller.present(Plan.from_report({"enemy_dodged": true}), state, state, 1)
	assert_eq(controller._feedback_labels.size(), 1)
	assert_eq(controller._feedback_labels[0].text, "UNIK")
	controller.reveal_result(screen.result_panel)
	assert_true(controller._feedback_labels.is_empty())


func test_effect_follows_resized_painted_target_without_moving_layout() -> void:
	var screen = _screen()
	var effect := _effect(screen, {})
	for dimensions: Vector2 in [Vector2(1366, 768), Vector2(1920, 1080), Vector2(2560, 1080)]:
		screen.size = dimensions
		await _settle()
		var player_position: Vector2 = screen.player_visual.position
		var enemy_position: Vector2 = screen.enemy_visual.position
		effect._sample(0.5)
		assert_true(
			Effect.painted_rect(screen.enemy_visual).has_point(
				effect.destination + effect.global_position
			)
		)
		assert_eq(screen.player_visual.position, player_position)
		assert_eq(screen.enemy_visual.position, enemy_position)
	effect.free()


func test_actual_turns_have_identical_domain_and_rng_in_full_and_reduced_motion() -> void:
	for class_code: String in ["warrior", "mage", "hunter", "pierrot"]:
		var fixture = _screen(class_code)
		var payload: Dictionary = Saves.new("user://unused-impact-test")._serialize_session(
			fixture._session
		)
		var states: Array[Dictionary] = []
		for reduced: bool in [true, false]:
			# Clone exactly the same player/items/weather, not two randomized new games.
			var screen = _screen(class_code, payload)
			screen.set_reduced_motion(reduced)
			for turn in 3:
				screen.attack_button.pressed.emit()
				if not reduced:
					assert_true(screen.attack_button.disabled)
					var hp: int = screen._enemy.current_hp
					screen.attack_button.pressed.emit()
					assert_eq(
						screen._enemy.current_hp, hp, "Double input cannot resolve another turn."
					)
				if screen._presentation_controller.is_busy():
					await screen._presentation_controller.playback_finished
				assert_eq(screen.enemy_hp_bar.value, float(screen._enemy.current_hp))
				assert_eq(
					screen.player_hp_bar.value, float(screen._session.player.stats.current_hp)
				)
			var state: Dictionary = Saves.new("user://unused-impact-test")._serialize_session(
				screen._session
			)
			state.erase("saved_at_unix")
			state["enemy_hp"] = screen._enemy.current_hp
			state["rng"] = screen._engine.rng.state
			states.append(state)
		assert_eq(
			states[0], states[1], class_code + ": presentation must not change simulation or saves."
		)


func _screen(class_code := "warrior", payload: Dictionary = {}):
	var session
	if payload.is_empty():
		session = NewGame.new().create_session("Aria", 1, null, "female")
		session.player.level = 12
		session.player.choose_class(class_code)
		session.player.stats.restore_full()
	else:
		var loaded := Saves.new("user://unused-impact-test")._deserialize_payload(
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
	screen._enemy.attack = 1
	screen._enemy.dodge = 0.0
	screen._engine.rng.seed = 907
	screen._presentation_controller.animation_duration_scale = 0.01
	screen._render()
	return screen


func _effect(screen, event: Dictionary) -> Effect:
	var effect := Effect.new()
	screen.get_node("%FeedbackLayer").add_child(effect)
	effect.start(screen.player_visual, screen.enemy_visual, event, 100.0)
	effect._tween.kill()
	return effect


func _settle() -> void:
	for frame in 4:
		await get_tree().process_frame
