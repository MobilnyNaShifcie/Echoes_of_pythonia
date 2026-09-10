extends SceneTree
## Captures the real Godot renderer. No source bitmap is modified.

const Lab := preload("res://tools/pierrot_native/portrait_lab.tscn")
const OUTPUT := "res://../output/pierrot_native_20260909/"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT + "frames"))
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1440, 900)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var lab = Lab.instantiate()
	lab.playing = false
	viewport.add_child(lab)
	for frame in 5:
		await process_frame
	lab.seek(0.0)
	await _capture(viewport, "rest.png")
	lab.seek(1.4)
	await _capture(viewport, "breath.png")
	lab.set_light_background(true)
	await _capture(viewport, "light_background.png")
	lab.set_light_background(false)
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1080)]:
		viewport.size = dimensions
		await _capture(viewport, "layout_%dx%d.png" % [dimensions.x, dimensions.y])
	viewport.size = Vector2i(1440, 900)
	if OS.get_cmdline_user_args().has("--movie"):
		for frame in 112:
			lab.seek(float(frame) / 20.0)
			await _capture(viewport, "frames/frame_%04d.png" % frame)
	print("NATIVE PIERROT PREVIEW COMPLETE: " + ProjectSettings.globalize_path(OUTPUT))
	lab.queue_free()
	await process_frame
	viewport.queue_free()
	await process_frame
	quit()


func _capture(viewport: SubViewport, file: String) -> void:
	# Root Control anchors and TextureRect layout settle after a viewport resize.
	for frame in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	if not file.begins_with("frames/"):
		var lab: Control = viewport.get_child(0)
		assert(
			lab.size.is_equal_approx(Vector2(viewport.size)), "Preview anchors must match viewport"
		)
	var error := viewport.get_texture().get_image().save_png(OUTPUT + file)
	assert(error == OK, "Failed to save preview: " + file)
