extends GutTest

const COMBAT_SCENE := preload("res://ui/screens/combat/combat.tscn")
const CombatScreenClass := preload("res://ui/screens/combat/combat.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const SKILLS_SCENE := preload("res://ui/screens/skills/skills.tscn")
const SkillsScreenClass := preload("res://ui/screens/skills/skills.gd")


func test_skill_catalog_screen_shows_unlock_state_and_details() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 5
	assert_true(session.player.choose_class("warrior"))
	session.player.level = 7
	var screen := SKILLS_SCENE.instantiate() as SkillsScreenClass
	screen.configure(session)
	add_child_autofree(screen)

	assert_eq(screen.skill_list.item_count, 4)
	assert_string_contains(screen.summary_label.text, "2/4")
	assert_eq(screen.skill_name_label.text, "Potężne Cięcie")
	assert_string_contains(screen.skill_status_label.text, "ODBLOKOWANA")
	screen.skill_list.select(2)
	screen.skill_list.item_selected.emit(2)
	assert_eq(screen.skill_name_label.text, "Postawa Obronna")
	assert_string_contains(screen.skill_status_label.text, "poziom 9")


func test_skills_screen_explains_state_before_class_selection() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var screen := SKILLS_SCENE.instantiate() as SkillsScreenClass
	screen.configure(session)
	add_child_autofree(screen)

	assert_eq(screen.path_selector.item_count, 4)
	assert_eq(screen.skill_list.item_count, 4)
	assert_eq(screen.skill_name_label.text, "Potężne Cięcie")
	assert_string_contains(screen.skill_status_label.text, "PODGLĄD")
	screen.path_selector.select(3)
	screen.path_selector.item_selected.emit(3)
	assert_eq(screen.skill_name_label.text, "Pchnięcie Losu")
	assert_eq(session.player.character_class_code, "none")


func test_skills_back_button_emits_navigation_request() -> void:
	var screen := SKILLS_SCENE.instantiate() as SkillsScreenClass
	add_child_autofree(screen)
	watch_signals(screen)

	screen.get_node("Page/Heading/BackButton").pressed.emit()
	assert_signal_emitted(screen, "back_requested")


func test_combat_shows_unlocked_skill_and_spends_mana() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 5
	assert_true(session.player.choose_class("warrior"))
	var screen := COMBAT_SCENE.instantiate() as CombatScreenClass
	screen.configure(session, "prologue_scarecrow", "prologue")
	add_child_autofree(screen)

	assert_eq(screen.skill_selector.item_count, 1)
	assert_string_contains(screen.skill_selector.get_item_text(0), "Potężne Cięcie")
	assert_false(screen.skill_button.disabled)
	assert_string_contains(screen.player_stats_label.text, "MANA 12/12")
	screen.skill_button.pressed.emit()

	assert_eq(session.player.stats.current_mana, 6)
	assert_string_contains(screen.combat_log.get_parsed_text(), "Potężne Cięcie")


func test_combat_disables_selected_skill_when_mana_is_missing() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 5
	assert_true(session.player.choose_class("warrior"))
	session.player.stats.current_mana = 0
	var screen := COMBAT_SCENE.instantiate() as CombatScreenClass
	screen.configure(session, "prologue_scarecrow", "prologue")
	add_child_autofree(screen)

	assert_true(screen.skill_button.disabled)
	assert_string_contains(screen.skill_button.tooltip_text, "Brak Many")
