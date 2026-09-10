extends SceneTree
## Import the actual Pierrot study without launching the game or touching saves.

var _failures := 0
var _checks := 0


func _init() -> void:
	_run.call_deferred()


func _run() -> void:
	var source := ProjectSettings.globalize_path(
		"res://../../art_drafts/pierrot_3d_study_01/pierrot_study.glb"
	)
	var state := GLTFState.new()
	var document := GLTFDocument.new()
	var result := document.append_from_file(source, state)
	if not _check(result == OK, "Actual study GLB can be parsed"):
		quit(1)
		return
	var model := document.generate_scene(state)
	if not _check(model != null, "Actual 3D scene can be instantiated"):
		quit(1)
		return
	root.add_child(model)
	await process_frame
	var head := model.find_child("Head_Authored_Face", true, false) as MeshInstance3D
	var torso := model.find_child("Body_Torso_Neck", true, false) as MeshInstance3D
	var weapon := model.find_child("Fate_Lance_Separate", true, false) as Node3D
	_check(head != null, "Head preserved as a mesh")
	_check(torso != null, "Torso preserved as a mesh")
	_check(weapon != null, "Separate lance preserved")
	if head != null:
		_check(head.get_aabb().size.z > 0.10, "Head has real depth, not a flat plane")
	if torso != null:
		_check(torso.get_aabb().size.z > 0.15, "Torso has real depth")
	var meshes := 0
	var vertices := 0
	var triangles := 0
	var bounds := AABB()
	var first := true
	for node: Node in model.find_children("*", "MeshInstance3D", true, false):
		var visual := node as MeshInstance3D
		meshes += 1
		for surface in visual.mesh.get_surface_count():
			vertices += visual.mesh.surface_get_array_len(surface)
			triangles += visual.mesh.surface_get_array_index_len(surface) / 3
		if weapon != null and weapon.is_ancestor_of(visual):
			continue
		var local_bounds: AABB = visual.global_transform * visual.get_aabb()
		if first:
			bounds = local_bounds
			first = false
		else:
			bounds = bounds.merge(local_bounds)
	_check(meshes > 150 and vertices > 30000, "Costume, hair and facial geometry imported")
	_check(bounds.size.y > 1.75 and bounds.size.y < 2.0, "Character scale preserved in metres")
	_check(absf(bounds.position.y) < 0.002, "Feet aligned with floor within 2 mm")
	_check(bounds.size.x > 0.6 and bounds.size.z > 0.15, "Character is volumetric on all axes")
	var report := {
		"checks": _checks,
		"failures": _failures,
		"mesh_count": meshes,
		"vertices": vertices,
		"triangles": triangles,
		"character_bounds": str(bounds),
		"weapon_separate": weapon != null,
		"status": "Unrigged geometry study, NOT production character",
		"godot_version": Engine.get_version_info().string,
	}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://generated"))
	var file := FileAccess.open("res://generated/pierrot_study_report.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("PIERROT_STUDY_IMPORT_REPORT ", JSON.stringify(report))
	model.queue_free()
	await process_frame
	quit(0 if _failures == 0 else 1)


func _check(condition: bool, description: String) -> bool:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("FAIL: " + description)
	else:
		print("PASS: ", description)
	return condition
