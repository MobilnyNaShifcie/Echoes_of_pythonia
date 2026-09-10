extends GutTest

const APP_SCENE := preload("res://scenes/app/app.tscn")
const NewGame := preload("res://core/game/new_game_service.gd")
const SaveService := preload("res://core/save/save_game_service.gd")
var _save_root: String


func before_each() -> void:
	_save_root = "user://test_menu_save_" + Crypto.new().generate_random_bytes(8).hex_encode()


func after_each() -> void:
	# Only remove this test's explicitly named slots, never the player's save directory.
	for slot in range(1, SaveService.SLOT_COUNT + 1):
		for suffix in ["", ".tmp", ".bak"]:
			var path := "%s/save_%d.json%s" % [_save_root, slot, suffix]
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(_save_root)):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(_save_root))


func _mount(dimensions := Vector2i(1920, 1080)) -> Control:
	var viewport := SubViewport.new()
	viewport.size = dimensions
	add_child_autoqfree(viewport)
	var app = APP_SCENE.instantiate()
	app._save_service = SaveService.new(_save_root)
	viewport.add_child(app)
	app._current_session = NewGame.new().create_session("Aria", 2)
	app._current_session.player.gold = 777
	app._show_main_menu()
	await wait_process_frames(4)
	return app


func _click(button: Button) -> void:
	var viewport := button.get_viewport()
	var motion := InputEventMouseMotion.new()
	motion.position = button.get_global_rect().get_center()
	viewport.push_input(motion, true)
	await wait_process_frames(1)
	assert_eq(viewport.gui_get_hovered_control(), button, "Pointer reaches the visible button.")
	var press := InputEventMouseButton.new()
	press.position = motion.position
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	viewport.push_input(press, true)
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	viewport.push_input(release, true)
	await wait_process_frames(3)


func test_save_click_writes_reloadable_slot_and_shows_confirmation_in_menu() -> void:
	var app = await _mount()
	var menu = app.screen_host.get_child(0)
	watch_signals(menu)
	assert_false(menu.save_button.disabled)
	assert_true(menu.load_button.disabled)
	await _click(menu.save_button)
	assert_signal_emit_count(menu, "save_requested", 1)
	var loaded := SaveService.new(_save_root).load_session(2)
	assert_true(loaded.ok, loaded.message)
	if loaded.ok:
		assert_eq(loaded.session.player.gold, 777)
	assert_false(menu.load_button.disabled, "Load must enable immediately after the first save.")
	var feedback := menu.find_child("SaveFeedback", true, false) as Label
	assert_not_null(feedback, "Saving needs visible feedback, not the hidden app footer.")
	if feedback != null:
		assert_true(feedback.is_visible_in_tree())
		assert_string_contains(feedback.text, "Zapisano")
		assert_true(menu.get_global_rect().encloses(feedback.get_global_rect()))


func test_failed_save_is_visible_preserves_previous_file_and_allows_retry() -> void:
	var app = await _mount(Vector2i(1280, 720))
	var menu = app.screen_host.get_child(0)
	await _click(menu.save_button)
	var original_file := FileAccess.get_file_as_string(app._save_service.slot_path(2))
	app._current_session.hour = 99
	await _click(menu.save_button)
	assert_string_contains(menu.save_feedback.text, "Nie zapisano gry")
	assert_string_contains(menu.save_feedback.text, app.app_status_label.text)
	assert_true(menu.save_feedback.is_visible_in_tree())
	assert_eq(FileAccess.get_file_as_string(app._save_service.slot_path(2)), original_file)
	assert_false(menu.save_button.disabled)
	assert_false(menu.load_button.disabled, "Previous valid save remains available.")
	assert_true(menu.get_global_rect().encloses(menu.get_node("%MenuPanel").get_global_rect()))
	app._current_session.hour = 12
	app._current_session.player.gold = 456
	await _click(menu.save_button)
	assert_string_contains(menu.save_feedback.text, "Zapisano")
	assert_false(menu.save_feedback.text.contains("Nie zapisano"))
	var loaded := SaveService.new(_save_root).load_session(2)
	assert_true(loaded.ok, loaded.message)
	if loaded.ok:
		assert_eq(loaded.session.player.gold, 456)
		assert_eq(loaded.session.hour, 12)


func test_failure_before_first_save_does_not_enable_load() -> void:
	var app = await _mount()
	var menu = app.screen_host.get_child(0)
	app._current_session.save_slot = 99
	await _click(menu.save_button)
	assert_true(menu.load_button.disabled)
	assert_string_contains(menu.save_feedback.text, "Nieprawidłowy slot zapisu")
	assert_false(app._save_service.any_save_exists())


func test_save_then_load_buttons_restore_actual_disk_state() -> void:
	for dimensions in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1080)]:
		var app = await _mount(dimensions)
		var menu = app.screen_host.get_child(0)
		var original_menu_rect: Rect2 = menu.get_node("%MenuPanel").get_global_rect()
		await _click(menu.save_button)
		assert_true(menu.get_global_rect().encloses(menu.save_feedback.get_global_rect()))
		assert_eq(
			menu.get_node("%MenuPanel").get_global_rect(),
			original_menu_rect,
			"A successful save does not shift menu buttons."
		)
		app._current_session.player.gold = 1
		await _click(menu.load_button)
		var load_menu = app.screen_host.get_child(0)
		assert_true(load_menu is LoadGameScreen)
		assert_eq(load_menu.slot_selector.get_selected_metadata(), 2)
		await _click(load_menu.load_button)
		assert_eq(app._current_session.player.gold, 777)
		assert_eq(app._current_session.save_slot, 2)
