extends SceneTree
## Captures the real app with memory-only sessions; does not access player saves.
const App = preload("res://scenes/app/app.tscn")
const NewGame = preload("res://core/game/new_game_service.gd")
const Fate = preload("res://core/combat/fate_engine.gd")
const OUTPUT := "res://../output/fate_panel/"


class MemorySave:
	extends SaveGameService

	func save_session(_session: GameSession) -> Dictionary:
		return {"ok": true, "message": "Preview only"}


func _init() -> void:
	if not InputMap.has_action("dialogic_default_action"):
		InputMap.add_action("dialogic_default_action")
	call_deferred("_render_previews")


func _render_previews() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var app = App.instantiate()
	app._save_service = MemorySave.new()
	viewport.add_child(app)
	var session = NewGame.new().create_session("Aria", 1, null, "female")
	session.player.level = 12
	session.player.choose_class("pierrot")
	session.player.stats.restore_full()
	app._current_session = session
	app._show_combat("wolf", "expedition")
	var screen = app.screen_host.get_child(0)
	screen.set_reduced_motion(true)
	await _capture(viewport, "pierrot_before_action")
	screen._enemy.current_hp = 1
	screen._enemy.dodge = 0.0
	screen.attack_button.pressed.emit()
	await _capture(viewport, "pierrot_basic_victory")
	app._show_combat("wolf", "expedition")
	screen = app.screen_host.get_child(0)
	screen.set_reduced_motion(true)
	screen._enemy.max_hp = 1000
	screen._enemy.current_hp = 1000
	screen._enemy.dodge = 0.0
	screen._engine.fate = Fate.new(screen._engine.rng, func() -> int: return 3)
	screen._use_skill_id("fate_thrust")
	await _capture(viewport, "pierrot_real_roll")
	screen._enemy.current_hp = 1
	screen._use_skill_id("fate_thrust")
	await _capture(viewport, "pierrot_skill_victory")
	app.free()
	viewport.queue_free()
	await process_frame
	print("FATE PANEL PREVIEW COMPLETE — 4 captures, memory-only saves")
	quit()


func _capture(viewport: SubViewport, stage: String) -> void:
	for frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := OUTPUT + stage + ".png"
	var error := viewport.get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Cannot save fate panel preview: %s" % error)
		quit(1)
	print("FATE_PANEL_CAPTURE ", path)
