extends SceneTree
## Actual app navigation, fixtures in memory, screenshots from offscreen viewports.
## Launch with isolated APPDATA/LOCALAPPDATA; no save is loaded or written.

const App = preload("res://scenes/app/app.tscn")
const NewGame = preload("res://core/game/new_game_service.gd")
const OUTPUT := "res://../output/dungeon_crypt/in_game/"


func _init() -> void:
	if not InputMap.has_action("dialogic_default_action"):
		InputMap.add_action("dialogic_default_action")
	call_deferred("_render_previews")


func _render_previews() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1080)]:
		var viewport := SubViewport.new()
		viewport.size = dimensions
		# Match project canvas_items + expand: 720p is a scaled 1920x1080 canvas.
		var scale_factor := minf(float(dimensions.x) / 1920.0, float(dimensions.y) / 1080.0)
		viewport.size_2d_override = Vector2i(Vector2(dimensions) / scale_factor)
		viewport.size_2d_override_stretch = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var app = App.instantiate()
		viewport.add_child(app)
		var session = NewGame.new().create_session("Aria", 1, null, "female")
		session.player.level = 8
		session.player.choose_class("mage")
		session.player.inventory.add("ancient_order_key")
		session.player.inventory.add("strong_healing_potion", 2)
		session.player.stats.current_hp = maxi(1, session.player.stats.max_hp - 5)
		app._current_session = session
		app._show_dungeon("sunken_order_crypt")
		await _capture(viewport, "entrance", dimensions)
		app.screen_host.get_child(0).actions.get_child(0).pressed.emit()
		await _capture(viewport, "room_one", dimensions)
		# Choose an existing drawn enemy without changing the actual encounter pool.
		for candidate_seed in range(1, 100):
			var probe := RandomNumberGenerator.new()
			probe.seed = candidate_seed
			if probe.randi_range(0, 2) == 2:
				app._dungeon_rng.seed = candidate_seed
				break
		app.screen_host.get_child(0).actions.get_child(0).pressed.emit()
		app.screen_host.get_child(0).set_reduced_motion(true)
		await _capture(viewport, "combat", dimensions)
		app.free()
		viewport.queue_free()
		await process_frame
		await process_frame
	print("CRYPT PREVIEW COMPLETE — memory fixtures only")
	quit()


func _capture(viewport: SubViewport, stage: String, dimensions: Vector2i) -> void:
	for frame in 5:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := OUTPUT + "%s_%dx%d.png" % [stage, dimensions.x, dimensions.y]
	var error := viewport.get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Cannot save crypt preview: %s" % error)
		quit(1)
	print("CRYPT_PREVIEW ", path)
