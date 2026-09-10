extends SceneTree
## Isolated in-memory fixture. Never instantiate the app or access save files.

const ITEMS := ["hearth_core","azhar_sigil"]
const OUTPUT := "res://../output/"


func _init() -> void:
	if not InputMap.has_action("dialogic_default_action"):
		InputMap.add_action("dialogic_default_action")
	call_deferred("render_preview")


func render_preview() -> void:
	var session = load("res://core/game/new_game_service.gd").new().create_session("Aria",1)
	session.black_market.unlocked = true
	session.player.gold = 200000
	var market = load("res://ui/screens/black_market/black_market.tscn").instantiate()
	root.add_child(market)
	market.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	market.configure(session,"2026-09-06")
	await create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT+"core_and_sigil_counter.png")
	root.get_texture().get_image().get_region(Rect2i(100,400,1230,415)).save_png(OUTPUT+"core_and_sigil_counter_detail.png")
	for item_id in ITEMS:
		var slot = null
		for candidate in market.offer_slots:
			if candidate.item_id == item_id:
				slot = candidate
		if slot == null or slot.model_view.model.get_child_count()<20:
			push_error("Missing artifact fixture/model: "+item_id)
			quit(1)
			return
		var view = slot.model_view
		slot.force_drag(slot._get_drag_data(Vector2(100,40)),null)
		var motion := InputEventMouseMotion.new()
		motion.position = Vector2(1150,400)
		root.push_input(motion)
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUTPUT+item_id+"_reference_held.png")
		var release := InputEventMouseButton.new()
		release.button_index = MOUSE_BUTTON_LEFT
		release.pressed = false
		release.position = motion.position
		root.push_input(release)
		await process_frame
		print(item_id," same live world returned: ",view==slot.model_view and view.get_parent()==slot)
	market.queue_free()
	await process_frame
	var result := OK
	for item_id in ITEMS:
		var prefix: String = OUTPUT+item_id+"_reference"
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
		original.texture = load("res://assets/items/materials/"+item_id+".png")
		original.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		original.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var detail = load("res://ui/screens/black_market/market_item_3d.gd").new()
		canvas.add_child(detail)
		detail.position = Vector2(975,135)
		detail.size = Vector2(780,800)
		detail.build(item_id)
		var camera: Camera3D = detail.viewport_3d.get_camera_3d()
		camera.size = 2.03
		camera.position = Vector3(0.3,2.68,5.5)
		camera.look_at(Vector3(0,0.73,0))
		for entry in [["ORYGINALNA GRAFIKA PRZEDMIOTU",Vector2(210,85)],["MODEL 3D — TEKSTURA Z ORYGINAŁU",Vector2(1055,85)]]:
			var label := Label.new()
			canvas.add_child(label)
			label.text = entry[0]
			label.position = entry[1]
			label.add_theme_font_size_override("font_size",24)
			label.modulate = Color("d9b96c")
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(prefix+"_comparison.png")
		detail.viewport_3d.get_texture().get_image().save_png(prefix+"_front.png")
		var export_root = detail.model.duplicate()
		export_root.get_node("ContactShadow").free()
		export_root.name = "HearthCore" if item_id=="hearth_core" else "AzharSigil"
		var document := GLTFDocument.new()
		var state := GLTFState.new()
		result = document.append_from_scene(export_root,state)
		if result == OK:
			result = document.write_to_filesystem(state,prefix+".glb")
		print(item_id," GLB export: ",result,"; solid meshes: ",export_root.get_child_count())
		export_root.free()
		detail.model.rotation_degrees.y = 35
		await create_timer(0.3).timeout
		await RenderingServer.frame_post_draw
		detail.viewport_3d.get_texture().get_image().save_png(prefix+"_turned.png")
		canvas.queue_free()
		await process_frame
		if result != OK:
			quit(1)
			return
	quit(0)
