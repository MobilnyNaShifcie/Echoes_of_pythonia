extends GutTest

const ModelView = preload("res://ui/screens/black_market/market_item_3d.gd")


func test_rotation_goods_use_geometry_and_clear_without_orphans() -> void:
	var view = ModelView.new()
	add_child_autofree(view)
	for item_id in [
		"common_essence",
		"spark_of_life",
		"grandmaster_elixir",
		"black_pearl",
		"hearth_core",
		"leviathan_scale",
		"azhar_sigil",
		"mastery_book",
		"mastery_attack_speed_book"
	]:
		view.build(item_id)
		assert_gt(view.model.get_child_count(), 2, item_id)
		for child in view.model.get_children():
			assert_true(child is MeshInstance3D, item_id + " uses real meshes")
			assert_not_null(child.mesh)
		var first_mesh = view.model.get_child(0)
		view.build(item_id)
		assert_same(view.model.get_child(0), first_mesh, "Hover refresh keeps existing geometry")
		view.build("")
		assert_eq(view.model.get_child_count(), 0, "Sold item leaves no geometry")
	assert_true(view.viewport_3d.transparent_bg)
	assert_true(view.key_light.shadow_enabled)


func test_reference_elixir_is_textured_volume_not_billboard() -> void:
	var view = ModelView.new()
	add_child_autofree(view)
	view.build("grandmaster_elixir")
	for part_name in ["OctagonalFoot", "FacetedVessel", "LeatherCollarAndLip", "WaxSealedCork"]:
		var mesh: MeshInstance3D = view.model.get_node(part_name)
		assert_gt(mesh.get_aabb().size.z, 0.15, part_name + " has depth")
		var arrays := mesh.mesh.surface_get_arrays(0)
		assert_eq(arrays[Mesh.ARRAY_TEX_UV].size(), arrays[Mesh.ARRAY_VERTEX].size())
		var material: StandardMaterial3D = mesh.material_override
		assert_string_contains(material.albedo_texture.resource_path, "grandmaster_elixir.png")
	var body: MeshInstance3D = view.model.get_node("FacetedVessel")
	var original_vertices: PackedVector3Array = body.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	view.model.rotation_degrees.y = 35
	assert_eq(
		body.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX],
		original_vertices,
		"Rotation never rebuilds a camera-facing plane"
	)


func test_reference_pearl_has_solid_iridescent_body_and_separate_carved_gold() -> void:
	var view = ModelView.new()
	add_child_autofree(view)
	view.build("black_pearl")
	for part in [
		"IridescentPearl",
		"EngravedGoldCradle",
		"LeftRearClaw",
		"LeftSweptClaw",
		"RightCrownClaw",
		"RightSweptClaw",
		"LowerGoldBead",
		"CarvedRimRelief",
		"LeftClawBevel"
	]:
		var node: MeshInstance3D = view.model.get_node(part)
		assert_true(node.mesh is ArrayMesh, part + " is authored geometry")
		var arrays := node.mesh.surface_get_arrays(0)
		assert_gt(arrays[Mesh.ARRAY_VERTEX].size(), 40)
		assert_eq(arrays[Mesh.ARRAY_TEX_UV].size(), arrays[Mesh.ARRAY_VERTEX].size())
		assert_string_contains(
			node.material_override.albedo_texture.resource_path, "black_pearl.png"
		)
		assert_gt(node.get_aabb().size.z, 0.08, "Separate curved fitting has physical depth")
	var pearl: MeshInstance3D = view.model.get_node("IridescentPearl")
	assert_gt(pearl.get_aabb().size.z, 1.1, "The pearl is a closed rounded volume")
	var vertices = pearl.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var uvs = pearl.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
	view.model.rotation_degrees.y = 35
	assert_eq(pearl.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX], vertices)
	assert_eq(
		pearl.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV],
		uvs,
		"Artwork stays fixed on geometry during rotation"
	)
	assert_true(view.model.get_node("ContactShadow") is MeshInstance3D)


func test_pearl_and_elixir_have_matching_reference_height() -> void:
	var view = ModelView.new()
	add_child_autofree(view)
	view.size = Vector2(640, 480)
	await get_tree().process_frame
	view.build("grandmaster_elixir")
	var elixir := _projected_model_rect(view)
	view.build("black_pearl")
	var pearl := _projected_model_rect(view)
	assert_almost_eq(
		pearl.size.y / elixir.size.y,
		1.0,
		0.05,
		"Same reference height, with the pearl's own round proportions"
	)


