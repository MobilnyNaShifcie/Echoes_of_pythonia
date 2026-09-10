extends GutTest

const ModelView = preload("res://ui/screens/black_market/market_item_3d.gd")
const Market = preload("res://ui/screens/black_market/black_market.tscn")
const NewGame = preload("res://core/game/new_game_service.gd")
const PARTS := {
	"hearth_core": ["ObsidianBody","BoneBinding0","BoneBinding1","MoltenWindow0","MoltenWindow1","PendantSuspension","PendantChain0","SunCharm","CharmAmber"],
	"azhar_sigil": ["BasaltSeal","BrokenFrame0","BrokenFrame8","AzharCrest0","AzharCrest7","GemBezel","AzharRuby","FrameStud0","SealHandle"]
}


func test_core_and_sigil_use_original_textures_on_fixed_solid_geometry() -> void:
	var view = ModelView.new()
	add_child_autofree(view)
	for item_id in PARTS:
		view.build(item_id)
		for part in PARTS[item_id]:
			var node: MeshInstance3D = view.model.get_node(part)
			assert_true(node.mesh is ArrayMesh,part+" is a solid reference mesh")
			var bounds := node.get_aabb()
			assert_gt(minf(bounds.size.x,minf(bounds.size.y,bounds.size.z)),0.001)
			var arrays := node.mesh.surface_get_arrays(0)
			assert_eq(arrays[Mesh.ARRAY_VERTEX].size(),arrays[Mesh.ARRAY_TEX_UV].size())
			var mat: StandardMaterial3D = node.material_override
			assert_string_contains(mat.albedo_texture.resource_path,item_id+".png")
			assert_eq(mat.transparency,BaseMaterial3D.TRANSPARENCY_DISABLED,"Solid surface, not a cutout plane")
			var vertices = arrays[Mesh.ARRAY_VERTEX]
			var texcoords = arrays[Mesh.ARRAY_TEX_UV]
			view.model.rotation_degrees.y = 35
			assert_eq(node.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX],vertices)
			assert_eq(node.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV],texcoords)
			view.model.rotation_degrees.y = 0
		assert_gt(view.model.get_child_count(),20,"Separate fittings instead of the former primitive")
		var body: MeshInstance3D = view.model.get_node(PARTS[item_id][0])
		assert_gt(body.get_aabb().size.z,0.25,"The principal body has a physical rear and thickness")


func test_artifacts_lie_on_counter_and_remain_in_frame() -> void:
	var view = ModelView.new()
	add_child_autofree(view)
	view.size = Vector2(640,480)
	await get_tree().process_frame
	view.build("grandmaster_elixir")
	var elixir := projected_rect(view)
	for item_id in PARTS:
		view.build(item_id)
		var minimum_y := INF
		for node: MeshInstance3D in view.model.get_children():
			if node.name != "ContactShadow":
				minimum_y = minf(minimum_y,node.get_aabb().position.y+node.position.y)
		assert_almost_eq(minimum_y,0.018,0.0001,item_id+" rests on its actual lowest solid point")
		assert_almost_eq(view.model.get_node("ContactShadow").position.y,0.004,0.0001)
		var rect := projected_rect(view)
		assert_lt(rect.size.y/elixir.size.y,0.85,"A stable lying artifact is lower than the upright bottle")
		assert_gt(rect.size.y/elixir.size.y,0.2,"Original artifact proportions remain legible")
		assert_true(Rect2(Vector2.ZERO,view.size).encloses(rect),"Handle, charm and tip must not be cropped")


func test_both_new_artifacts_drag_live_return_and_buy_without_duplicate_or_changed_price() -> void:
	var session = NewGame.new().create_session("Aria",1)
	session.black_market.unlocked = true
	session.player.gold = 200000
	var market = Market.instantiate()
	add_child_autofree(market)
	market.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	market.size = Vector2(1920,1080)
	market.configure(session,"2026-09-06")
	await get_tree().process_frame
	for item_id in PARTS:
		var slot = null
		for candidate in market.offer_slots:
			if candidate.item_id == item_id:
				slot = candidate
		assert_not_null(slot,item_id+" is present in the isolated 6 September delivery")
		if slot == null:
			continue
		var view = slot.model_view
		var world = view.model
		var dimensions: Vector2 = view.size
		var gold_before: int = session.player.gold
		var price := 9500 if item_id=="hearth_core" else 12000
		assert_almost_eq(dimensions.x/slot.size.x,1.5,0.01)
		assert_string_contains(slot._item_texture.resource_path,item_id+".png")
		var data = slot._get_drag_data(Vector2(90,45))
		assert_eq(data.item_id,item_id)
		assert_same(view.model,world)
		assert_false(view.get_parent()==slot,"No duplicate left on the leather mat")
		assert_same(slot.price_sign.get_parent(),slot,"The hanging sign stays attached to the counter")
		assert_lt(view.size.distance_to(dimensions),0.001)
		assert_false(world.get_node("ContactShadow").visible)
		slot.notification(Control.NOTIFICATION_DRAG_END)
		await get_tree().process_frame
		assert_same(view.get_parent(),slot)
		assert_true(world.get_node("ContactShadow").visible)
		var camera: Camera3D = view.viewport_3d.get_camera_3d()
		assert_lt((view.position+camera.unproject_position(Vector3(0,0.035,0))).distance_to(slot._counter_anchor),0.1)
		assert_eq(session.player.gold,gold_before)
		slot._get_drag_data(Vector2(90,45))
		market.inventory_drop_target._drop_data(Vector2.ZERO,data)
		slot.notification(Control.NOTIFICATION_DRAG_END)
		assert_false(view.visible)
		assert_eq(world.get_child_count(),0)
		assert_eq(session.player.inventory.count(item_id),1)
		assert_eq(session.player.gold,gold_before-price,"Original economy is unchanged")


func test_core_volume_tapers_at_silhouette_instead_of_extruding_texture_stripes() -> void:
	var view = ModelView.new()
	add_child_autofree(view)
	var builder = load("res://ui/screens/black_market/hearth_core_reference_model.gd").new()
	builder.build(view)
	for pixel: Vector2 in builder.body_outline:
		assert_almost_eq(builder._body_depth(pixel),4.0,0.01,"The two faces meet along a narrow stone edge")
	assert_gt(builder._body_depth(Vector2(540,710)),150.0,"Interior remains a full rounded mass")


func projected_rect(view) -> Rect2:
	var camera: Camera3D = view.viewport_3d.get_camera_3d()
	var minimum := Vector2(INF,INF)
	var maximum := Vector2(-INF,-INF)
	for child: MeshInstance3D in view.model.get_children():
		if child.name == "ContactShadow":
			continue
		var vertices: PackedVector3Array = child.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for vertex in vertices:
			var pixel := camera.unproject_position(child.global_transform*vertex)
			minimum = minimum.min(pixel)
			maximum = maximum.max(pixel)
	return Rect2(minimum,maximum-minimum)
