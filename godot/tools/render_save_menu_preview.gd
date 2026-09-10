extends SceneTree
## Uses the real save service only under a new fixture directory, never the player's slots.
const App := preload("res://scenes/app/app.tscn")
const NewGame := preload("res://core/game/new_game_service.gd")
const SaveService := preload("res://core/save/save_game_service.gd")
const OUTPUT := "res://../output/ui_refresh_20260907/save_menu/"
var _failures := 0


func _init() -> void:
	if not InputMap.has_action("dialogic_default_action"):
		InputMap.add_action("dialogic_default_action")
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var save_root := OUTPUT + "fixture_" + Crypto.new().generate_random_bytes(8).hex_encode()
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var app = App.instantiate()
	app._save_service = SaveService.new(save_root)
	viewport.add_child(app)
	app._current_session = NewGame.new().create_session("Aria", 2)
	app._current_session.player.gold = 777
	app._show_main_menu()
	await _settle()
	var menu = app.screen_host.get_child(0)
	await _click(menu.save_button)
	var loaded := SaveService.new(save_root).load_session(2)
	_check(loaded.ok, "Saved slot can be loaded: " + loaded.message)
	_check(not menu.load_button.disabled, "Load enabled without leaving the menu")
	_check(menu.save_feedback.is_visible_in_tree(), "Save confirmation is visible")
	_check(menu.save_feedback.text.contains("Zapisano"), "Success message")
	await _capture(viewport, "success")
	app._current_session.hour = 99  # Deliberate validation failure, not real player data.
	await _click(menu.save_button)
	_check(menu.save_feedback.text.contains("Nie zapisano gry"), "Error message is visible")
	loaded = SaveService.new(save_root).load_session(2)
	_check(loaded.ok, "A failed save preserves the previous valid slot")
	await _capture(viewport, "error")
	app._current_session.hour = 8
	await _click(menu.save_button)
	await _click(menu.load_button)
	var load_menu = app.screen_host.get_child(0)
	_check(load_menu is LoadGameScreen, "Pointer opens load screen")
	await _capture(viewport, "load_slot")
	await _click(load_menu.load_button)
	_check(app._current_session.player.gold == 777, "Load button restores saved progress")
	app.queue_free()
	await _settle()
	viewport.queue_free()
	await process_frame
	print("SAVE MENU PREVIEW: failures=", _failures, "; fixture=", save_root)
	quit(0 if _failures == 0 else 1)


func _click(button: Button) -> void:
	var viewport := button.get_viewport()
	var motion := InputEventMouseMotion.new()
	motion.position = button.get_global_rect().get_center()
	viewport.push_input(motion, true)
	await _settle()
	_check(viewport.gui_get_hovered_control() == button, "Pointer reaches " + button.text)
	var press := InputEventMouseButton.new()
	press.position = motion.position
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	viewport.push_input(press, true)
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	viewport.push_input(release, true)
	await _settle()


func _settle() -> void:
	for frame in 15:
		await process_frame


func _capture(viewport: SubViewport, name: String) -> void:
	await RenderingServer.frame_post_draw
	_check(viewport.get_texture().get_image().save_png(OUTPUT + name + ".png") == OK, name)


func _check(condition: bool, description: String) -> void:
	if not condition:
		_failures += 1
		push_error(description)
	else:
		print("PASS: ", description)