func test_manuscript_is_layered_volume_with_original_art_and_raised_fittings() -> void:
	var view = ModelView.new()
	add_child_autofree(view)
	view.build("mastery_attack_speed_book")
	for part in [
		"EmbossedLeatherCover",
		"BackLeatherCover",
		"LayeredParchmentBlock",
		"RoundedLeatherSpine",
		"SilverCorner0",
		"SilverCorner1",
		"SilverCorner2",
		"SilverCorner3",
		"SwiftBladeRelief0",
		"SwiftBladeRelief1",
		"SwiftBladeRelief2",
		"LeatherClasp",
		"SilverBuckle",
		"ClaspDiamond",
		"CrimsonRibbon",
		"RaisedSpineBand0",
		"SpineSilverStud0",
		"ParchmentEdge00"
	]:
		var node: MeshInstance3D = view.model.get_node(part)
		assert_true(node.mesh is ArrayMesh, part + " is solid authored geometry")
		var arrays := node.mesh.surface_get_arrays(0)
		assert_eq(arrays[Mesh.ARRAY_TEX_UV].size(), arrays[Mesh.ARRAY_VERTEX].size())
		assert_gt(node.get_aabb().size.z, 0.001, part + " has depth")
		assert_string_contains(
			node.material_override.albedo_texture.resource_path, "mastery_attack_speed_book.png"
		)
	assert_gt(view.model.get_node("LayeredParchmentBlock").get_aabb().size.z, 0.15)
	var cover: MeshInstance3D = view.model.get_node("EmbossedLeatherCover")
	var vertices = cover.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var uvs = cover.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
	view.model.rotation_degrees.y = 35
	assert_eq(cover.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX], vertices)
	assert_eq(
		cover.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV],
		uvs,
		"No camera-facing reconstruction on rotation"
	)


func test_manuscript_lies_flat_on_the_counter_and_fits_viewport() -> void:
	var view = ModelView.new()
	add_child_autofree(view)
	view.size = Vector2(640, 480)
	await get_tree().process_frame
	view.build("grandmaster_elixir")
	var elixir := _projected_model_rect(view)
	view.build("mastery_attack_speed_book")
	var book := _projected_model_rect(view)
	assert_lt(
		book.size.y / elixir.size.y,
		0.70,
		"A lying book is foreshortened, not standing upright like the bottle"
	)
	assert_true(
		Rect2(Vector2.ZERO, view.size).encloses(book), "Ribbon and all corners remain in frame"
	)
	var cover: MeshInstance3D = view.model.get_node("EmbossedLeatherCover")
	assert_lt(cover.get_aabb().size.y, 0.05, "Both faces of the cover are parallel to the tabletop")
	var back: MeshInstance3D = view.model.get_node("BackLeatherCover")
	assert_almost_eq(
		back.get_aabb().position.y,
		0.018,
		0.001,
		"The broad lower cover rests directly above the mat"
	)
	var minimum := Vector3(INF, INF, INF)
	var maximum := Vector3(-INF, -INF, -INF)
	for child: MeshInstance3D in view.model.get_children():
		if child.name == "ContactShadow":
			continue
		var bounds := child.get_aabb()
		minimum = minimum.min(bounds.position)
		maximum = maximum.max(bounds.end)
	assert_gte(minimum.y, 0.011, "Neither binding nor bookmark intersects the tabletop")
	assert_lt(
		maximum.y - minimum.y, 0.40, "The complete book lies down, not just its cover texture"
	)
	assert_gt(maximum.z - minimum.z, 1.0, "The book now occupies depth on the leather mat")
	assert_almost_eq(view.model.get_node("ContactShadow").position.y, 0.004, 0.001)
	var arrays := cover.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var upper_normal := Vector3.ZERO
	var upper_count := 0
	for i in vertices.size():
		if absf(vertices[i].y - cover.get_aabb().end.y) < 0.001:
			upper_normal += normals[i]
			upper_count += 1
	assert_gt(upper_count, 0)
	assert_gt(
		upper_normal.normalized().y,
		0.8,
		"The upper cover faces the camera/light instead of exposing its underside"
	)


func _projected_model_rect(view) -> Rect2:
	var camera: Camera3D = view.viewport_3d.get_camera_3d()
	var minimum := Vector2(INF, INF)
	var maximum := Vector2(-INF, -INF)
	for child: MeshInstance3D in view.model.get_children():
		if child.name == "ContactShadow":
			continue
		var vertices: PackedVector3Array = child.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for vertex in vertices:
			var pixel := camera.unproject_position(child.global_transform * vertex)
			minimum = minimum.min(pixel)
			maximum = maximum.max(pixel)
	return Rect2(minimum, maximum - minimum)
