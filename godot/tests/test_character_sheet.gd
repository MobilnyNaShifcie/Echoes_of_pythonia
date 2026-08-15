extends GutTest

const CharacterSheetScreenClass := preload("res://ui/screens/character_sheet/character_sheet.gd")
const CHARACTER_SHEET_SCENE := preload("res://ui/screens/character_sheet/character_sheet.tscn")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const PlayerAttributesClass := preload("res://core/player/attributes.gd")


func test_renders_migrated_character_state() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 2)
	var screen := CHARACTER_SHEET_SCENE.instantiate() as CharacterSheetScreenClass
	screen.configure(session)
	add_child_autofree(screen)

	assert_eq(screen.hero_name_label.text, "Aria")
	assert_string_contains(screen.progression_label.text, "Poszukiwacz  •  Poziom 0")
	assert_string_contains(screen.primary_stats_label.text, "ATK     3")
	assert_string_contains(screen.primary_stats_label.text, "DEF     2")
	assert_string_contains(screen.equipment_label.text, "Stary Miecz +0")
	assert_string_contains(screen.equipment_label.text, "Zużyta Skórzana Zbroja +0")


func test_back_button_emits_navigation_request() -> void:
	var screen := CHARACTER_SHEET_SCENE.instantiate() as CharacterSheetScreenClass
	add_child_autofree(screen)
	watch_signals(screen)

	screen.get_node("Page/Heading/BackButton").pressed.emit()
	assert_signal_emitted(screen, "back_requested")


func test_equipment_button_emits_navigation_request() -> void:
	var screen := CHARACTER_SHEET_SCENE.instantiate() as CharacterSheetScreenClass
	add_child_autofree(screen)
	watch_signals(screen)

	screen.get_node("Page/Heading/EquipmentButton").pressed.emit()
	assert_signal_emitted(screen, "equipment_requested")


func test_skills_button_emits_navigation_request() -> void:
	var screen := CHARACTER_SHEET_SCENE.instantiate() as CharacterSheetScreenClass
	add_child_autofree(screen)
	watch_signals(screen)

	screen.get_node("Page/Heading/SkillsButton").pressed.emit()
	assert_signal_emitted(screen, "skills_requested")


func test_attribute_buttons_spend_points_and_refresh_derived_stats() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.unspent_attribute_points = 2
	var screen := CHARACTER_SHEET_SCENE.instantiate() as CharacterSheetScreenClass
	screen.configure(session)
	add_child_autofree(screen)

	assert_false(screen.attribute_buttons[PlayerAttributesClass.STRENGTH].disabled)
	assert_true(screen.attribute_buttons[PlayerAttributesClass.LUCK].disabled)
	screen.attribute_buttons[PlayerAttributesClass.STRENGTH].pressed.emit()

	assert_eq(session.player.attributes.strength, 1)
	assert_eq(session.player.unspent_attribute_points, 1)
	assert_eq(session.player.stats.attack, 4)
	assert_eq(screen.attribute_value_labels[PlayerAttributesClass.STRENGTH].text, "1")
	assert_string_contains(screen.progression_label.text, "Wolne punkty atrybutów: 1")


func test_pierrot_can_spend_luck_and_class_button_emits_navigation() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 5
	assert_true(session.player.choose_class("pierrot"))
	session.player.unspent_attribute_points = 1
	var screen := CHARACTER_SHEET_SCENE.instantiate() as CharacterSheetScreenClass
	screen.configure(session)
	add_child_autofree(screen)
	watch_signals(screen)

	assert_false(screen.attribute_buttons[PlayerAttributesClass.LUCK].disabled)
	screen.attribute_buttons[PlayerAttributesClass.LUCK].pressed.emit()
	assert_eq(session.player.attributes.luck, 1)
	assert_eq(session.player.unspent_attribute_points, 0)
	screen.class_button.pressed.emit()
	assert_signal_emitted(screen, "class_selection_requested")
