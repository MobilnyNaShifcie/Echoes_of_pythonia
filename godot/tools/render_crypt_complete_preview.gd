extends SceneTree
## Production UI route rendered offscreen. All sessions and saves are memory-only.
const App = preload("res://scenes/app/app.tscn")
const NewGame = preload("res://core/game/new_game_service.gd")
const OUTPUT := "res://../output/dungeon_crypt/in_game_complete/"


class MemorySave:
	extends SaveGameService

	func save_session(_session: GameSession) -> Dictionary:
		return {"ok": true, "message": "Preview: no disk write"}


func _init() -> void:
	if not InputMap.has_action("dialogic_default_action"):
		InputMap.add_action("dialogic_default_action")
	call_deferred("_render_previews")


func _render_previews() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1080)]:
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
		var session = NewGame.new().create_session("Aria", 1, null, "female")
		session.player.level = 8
		session.player.choose_class("mage")
		session.player.inventory.add("ancient_order_key")
		session.player.inventory.add("strong_healing_potion", 2)
		app._current_session = session
		app._show_dungeon("sunken_order_crypt")
		await _capture(viewport, "entrance", dimensions)
		app.screen_host.get_child(0).actions.get_child(0).pressed.emit()
		await process_frame
		for iteration in 30:
			var run = app._active_dungeon_run
			var screen = app.screen_host.get_child(0)
			if run.is_finished():
				await _capture(viewport, "completed", dimensions)
				screen.actions.get_child(0).pressed.emit()
				await process_frame
				break
			if run.step == "in_combat":
				screen.set_reduced_motion(true)
				await _capture(viewport, "combat_" + run.pending_enemy_id, dimensions)
				# Weaken only after the real unmodified opening portrait was captured.
				screen._enemy.current_hp = 1
				screen._enemy.defense = 0
				screen._enemy.dodge = 0.0
				screen.attack_button.pressed.emit()
				for frame in 240:
					if screen.result_panel.visible:
						break
					await process_frame
				if not screen.result_panel.visible:
					push_error("Preview combat did not reach its result")
					quit(1)
					return
				screen.continue_button.pressed.emit()
			else:
				await _capture(viewport, run.step, dimensions)
				if run.step == "room_one":
					_seed_pool_index(app._dungeon_rng, 2)
				elif run.step == "pause_after_room_one":
					_seed_pool_index(app._dungeon_rng, 0)
				elif run.step == "pause_after_path":
					_seed_pool_index(app._dungeon_rng, 2)
				screen.actions.get_child(0).pressed.emit()
			await process_frame
		app.free()
		viewport.queue_free()
		await process_frame
	print("CRYPT COMPLETE PREVIEW — full iron route, three resolutions, no real saves")
	quit()


func _seed_pool_index(rng: RandomNumberGenerator, desired: int) -> void:
	for seed_value in range(1, 100):
		var probe := RandomNumberGenerator.new()
		probe.seed = seed_value
		if probe.randi_range(0, 2) == desired:
			rng.seed = seed_value
			return


func _capture(viewport: SubViewport, stage: String, dimensions: Vector2i) -> void:
	for frame in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := OUTPUT + "%s_%dx%d.png" % [stage, dimensions.x, dimensions.y]
	var error := viewport.get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Cannot save crypt preview: %s" % error)
		quit(1)
	print("CRYPT_CAPTURE ", path)
