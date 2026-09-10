extends GutTest

const MainMenuScreenClass := preload("res://ui/screens/main_menu/main_menu.gd")
const MAIN_MENU_SCENE := preload("res://ui/screens/main_menu/main_menu.tscn")


func test_session_actions_start_disabled() -> void:
	var menu := MAIN_MENU_SCENE.instantiate() as MainMenuScreenClass
	add_child_autofree(menu)

	assert_true(menu.continue_button.disabled)
	assert_true(menu.load_button.disabled)
	assert_true(menu.save_button.disabled)


func test_session_actions_enable_when_session_exists() -> void:
	var menu := MAIN_MENU_SCENE.instantiate() as MainMenuScreenClass
	add_child_autofree(menu)
	menu.configure(true)

	assert_false(menu.continue_button.disabled)
	assert_false(menu.save_button.disabled)


func test_load_action_enables_only_when_a_persistent_save_exists() -> void:
	var menu := MAIN_MENU_SCENE.instantiate() as MainMenuScreenClass
	add_child_autofree(menu)
	menu.configure(false, true)

	assert_true(menu.continue_button.disabled)
	assert_false(menu.load_button.disabled)
	assert_true(menu.save_button.disabled)


func test_main_menu_uses_varenhold_background_and_left_hand_navigation() -> void:
	var menu := MAIN_MENU_SCENE.instantiate() as MainMenuScreenClass
	menu.set_anchors_preset(Control.PRESET_TOP_LEFT)
	menu.size = Vector2(1280.0, 720.0)
	add_child_autofree(menu)
	await get_tree().process_frame

	var background := menu.get_node("%Background") as TextureRect
	var menu_panel := menu.get_node("%MenuPanel") as PanelContainer
	var introduction := menu.get_node("%Introduction") as PanelContainer

	assert_not_null(background.texture)
	assert_eq(
		background.texture.resource_path,
		"res://assets/city/varenhold/backgrounds/varenhold_main_menu.png"
	)
	assert_eq(menu_panel.anchor_left, 0.0)
	assert_eq(menu_panel.anchor_right, 0.0)
	assert_eq(introduction.anchor_left, 1.0)
	assert_eq(introduction.anchor_right, 1.0)
	assert_lte(menu_panel.get_rect().end.x, introduction.get_rect().position.x)
	assert_true(menu.get_rect().encloses(menu_panel.get_rect()))
	assert_lte(absf(introduction.offset_left), 660.0)
