extends SceneTree
## Technical export/import validation. Does not load the game or player saves.
# gdlint: disable=max-returns
# Fail immediately after each prerequisite, before dereferencing imported nodes.


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var packed := load("res://generated/pipeline_probe.glb") as PackedScene
	if not _check(packed != null, "GLB imported as PackedScene"):
		return
	var model := packed.instantiate()
	root.add_child(model)
	await process_frame
	var skeleton: Skeleton3D
	var player: AnimationPlayer
	var skinned_mesh: MeshInstance3D
	for child: Node in model.find_children("*", "", true, false):
		if child is Skeleton3D:
			skeleton = child
		if child is AnimationPlayer:
			player = child
		if child is MeshInstance3D and child.skin != null:
			skinned_mesh = child
	if not _check(skeleton != null and skeleton.get_bone_count() == 2, "Two real 3D bones"):
		return
	if not _check(skinned_mesh != null and skinned_mesh.skin.get_bind_count() >= 2, "Skin binds"):
		return
	if not _check(skinned_mesh.mesh.surface_get_material(0) != null, "Material imported"):
		return
	if not _check(player != null, "AnimationPlayer imported"):
		return
	var clip := ""
	for candidate: String in player.get_animation_list():
		if candidate.contains("ProbeBend"):
			clip = candidate
	if not _check(not clip.is_empty(), "ProbeBend animation imported"):
		return
	var upper := skeleton.find_bone("upper")
	if not _check(upper >= 0, "Bone names preserved"):
		return
	player.play(clip)
	player.seek(0.0, true)
	var start := skeleton.get_bone_pose_rotation(upper)
	player.seek(0.5, true)
	var middle := skeleton.get_bone_pose_rotation(upper)
	if not _check(start.angle_to(middle) > 0.5, "Imported animation moves the skeleton"):
		return
	player.seek(player.get_animation(clip).length, true)
	var returned := skeleton.get_bone_pose_rotation(upper)
	if not _check(start.angle_to(returned) < 0.01, "Animation returns to initial pose"):
		return
	var report := {
		"godot_version": Engine.get_version_info().string,
		"bone_count": skeleton.get_bone_count(),
		"animation": clip,
		"animation_length": player.get_animation(clip).length,
		"midpoint_rotation_radians": start.angle_to(middle),
		"checks_passed": 9,
	}
	var file := FileAccess.open("res://generated/godot_report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("GODOT_CHARACTER_PIPELINE_OK ", JSON.stringify(report))
	model.queue_free()
	await process_frame
	quit(0)


func _check(condition: bool, description: String) -> bool:
	if not condition:
		push_error("FAIL: " + description)
		quit(1)
		return false
	print("PASS: ", description)
	return true
