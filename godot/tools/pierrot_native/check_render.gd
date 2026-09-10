extends SceneTree
## Pixel check of the native skinned mesh against a Sprite2D at the same scale.

const Rig := preload("res://tools/pierrot_native/portrait_rig.gd")
const OUTPUT := "res://../output/pierrot_native_20260909/"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var viewport := SubViewport.new()
	viewport.size = Vector2i(512, 768)
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var source := Sprite2D.new()
	source.texture = Rig.SOURCE
	source.centered = false
	source.scale = Vector2.ONE * 0.5
	viewport.add_child(source)
	var rig := Rig.new()
	rig.scale = source.scale
	rig.visible = false
	viewport.add_child(rig)
	for frame in 5:
		await process_frame
	var original := await _snapshot(viewport)
	original.save_png(OUTPUT + "qa_reference.png")
	source.visible = false
	rig.visible = true
	rig.apply_rest()
	var rest := await _snapshot(viewport)
	rest.save_png(OUTPUT + "qa_rest.png")
	var reference_data := original.get_data()
	var rest_data := rest.get_data()
	var maximum_delta := 0
	var mismatched_channels := 0
	for index in reference_data.size():
		var difference := absi(int(reference_data[index]) - int(rest_data[index]))
		maximum_delta = maxi(maximum_delta, difference)
		if difference > 2:
			mismatched_channels += 1
	rig.seek(1.4)
	var moved := await _snapshot(viewport)
	moved.save_png(OUTPUT + "qa_breath.png")
	var moved_data := moved.get_data()
	var motion_channels := 0
	for index in moved_data.size():
		if absi(int(rest_data[index]) - int(moved_data[index])) > 3:
			motion_channels += 1
	var mismatch_fraction := float(mismatched_channels) / reference_data.size()
	var passed := mismatch_fraction < 0.001 and motion_channels > 1000
	var report := {
		"passed": passed,
		"renderer": RenderingServer.get_current_rendering_method(),
		"max_rest_channel_delta": maximum_delta,
		"rest_channels_delta_over_2": mismatched_channels,
		"rest_mismatch_fraction": mismatch_fraction,
		"motion_channels_delta_over_3": motion_channels,
		"source_sha256": FileAccess.get_sha256("res://assets/combat/heroes/pierrot.png"),
		"note":
		"Checks rest fidelity and actual GPU deformation, not artistic approval or frame rate."
	}
	var file := FileAccess.open(OUTPUT + "render_qa.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("NATIVE PORTRAIT RENDER QA: " + JSON.stringify(report))
	viewport.queue_free()
	await process_frame
	quit(0 if passed else 1)


func _snapshot(viewport: SubViewport) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return viewport.get_texture().get_image()
