extends GutTest

const SCENE := preload("res://ui/screens/world_map/world_map.tscn")
const NewGame := preload("res://core/game/new_game_service.gd")
const Layout := preload("res://ui/screens/world_map/varenhold_valley_layout.gd")
const VIEWPORTS := [
	Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1080)
]


func _mount(viewport_size := Vector2i(1600, 900), locked := false) -> Control:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	add_child_autofree(viewport)
	var screen = SCENE.instantiate()
	screen.configure(NewGame.new().create_session("Aria", 1), "twilight_plains" if locked else "")
	viewport.add_child(screen)
	viewport.notify_mouse_entered()
	await wait_process_frames(3)
	watch_signals(screen)
	watch_signals(screen.region_map)
	return screen


# Use the actual drawn layer, independently of the hit-test transform.
func _module_point(screen: Control, uv: Vector2) -> Vector2:
	var module: TextureRect = screen.get_node("%VarenholdModule")
	return module.global_position + uv * module.size


func _map_point(screen: Control, reference: Vector2) -> Vector2:
	var base: TextureRect = screen.get_node("Page/Body/MapLayer/MapTexture")
	return base.global_position + reference / base.texture.get_size() * base.size


func _hover(screen: Control, position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	motion.relative = position - screen.get_viewport().get_mouse_position()
	screen.get_viewport().push_input(motion, true)
	await wait_process_frames(1)


func _click(screen: Control, position: Vector2) -> void:
	await _hover(screen, position)
	var press := InputEventMouseButton.new()
	press.button_index = MOUSE_BUTTON_LEFT
	press.position = position
	press.pressed = true
	screen.get_viewport().push_input(press, true)
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	screen.get_viewport().push_input(release, true)
	await wait_process_frames(2)


func test_the_approved_module_is_independent_and_uses_the_preview_placement() -> void:
	var screen = await _mount()
	var module: TextureRect = screen.get_node("%VarenholdModule")
	var base: TextureRect = screen.get_node("Page/Body/MapLayer/MapTexture")
	assert_string_ends_with(module.texture.resource_path, "varenhold_valley_two_cities_v2.png")
	assert_string_ends_with(base.texture.resource_path, "pythonia_world_map_integrated.png")
	assert_eq(Layout.REFERENCE_RECT, Rect2(100, 350, 850, 850))
	assert_true(ResourceLoader.exists("res://assets/world_map/modules/varenhold_valley_v1.png"))
	assert_false(screen._session.known_region_ids.has(WorldRegionMap.VARENHOLD_VALLEY_ID))
	assert_eq(module.material.get_shader_parameter("east_blend_range"), Layout.EAST_BLEND_RANGE)
	assert_eq(
		module.material.get_shader_parameter("city_polygon"),
		PackedVector2Array(Layout.CITY_POLYGON)
	)


func test_clicking_varenhold_returns_to_city_at_every_supported_size() -> void:
	for viewport_size: Vector2i in VIEWPORTS:
		var screen = await _mount(viewport_size)
		await _hover(screen, _module_point(screen, Vector2(0.362, 0.468)))
		assert_eq(screen.region_map._hovered_region_id, "varenhold", str(viewport_size))
		assert_true(screen.map_hint_label.visible)
		assert_string_contains(screen.map_hint_label.text, "kliknij, aby wrócić")
		var material: ShaderMaterial = screen.get_node("%VarenholdModule").material
		assert_gt(float(material.get_shader_parameter("city_hover_strength")), 0.0)
		assert_eq(float(material.get_shader_parameter("hover_strength")), 0.0)
		await _click(screen, _module_point(screen, Vector2(0.362, 0.468)))
		assert_signal_emitted_with_parameters(screen.region_map, "city_selected", ["varenhold"])
		assert_signal_emitted(screen, "back_requested")
		assert_signal_not_emitted(screen.region_map, "region_selected")


func test_far_city_and_fields_are_scenery_not_a_second_varenhold_entrance() -> void:
	var screen = await _mount()
	for uv: Vector2 in [Vector2(0.64, 0.22), Vector2(0.35, 0.68), Vector2(0.50, 0.50)]:
		await _click(screen, _module_point(screen, uv))
		assert_eq(screen.region_map._hovered_region_id, WorldRegionMap.VARENHOLD_VALLEY_ID)
		assert_eq(screen.region_map.mouse_default_cursor_shape, Control.CURSOR_MOVE)
		assert_string_contains(screen.map_hint_label.text, "Okolice Varenholdu")
		var material: ShaderMaterial = screen.get_node("%VarenholdModule").material
		assert_gt(float(material.get_shader_parameter("hover_strength")), 0.0)
		assert_eq(float(material.get_shader_parameter("city_hover_strength")), 0.0)
	assert_signal_not_emitted(screen, "back_requested")
	assert_signal_not_emitted(screen.region_map, "region_selected")
	assert_signal_not_emitted(screen.region_map, "city_selected")


func test_discarded_background_and_faded_east_edge_do_not_capture_mouse() -> void:
	var screen = await _mount()
	await _hover(screen, _module_point(screen, Vector2(0.02, 0.02)))
	assert_eq(screen.region_map._hovered_region_id, "")
	assert_false(screen.map_hint_label.visible)
	await _click(screen, _module_point(screen, Vector2(0.97, 0.60)))
	assert_eq(screen.region_map._hovered_region_id, "twilight_plains")
	assert_signal_emitted_with_parameters(screen.region_map, "region_selected", ["twilight_plains"])
	assert_signal_not_emitted(screen, "back_requested")


func test_all_original_regions_remain_clickable_and_have_exclusive_highlights() -> void:
	var screen = await _mount()
	var samples := {
		"twilight_plains": Vector2(940, 780),
		"black_forest": Vector2(1194, 569),
		"silentwater_marshes": Vector2(1694, 529),
		"ashen_borderlands": Vector2(1264, 899),
		"ice_coast": Vector2(1844, 819),
	}
	for region: String in samples:
		await _click(screen, _map_point(screen, samples[region]))
		assert_eq(screen.region_map._hovered_region_id, region)
		assert_signal_emitted_with_parameters(screen.region_map, "region_selected", [region])
		var material: ShaderMaterial = screen.get_node("%VarenholdModule").material
		assert_eq(
			roundi(float(material.get_shader_parameter("hover_code"))),
			WorldRegionMap.REGION_ID_CODES[region]
		)
		assert_eq(float(material.get_shader_parameter("city_hover_strength")), 0.0)
	assert_signal_not_emitted(screen, "back_requested")


func test_module_and_hit_areas_follow_resize_and_pan_without_drag_clicks() -> void:
	var screen = await _mount()
	for viewport_size: Vector2i in VIEWPORTS:
		screen.get_viewport().size = viewport_size
		await wait_process_frames(3)
		var origin: Vector2 = screen.region_map.size * 0.5
		screen.region_map._begin_drag(origin)
		screen.region_map._drag_map(origin + Vector2(64, -32))
		screen.region_map._finish_drag(origin + Vector2(64, -32))
		await _hover(screen, _module_point(screen, Vector2(0.362, 0.468)))
		assert_eq(screen.region_map._hovered_region_id, "varenhold")
	assert_signal_not_emitted(screen, "back_requested")
	assert_signal_not_emitted(screen.region_map, "region_selected")


func test_locked_expedition_cannot_return_to_city_or_select_the_valley() -> void:
	var screen = await _mount(Vector2i(1600, 900), true)
	await _click(screen, _module_point(screen, Vector2(0.362, 0.468)))
	assert_eq(screen.region_map._hovered_region_id, "")
	await _click(screen, _module_point(screen, Vector2(0.64, 0.22)))
	assert_eq(screen.region_map._hovered_region_id, "")
	assert_signal_not_emitted(screen, "back_requested")
	assert_signal_not_emitted(screen.region_map, "city_selected")


func test_cpu_coverage_uses_the_same_key_and_east_fade_as_the_shader() -> void:
	assert_eq(Layout.coverage(Color.WHITE, Vector2(0.5, 0.5)), 0.0)
	assert_eq(Layout.coverage(Color(0.93, 0.93, 0.93), Vector2(0.5, 0.5)), 0.0)
	assert_eq(Layout.coverage(Color(0.3, 0.25, 0.12, 0.0), Vector2(0.5, 0.5)), 0.0)
	var earth := Color(0.3, 0.25, 0.12)
	assert_eq(Layout.coverage(earth, Vector2(0.5, 0.5)), 1.0)
	assert_almost_eq(Layout.coverage(earth, Vector2(0.86, 0.5)), 0.5, 0.001)
	assert_eq(Layout.coverage(earth, Vector2(0.95, 0.5)), 0.0)
	assert_true(Layout.is_city(Vector2(0.362, 0.468)))
	assert_false(Layout.is_city(Vector2(0.64, 0.22)))
	assert_false(Layout.is_city(Vector2(0.35, 0.68)))


func test_real_app_routes_map_city_click_back_to_city_hub_without_changing_session() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1600, 900)
	add_child_autofree(viewport)
	var app = load("res://scenes/app/app.tscn").instantiate()
	viewport.add_child(app)
	viewport.notify_mouse_entered()
	var session = NewGame.new().create_session("Aria", 1)
	session.prologue_completed = true
	app._current_session = session
	app._show_world_map()
	await wait_process_frames(3)
	var map = app.screen_host.get_child(0)
	var location_before: String = session.current_location_id
	var time_before: String = session.formatted_time()
	await _click(map, _module_point(map, Vector2(0.362, 0.468)))
	assert_eq(
		app.screen_host.get_child(0).get_script(), load("res://ui/screens/city_hub/city_hub.gd")
	)
	assert_same(app._current_session, session)
	assert_eq(session.current_location_id, location_before)
	assert_eq(session.formatted_time(), time_before)
	assert_eq(session.known_region_ids.size(), 5)
