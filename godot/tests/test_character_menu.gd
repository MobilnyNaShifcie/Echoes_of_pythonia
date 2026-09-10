extends GutTest

const CharacterMenuScreenClass := preload("res://ui/screens/character_menu/character_menu.gd")
const CharacterSheetScreenClass := preload("res://ui/screens/character_sheet/character_sheet.gd")
const EquipmentScreenClass := preload("res://ui/screens/equipment/equipment.gd")
const ProgressionScreenClass := preload("res://ui/screens/progression/progression.gd")
const SkillsScreenClass := preload("res://ui/screens/skills/skills.gd")
const CHARACTER_MENU_SCENE := preload("res://ui/screens/character_menu/character_menu.tscn")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")


func test_unifies_character_sections_over_one_persistent_armory_background() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 2)
	var screen := CHARACTER_MENU_SCENE.instantiate() as CharacterMenuScreenClass
	screen.configure(session)
	add_child_autofree(screen)
	await get_tree().process_frame

	var background := screen.get_node("Background") as TextureRect
	var background_wash := screen.get_node("BackgroundWash") as ColorRect
	assert_not_null(background.texture)
	assert_lt(background_wash.color.a, 0.1)
	assert_eq(
		background.texture.resource_path,
		"res://assets/ui/character_menu/character_armory_background_v1.png",
	)
	assert_eq(screen.active_section(), CharacterMenuScreenClass.SECTION_CHARACTER)
	var character_view := screen.view_for_section(CharacterMenuScreenClass.SECTION_CHARACTER)
	assert_eq(character_view.get_script(), CharacterSheetScreenClass)
	assert_false(character_view.get_node("Page/Heading").visible)
	assert_true(character_view.get_node("Page/OverviewPanel").is_visible_in_tree())

	screen.get_node("%EquipmentTab").pressed.emit()
	assert_eq(screen.active_section(), CharacterMenuScreenClass.SECTION_EQUIPMENT)
	var equipment_view := screen.view_for_section(CharacterMenuScreenClass.SECTION_EQUIPMENT)
	assert_eq(equipment_view.get_script(), EquipmentScreenClass)
	assert_false(equipment_view.get_node("Page/Header").visible)
	assert_true(background.is_visible_in_tree())

	screen.get_node("%SkillsTab").pressed.emit()
	assert_eq(screen.active_section(), CharacterMenuScreenClass.SECTION_SKILLS)
	var skills_view := screen.view_for_section(CharacterMenuScreenClass.SECTION_SKILLS)
	assert_eq(skills_view.get_script(), SkillsScreenClass)
	assert_false(skills_view.get_node("Page/Heading").visible)

	screen.get_node("%ProgressionTab").pressed.emit()
	assert_eq(screen.active_section(), CharacterMenuScreenClass.SECTION_PROGRESSION)
	var progression_view := screen.view_for_section(CharacterMenuScreenClass.SECTION_PROGRESSION)
	assert_eq(progression_view.get_script(), ProgressionScreenClass)
	assert_false(progression_view.get_node("Page/Heading").visible)
	assert_true(progression_view.get_node("Page/PointsPanel").is_visible_in_tree())


func test_back_button_keeps_one_navigation_exit_for_the_whole_menu() -> void:
	var screen := CHARACTER_MENU_SCENE.instantiate() as CharacterMenuScreenClass
	add_child_autofree(screen)
	watch_signals(screen)

	screen.get_node("%BackButton").pressed.emit()
	assert_signal_emitted(screen, "back_requested")
