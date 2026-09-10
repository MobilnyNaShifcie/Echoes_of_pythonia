extends GutTest

const Rig := preload("res://tools/pierrot_native/portrait_rig.gd")
const SkinData := preload("res://tools/pierrot_native/portrait_skin.gd")
const Lab := preload("res://tools/pierrot_native/portrait_lab.tscn")
const SOURCE_HASH := "e31a4bbf95d49cc4a5a63ad37d551a32261088154a627a5761e79fae3b7ff830"


func test_original_is_unchanged_and_has_real_alpha() -> void:
	for path: String in [
		"res://assets/combat/heroes/pierrot.png",
		"res://assets/ui/class_selection/pierrot_female.png"
	]:
		assert_eq(FileAccess.get_sha256(path), SOURCE_HASH)
	var pixels := Rig.SOURCE.get_image()
	assert_true(pixels.has_mipmaps() == false)
	assert_eq(pixels.get_pixel(0, 0).a, 0.0)
	assert_gt(pixels.get_pixel(558, 180).a, 0.95)


func test_weights_normalize_and_respect_renderer_four_influence_limit() -> void:
	var valid := true
	for y in range(0, 1537, 16):
		for x in range(0, 1025, 16):
			var weights := SkinData.weights_at(Vector2(x, y))
			var total := 0.0
			var count := 0
			for weight in weights:
				total += weight
				count += 1 if weight > 0.0 else 0
				valid = valid and weight >= 0.0 and is_finite(weight)
			valid = valid and absf(total - 1.0) < 0.00001 and count <= 4
	assert_true(valid)


func test_face_has_only_the_rigid_head_influence() -> void:
	for point: Vector2 in [
		Vector2(546, 145), Vector2(601, 164), Vector2(570, 181), Vector2(573, 201)
	]:
		var weights := SkinData.weights_at(point)
		assert_eq(weights[2], 1.0)


func test_rest_vertices_and_uvs_preserve_the_complete_original_canvas() -> void:
	var rig := Rig.new()
	add_child_autofree(rig)
	assert_true(rig.skeleton is Skeleton2D)
	assert_eq(rig.mesh.texture, Rig.SOURCE)
	assert_eq(rig.mesh.polygon, rig.mesh.uv)
	assert_eq(rig.mesh.polygon.size(), 65 * 97)
	assert_eq(rig.mesh.polygons.size(), 64 * 96 * 2)
	assert_eq(rig.mesh.get_bone_count(), SkinData.BONES.size())
	for index in rig.mesh.get_bone_count():
		assert_not_null(rig.skeleton.get_node_or_null(rig.mesh.get_bone_path(index)))
	for point: Vector2 in [
		Vector2.ZERO, Vector2(552, 165), Vector2(270, 740), Vector2(840, 920), SkinData.SIZE
	]:
		assert_lt(rig.point_in_pose(point).distance_to(point), 0.001)


func test_weapon_grip_and_boot_soles_stay_fixed_under_parent_scaling() -> void:
	var parent := Node2D.new()
	parent.scale = Vector2.ONE * 0.47
	parent.position = Vector2(27, 41)
	add_child_autofree(parent)
	var rig := Rig.new()
	rig.position = Vector2(140, 112)
	parent.add_child(rig)
	for frame in 57:
		rig.seek(frame / 10.0)
		for point: Vector2 in [
			Vector2(15, 26),
			Vector2(350, 532),
			Vector2(1008, 1468),
			Vector2(474, 1353),
			Vector2(722, 1425)
		]:
			assert_lt(rig.point_in_pose(point).distance_to(point), 0.001)


func test_face_does_not_squash_while_hair_and_cloth_move() -> void:
	var rig := Rig.new()
	add_child_autofree(rig)
	var eye_a := Vector2(548, 146)
	var eye_b := Vector2(601, 164)
	rig.seek(1.4)
	assert_almost_eq(
		rig.point_in_pose(eye_a).distance_to(rig.point_in_pose(eye_b)),
		eye_a.distance_to(eye_b),
		0.001
	)
	assert_gt(rig.point_in_pose(Vector2(361, 176)).distance_to(Vector2(361, 176)), 1.0)
	assert_gt(rig.point_in_pose(Vector2(167, 931)).distance_to(Vector2(167, 931)), 1.0)


func test_loop_is_continuous_and_seeking_does_not_accumulate_transforms() -> void:
	var rig := Rig.new()
	add_child_autofree(rig)
	var point := Vector2(552, 175)
	rig.seek(1.4)
	var expected := rig.point_in_pose(point)
	for time: float in [4.3, 0.2, 2.8, 5.6, 1.4]:
		rig.seek(time)
	assert_lt(expected.distance_to(rig.point_in_pose(point)), 0.001)
	rig.seek(SkinData.CYCLE - 0.00001)
	var before := rig.point_in_pose(point)
	rig.seek(0.00001)
	assert_lt(before.distance_to(rig.point_in_pose(point)), 0.001)
	rig.seek(5.6)
	assert_lt(rig.point_in_pose(point).distance_to(point), 0.001)
	rig.set_strength(0.0)
	rig.seek(1.4)
	assert_lt(rig.point_in_pose(point).distance_to(point), 0.001)


func test_preview_pause_seek_background_and_responsive_stage() -> void:
	var lab = Lab.instantiate()
	lab.playing = false
	add_child_autofree(lab)
	lab.seek(1.4)
	assert_false(lab.playing)
	assert_false(lab.rig.player.is_playing())
	lab.set_playing(true)
	assert_true(lab.rig.player.is_playing())
	var phase_before: float = lab.rig.phase
	lab.rig.player.advance(0.1)
	assert_gt(lab.rig.phase, phase_before)
	lab.set_playing(false)
	lab.set_light_background(true)
	assert_false(lab._backdrop.visible)
	lab.set_light_background(false)
	assert_true(lab._backdrop.visible)
	lab.set_anchors_preset(Control.PRESET_TOP_LEFT)
	for dimensions: Vector2 in [Vector2(1280, 720), Vector2(1920, 1080), Vector2(2560, 1080)]:
		lab.size = dimensions
		lab._layout()
		assert_lte(lab.stage.position.x + 1440.0 * lab.stage.scale.x, dimensions.x + 0.01)
		assert_lte(lab.stage.position.y + 900.0 * lab.stage.scale.y, dimensions.y + 0.01)
		assert_lt((lab.stage.position + lab._backdrop.position * lab.stage.scale).length(), 0.01)
		assert_lt((lab._backdrop.size * lab.stage.scale).distance_to(dimensions), 0.01)
	assert_null(lab.get_node_or_null("App"))
	assert_false(lab.rig.player.has_animation("fate_thrust"))
