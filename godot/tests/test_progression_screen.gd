extends GutTest

const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const PassiveProgressionServiceClass := preload(
	"res://core/progression/passive_progression_service.gd"
)
const ProgressionScreenClass := preload("res://ui/screens/progression/progression.gd")
const PROGRESSION_SCENE := preload("res://ui/screens/progression/progression.tscn")
const TalentProgressionServiceClass := preload(
	"res://core/progression/talent_progression_service.gd"
)


func test_class_tree_lists_both_paths_and_spends_a_real_point() -> void:
	var session = _class_session("warrior", 9)
	var screen := PROGRESSION_SCENE.instantiate() as ProgressionScreenClass
	screen.configure(session)
	add_child_autofree(screen)

	assert_eq(screen.path_list.item_count, 2)
	assert_eq(screen.talent_list.item_count, 5)
	assert_string_contains(screen.points_label.text, "Punkty drzewka: 3")
	assert_false(screen.learn_button.disabled)
	screen.learn_button.pressed.emit()

	assert_eq(TalentProgressionServiceClass.talent_rank(session.player, "warrior_battle_fury"), 1)
	assert_string_contains(screen.points_label.text, "Punkty drzewka: 2")
	assert_string_contains(screen.feedback_label.text, "Furia Bitewna")


func test_locked_specialization_path_explains_the_required_book() -> void:
	var session = _class_session("mage", 12)
	var screen := PROGRESSION_SCENE.instantiate() as ProgressionScreenClass
	screen.configure(session)
	add_child_autofree(screen)

	screen.path_list.select(1)
	screen.path_list.item_selected.emit(1)

	assert_string_contains(screen.path_description_label.text, "Księgi Ścieżki")
	assert_string_contains(screen.path_description_label.text, "Arkana")
	assert_true(screen.learn_button.disabled)
	assert_string_contains(screen.learn_button.tooltip_text, "Księgi Ścieżki")


func test_passive_tab_spends_point_and_refreshes_the_effect() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 6
	var screen := PROGRESSION_SCENE.instantiate() as ProgressionScreenClass
	screen.configure(session)
	add_child_autofree(screen)

	assert_eq(screen.passive_list.item_count, 4)
	assert_false(screen.spend_passive_button.disabled)
	screen.spend_passive_button.pressed.emit()

	assert_eq(PassiveProgressionServiceClass.rank(session.player, "attack_speed"), 1)
	assert_string_contains(screen.points_label.text, "Punkty pasywne: 2")
	assert_string_contains(screen.passive_effect_label.text, "5%")


func test_back_button_emits_navigation_request() -> void:
	var screen := PROGRESSION_SCENE.instantiate() as ProgressionScreenClass
	add_child_autofree(screen)
	watch_signals(screen)

	screen.get_node("Page/Heading/BackButton").pressed.emit()
	assert_signal_emitted(screen, "back_requested")


func _class_session(class_code: String, level: int):
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 5
	assert_true(session.player.choose_class(class_code))
	session.player.level = level
	session.player.stats.restore_full()
	return session
