extends SceneTree
## Real combat scene, fixed presentation-only reports; never read/write player saves.
const App := preload("res://scenes/app/app.tscn")
const NewGame := preload("res://core/game/new_game_service.gd")
const Plan := preload("res://ui/presentation/combat_presentation_plan.gd")
const Fate := preload("res://core/combat/fate_engine.gd")
var output := "res://../build/combat-dice-review/after/evidence"


class MemorySave:
	extends SaveGameService

	func save_session(_session: GameSession) -> Dictionary:
		return {"ok": true, "message": "Preview only"}


func _init() -> void:
	if not InputMap.has_action("dialogic_default_action"):
		InputMap.add_action("dialogic_default_action")
	call_deferred("_record_movie" if "--movie" in OS.get_cmdline_user_args() else "_capture_all")


func _record_movie() -> void:
	var app = App.instantiate()
	app._save_service = MemorySave.new()
	root.add_child(app)
	var session = NewGame.new().create_session("Aria", 1, null, "female")
	session.player.level = 12
	session.player.choose_class("pierrot")
	session.player.stats.restore_full()
	app._current_session = session
	app._show_combat("wolf", "expedition")
	var screen = app.screen_host.get_child(0)
	screen.set_reduced_motion(false)
	screen._presentation_controller.audio_feedback.set_muted(true)
	screen._enemy.max_hp = 1000
	screen._enemy.current_hp = 1000
	screen._enemy.attack = 0
	screen._enemy.dodge = 0.0
	screen._engine.rng.seed = 907
	var values: Array[int] = [1, 3, 6]
	screen._engine.fate = Fate.new(screen._engine.rng, func() -> int: return values.pop_front())
	screen._render()
	await create_timer(0.5).timeout
	screen._use_skill_id("grand_gamble")
	if screen._presentation_controller.is_busy():
		await screen._presentation_controller.playback_finished
	await create_timer(0.8).timeout
	print("COMBAT DICE MOVIE COMPLETE — real skill, memory-only saves")
	quit()


func _capture_all() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		output = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for dimensions: Vector2i in [
		Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1920, 1080), Vector2i(2560, 1080)
	]:
		var viewport := SubViewport.new()
		viewport.size = dimensions
		var factor := minf(float(dimensions.x) / 1920.0, float(dimensions.y) / 1080.0)
		viewport.size_2d_override = Vector2i(Vector2(dimensions) / factor)
		viewport.size_2d_override_stretch = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var app = App.instantiate()
		app._save_service = MemorySave.new()
		viewport.add_child(app)
		for fixture: Dictionary in [
			{"id": "one", "dice": [6]},
			{"id": "two", "dice": [2, 5]},
			{"id": "three", "dice": [1, 3, 4]},
			{"id": "reduced", "dice": [6, 2, 5]}
		]:
			var session = NewGame.new().create_session("Aria", 1, null, "female")
			session.player.level = 12
			session.player.choose_class("pierrot")
			app._current_session = session
			app._show_combat("wolf", "expedition")
			var screen = app.screen_host.get_child(0)
			screen.set_reduced_motion(fixture.id == "reduced")
			var controller = screen._presentation_controller
			controller.audio_feedback.set_muted(true)
			screen.fate_panel.show()
			for frame in 8:
				await process_frame
			var state: Dictionary = controller.resource_snapshot(session.player, screen._enemy)
			controller.present(
				Plan.from_report(
					{"fate_dice": fixture.dice, "fate_outcome": "Wynik: " + str(fixture.dice)}
				),
				state,
				state,
				1
			)
			await create_timer(0.25).timeout
			await _capture(viewport, fixture.id + "_rolling", dimensions)
			await create_timer(0.5).timeout
			await _capture(viewport, fixture.id + "_landing", dimensions)
			if controller.is_busy():
				await controller.playback_finished
			await _capture(viewport, fixture.id + "_settled", dimensions)
		app.free()
		viewport.free()
	print("COMBAT DICE PREVIEW COMPLETE")
	quit()


func _capture(viewport: SubViewport, stage: String, dimensions: Vector2i) -> void:
	await RenderingServer.frame_post_draw
	var path := output.path_join("%s_%dx%d.png" % [stage, dimensions.x, dimensions.y])
	if viewport.get_texture().get_image().save_png(path) != OK:
		push_error("Cannot save dice preview: " + path)
		quit(1)
