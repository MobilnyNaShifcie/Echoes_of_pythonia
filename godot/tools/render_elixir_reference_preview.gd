extends SceneTree
## Manual visual QA. No gameplay saves are read or written.

class PreviewSaveService extends SaveGameService:
	func any_save_exists() -> bool:
		return false

	func save_session(_session: GameSessionClass) -> Dictionary:
		return {"ok": true, "message": "Preview: disk saves disabled."}

func _init():
	call_deferred("render_preview")

func render_preview():
	var app = load("res://scenes/app/app.tscn").instantiate()
	app._save_service = PreviewSaveService.new()
	root.add_child(app)
	await process_frame
	var session = load("res://core/game/new_game_service.gd").new().create_session("Aria", 1)
	session.black_market.unlocked = true
	session.player.gold = 200000
	app._on_session_created(session)
	app._show_black_market()
	app.screen_host.get_child(0).configure(session, "2026-09-05")
	await create_timer(1.5).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../output/elixir_reference_counter.png")
	app.queue_free()
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
	original.position = Vector2(160,100)
	original.size = Vector2(560,860)
	original.texture = load("res://assets/items/consumables/grandmaster_elixir.png")
	original.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	original.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var detail = load("res://ui/screens/black_market/market_item_3d.gd").new()
	canvas.add_child(detail)
	detail.position = Vector2(820,80)
	detail.size = Vector2(790,900)
	detail.build("grandmaster_elixir")
	var camera = detail.viewport_3d.get_camera_3d()
	camera.size = 1.7
	camera.position = Vector3(0.3,2.81,5.5)
	camera.look_at(Vector3(0,0.86,0))
	for entry in [["ZATWIERDZONA GRAFIKA 2D",Vector2(210,42)],["MODEL 3D Z TEKSTURĄ Z ORYGINAŁU",Vector2(960,42)]]:
		var label := Label.new()
		canvas.add_child(label)
		label.text = entry[0]
		label.position = entry[1]
		label.add_theme_font_size_override("font_size",24)
		label.modulate = Color("d9b96c")
	await create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../output/elixir_reference_comparison.png")
	detail.viewport_3d.get_texture().get_image().save_png("res://../output/elixir_reference_front.png")
	# Export solid meshes with their artwork UVs for independent 3D inspection.
	var export_root = detail.model.duplicate()
	export_root.get_node("ContactShadow").free()
	export_root.name = "GrandmasterElixir"
	var document := GLTFDocument.new()
	var state := GLTFState.new()
	var result := document.append_from_scene(export_root, state)
	if result == OK:
		result = document.write_to_filesystem(state, "res://../output/grandmaster_elixir_reference.glb")
	print("Elixir GLB export: ", result)
	export_root.free()
	detail.model.rotation_degrees.y = 35
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	detail.viewport_3d.get_texture().get_image().save_png("res://../output/elixir_reference_turned.png")
	quit()
