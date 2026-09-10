extends GutTest

const SCENE := preload("res://ui/screens/combat/combat.tscn")
const NewGame := preload("res://core/game/new_game_service.gd")
const Fate := preload("res://core/combat/fate_engine.gd")
const Plan := preload("res://ui/presentation/combat_presentation_plan.gd")
const Effect := preload("res://ui/presentation/fate_thrust_effect.gd")


func test_thrust_plan_preserves_each_real_hit_and_bonus_without_mutating_report() -> void:
	var report := {
		"skill_id": "fate_thrust",
		"fate_dice": [5],
		"player_hit_damages": [13, 17],
		"skill_total_damage": 34,
		"player_critical": true,
		"enemy_bleed_damage": 2
	}
	var frozen := report.duplicate(true)
	var events := Plan.from_report(report)
	assert_eq(report, frozen)
	assert_eq(events[0].kind, "fate_roll")
	for index in 3:
		assert_eq(events[index + 1].vfx, "fate_thrust")
		assert_eq(events[index + 1].hit_count, 3)
		assert_eq(events[index + 1].hit_index, index)
	assert_eq(events[1].amount, 13)
	assert_eq(events[2].amount, 17)
	assert_eq(events[3].amount, 4)
	assert_false(events[4].has("vfx"), "Bleeding must not launch another lance.")
	assert_eq(events[4].amount, 2)


func test_basic_attacks_other_skills_and_reflections_do_not_use_thrust_art() -> void:
	for skill_id: String in ["", "fate_feint", "double_roll", "power_slash", "fire_bolt"]:
		var events := Plan.from_report(
			{
				"skill_id": skill_id,
				"player_damage": 9,
				"reflected_damage": 4,
				"enemy_bleed_damage": 2
			}
		)
		for event in events:
			assert_false(event.has("vfx"), skill_id)


func test_exact_per_hit_crits_override_the_legacy_aggregated_flag() -> void:
	var events := Plan.from_report(
		{
			"skill_id": "fate_thrust",
			"fate_dice": [5],
			"player_hit_damages": [13, 17],
			"skill_total_damage": 34,
			"extra_player_critical": true,
			"fate_hits":
			[
				{"amount": 13, "critical": false},
				{"amount": 17, "critical": false},
				{"amount": 4, "critical": true}
			]
		}
	)
	assert_false(events[1].critical)
	assert_false(events[2].critical)
	assert_true(events[3].critical)


func test_full_and_reduced_motion_have_identical_results_for_all_six_faces() -> void:
	for face in range(1, 7):
		var final_states: Array[Dictionary] = []
		for reduced: bool in [true, false]:
			var screen = _screen()
			screen.set_reduced_motion(reduced)
			var impacts: Array[Dictionary] = []
			screen._presentation_controller.skill_impact.connect(
				func(event: Dictionary) -> void: impacts.append(event.duplicate())
			)
			screen._engine.fate = Fate.new(screen._engine.rng, func() -> int: return face)
			var before_hp: int = screen._enemy.current_hp
			screen._use_skill_id("fate_thrust")
			if screen._presentation_controller.is_busy():
				await screen._presentation_controller.playback_finished
			await get_tree().process_frame
			final_states.append(
				{
					"hp": screen._session.player.stats.current_hp,
					"mana": screen._session.player.stats.current_mana,
					"enemy_hp": screen._enemy.current_hp,
					"tokens": screen._engine.fate_tokens,
					"rng": screen._engine.rng.state
				}
			)
			assert_eq(screen._engine.fate.history.size(), 1)
			assert_eq(screen._presentation_controller._active_skill_effect, null)
			assert_eq(screen.player_visual.rotation, 0.0)
			assert_eq(screen.player_visual.modulate, Color.WHITE)
			assert_eq(screen.enemy_hp_bar.value, float(screen._enemy.current_hp))
			assert_string_contains(
				screen.enemy_stats_label.text, "PŻ %d/" % screen._enemy.current_hp
			)
			if reduced:
				assert_true(impacts.is_empty())
			else:
				assert_eq(impacts.size(), 2 if face == 5 else 1)
				var total := 0
				for event in impacts:
					total += int(event.amount)
				assert_eq(total, before_hp - screen._enemy.current_hp)
		assert_eq(
			final_states[0], final_states[1], "Face %d: VFX must not alter RNG or combat." % face
		)


func test_hp_and_damage_text_wait_for_impact_and_input_stays_locked() -> void:
	var screen = _screen()
	screen.set_reduced_motion(false)
	screen._presentation_controller.animation_duration_scale = 0.4
	screen._engine.fate = Fate.new(screen._engine.rng, func() -> int: return 3)
	var before: int = screen._enemy.current_hp
	var mana_before: int = screen._session.player.stats.current_mana
	screen._use_skill_id("fate_thrust")
	assert_true(screen.attack_button.disabled)
	assert_true(screen.motion_toggle_button.disabled)
	assert_false(screen.result_panel.visible)
	assert_eq(screen.enemy_hp_bar.value, float(before))
	assert_eq(screen.player_mana_bar.value, float(mana_before - 5), "Mana is spent at cast start.")
	assert_string_contains(screen.enemy_stats_label.text, "PŻ %d/" % before)
	assert_true(screen._presentation_controller.last_feedback_texts.is_empty())
	var resolved_hp: int = screen._enemy.current_hp
	screen._use_skill_id("fate_thrust")
	assert_eq(screen._enemy.current_hp, resolved_hp, "Double click cannot resolve another turn.")
	await screen._presentation_controller.skill_impact
	assert_false(screen._presentation_controller.last_feedback_texts.is_empty())
	assert_true(screen._presentation_controller.is_busy())
	await screen._presentation_controller.playback_finished
	assert_false(screen.attack_button.disabled)
	assert_eq(screen.enemy_hp_bar.value, float(resolved_hp))


