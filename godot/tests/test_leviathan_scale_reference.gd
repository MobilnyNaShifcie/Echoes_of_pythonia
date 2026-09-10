extends GutTest

const ModelView = preload("res://ui/screens/black_market/market_item_3d.gd")
const Builder = preload("res://ui/screens/black_market/leviathan_scale_reference_model.gd")
const Market = preload("res://ui/screens/black_market/black_market.tscn")
const NewGame = preload("res://core/game/new_game_service.gd")
const Offer = preload("res://core/economy/black_market_offer.gd")


func test_scale_has_closed_textured_shell_ribs_and_separate_metal_collar() -> void:
	var view = ModelView.new()
	add_child_autofree(view)
	view.build("leviathan_scale")
	for part in ["IridescentShell", "GrowthRib0", "GrowthRib1", "GrowthRib2", "ArmoredRim", "WeatheredCollar", "CollarBevel0", "CollarBevel1", "CollarBevel2"]:
		var node: MeshInstance3D = view.model.get_node(part)
		assert_true(node.mesh is ArrayMesh)
		var arrays := node.mesh.surface_get_arrays(0)
		assert_eq(arrays[Mesh.ARRAY_VERTEX].size(), arrays[Mesh.ARRAY_TEX_UV].size())
		assert_gt(node.get_aabb().size.z, 0.01, part + " has actual depth")
		var mat: StandardMaterial3D = node.material_override
		assert_same(mat.albedo_texture, Builder.ART)
		assert_eq(mat.transparency, BaseMaterial3D.TRANSPARENCY_DISABLED)
		assert_true(_is_closed(arrays), part + " has no open mesh boundary")
		var vertices = arrays[Mesh.ARRAY_VERTEX].duplicate()
		var uvs = arrays[Mesh.ARRAY_TEX_UV].duplicate()
		view.model.rotation_degrees.y = 45
		assert_eq(node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX], vertices)
		assert_eq(node.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV], uvs)
		view.model.rotation_degrees.y = 0
	assert_gt(view.model.get_node("IridescentShell").get_aabb().size.z, 0.30)
	var original_shell = view.model.get_node("IridescentShell")
	view.highlight(true)
	view.build("leviathan_scale")
	assert_same(view.model.get_node("IridescentShell"), original_shell, "Hover never rebuilds the model")


func test_scale_curves_inward_towards_a_narrow_edge() -> void:
	var view = ModelView.new()
	add_child_autofree(view)
	var builder = Builder.new()
	builder.build(view)
	assert_eq(builder.art_size, Builder.ART.get_size())
	for pixel: Vector2 in builder.shell_outline:
		assert_almost_eq(builder._shell_depth(pixel), 3.0, 0.001)
	assert_gt(builder._shell_depth(Vector2(630, 570)), 150.0)
	assert_lt(builder._rear_depth(Vector2(630, 570)), -60.0)


func test_scale_lies_on_counter_and_fits_in_viewport() -> void:
	var view = ModelView.new()
	add_child_autofree(view)
	view.size = Vector2(640, 480)
	await get_tree().process_frame
	view.build("grandmaster_elixir")
	var elixir := _projected_rect(view)
	view.build("leviathan_scale")
	var minimum_y := INF
	for node: MeshInstance3D in view.model.get_children():
		if node.name != "ContactShadow":
			minimum_y = minf(minimum_y, node.get_aabb().position.y + node.position.y)
	assert_almost_eq(minimum_y, 0.018, 0.0001)
	assert_almost_eq(view.model.get_node("ContactShadow").position.y, 0.004, 0.0001)
	var scale_rect := _projected_rect(view)
	assert_lt(scale_rect.size.y / elixir.size.y, 0.8, "A lying scale is lower than an upright bottle")
	assert_gt(scale_rect.size.y / elixir.size.y, 0.2, "Lying does not shrink the item into an unreadable speck")
	for turn in [0, 35, -35]:
		view.model.rotation_degrees.y = turn
		assert_true(Rect2(Vector2.ZERO, view.size).encloses(_projected_rect(view)), "Entire shell remains in frame at %d degrees" % turn)


func test_scale_live_drag_cancel_and_purchase_keep_original_item_and_price() -> void:
	var market = _market(200000)
	await get_tree().process_frame
	var slot = market.offer_slots[0]
	var view = slot.model_view
	var world = view.model
	var size_before: Vector2 = view.size
	assert_almost_eq(view.size.x / slot.size.x, 1.5, 0.01)
	assert_same(slot._item_texture, Builder.ART)
	var data = slot._get_drag_data(Vector2(70, 35))
	assert_eq(data.item_id, "leviathan_scale")
	assert_same(view.model, world)
	assert_false(view.get_parent() == slot)
	assert_same(slot.price_sign.get_parent(), slot)
	assert_eq(view.size, size_before)
	assert_false(world.get_node("ContactShadow").visible)
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(950, 350)
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
	assert_eq(market._session.player.gold, 187000)
	assert_eq(market._session.player.inventory.count("leviathan_scale"), 1)
	assert_false(view.visible)
	assert_eq(world.get_child_count(), 0)


func test_failed_scale_purchase_returns_same_model_and_does_not_charge() -> void:
	var market = _market(0)
	await get_tree().process_frame
	var slot = market.offer_slots[0]
	var world = slot.model_view.model
	var data = slot._get_drag_data(Vector2(70, 35))
	market.inventory_drop_target._drop_data(Vector2.ZERO, data)
	slot.notification(Control.NOTIFICATION_DRAG_END)
	assert_same(slot.model_view.model, world)
	assert_true(slot.model_view.visible)
	assert_same(slot.model_view.get_parent(), slot)
	assert_true(world.get_node("ContactShadow").visible)
	assert_eq(market._session.player.gold, 0)
	assert_eq(market._session.player.inventory.count("leviathan_scale"), 0)


func _market(gold: int):
	var session = NewGame.new().create_session("Aria", 1)
	session.black_market.unlocked = true
	session.black_market.rotation_key = "2026-09-06"
	session.black_market.offers = [Offer.new("2026-09-06:0", "leviathan_scale", 1, 13000)]
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
	for child: MeshInstance3D in view.model.get_children():
		if child.name == "ContactShadow":
			continue
		for vertex: Vector3 in child.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			var pixel := camera.unproject_position(child.global_transform * vertex)
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
