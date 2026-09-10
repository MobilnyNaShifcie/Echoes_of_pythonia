extends GutTest

const CITY_HUB_SCENE := preload("res://ui/screens/city_hub/city_hub.tscn")
const CityHubScreenClass := preload("res://ui/screens/city_hub/city_hub.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")


func test_sidebar_highlights_match_the_gate_at_supported_sizes() -> void:
	for viewport_size: Vector2 in [Vector2(1280, 720), Vector2(1600, 900), Vector2(1920, 1080)]:
		await _assert_navigation_widths(viewport_size, false)


func test_sidebar_keeps_full_width_when_party_action_is_visible() -> void:
	await _assert_navigation_widths(Vector2(1280, 720), true)


func _assert_navigation_widths(viewport_size: Vector2, show_preparation: bool) -> void:
	var host := Control.new()
	host.size = viewport_size
	add_child(host)
	var city := CITY_HUB_SCENE.instantiate() as CityHubScreenClass
	city.configure(NewGameServiceClass.new().create_session("Aria", 1))
	host.add_child(city)
	city.navigation_drawer.pinned = true
	city.navigation_drawer.set_open(true, true)
	city.get_node("%PreparationButton").visible = show_preparation
	await get_tree().process_frame
	await get_tree().process_frame

	var gate := city.get_node("%GateButton") as Button
	var gate_rect := gate.get_global_rect()
	assert_gt(gate_rect.size.x, 200.0)
	for node_name: String in CityHubScreenClass.NAV_BUTTON_NAMES:
		var button := city.get_node("%%%s" % node_name) as Button
		if not button.visible:
			continue
		var button_rect := button.get_global_rect()
		var context := "%s at %s" % [node_name, viewport_size]
		assert_almost_eq(button_rect.position.x, gate_rect.position.x, 0.5, context)
		assert_almost_eq(button_rect.end.x, gate_rect.end.x, 0.5, context)
		assert_almost_eq(button_rect.size.x, gate_rect.size.x, 0.5, context)
		assert_eq(button.alignment, HORIZONTAL_ALIGNMENT_LEFT, context)
		assert_eq(button.icon_alignment, HORIZONTAL_ALIGNMENT_LEFT, context)
	host.free()