func test_killing_double_thrust_uses_only_the_hit_that_actually_happened() -> void:
	var screen = _screen()
	screen._enemy.current_hp = 1
	screen.set_reduced_motion(false)
	screen._engine.fate = Fate.new(screen._engine.rng, func() -> int: return 5)
	var hits: Array = []
	screen._presentation_controller.skill_impact.connect(
		func(event: Dictionary) -> void: hits.append(event)
	)
	screen._use_skill_id("fate_thrust")
	assert_false(screen.result_panel.visible)
	await screen._presentation_controller.playback_finished
	await get_tree().process_frame
	assert_eq(hits.size(), 1)
	assert_true(screen.result_panel.visible)
	assert_false(screen.fate_panel.visible)
	assert_eq(screen.dice_row.get_child_count(), 0)
	assert_eq(
		screen.get_node("%FeedbackLayer").find_children("FateThrustEffect", "", false).size(), 0
	)


func test_effect_tracks_painted_targets_at_different_resolutions_and_restores_pose() -> void:
	for dimensions: Vector2 in [Vector2(1280, 720), Vector2(1920, 1080), Vector2(2560, 1080)]:
		var screen = _screen()
		screen.set_anchors_preset(Control.PRESET_TOP_LEFT)
		screen.size = dimensions
		await get_tree().process_frame
		var effect := Effect.new()
		screen.get_node("%FeedbackLayer").add_child(effect)
		effect.start(screen.player_visual, screen.enemy_visual, {"fate_face": 6}, 100.0)
		effect._tween.kill()
		var hits: Array[int] = []
		effect.impact.connect(func() -> void: hits.append(1))
		effect._sample(0.55)
		assert_true(hits.is_empty())
		effect._sample(0.56)
		assert_eq(hits.size(), 1)
		assert_almost_eq(effect.projectile_tip, effect.destination, Vector2.ONE)
		var target_rect: Rect2 = screen.enemy_visual.static_texture.get_global_rect()
		assert_true(target_rect.has_point(effect.destination + effect.global_position))
		assert_lt(
			screen.get_node("Page/Arena/VfxStage").get_global_rect().end.y,
			minf(effect.origin.y, effect.destination.y) + effect.global_position.y - 35,
			"The dice HUD must not cover the projectile corridor."
		)
		assert_eq(effect.mouse_filter, Control.MOUSE_FILTER_IGNORE)
		assert_true(effect.jackpot)
		effect._sample(0.8)
		assert_eq(hits.size(), 1, "An impact can only happen once.")
		effect.cancel()
		assert_eq(screen.player_visual.rotation, 0.0)
		assert_eq(screen.player_visual.pivot_offset, Vector2.ZERO)
		assert_eq(screen.player_visual.modulate, Color.WHITE)
		effect.free()


func test_removing_effect_mid_flight_restores_the_actor_without_impact() -> void:
	var screen = _screen()
	var effect := Effect.new()
	screen.get_node("%FeedbackLayer").add_child(effect)
	effect.start(screen.player_visual, screen.enemy_visual, {}, 100.0)
	effect._tween.kill()
	effect._sample(0.15)
	assert_ne(screen.player_visual.rotation, 0.0)
	effect.free()
	assert_eq(screen.player_visual.rotation, 0.0)
	assert_eq(screen.player_visual.modulate, Color.WHITE)


func test_streak_has_real_alpha_and_does_not_replace_the_approved_card() -> void:
	var pixels := Effect.STREAK.get_image()
	assert_true(pixels.detect_alpha() != Image.ALPHA_NONE)
	for point: Vector2i in [
		Vector2i.ZERO,
		Vector2i(pixels.get_width() - 1, 0),
		Vector2i(0, pixels.get_height() - 1),
		pixels.get_size() - Vector2i.ONE
	]:
		assert_eq(pixels.get_pixelv(point).a, 0.0)
	assert_gt(pixels.get_used_rect().size.x, 100)
	assert_string_contains(Effect.STREAK.resource_path, "/combat/vfx/")
	assert_file_exists("res://assets/skills/pierrot/fate_thrust.png")


func _screen():
	var session = NewGame.new().create_session("Aria", 1)
	session.player.level = 12
	session.player.choose_class("pierrot")
	session.player.stats.restore_full()
	var screen = SCENE.instantiate()
	screen.configure(session, "wolf", "expedition")
	add_child_autoqfree(screen)
	screen._enemy.max_hp = 1000
	screen._enemy.current_hp = 1000
	screen._enemy.attack = 0
	screen._enemy.dodge = 0.0
	screen._enemy.defense = 0
	screen._engine.rng.seed = 907
	screen._presentation_controller.animation_duration_scale = 0.01
	screen._render()
	return screen
