extends SceneTree
## Isolated in-memory delivery. Never load the app or the real player's save.

const OUTPUT := "res://../output/spark_of_life/"
const ModelView = preload("res://ui/screens/black_market/market_item_3d.gd")
const Offer = preload("res://core/economy/black_market_offer.gd")


func _init() -> void:
	if not InputMap.has_action("dialogic_default_action"):
		InputMap.add_action("dialogic_default_action")
	call_deferred("render_preview")


func capture(path: String) -> void:
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png(OUTPUT + path + ".png") == OK)


func render_preview() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var session = load("res://core/game/new_game_service.gd").new().create_session("Aria", 1)
	session.black_market.unlocked = true
	session.black_market.rotation_key = "2026-09-06"
	session.player.gold = 200000
	var items := ["grandmaster_elixir", "black_pearl", "spark_of_life", "leviathan_scale"]
	var prices := [7500, 7000, 8500, 13000]
	for i in items.size():
		session.black_market.offers.append(Offer.new("2026-09-06:%d" % i, items[i], 1, prices[i]))
	var market = load("res://ui/screens/black_market/black_market.tscn").instantiate()
	root.add_child(market)
	market.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	market.configure(session, "2026-09-06")
	await capture("counter")
	root.get_texture().get_image().get_region(Rect2i(50, 440, 1300, 400)).save_png(OUTPUT + "counter_detail.png")
	var slot = market.offer_slots[2]
	var world = slot.model_view.model
	slot.force_drag(slot._get_drag_data(Vector2(100, 40)), null)
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(1120, 390)
	root.push_input(motion)
	await capture("held")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = motion.position
	root.push_input(release)
	await process_frame
	assert(slot.model_view.get_parent() == slot and slot.model_view.model == world)
	print("Spark drag returned the same live model to the mat")
	market.queue_free()
	await process_frame
	var canvas := Control.new()
	root.add_child(canvas)
	canvas.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var bg := ColorRect.new()
	canvas.add_child(bg)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color("0b0e12")
	var original := TextureRect.new()
	canvas.add_child(original)
	original.position = Vector2(130, 185)
	original.size = Vector2(700, 700)
	original.texture = load("res://assets/items/materials/spark_of_life.png")
	original.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	original.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var detail = ModelView.new()
	canvas.add_child(detail)
	detail.position = Vector2(975, 135)
	detail.size = Vector2(780, 800)
	detail.build("spark_of_life")
	var camera: Camera3D = detail.viewport_3d.get_camera_3d()
	camera.size = 2.03
	camera.position = Vector3(0.57, 2.68, 5.5)
	camera.look_at(Vector3(0.27, 0.73, 0))
	for entry in [["ORYGINALNA GRAFIKA PRZEDMIOTU", Vector2(210, 85)], ["MODEL 3D — TEKSTURA Z ORYGINAŁU", Vector2(1055, 85)]]:
		var label := Label.new()
		canvas.add_child(label)
		label.text = entry[0]
		label.position = entry[1]
		label.add_theme_font_size_override("font_size", 24)
		label.modulate = Color("d9b96c")
	await capture("comparison")
	detail.viewport_3d.get_texture().get_image().save_png(OUTPUT + "front.png")
	detail.model.rotation_degrees.y = 35
	await capture("comparison_turned")
	detail.viewport_3d.get_texture().get_image().save_png(OUTPUT + "turned.png")
	detail.model.rotation_degrees.y = -35
	await capture("comparison_reverse_turn")
	detail.model.rotation_degrees.y = 0
	var export_root = detail.model.duplicate()
	export_root.get_node("ContactShadow").free()
	export_root.name = "SparkOfLife"
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var result := document.append_from_scene(export_root, state)
	if result == OK:
		result = document.write_to_filesystem(state, OUTPUT + "spark_of_life.glb")
	print("Spark GLB export: ", result, "; solid meshes: ", export_root.get_child_count())
	export_root.free()
	quit(0 if result == OK else 1)
