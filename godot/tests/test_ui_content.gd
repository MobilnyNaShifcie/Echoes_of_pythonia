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
	var menu_scroll := city.get_node("Layout/MenuPanel/MenuScroll") as ScrollContainer
	var grid := city.get_node("Layout/MenuPanel/MenuScroll/Menu/Grid") as GridContainer
	var expected_labels := [
		"Brama Zachodnia",
		"Gildia Poszukiwaczy",
		"Kuźnia Garrana",
		"Warsztat Mireli",
		"Kram Orena",
		"Karczma",
		"Bohater",
		"Przygotowanie wyprawy",
	]
	var actual_labels: Array[String] = []
	for button: Button in grid.get_children():
		actual_labels.append(button.text)

	assert_eq(grid.columns, 1)
	assert_eq(actual_labels, expected_labels)
	assert_eq(menu_scroll.horizontal_scroll_mode, ScrollContainer.SCROLL_MODE_DISABLED)
