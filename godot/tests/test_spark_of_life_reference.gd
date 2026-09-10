extends GutTest

const ModelView = preload("res://ui/screens/black_market/market_item_3d.gd")
const Builder = preload("res://ui/screens/black_market/spark_of_life_reference_model.gd")
const Market = preload("res://ui/screens/black_market/black_market.tscn")
const NewGame = preload("res://core/game/new_game_service.gd")
const Offer = preload("res://core/economy/black_market_offer.gd")


func test_original_icon_is_mapped_to_closed_core_leaves_stem_and_veins() -> void:
	var view = ModelView.new()
	add_child_autofree(view)
	view.build("spark_of_life")
	assert_not_null(view.model.get_node("LivingCrystal"))
	assert_not_null(view.model.get_node("LeftBronzeLeaf"))
	assert_not_null(view.model.get_node("RightBronzeLeaf"))
	assert_not_null(view.model.get_node("TwistedStem"))
	assert_eq(view.model.get_child_count(), 20, "19 solid meshes and the contact shadow")
	for node: MeshInstance3D in view.model.get_children():
		if node.name == "ContactShadow":
			continue
		assert_true(node.mesh is ArrayMesh)
		var arrays := node.mesh.surface_get_arrays(0)
		assert_gt(node.get_aabb().size.z, 0.005)
		assert_eq(arrays[Mesh.ARRAY_VERTEX].size(), arrays[Mesh.ARRAY_TEX_UV].size())
		assert_true(_is_closed(arrays), str(node.name) + " is closed, including its reverse")
		var mat: StandardMaterial3D = node.material_override
		assert_same(mat.albedo_texture, Builder.ART)
		assert_eq(mat.transparency, BaseMaterial3D.TRANSPARENCY_DISABLED)
		var vertices = arrays[Mesh.ARRAY_VERTEX].duplicate()
		var texcoords = arrays[Mesh.ARRAY_TEX_UV].duplicate()
		view.model.rotation_degrees.y = 35
		assert_eq(node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX], vertices)
		assert_eq(node.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV], texcoords)
		view.model.rotation_degrees.y = 0
	var core: MeshInstance3D = view.model.get_node("LivingCrystal")
	assert_gt(core.get_aabb().size.z, 0.30)
	assert_gt(core.material_override.emission_energy_multiplier, view.model.get_node("LeftBronzeLeaf").material_override.emission_energy_multiplier)
	view.highlight(true)
	view.build("spark_of_life")
	assert_same(view.model.get_node("LivingCrystal"), core)


func test_spark_lies_on_counter_without_clipping() -> void:
	var view = ModelView.new()
	add_child_autofree(view)
	view.size = Vector2(640, 480)
	await get_tree().process_frame
	view.build("grandmaster_elixir")
	var height := _projected_rect(view).size.y
	view.build("spark_of_life")
	var minimum_y := INF
	for node: MeshInstance3D in view.model.get_children():
		if node.name != "ContactShadow":
			minimum_y = minf(minimum_y, node.get_aabb().position.y + node.position.y)
	assert_almost_eq(minimum_y, 0.018, 0.0001)
	assert_almost_eq(view.model.get_node("ContactShadow").position.y, 0.004, 0.0001)
	assert_lt(_projected_rect(view).size.y / height, 0.8, "The unbased crystal lies on its side")
	assert_gt(_projected_rect(view).size.y / height, 0.2)
	for turn in [0, 35, -35]:
		view.model.rotation_degrees.y = turn
		assert_true(Rect2(Vector2.ZERO, view.size).encloses(_projected_rect(view)))


func test_curved_body_tapers_at_organic_outline() -> void:
	var view = ModelView.new()
	add_child_autofree(view)
	var builder = Builder.new()
	builder.build(view)
	assert_eq(builder.art_size, Builder.ART.get_size())
	for pixel: Vector2 in builder.silhouette:
		assert_almost_eq(builder._volume_depth(pixel), 3.0, 0.001)
	assert_gt(builder._volume_depth(Vector2(670, 620)), 150.0)


func test_crystal_overlaps_leaf_lips_instead_of_leaving_dark_seams() -> void:
	var view = ModelView.new()
	add_child_autofree(view)
	var builder = Builder.new()
	builder.build(view)
	for pixel: Vector2 in [Vector2(641, 227), Vector2(597, 252), Vector2(524, 322), Vector2(480, 412), Vector2(470, 462), Vector2(589, 961), Vector2(673, 871), Vector2(810, 753), Vector2(948, 575), Vector2(524, 1030)]:
		assert_true(Geometry2D.is_point_in_polygon(pixel, builder.core_outline), "Crystal extends under the metal lip at " + str(pixel))


