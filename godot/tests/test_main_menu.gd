extends GutTest

const MainMenuScreenClass := preload("res://ui/screens/main_menu/main_menu.gd")
const MAIN_MENU_SCENE := preload("res://ui/screens/main_menu/main_menu.tscn")


func test_session_actions_start_disabled() -> void:
	var menu := MAIN_MENU_SCENE.instantiate() as MainMenuScreenClass
	add_child_autofree(menu)

	assert_true(menu.continue_button.disabled)
	assert_true(menu.save_button.disabled)


func test_session_actions_enable_when_session_exists() -> void:
	var menu := MAIN_MENU_SCENE.instantiate() as MainMenuScreenClass
	add_child_autofree(menu)
	menu.configure(true)

	assert_false(menu.continue_button.disabled)
	assert_false(menu.save_button.disabled)
