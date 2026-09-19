extends GutTest

const SCENE := preload("res://ui/screens/combat/combat.tscn")
const Audio := preload("res://ui/presentation/combat_audio_feedback.gd")
const NewGame := preload("res://core/game/new_game_service.gd")
const Saves := preload("res://core/save/save_game_service.gd")
const Plan := preload("res://ui/presentation/combat_presentation_plan.gd")
const Fate := preload("res://core/combat/fate_engine.gd")


func test_cues_use_imported_short_non_looping_streams_and_bounded_gain() -> void:
	var audio = _screen()._presentation_controller.audio_feedback
	assert_eq(Audio.STREAMS.size(), 5)
	assert_eq(audio._voices.size(), 2)
	for cue: String in Audio.STREAMS:
		var stream: AudioStreamOggVorbis = Audio.STREAMS[cue]
		assert_false(stream.loop)
		assert_gt(stream.get_length(), 0.01, cue)
		assert_lt(stream.get_length(), 3.0, cue)
		audio._play(cue)
	for voice: AudioStreamPlayer in audio._voices:
		assert_eq(voice.max_polyphony, 1)
		assert_lte(voice.volume_db, -12.0)
		assert_true(voice.playing)
	assert_file_exists("res://assets/audio/combat/LICENSE-rpg-audio.txt")
	assert_file_exists("res://assets/audio/combat/LICENSE-impact-sounds.txt")


func test_event_mapping_excludes_passive_damage_zero_damage_and_non_impacts() -> void:
	for fixture: Array in [
		[{"kind": "damage", "amount": 3}, "hit"],
		[{"kind": "damage", "amount": 3, "critical": true}, "critical"],
		[{"kind": "feedback", "tone": "block", "amount": 3}, "block"],
		[{"kind": "feedback", "tone": "dodge"}, "dodge"],
		[{"kind": "damage", "amount": 0, "critical": true}, ""],
		[{"kind": "damage", "amount": 9, "direct_attack": false}, ""],
		[{"kind": "restore", "health": 5}, ""],
		[{"kind": "fate_roll", "dice": [6]}, ""],
		[{"kind": "turn"}, ""],
	]:
		assert_eq(Audio.cue_for(fixture[0]), fixture[1])


func test_full_motion_audio_fires_at_impact_not_at_action_start() -> void:
	for fixture: Array in [
		[{"player_damage": 4}, "hit"],
		[{"player_damage": 7, "player_critical": true}, "critical"],
		[{"enemy_dodged": true}, "dodge"],
		[{"enemy_acted": true, "shield_blocked": true, "enemy_damage": 2}, "block"],
	]:
		var screen = _screen()
		var controller = screen._presentation_controller
		screen.set_reduced_motion(false)
		controller.animation_duration_scale = 0.35
		var cues := _listen(controller.audio_feedback)
		var before: Dictionary = controller.resource_snapshot(screen._session.player, screen._enemy)
		var after := before.duplicate()
		after.enemy_hp -= int(fixture[0].get("player_damage", 0))
		after.player_hp -= int(fixture[0].get("enemy_damage", 0))
		controller.present(Plan.from_report(fixture[0]), before, after, 1)
		assert_true(cues.is_empty())
		await controller.impact_presented
		assert_eq(cues, [fixture[1]])
		assert_eq(screen.player_hp_bar.value, float(after.player_hp))
		assert_eq(screen.enemy_hp_bar.value, float(after.enemy_hp))
		await controller.playback_finished
		assert_eq(cues.size(), 1)


func test_fate_thrust_plays_once_per_actual_hit_at_skill_impact() -> void:
	var screen = _screen("pierrot")
	screen.set_reduced_motion(false)
	screen._engine.fate = Fate.new(screen._engine.rng, func() -> int: return 5)
	var controller = screen._presentation_controller
	var cues := _listen(controller.audio_feedback)
	var impacts: Array[int] = []
	controller.skill_impact.connect(func(_event: Dictionary) -> void: impacts.append(cues.size()))
	screen._use_skill_id("fate_thrust")
	assert_true(cues.is_empty())
	await controller.playback_finished
	assert_eq(impacts, [1, 2], "Both thrust impacts must already have their audio cue.")
	assert_gte(cues.size(), 2)


