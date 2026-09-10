extends GutTest

const SCENE := preload("res://ui/screens/world_map/world_map.tscn")
const NewGame := preload("res://core/game/new_game_service.gd")
const ATLAS := preload("res://assets/world_map/pythonia_region_atlas_v2.png")


func _mount() -> Control:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	add_child_autofree(viewport)
	var screen = SCENE.instantiate()
	screen.configure(NewGame.new().create_session("Aria", 1))
	viewport.add_child(screen)
	await wait_process_frames(3)
	return screen


func test_both_art_layers_use_the_same_unfiltered_region_data() -> void:
	var screen = await _mount()
	var base: TextureRect = screen.get_node("Page/Body/MapLayer/MapTexture")
	var module: TextureRect = screen.get_node("%VarenholdModule")
	assert_eq(base.material.get_shader_parameter("region_ids"), ATLAS)
	assert_eq(module.material.get_shader_parameter("region_ids"), ATLAS)
	for region: String in WorldRegionMap.REGION_ID_CODES:
		screen.region_map._set_hovered_region(region)
		for layer: TextureRect in [base, module]:
			assert_eq(
				roundi(float(layer.material.get_shader_parameter("hover_code"))),
				WorldRegionMap.REGION_ID_CODES[region]
			)
			assert_almost_eq(
				float(layer.material.get_shader_parameter("hover_strength")), 0.42, 0.001
			)
	var uv_rect: Vector4 = module.material.get_shader_parameter("world_rect_uv")
	assert_almost_eq(uv_rect.x * 2560.0, 100.0, 0.001)
	assert_almost_eq(uv_rect.y * 1440.0, 350.0, 0.001)
	assert_almost_eq(uv_rect.z * 2560.0, 850.0, 0.001)
	assert_almost_eq(uv_rect.w * 1440.0, 850.0, 0.001)


func test_picking_matches_the_full_atlas_after_resize_and_pan() -> void:
	var screen = await _mount()
	var atlas := ATLAS.get_image()
	var names := {0: ""}
	for region: String in WorldRegionMap.REGION_ID_CODES:
		names[WorldRegionMap.REGION_ID_CODES[region]] = region
	for resolution: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1080)]:
		screen.get_viewport().size = resolution
		await wait_process_frames(3)
		screen.region_map._pan_offset = screen.region_map._clamp_pan(Vector2(50, -30))
		screen.region_map._sync_view()
		var base: TextureRect = screen.get_node("Page/Body/MapLayer/MapTexture")
		var failures: Array[String] = []
		for y in range(4, 1440, 16):
			for x in range(4, 2560, 16):
				var reference := Vector2(x + 0.5, y + 0.5)
				var expected: String = names[roundi(atlas.get_pixel(x, y).r * 255.0)]
				if expected == "varenhold_valley":
					var uv := (reference - Vector2(100, 350)) / Vector2(850, 850)
					if WorldRegionMap.ValleyLayout.is_city(uv):
						expected = "varenhold"
				var local := base.position + reference / Vector2(2560, 1440) * base.size
				if screen.region_map._region_at(local) != expected and failures.size() < 5:
					failures.append(str(reference) + ": " + expected)
		assert_eq(failures, [] as Array[String], "Atlas/picking at " + str(resolution))


func test_valley_boundary_is_drawn_at_every_shared_plains_edge() -> void:
	var image := ATLAS.get_image()
	var shared_count := 0
	var missing_count := 0
	for y in range(350, 1200):
		for x in range(600, 949):
			var current := image.get_pixel(x, y)
			var code := roundi(current.r * 255.0)
			if code != 26 and code != 51:
				continue
			for delta: Vector2i in [Vector2i.RIGHT, Vector2i.DOWN]:
				var next := image.get_pixel(x + delta.x, y + delta.y)
				var next_code := roundi(next.r * 255.0)
				if (code == 26 and next_code == 51) or (code == 51 and next_code == 26):
					shared_count += 1
					if maxf(current.b, next.b) < 0.1:
						missing_count += 1
	assert_gt(shared_count, 400)
	assert_eq(missing_count, 0, "Every shared edge has the matching visible gold seam")


func test_border_overlay_tracks_the_art_and_never_blocks_mouse() -> void:
	var screen = await _mount()
	var base: TextureRect = screen.get_node("Page/Body/MapLayer/MapTexture")
	var border: TextureRect = screen.get_node("Page/Body/MapLayer/RegionBorders")
	assert_eq(border.texture, ATLAS)
	assert_eq(border.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	for resolution: Vector2i in [Vector2i(1600, 900), Vector2i(2560, 1080)]:
		screen.get_viewport().size = resolution
		await wait_process_frames(3)
		screen.region_map._pan_offset = screen.region_map._clamp_pan(Vector2(-40, 30))
		screen.region_map._sync_view()
		assert_eq(border.position, base.position)
		assert_eq(border.size, base.size)
