extends GutTest

const CITY_HUB_SCENE := preload("res://ui/screens/city_hub/city_hub.tscn")
const CityHubScreenClass := preload("res://ui/screens/city_hub/city_hub.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const PrologueScreenClass := preload("res://ui/screens/prologue/prologue.gd")


func test_prologue_uses_requested_polish_wording() -> void:
	var prologue_text := JSON.stringify(PrologueScreenClass.SCENES)

	assert_false(prologue_text.contains("Gold"))
	assert_false(prologue_text.to_lower().contains("edykt"))
	assert_true(prologue_text.contains("złota"))
	assert_true(prologue_text.contains("złotem"))
	assert_true(prologue_text.contains("dekretu"))


func test_city_plan_is_a_single_top_to_bottom_column() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var city := CITY_HUB_SCENE.instantiate() as CityHubScreenClass
	city.configure(session)
	add_child_autofree(city)
	await get_tree().process_frame
	var menu_scroll := city.get_node("Layout/MenuPanel/MenuScroll") as ScrollContainer
	var travel_grid := city.get_node("Layout/MenuPanel/MenuScroll/Menu/TravelGrid") as GridContainer
	var services_grid := (
		city.get_node("Layout/MenuPanel/MenuScroll/Menu/ServicesGrid") as GridContainer
	)
	var hero_grid := city.get_node("Layout/MenuPanel/MenuScroll/Menu/HeroGrid") as GridContainer
	var expected_service_labels := [
		"Gildia Poszukiwaczy",
		"Kwatermistrz i magazyn",
		"Kuźnia Garrana",
		"Warsztat Mireli",
		"Kram Orena",
		"Karczma",
	]
	var expected_hero_labels := [
		"Karta bohatera i ekwipunek",
		"Dziennik Przygód",
		"Osiągnięcia i tytuły",
	]
	var actual_service_labels: Array[String] = []
	for button: Button in services_grid.get_children():
		actual_service_labels.append(button.text)
		assert_eq(button.alignment, HORIZONTAL_ALIGNMENT_CENTER)
	var actual_hero_labels: Array[String] = []
	for button: Button in hero_grid.get_children():
		actual_hero_labels.append(button.text)
		assert_eq(button.alignment, HORIZONTAL_ALIGNMENT_CENTER)

	assert_eq(travel_grid.columns, 1)
	assert_eq(services_grid.columns, 1)
	assert_eq(hero_grid.columns, 1)
	assert_eq(travel_grid.get_child(0).text, "Brama Zachodnia — wyprawa SOLO")
	assert_false(city.get_node("%PreparationButton").visible)
	assert_eq(actual_service_labels, expected_service_labels)
	assert_eq(actual_hero_labels, expected_hero_labels)
	assert_lt(
		city.get_node("Layout/MenuPanel").get_index(),
		city.get_node("Layout/City").get_index(),
	)
	assert_eq(menu_scroll.horizontal_scroll_mode, ScrollContainer.SCROLL_MODE_DISABLED)


func test_city_gate_opens_world_map_without_solo_preparation() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var city := CITY_HUB_SCENE.instantiate() as CityHubScreenClass
	city.configure(session)
	add_child_autofree(city)
	watch_signals(city)

	city.get_node("%GateButton").pressed.emit()

	assert_signal_emitted(city, "world_map_requested")
	assert_signal_not_emitted(city, "service_requested")