func test_reduced_motion_emits_one_priority_cue_and_finishes_immediately() -> void:
	var screen = _screen()
	screen.set_reduced_motion(true)
	var controller = screen._presentation_controller
	var cues := _listen(controller.audio_feedback)
	var state: Dictionary = controller.resource_snapshot(screen._session.player, screen._enemy)
	controller.present(
		Plan.from_report(
			{
				"player_damage": 4,
				"player_critical": true,
				"enemy_acted": true,
				"shield_blocked": true,
				"enemy_damage": 2
			}
		),
		state,
		state,
		1
	)
	assert_eq(cues, ["critical"])
	assert_false(controller.is_busy())
	var empty_events: Array[Dictionary] = []
	controller.present(empty_events, state, state, 2)
	assert_eq(cues, ["critical"])
	for voice: AudioStreamPlayer in controller.audio_feedback._voices:
		assert_false(voice.playing, "A new instant turn clears the previous sound tail.")


func test_toggle_stops_active_audio_and_is_usable_during_action_lock() -> void:
	var screen = _screen()
	screen.set_reduced_motion(false)
	var audio = screen._presentation_controller.audio_feedback
	var button: Button = screen.get_node("%AudioToggleButton")
	var cues := _listen(audio)
	audio._play("block")
	screen.attack_button.pressed.emit()
	assert_true(screen.attack_button.disabled)
	assert_false(button.disabled)
	button.button_pressed = false
	assert_true(audio.muted)
	for voice: AudioStreamPlayer in audio._voices:
		assert_false(voice.playing)
	await screen._presentation_controller.playback_finished
	assert_eq(cues, ["block"], "Muted impacts cannot start another voice.")
	button.button_pressed = true
	assert_false(audio.muted)
	assert_eq(cues, ["block"], "Unmuting must not replay old events.")
	audio._play("hit")
	assert_eq(cues, ["block", "hit"])


func test_preference_roundtrip_is_separate_from_player_data_and_safe_on_bad_type() -> void:
	var first = _screen()._presentation_controller.audio_feedback
	var path := "user://combat-audio-test-%s.cfg" % get_instance_id()
	first.preferences_path = path
	first.set_muted(true, true)
	var second = _screen()._presentation_controller.audio_feedback
	second.preferences_path = path
	second.load_preferences()
	assert_true(second.muted)
	assert_false(second._button.button_pressed)
	var config := ConfigFile.new()
	assert_eq(config.load(path), OK)
	assert_eq(config.get_sections(), PackedStringArray(["combat"]))
	assert_eq(config.get_section_keys("combat"), PackedStringArray(["muted"]))
	config.set_value("combat", "muted", "not-a-bool")
	assert_eq(config.save(path), OK)
	second.load_preferences()
	assert_false(second.muted)
	assert_eq(DirAccess.remove_absolute(path), OK)
	second.load_preferences()
	assert_false(second.muted)


func test_result_only_plays_victory_once_and_cannot_replay_after_unmute() -> void:
	var screen = _screen()
	var controller = screen._presentation_controller
	var audio = controller.audio_feedback
	var cues := _listen(audio)
	controller.reveal_result(screen.result_panel, "victory")
	controller.reveal_result(screen.result_panel, "victory")
	screen._render()
	assert_eq(cues, ["victory"])
	for result_code: String in ["defeat", "fled"]:
		audio.begin_turn()
		controller.reveal_result(screen.result_panel, result_code)
	assert_eq(cues, ["victory"])
	audio.begin_turn()
	audio.set_muted(true)
	controller.reveal_result(screen.result_panel, "victory")
	audio.set_muted(false)
	controller.reveal_result(screen.result_panel, "victory")
	assert_eq(cues, ["victory"])


