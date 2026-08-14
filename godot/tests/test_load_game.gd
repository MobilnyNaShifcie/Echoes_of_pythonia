extends GutTest

const LOAD_GAME_SCENE := preload("res://ui/screens/load_game/load_game.tscn")
const LoadGameScreenClass := preload("res://ui/screens/load_game/load_game.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")

var _save_root: String
var _service: SaveGameServiceClass


func before_each() -> void:
	_save_root = "user://test_load_screen_%s" % Crypto.new().generate_random_bytes(8).hex_encode()
	_service = SaveGameServiceClass.new(_save_root)


func after_each() -> void:
	var directory := DirAccess.open(_save_root)
	if directory != null:
		for file_name in directory.get_files():
			DirAccess.remove_absolute(
				ProjectSettings.globalize_path("%s/%s" % [_save_root, file_name])
			)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_save_root))


func test_empty_screen_lists_four_slots_and_disables_loading() -> void:
	var screen := LOAD_GAME_SCENE.instantiate() as LoadGameScreenClass
	add_child_autofree(screen)
	screen.configure(_service)

	assert_eq(screen.slot_selector.item_count, 4)
	assert_true(screen.load_button.disabled)
	assert_true(screen.details_label.text.contains("pusty"))


func test_valid_slot_can_be_loaded_from_the_screen() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 3)
	assert_true(_service.save_session(session).ok)
	var screen := LOAD_GAME_SCENE.instantiate() as LoadGameScreenClass
	add_child_autofree(screen)
	screen.configure(_service)
	watch_signals(screen)

	assert_false(screen.load_button.disabled)
	screen.load_button.pressed.emit()
	assert_signal_emitted(screen, "session_loaded")
