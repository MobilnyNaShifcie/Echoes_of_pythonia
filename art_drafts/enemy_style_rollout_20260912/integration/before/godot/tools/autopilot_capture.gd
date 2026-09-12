extends SceneTree
## Deterministic review fixtures. Player saves are never used.
const App := preload("res://scenes/app/app.tscn")
const NewGame := preload("res://core/game/new_game_service.gd")
const Saves := preload("res://core/save/save_game_service.gd")
var _output := ""
var _images: Array[String] = []
var _failed := false


func _init() -> void:
	if not InputMap.has_action("dialogic_default_action"):
		InputMap.add_action("dialogic_default_action")
	_run.call_deferred()


func _run() -> void:
	var request := _read_request()
	if request.is_empty():
		return
	seed(741)
	for resolution: Array in request.resolutions:
		var dimensions := Vector2i(int(resolution[0]), int(resolution[1]))
		var viewport := SubViewport.new()
		viewport.size = dimensions
		var factor := minf(float(dimensions.x) / 1920.0, float(dimensions.y) / 1080.0)
		viewport.size_2d_override = Vector2i(Vector2(dimensions) / factor)
		viewport.size_2d_override_stretch = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var app = App.instantiate()
		# All reads and writes, including menu save-slot discovery, use an isolated directory.
		app._save_service = Saves.new(_output.path_join("fixture_saves"))
		viewport.add_child(app)
		var session = NewGame.new().create_session("Aria", 1, null, "female")
		while session.player.level < 12:
			session.player.gain_experience(session.player.experience_remaining_to_next_level())
		session.player.gold = 5000
		session.black_market.unlocked = true
		session.player.inventory.add("strong_healing_potion", 3)
		app._current_session = session
		for scenario: String in request.scenarios:
			if not _show(app, scenario):
				app.free()
				viewport.queue_free()
				_fail("Unknown scenario: " + scenario)
				return
			await _settle()
			if app.screen_host.get_child_count() != 1:
				_fail("Screen navigation did not settle: " + scenario)
				return
			await RenderingServer.frame_post_draw
			if not _save_image(viewport, scenario, dimensions):
				return
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		app.queue_free()
		await _settle()
		viewport.queue_free()
		await _settle()
		await RenderingServer.frame_post_draw
	var manifest := FileAccess.open(_output.path_join("manifest.json"), FileAccess.WRITE)
	if manifest == null:
		_fail("Cannot write capture manifest")
		return
	manifest.store_string(JSON.stringify({"ok": not _failed, "images": _images}, "\t"))
	manifest.close()
	print("AUTOPILOT CAPTURE COMPLETE: ", _images.size())
	quit(0)


func _read_request() -> Dictionary:
	var args := OS.get_cmdline_user_args()
	if args.size() != 1:
		_fail("Expected a capture request JSON path")
		return {}
	var request_file := FileAccess.open(args[0], FileAccess.READ)
	if request_file == null:
		_fail("Cannot read capture request")
		return {}
	var request: Variant = JSON.parse_string(request_file.get_as_text())
	request_file.close()
	if not request is Dictionary:
		_fail("Invalid capture request")
		return {}
	_output = str(request.get("output", ""))
	if not _output.is_absolute_path():
		_fail("Output directory must be absolute")
		return {}
	if DirAccess.make_dir_recursive_absolute(_output) != OK:
		_fail("Cannot create output directory")
		return {}
	return request


func _save_image(viewport: SubViewport, scenario: String, dimensions: Vector2i) -> bool:
	var image := viewport.get_texture().get_image()
	if image == null or image.is_empty():
		_fail("Renderer produced no image: " + scenario)
		return false
	var first := image.get_pixel(0, 0)
	var varied := false
	for x in range(1, 10):
		for y in range(1, 10):
			if image.get_pixel(image.get_width() * x / 10, image.get_height() * y / 10) != first:
				varied = true
	if not varied:
		_fail("Renderer produced a uniform frame: " + scenario)
		return false
	var filename := "%s_%dx%d.png" % [scenario, dimensions.x, dimensions.y]
	if image.save_png(_output.path_join(filename)) != OK:
		_fail("Cannot write image: " + filename)
		return false
	_images.append(filename)
	print("CAPTURE ", filename)
	return true


func _show(app: Node, scenario: String) -> bool:
	match scenario:
		"main_menu":
			app._show_main_menu()
		"class_selection":
			app._show_class_selection()
		"city":
			app._show_city_hub()
			var city = app.screen_host.get_child(0)
			city.navigation_drawer.pinned = true
			city.navigation_drawer.set_open(true, true)
		"inn", "merchant":
			app._show_city_service(scenario)
			app.screen_host.get_child(0)._open_service()
		"equipment":
			app._show_equipment()
		"world_map":
			app._show_world_map()
		"guild":
			app._show_guild()
			app.screen_host.get_child(0).show_story_board()
		"black_market":
			app._show_black_market()
		"combat_wolf", "combat_ice_crab":
			# The fixture must match the region passed to visual review.
			app._current_session.current_location_id = (
				"ice_coast" if scenario == "combat_ice_crab" else "twilight_plains"
			)
			app._current_session.player.stats.restore_full()
			app._show_combat(scenario.trim_prefix("combat_"), "expedition")
			app.screen_host.get_child(0).set_reduced_motion(true)
		_:
			return false
	return true


func _settle() -> void:
	for frame in 20:
		await process_frame


func _fail(message: String) -> void:
	_failed = true
	push_error(message)
	quit(1)