func test_live_drag_cancel_and_purchase_preserve_identity_and_price() -> void:
	var market = _market(200000)
	await get_tree().process_frame
	var slot = market.offer_slots[0]
	var view = slot.model_view
	var world = view.model
	assert_same(slot._item_texture, Builder.ART)
	assert_almost_eq(view.size.x / slot.size.x, 1.5, 0.01)
	var size_before: Vector2 = view.size
	var data = slot._get_drag_data(Vector2(70, 35))
	assert_eq(data.item_id, "spark_of_life")
	assert_same(view.model, world)
	assert_false(view.get_parent() == slot)
	assert_same(slot.price_sign.get_parent(), slot)
	assert_eq(view.size, size_before)
	assert_false(world.get_node("ContactShadow").visible)
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(960, 340)
	slot._input(motion)
	slot._process(0.0)
	assert_eq(view.position, motion.position + slot._grab_offset)
	slot.notification(Control.NOTIFICATION_DRAG_END)
	await get_tree().process_frame
	assert_same(view.get_parent(), slot)
	assert_true(world.get_node("ContactShadow").visible)
	var camera: Camera3D = view.viewport_3d.get_camera_3d()
	assert_lt((view.position + camera.unproject_position(Vector3(0, 0.035, 0))).distance_to(slot._counter_anchor), 0.1)
	assert_eq(market._session.player.gold, 200000)
	slot._get_drag_data(Vector2(70, 35))
	market.inventory_drop_target._drop_data(Vector2.ZERO, data)
	slot.notification(Control.NOTIFICATION_DRAG_END)
	assert_eq(market._session.player.gold, 191500)
	assert_eq(market._session.player.inventory.count("spark_of_life"), 1)
	assert_false(view.visible)
	assert_eq(world.get_child_count(), 0)


func test_failed_purchase_restores_spark_without_duplicate_or_charge() -> void:
	var market = _market(0)
	await get_tree().process_frame
	var slot = market.offer_slots[0]
	var world = slot.model_view.model
	var data = slot._get_drag_data(Vector2(70, 35))
	market.inventory_drop_target._drop_data(Vector2.ZERO, data)
	slot.notification(Control.NOTIFICATION_DRAG_END)
	assert_same(slot.model_view.model, world)
	assert_same(slot.model_view.get_parent(), slot)
	assert_true(slot.model_view.visible)
	assert_true(world.get_node("ContactShadow").visible)
	assert_eq(market._session.player.gold, 0)
	assert_eq(market._session.player.inventory.count("spark_of_life"), 0)


func _market(gold: int):
	var session = NewGame.new().create_session("Aria", 1)
	session.black_market.unlocked = true
	session.black_market.rotation_key = "2026-09-06"
	session.black_market.offers = [Offer.new("2026-09-06:0", "spark_of_life", 1, 8500)]
	session.player.gold = gold
	var market = Market.instantiate()
	add_child_autofree(market)
	market.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	market.size = Vector2(1920, 1080)
	market.configure(session, "2026-09-06")
	return market


func _projected_rect(view) -> Rect2:
	var camera: Camera3D = view.viewport_3d.get_camera_3d()
	var minimum := Vector2(INF, INF)
	var maximum := Vector2(-INF, -INF)
	for node: MeshInstance3D in view.model.get_children():
		if node.name == "ContactShadow":
			continue
		for vertex: Vector3 in node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			var pixel := camera.unproject_position(node.global_transform * vertex)
			minimum = minimum.min(pixel)
			maximum = maximum.max(pixel)
	return Rect2(minimum, maximum - minimum)


func _is_closed(arrays: Array) -> bool:
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var edges := {}
	for triangle in range(0, indices.size(), 3):
		for side in 3:
			var a := Vector3i((vertices[indices[triangle + side]] * 100000.0).round())
			var b := Vector3i((vertices[indices[triangle + (side + 1) % 3]] * 100000.0).round())
			var key := str(a) + ":" + str(b) if str(a) < str(b) else str(b) + ":" + str(a)
			edges[key] = edges.get(key, 0) + 1
	for count in edges.values():
		if count != 2:
			return false
	return not edges.is_empty()
