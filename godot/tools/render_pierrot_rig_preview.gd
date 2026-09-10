extends SceneTree

const Lab := preload("res://tools/pierrot_thrust_lab.tscn")
const OUTPUT := "res://../output/pierrot_rig_20260908/"


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT + "frames"))
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1280, 720)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var lab = Lab.instantiate()
	viewport.add_child(lab)
	for frame in 8:
		await process_frame
	for phase: String in ["idle", "anticipation", "approach", "contact", "withdraw", "returned"]:
		var at: float = {
			"idle": 0.0,
			"anticipation": 0.16,
			"approach": 0.39,
			"contact": 0.56,
			"withdraw": 0.75,
			"returned": 1.0
		}[phase]
		lab.seek(at)
		await process_frame
		await RenderingServer.frame_post_draw
		viewport.get_texture().get_image().save_png(OUTPUT + phase + ".png")
		if phase == "contact":
			var expected: Vector2 = lab._stage.to_global(lab.target)
			assert(
				lab.rig.tip_global().distance_to(expected) < 0.1,
				"Actual lance tip must reach the target."
			)
	if OS.get_cmdline_user_args().has("--movie"):
		for frame in 92:
			lab.seek(clampf(float(frame - 13) / 56.0, 0, 1))
			await process_frame
			await RenderingServer.frame_post_draw
			viewport.get_texture().get_image().save_png(OUTPUT + "frames/frame_%04d.png" % frame)
	print("PIERROT RIG CAPTURE COMPLETE — isolated preview, no player saves")
	lab.queue_free()
	await process_frame
	viewport.queue_free()
	await process_frame
	quit()
