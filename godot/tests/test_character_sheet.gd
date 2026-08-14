extends GutTest

const CharacterSheetScreenClass := preload("res://ui/screens/character_sheet/character_sheet.gd")
const CHARACTER_SHEET_SCENE := preload("res://ui/screens/character_sheet/character_sheet.tscn")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")


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
