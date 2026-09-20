extends SceneTree
## Actual app and canonical recipes; never loads a player's real save.
const App := preload("res://scenes/app/app.tscn")
const Fixture := preload("res://tests/fixtures/equipment_layout_fixture.gd")
const Saves := preload("res://core/save/save_game_service.gd")


func _init() -> void:
	if not InputMap.has_action("dialogic_default_action"):
		InputMap.add_action("dialogic_default_action")
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2 or not args[0].is_absolute_path() or not args[1].is_absolute_path():
		push_error("Expected absolute evidence and isolated save directories")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(args[0])
	for dimensions: Vector2i in [Vector2i(1920, 1080), Vector2i(1366, 768), Vector2i(1280, 720)]:
		var viewport := SubViewport.new()
		viewport.size = dimensions
		var factor := minf(float(dimensions.x) / 1920.0, float(dimensions.y) / 1080.0)
		viewport.size_2d_override = Vector2i(Vector2(dimensions) / factor)
		viewport.size_2d_override_stretch = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var app = App.instantiate()
		app._save_service = Saves.new(args[1])
		viewport.add_child(app)
		var session = Fixture.create_session()
		session.player.inventory.add("weak_leather", 9)
		app._current_session = session
		app._show_city_service("workshop")
		var screen = app.screen_host.get_child(0)
		var suffix := "_%dx%d.png" % [dimensions.x, dimensions.y]
		await _capture(viewport, args[0].path_join("ambient" + suffix))
		screen.npc_hit_area.pressed.emit()
		await _capture(viewport, args[0].path_join("dialogue" + suffix))
		screen.open_service_button.pressed.emit()
		await _capture(viewport, args[0].path_join("recipe" + suffix))
		var book = screen.get_node_or_null("WorkshopBook")
		if book != null:
			book.change_page(1)
			await _capture(viewport, args[0].path_join("page2" + suffix))
			book.select_region(4)
			book.select_recipe(3)
			await _capture(viewport, args[0].path_join("ingredients" + suffix))
			book.select_recipe(0)
			await _capture(viewport, args[0].path_join("six_costs" + suffix))
			book.select_region(0)
			book.craft_button.pressed.emit()
			await _capture(viewport, args[0].path_join("crafted" + suffix))
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		app.queue_free()
		await process_frame
		viewport.queue_free()
		await process_frame
		print("WORKSHOP CAPTURE ", suffix)
	quit(0)


func _capture(viewport: SubViewport, path: String) -> void:
	for frame in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	assert(viewport.get_texture().get_image().save_png(path) == OK)
