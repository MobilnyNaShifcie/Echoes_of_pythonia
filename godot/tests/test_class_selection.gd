extends GutTest

const CLASS_SELECTION_SCENE := preload("res://ui/screens/class_selection/class_selection.tscn")
const ClassCarouselSelectorClass := preload(
	"res://ui/components/class_carousel_selector/class_carousel_selector.gd"
)
const ClassSelectionScreenClass := preload("res://ui/screens/class_selection/class_selection.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const PlayerEquipmentClass := preload("res://core/player/equipment.gd")
const PlayerFactoryClass := preload("res://core/player/player_factory.gd")


func test_class_choice_unlocks_at_level_five_and_remains_permanent() -> void:
	var player = PlayerFactoryClass.create_player("Tester")

	assert_false(player.can_choose_class)
	assert_false(player.choose_class("pierrot"))
	player.level = 5
	assert_true(player.can_choose_class)
	assert_true(player.choose_class("pierrot"))
	assert_eq(player.character_class_code, "pierrot")
	assert_false(player.can_choose_class)
	assert_false(player.choose_class("warrior"))


func test_each_class_equips_its_starting_set_at_level_five() -> void:
	var expectations := {
		"warrior": ["starter_sword", "training_shield", 12],
		"hunter": ["hunting_bow", "simple_quiver", 16],
		"mage": ["apprentice_staff", "mana_crystal_artifact", 37],
		"pierrot": ["caprice_lance", "worn_fate_dice", 18],
	}
	for class_code: String in expectations:
		var player = PlayerFactoryClass.create_player("Tester")
		player.level = 5

		assert_true(player.choose_class(class_code), class_code)
		assert_eq(player.weapon_id, expectations[class_code][0], class_code)
		assert_eq(
			player.get_equipped_item_id(PlayerEquipmentClass.OFF_HAND),
			expectations[class_code][1],
			class_code,
		)
		assert_eq(player.stats.max_mana, expectations[class_code][2], class_code)


func test_gender_is_chosen_once_and_feminizes_the_neutral_role_name() -> void:
	var player = PlayerFactoryClass.create_player("Aria")

	assert_eq(player.gender_code, "unspecified")
	assert_true(player.choose_gender("female"))
	assert_eq(player.gender_name, "Kobieta")
	assert_eq(player.character_class_name, "Poszukiwaczka")
	assert_false(player.choose_gender("male"))
	assert_eq(player.gender_code, "female")


func test_class_screen_builds_a_three_figure_carousel_with_minimal_selectors() -> void:
	var host := Control.new()
	host.size = Vector2(1920, 860)
	add_child(host)
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 5
	var screen := CLASS_SELECTION_SCENE.instantiate() as ClassSelectionScreenClass
	host.add_child(screen)
	screen.configure(session)
	await get_tree().process_frame

	assert_eq(screen.selector_row.get_child_count(), 4)
	assert_eq(screen.selected_class_code(), "warrior")
	assert_eq(screen.center_art.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	assert_eq(screen.left_art.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	assert_eq(screen.right_art.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	assert_eq(screen.left_figure.get_meta("class_code"), "pierrot")
	assert_eq(screen.right_figure.get_meta("class_code"), "hunter")
	for class_code: String in ["warrior", "hunter", "mage", "pierrot"]:
		var selector := screen.selector_for_class(class_code)
		assert_true(selector is ClassCarouselSelectorClass, class_code)
		assert_eq(selector.focus_mode, Control.FOCUS_ALL, class_code)

	var hunter := screen.selector_for_class("hunter")
	hunter.pressed.emit()
	assert_eq(screen.selected_class_code(), "hunter")
	assert_true(hunter.is_selected())
	assert_false(screen.selector_for_class("warrior").is_selected())
	assert_eq(screen.detail_class_name.text, "Łowca")
	assert_eq(screen.primary_attributes_label.text, "Zręczność / Siła")
	assert_eq(screen.mana_value_label.text, "16")
	assert_string_contains(screen.equipment_list.text, "Łuk Myśliwski")
	assert_eq(session.player.character_class_code, "none")
	host.free()


func test_carousel_uses_full_body_gender_art_without_cover_or_stretch() -> void:
	var expected_paths := {
		"warrior":
		{
			"male": "res://assets/ui/class_selection/warrior_male.png",
			"female": "res://assets/ui/class_selection/warrior_female.png",
		},
		"hunter":
		{
			"male": "res://assets/ui/class_selection/hunter_male.png",
			"female": "res://assets/ui/class_selection/hunter_female.png",
		},
		"mage":
		{
			"male": "res://assets/ui/class_selection/mage_male.png",
			"female": "res://assets/ui/class_selection/mage_female.png",
		},
		"pierrot":
		{
			"male": "res://assets/ui/class_selection/pierrot_male.png",
			"female": "res://assets/ui/class_selection/pierrot_female.png",
		},
	}
	for gender_code: String in ["male", "female"]:
		var session = NewGameServiceClass.new().create_session("Sylwetka", 1)
		assert_true(session.player.choose_gender(gender_code))
		var screen := CLASS_SELECTION_SCENE.instantiate() as ClassSelectionScreenClass
		add_child(screen)
		screen.configure(session)
		await get_tree().process_frame

		assert_eq(screen.CLASS_ART_PATHS, expected_paths)
		for class_code: String in expected_paths:
			var expected_path: String = expected_paths[class_code][gender_code]
			assert_true(ResourceLoader.exists(expected_path), class_code)
			screen.selector_for_class(class_code).pressed.emit()
			var character_texture := screen.center_art.texture as Texture2D
			assert_not_null(character_texture, class_code)
			assert_eq(character_texture.resource_path, expected_path, class_code)
			assert_eq(screen.center_art.expand_mode, TextureRect.EXPAND_IGNORE_SIZE, class_code)
			assert_eq(
				screen.center_art.stretch_mode,
				TextureRect.STRETCH_KEEP_ASPECT_CENTERED,
				class_code,
			)
			assert_true(_has_visible_pixels_in_lower_quarter(character_texture), class_code)
		screen.free()


func test_center_figure_has_alpha_driven_depth_layers_and_class_atmosphere() -> void:
	var screen := CLASS_SELECTION_SCENE.instantiate() as ClassSelectionScreenClass
	add_child_autofree(screen)
	await get_tree().process_frame

	assert_not_null(screen.center_art.texture)
	assert_eq(screen.center_shadow.texture, screen.center_art.texture)
	assert_eq(screen.center_glow.texture, screen.center_art.texture)
	assert_true(screen.center_glow.material is ShaderMaterial)
	assert_true(screen.pedestal.material is ShaderMaterial)
	assert_true(screen.atmosphere.material is ShaderMaterial)
	assert_gt(screen.center_figure_layer.z_index, screen.left_figure.z_index)
	screen.selector_for_class("mage").pressed.emit()
	var atmosphere_material := screen.atmosphere.material as ShaderMaterial
	assert_eq(
		atmosphere_material.get_shader_parameter("primary_color"),
		screen.CLASS_ACCENTS["mage"],
	)


func test_arrow_controls_wrap_the_carousel_and_confirmation_stays_separate() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 5
	var screen := CLASS_SELECTION_SCENE.instantiate() as ClassSelectionScreenClass
	add_child_autofree(screen)
	screen.configure(session)
	await get_tree().process_frame
	watch_signals(screen)

	screen.previous_button.pressed.emit()
	assert_eq(screen.selected_class_code(), "pierrot")
	assert_eq(session.player.character_class_code, "none")
	assert_false(screen.choose_button.disabled)
	screen.next_button.pressed.emit()
	assert_eq(screen.selected_class_code(), "warrior")
	screen.selector_for_class("pierrot").pressed.emit()
	screen.choose_button.pressed.emit()
	assert_eq(session.player.character_class_code, "pierrot")
	assert_true(screen.selector_for_class("pierrot").is_permanent())
	assert_false(screen.selector_for_class("warrior").is_permanent())
	assert_true(screen.choose_button.disabled)
	assert_signal_emitted(screen, "class_chosen")
	screen.back_button.pressed.emit()
	assert_signal_emitted(screen, "back_requested")


func test_permanent_marker_does_not_replace_the_live_preview() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	assert_true(session.player.choose_gender("female"))
	session.player.level = 5
	assert_true(session.player.choose_class("pierrot"))
	var screen := CLASS_SELECTION_SCENE.instantiate() as ClassSelectionScreenClass
	add_child_autofree(screen)
	screen.configure(session)
	await get_tree().process_frame

	var warrior := screen.selector_for_class("warrior")
	var pierrot := screen.selector_for_class("pierrot")
	assert_true(pierrot.is_permanent())
	assert_false(warrior.is_permanent())
	warrior.pressed.emit()
	assert_eq(screen.selected_class_code(), "warrior")
	assert_true(warrior.is_selected())
	assert_false(warrior.is_permanent())
	assert_true(pierrot.is_permanent())
	assert_eq(session.player.character_class_code, "pierrot")
	assert_true(screen.choose_button.disabled)


func test_carousel_stays_inside_the_supported_windowed_layout() -> void:
	for viewport_size: Vector2 in [Vector2(1920, 860), Vector2(1280, 650)]:
		var host := Control.new()
		host.size = viewport_size
		add_child(host)
		var screen := CLASS_SELECTION_SCENE.instantiate() as ClassSelectionScreenClass
		host.add_child(screen)
		await get_tree().process_frame

		var main_stage := screen.get_node("Page/MainStage") as Control
		var selector_dock := screen.get_node("Page/SelectorDock") as Control
		assert_lte(main_stage.get_global_rect().end.x, host.size.x)
		assert_lte(selector_dock.get_global_rect().end.y, host.size.y)
		assert_lte(screen.center_art.get_global_rect().end.y, selector_dock.global_position.y)
		host.free()


func _has_visible_pixels_in_lower_quarter(texture: Texture2D) -> bool:
	var image := texture.get_image()
	if image == null or image.is_empty():
		return false
	var start_y := int(image.get_height() * 0.75)
	for y in range(start_y, image.get_height(), 8):
		for x in range(0, image.get_width(), 8):
			if image.get_pixel(x, y).a > 0.1:
				return true
	return false
