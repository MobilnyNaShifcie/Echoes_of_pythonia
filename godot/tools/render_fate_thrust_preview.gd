extends SceneTree
## Real App + pointer input + real combat/VFX, with memory-only sessions.
const App := preload("res://scenes/app/app.tscn")
const NewGame := preload("res://core/game/new_game_service.gd")
const Fate := preload("res://core/combat/fate_engine.gd")
const OUTPUT := "res://../output/fate_thrust_20260908/"
var _failures := 0


class MemorySave:
	extends SaveGameService

	func save_session(_session: GameSession) -> Dictionary:
		return {"ok": true, "message": "Preview only"}


func _init() -> void:
	if not InputMap.has_action("dialogic_default_action"):
		InputMap.add_action("dialogic_default_action")
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT + "frames"))
	await _case(Vector2i(1280, 720), 3, "female", "normal", true)
	await _case(Vector2i(1920, 1080), 6, "female", "jackpot", false)
	await _case(Vector2i(2560, 1080), 5, "male", "double", false)
	print("FATE THRUST PREVIEW COMPLETE — failures=", _failures, "; no player saves touched")
	quit(0 if _failures == 0 else 1)


func _case(dimensions: Vector2i, face: int, gender: String, label: String, movie: bool) -> void:
	var viewport := SubViewport.new()
	viewport.size = dimensions
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var app = App.instantiate()
	app._save_service = MemorySave.new()
	viewport.add_child(app)
	var session = NewGame.new().create_session(
		"Aria" if gender == "female" else "Ari", 1, null, gender
	)
	session.player.level = 12
	session.player.choose_class("pierrot")
	session.player.stats.restore_full()
	session.hour = 8 if face == 6 else 22
	app._current_session = session
	app._show_combat("wolf" if face == 6 else "plains_spirit", "expedition")
	var screen = app.screen_host.get_child(0)
	screen.set_reduced_motion(false)
	screen._enemy.max_hp = 150
	screen._enemy.current_hp = 150
	screen._enemy.attack = 0
	screen._enemy.dodge = 0.0
	screen._enemy.defense = 0
	screen._engine.rng.seed = 907
	screen._engine.fate = Fate.new(screen._engine.rng, func() -> int: return face)
	screen._render()
	await _settle()
	var drawer = screen.get_node("Page/Lower").drawer
	drawer.set_open(true, true)
	await _settle()
	var card: Button
	for candidate in screen.skill_cards.get_children():
		if candidate.action_id == "fate_thrust":
			card = candidate
	_check(card != null, label + ": skill card available on an existing class")
	await _capture(viewport, label + "_ready")
	var hits: Array = []
	screen._presentation_controller.skill_impact.connect(
		func(event: Dictionary) -> void:
			hits.append(event)
			_check(
				screen._presentation_controller.is_busy(), label + ": impact during locked playback"
			)
			_check(not screen.result_panel.visible, label + ": result never covers the impact")
	)
	await _click(card)
	_check(screen._presentation_controller.is_busy(), label + ": pointer starts animation")
	var snapshots: Dictionary = {}
	var frame := 0
	var ended := 0
	while frame < 240:
		await process_frame
		await RenderingServer.frame_post_draw
		var effect = screen._presentation_controller._active_skill_effect
		if effect != null:
			for stage: String in ["charge", "flight", "impact", "recovery"]:
				var threshold: float = {
					"charge": 0.14, "flight": 0.44, "impact": 0.59, "recovery": 0.8
				}[stage]
				if effect.progress >= threshold and not snapshots.has(stage):
					snapshots[stage] = true
					_save(viewport, label + "_" + stage)
		if movie and frame % 2 == 0:
			_save(viewport, "frames/frame_%04d" % (frame / 2))
		if not screen._presentation_controller.is_busy():
			ended += 1
			if ended >= 24:
				break
		frame += 1
	_check(frame < 240, label + ": playback terminates")
	_check(hits.size() == (2 if face == 5 else 1), label + ": correct impact count")
	_check(snapshots.size() == 4, label + ": captured all four animation phases")
	_check(screen.player_visual.rotation == 0.0, label + ": actor pose restored")
	_check(
		screen._presentation_controller._active_skill_effect == null, label + ": effect cleaned up"
	)
	_check(not screen.attack_button.disabled, label + ": actions restored")
	await _capture(viewport, label + "_finished")
	app.queue_free()
	await _settle()
	viewport.queue_free()
	await process_frame


func _click(button: Button) -> void:
	var viewport := button.get_viewport()
	var motion := InputEventMouseMotion.new()
	motion.position = button.get_global_rect().get_center()
	viewport.push_input(motion, true)
	await process_frame
	_check(viewport.gui_get_hovered_control() == button, "Pointer reaches Pchnięcie Losu")
	var press := InputEventMouseButton.new()
	press.position = motion.position
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	viewport.push_input(press, true)
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	viewport.push_input(release, true)
	# Move off the drawer so it can retract during the demonstration.
	motion.position = Vector2(8, 8)
	viewport.push_input(motion, true)


func _settle() -> void:
	for frame in 12:
		await process_frame


func _capture(viewport: SubViewport, label: String) -> void:
	await RenderingServer.frame_post_draw
	_save(viewport, label)


func _save(viewport: SubViewport, label: String) -> void:
	var error := viewport.get_texture().get_image().save_png(OUTPUT + label + ".png")
	if error != OK:
		_check(false, "Cannot capture " + label)


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		push_error(description)
	else:
		print("PASS: ", description)
