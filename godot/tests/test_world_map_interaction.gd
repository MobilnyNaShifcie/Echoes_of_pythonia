extends GutTest

const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const WorldMapScreenClass := preload("res://ui/screens/world_map/world_map.gd")
const WORLD_MAP_SCENE := preload("res://ui/screens/world_map/world_map.tscn")


func test_map_replaces_the_visible_region_list_and_selects_regions() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var screen := WORLD_MAP_SCENE.instantiate() as WorldMapScreenClass
	screen.configure(session)
	add_child_autofree(screen)
	await get_tree().process_frame

	assert_false(screen.region_list.is_visible_in_tree())
	assert_true(screen.region_map.is_visible_in_tree())
	screen.region_map.region_selected.emit("ice_coast")
	assert_eq(screen.title_label.text, "Lodowe Wybrzeże")
	assert_string_contains(screen.risk_label.text, "14–18")


func test_each_region_owns_an_independent_map_hotspot() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var screen := WORLD_MAP_SCENE.instantiate() as WorldMapScreenClass
	screen.configure(session)
	add_child_autofree(screen)
	await get_tree().process_frame

	var sample_points := {
		"twilight_plains": Vector2(940.0, 780.0),
		"black_forest": Vector2(1194.0, 569.0),
		"silentwater_marshes": Vector2(1694.0, 529.0),
		"ashen_borderlands": Vector2(1264.0, 899.0),
		"ice_coast": Vector2(1844.0, 819.0),
	}
	var map_scale: float = screen.region_map._map_scale()
	var map_offset: Vector2 = screen.region_map._map_offset(map_scale)
	for region_id in sample_points:
		var local_point: Vector2 = map_offset + sample_points[region_id] * map_scale
		assert_eq(screen.region_map._region_at(local_point), region_id)
	var varenhold_point := (
		map_offset + WorldRegionMap.ValleyLayout.city_reference_position() * map_scale
	)
	assert_eq(screen.region_map._region_at(varenhold_point), WorldRegionMap.VARENHOLD_ID)


func test_region_interaction_uses_one_invisible_id_texture() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var screen := WORLD_MAP_SCENE.instantiate() as WorldMapScreenClass
	screen.configure(session)
	add_child_autofree(screen)
	await get_tree().process_frame

	assert_not_null(screen.region_map._region_id_image)
	assert_eq(screen.region_map._region_id_image.get_size(), Vector2i(2560, 1440))
	var module: TextureRect = screen.get_node("%VarenholdModule")
	assert_eq(module.texture.get_size(), Vector2(1254, 1254))
	assert_eq(module.material.get_shader_parameter("region_ids"), WorldRegionMap.REGION_ID_TEXTURE)
	assert_eq(screen.region_map.tooltip_text, "")

	var map_scale: float = screen.region_map._map_scale()
	var ocean_point := screen.region_map._map_offset(map_scale) + Vector2(40.0, 40.0) * map_scale
	assert_eq(screen.region_map._region_at(ocean_point), "")
	assert_false(screen.has_node("Page/Body/MapLayer/RegionHighlight"))


func test_map_fills_the_screen_and_uses_only_a_compact_bottom_summary() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var screen := WORLD_MAP_SCENE.instantiate() as WorldMapScreenClass
	screen.configure(session)
	add_child_autofree(screen)
	await get_tree().process_frame

	var body := screen.get_node("Page/Body") as Control
	var map_layer := screen.get_node("Page/Body/MapLayer") as Control
	var map_texture := screen.get_node("Page/Body/MapLayer/MapTexture") as TextureRect
	var varenhold_module := screen.get_node("Page/Body/MapLayer/VarenholdModule") as TextureRect
	var top_info := screen.get_node("Page/Body/OverlayLayer/TopInfo") as Control
	var info_bar := screen.get_node("Page/Body/OverlayLayer/CompactInfoBar") as Control
	assert_eq(map_layer.size.x, body.size.x + 128.0)
	assert_eq(map_layer.size.y, body.size.y)
	assert_true(map_layer.clip_contents)
	assert_false(screen.has_node("Page/Body/MapLayer/OceanBackground"))
	assert_true(map_texture.material is ShaderMaterial)
	assert_eq(map_texture.texture.get_size(), Vector2(2560.0, 1440.0))
	assert_true(varenhold_module.material is ShaderMaterial)
	assert_eq(varenhold_module.texture.get_size(), Vector2(1254.0, 1254.0))
	assert_eq(top_info.position.x, 32.0)
	assert_false(screen.has_node("Page/Body/MapLayer/RegionMap/TwilightPlate"))
	assert_false(screen.has_node("Page/Body/MapLayer/RegionMap/BlackForestPlate"))
	assert_false(screen.has_node("Page/Body/MapLayer/RegionMap/MarshesPlate"))
	assert_false(screen.has_node("Page/Body/MapLayer/RegionMap/AshenPlate"))
	assert_false(screen.has_node("Page/Body/MapLayer/RegionMap/IceCoastPlate"))
	assert_false(screen.has_node("Page/Body/MapPanel"))
	assert_false(screen.has_node("Page/Body/OverlayLayer/TopShade"))
	assert_lte(info_bar.size.y, 70.0)
	assert_eq(screen.description_label.max_lines_visible, 1)


