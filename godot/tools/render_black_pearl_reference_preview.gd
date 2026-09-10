extends SceneTree
## Isolated visual QA: standalone market, no app, no save service or save I/O.


func _init() -> void:
	if not InputMap.has_action("dialogic_default_action"):
		InputMap.add_action("dialogic_default_action")
	call_deferred("render_preview")


func render_preview() -> void:
	var session = load("res://core/game/new_game_service.gd").new().create_session("Aria", 1)
	session.black_market.unlocked = true
	session.player.gold = 200000
	var market = load("res://ui/screens/black_market/black_market.tscn").instantiate()
	root.add_child(market)
	market.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	market.configure(session, "2026-09-05")
	var slot = market.offer_slots[1]
	assert(slot.item_id == "black_pearl")
	market._select_offer(slot.offer_id)
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../output/black_pearl_reference_counter.png")
	var data = slot._get_drag_data(Vector2(100,40))
	slot.force_drag(data, null)
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(1150,400)
	root.push_input(motion)
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../output/black_pearl_reference_held.png")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	release.position = Vector2(1150,400)
	root.push_input(release)
	await process_frame
	print("Pearl returned to counter: ", slot.model_view.get_parent() == slot)
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
	original.position = Vector2(130,185)
	original.size = Vector2(700,700)
	original.texture = load("res://assets/items/materials/black_pearl.png")
	original.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	original.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var detail = load("res://ui/screens/black_market/market_item_3d.gd").new()
	canvas.add_child(detail)
	detail.position = Vector2(975,135)
	detail.size = Vector2(780,800)
	detail.build("black_pearl")
	var camera: Camera3D = detail.viewport_3d.get_camera_3d()
	camera.size = 1.97
	camera.position = Vector3(0.3,2.68,5.5)
	camera.look_at(Vector3(0,0.73,0))
	for entry in [["ZATWIERDZONA GRAFIKA 2D",Vector2(230,85)],["MODEL 3D — TEKSTURA Z ORYGINAŁU",Vector2(1055,85)]]:
		var label := Label.new()
		canvas.add_child(label)
		label.text = entry[0]
		label.position = entry[1]
		label.add_theme_font_size_override("font_size",24)
		label.modulate = Color("d9b96c")
	await create_timer(0.6).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../output/black_pearl_reference_comparison.png")
	detail.viewport_3d.get_texture().get_image().save_png("res://../output/black_pearl_reference_front.png")
	var export_root = detail.model.duplicate()
	export_root.get_node("ContactShadow").free()
	export_root.name = "BlackPearl"
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var result := document.append_from_scene(export_root, state)
	if result == OK:
		result = document.write_to_filesystem(state, "res://../output/black_pearl_reference.glb")
	print("Black Pearl GLB export: ", result)
	export_root.free()
	detail.model.rotation_degrees.y = 35
	await create_timer(0.3).timeout
	await RenderingServer.frame_post_draw
	detail.viewport_3d.get_texture().get_image().save_png("res://../output/black_pearl_reference_turned.png")
	quit()
