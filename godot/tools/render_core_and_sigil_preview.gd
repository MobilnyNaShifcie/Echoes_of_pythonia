extends SceneTree
## Isolated in-memory fixture. Never instantiate the app or access save files.

const ITEMS := ["hearth_core","azhar_sigil"]
const OUTPUT := "res://../output/"


func _init() -> void:
	if not InputMap.has_action("dialogic_default_action"):
		InputMap.add_action("dialogic_default_action")
	call_deferred("render_preview")


func render_preview() -> void:
	# Legacy 3D asset inspection only. Live market review: scripts/review_black_market.py.
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