func test_map_can_be_dragged_without_desynchronizing_hotspots() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var screen := WORLD_MAP_SCENE.instantiate() as WorldMapScreenClass
	screen.configure(session)
	add_child_autofree(screen)
	await get_tree().process_frame

	var map_texture := screen.get_node("Page/Body/MapLayer/MapTexture") as TextureRect
	var initial_texture_position := map_texture.position
	var drag_origin := screen.region_map.size * 0.5
	screen.region_map._begin_drag(drag_origin)
	screen.region_map._drag_map(drag_origin + Vector2(80.0, 40.0))
	screen.region_map._finish_drag(drag_origin + Vector2(80.0, 40.0))

	assert_ne(map_texture.position, initial_texture_position)
	var map_scale: float = screen.region_map._map_scale()
	var local_point := screen.region_map._map_offset(map_scale) + Vector2(1194.0, 569.0) * map_scale
	assert_eq(screen.region_map._region_at(local_point), "black_forest")


func test_hover_highlight_uses_exact_region_id_and_varenhold_module() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var screen := WORLD_MAP_SCENE.instantiate() as WorldMapScreenClass
	screen.configure(session)
	add_child_autofree(screen)
	await get_tree().process_frame

	var map_texture := screen.get_node("Page/Body/MapLayer/MapTexture") as TextureRect
	var varenhold_module := screen.get_node("Page/Body/MapLayer/VarenholdModule") as TextureRect
	var region_material := map_texture.material as ShaderMaterial
	var city_material := varenhold_module.material as ShaderMaterial
	screen.region_map._set_hovered_region("black_forest")
	assert_eq(roundi(float(region_material.get_shader_parameter("hover_code"))), 102)
	assert_gt(float(region_material.get_shader_parameter("hover_strength")), 0.0)
	assert_eq(roundi(float(city_material.get_shader_parameter("hover_code"))), 102)
	assert_eq(
		city_material.get_shader_parameter("region_ids"),
		region_material.get_shader_parameter("region_ids")
	)

	screen.region_map._set_hovered_region(WorldRegionMap.VARENHOLD_ID)
	assert_lt(float(region_material.get_shader_parameter("hover_code")), 0.0)
	assert_eq(float(region_material.get_shader_parameter("hover_strength")), 0.0)
	assert_gt(float(city_material.get_shader_parameter("city_hover_strength")), 0.0)
	assert_eq(float(city_material.get_shader_parameter("hover_strength")), 0.0)


func test_varenhold_module_emits_city_navigation_without_becoming_a_combat_region() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var screen := WORLD_MAP_SCENE.instantiate() as WorldMapScreenClass
	screen.configure(session)
	add_child_autofree(screen)
	await get_tree().process_frame
	watch_signals(screen.region_map)

	var map_scale: float = screen.region_map._map_scale()
	var local_point := (
		screen.region_map._map_offset(map_scale)
		+ WorldRegionMap.ValleyLayout.city_reference_position() * map_scale
	)
	screen.region_map._begin_drag(local_point)
	screen.region_map._finish_drag(local_point)
	assert_signal_emitted_with_parameters(
		screen.region_map, "city_selected", [WorldRegionMap.VARENHOLD_ID]
	)
	assert_false(session.known_region_ids.has(WorldRegionMap.VARENHOLD_ID))
