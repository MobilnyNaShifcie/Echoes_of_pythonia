extends SceneTree
## Real app and in-memory market fixture; never reads the player's saves.
const App = preload("res://scenes/app/app.tscn")
const NewGame = preload("res://core/game/new_game_service.gd")
const Saves = preload("res://core/save/save_game_service.gd")
const Books = preload("res://core/progression/book_catalog.gd")


func _init() -> void:
	if not InputMap.has_action("dialogic_default_action"):
		InputMap.add_action("dialogic_default_action")
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2 or not args[0].is_absolute_path() or not args[1].is_absolute_path():
		push_error("Use scripts/review_black_market.py with isolated evidence/save directories")
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
		var session = NewGame.new().create_session("Aria", 1)
		session.black_market.unlocked = true
		session.player.gold = 2918
		session.player.inventory.add(Books.BOOK_ORDER[0], 2)
		app._current_session = session
		app._show_black_market()
		var screen = app.screen_host.get_child(0)
		screen.configure(session, "2026-09-19")
		var suffix := "_%dx%d.png" % [dimensions.x, dimensions.y]
		await _capture(viewport, args[0].path_join("entrance" + suffix))
		screen.merchant_button.pressed.emit()
		await _capture(viewport, args[0].path_join("conversation" + suffix))
		print("CONVERSATION RECT ", screen.npc_action_panel.get_rect())
		assert(screen.npc_action_panel.size.y <= 343, "Conversation must stay compact")
		screen.get_node("%OpenServiceButton").pressed.emit()
		await _capture(viewport, args[0].path_join("offers" + suffix))
		screen.action_button.pressed.emit()
		await _capture(viewport, args[0].path_join("insufficient_gold" + suffix))
		session.player.gold = 200000
		screen.action_button.pressed.emit()
		await _capture(viewport, args[0].path_join("sold" + suffix))
		screen.show_book_sales()
		await _capture(viewport, args[0].path_join("books" + suffix))
		app.queue_free()
		await _settle()
		viewport.queue_free()
		await _settle()
		print("MARKET CAPTURE ", suffix)
	quit(0)


func _capture(viewport: SubViewport, path: String) -> void:
	await _settle()
	await RenderingServer.frame_post_draw
	assert(viewport.get_texture().get_image().save_png(path) == OK)


func _settle() -> void:
	for frame in 20:
		await process_frame