func test_actual_victory_emits_one_coin_cue_without_regranting_rewards() -> void:
	var screen = _screen("pierrot")
	screen.set_reduced_motion(false)
	screen._enemy.current_hp = 1
	screen._enemy.defense = 0
	screen._engine.fate = Fate.new(screen._engine.rng, func() -> int: return 5)
	var controller = screen._presentation_controller
	var cues := _listen(controller.audio_feedback)
	screen._use_skill_id("fate_thrust")
	assert_false(cues.has("victory"))
	await controller.playback_finished
	assert_true(screen.result_panel.visible)
	assert_eq(cues.count("victory"), 1)
	var codec := Saves.new("user://unused-combat-audio")
	var before: Dictionary = codec._serialize_session(screen._session)
	screen._render()
	controller.reveal_result(screen.result_panel, screen._engine.result)
	var after: Dictionary = codec._serialize_session(screen._session)
	before.erase("saved_at_unix")
	after.erase("saved_at_unix")
	assert_eq(before, after)
	assert_eq(cues.count("victory"), 1)


func test_voices_are_owned_by_screen_and_freed_on_exit() -> void:
	var screen = _screen()
	var audio = screen._presentation_controller.audio_feedback
	var voices: Array = audio._voices.duplicate()
	audio._play("victory")
	screen.queue_free()
	await get_tree().process_frame
	for voice in voices:
		assert_false(is_instance_valid(voice))


func test_toggle_fits_header_at_supported_sizes_and_has_keyboard_focus() -> void:
	var screen = _screen()
	var button: Button = screen.get_node("%AudioToggleButton")
	for dimensions: Vector2 in [
		Vector2(1280, 720), Vector2(1366, 768), Vector2(1920, 1080), Vector2(2560, 1080)
	]:
		screen.size = dimensions
		for frame in 4:
			await get_tree().process_frame
		var rect := button.get_global_rect()
		assert_true(screen.get_global_rect().encloses(rect), str(dimensions))
		for sibling in screen.get_node("Page/EncounterHeader").get_children():
			if sibling != button:
				assert_false(sibling.get_global_rect().intersects(rect))
		assert_eq(button.focus_mode, Control.FOCUS_ALL)
		button.grab_focus()
		assert_true(button.has_focus())


func test_audio_mute_and_motion_modes_do_not_change_real_turns_saves_or_rng() -> void:
	for class_code: String in ["warrior", "mage", "hunter", "pierrot"]:
		var fixture = _screen(class_code)
		var codec := Saves.new("user://unused-combat-audio")
		var payload: Dictionary = codec._serialize_session(fixture._session)
		var states: Array[Dictionary] = []
		for reduced: bool in [true, false]:
			for muted: bool in [true, false]:
				var screen = _screen(class_code, payload)
				screen.set_reduced_motion(reduced)
				screen._presentation_controller.audio_feedback.set_muted(muted)
				for turn in 3:
					screen.attack_button.pressed.emit()
					if screen._presentation_controller.is_busy():
						await screen._presentation_controller.playback_finished
				var state: Dictionary = codec._serialize_session(screen._session)
				state.erase("saved_at_unix")
				state["enemy_hp"] = screen._enemy.current_hp
				state["rng"] = screen._engine.rng.state
				states.append(state)
		for state in states:
			assert_eq(state, states[0], class_code + ": audio cannot affect game state.")


func _screen(class_code := "warrior", payload: Dictionary = {}):
	var session
	if payload.is_empty():
		session = NewGame.new().create_session("Aria", 1, null, "female")
		session.player.level = 12
		session.player.choose_class(class_code)
		session.player.stats.restore_full()
	else:
		var loaded := Saves.new("user://unused-combat-audio")._deserialize_payload(
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
	var audio = screen._presentation_controller.audio_feedback
	audio.preferences_path = ""
	audio.set_muted(false)
	screen._render()
	return screen


func _listen(audio) -> Array[String]:
	var cues: Array[String] = []
	audio.cue_played.connect(func(cue: String) -> void: cues.append(cue))
	return cues
