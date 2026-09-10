extends GutTest

const Pose := preload("res://ui/presentation/rigs/pierrot_thrust_pose.gd")
const Rig := preload("res://ui/presentation/rigs/pierrot_cutout_rig.gd")
const Art := preload("res://ui/presentation/rigs/pierrot_cutout_art.gd")
const Lab := preload("res://tools/pierrot_thrust_lab.tscn")


func test_tip_reaches_the_target_and_weapon_never_leaves_the_grip() -> void:
	for target: Vector2 in [Vector2(650, -310), Vector2(790, -290), Vector2(1020, -340)]:
		for frame in 201:
			var pose := Pose.sample(frame / 200.0, target)
			assert_almost_eq(pose.rear_grip.distance_to(pose.tip), Pose.REAR_TO_TIP, 0.001)
			assert_almost_eq(pose.rear_grip.distance_to(pose.front_grip), Pose.HAND_SPACING, 0.001)
			if pose.progress >= Pose.CONTACT and pose.progress <= Pose.RELEASE:
				assert_lt((pose.root + pose.tip).distance_to(target), 0.001)


func test_limb_lengths_are_constant_and_feet_are_grounded_at_contact() -> void:
	for frame in 201:
		var pose := Pose.sample(frame / 200.0, Vector2(790, -310))
		for side: String in ["far", "near"]:
			var hand: Vector2 = pose["rear_grip" if side == "near" else "front_grip"]
			assert_almost_eq(
				pose["shoulder_" + side].distance_to(pose["elbow_" + side]), Pose.UPPER_ARM, 0.001
			)
			assert_almost_eq(pose["elbow_" + side].distance_to(hand), Pose.FOREARM, 0.001)
			assert_almost_eq(
				pose["hip_" + side].distance_to(pose["knee_" + side]), Pose.THIGH, 0.001
			)
			assert_almost_eq(
				pose["knee_" + side].distance_to(pose["ankle_" + side]), Pose.SHIN, 0.001
			)
			assert_lte(pose["ankle_" + side].y, Pose.ANKLE_HEIGHT)
			if pose.progress >= 0.40 and pose.progress <= 0.78:
				assert_almost_eq(pose["ankle_" + side].y, Pose.ANKLE_HEIGHT, 0.001)


func test_sampling_is_reversible_and_does_not_accumulate_transforms() -> void:
	var target := Vector2(790, -310)
	var initial := Pose.sample(0.0, target)
	for p: float in [0.57, 0.94, 0.15, 0.62, 0.01, 0.50]:
		Pose.sample(p, target)
	assert_eq(Pose.sample(0.0, target), initial)
	var final := Pose.sample(1.0, target)
	for key: String in ["root", "hip", "rear_grip", "front_grip", "tip", "ankle_near", "ankle_far"]:
		assert_lt(final[key].distance_to(initial[key]), 0.001, key)
	assert_eq(Pose.sample(-3.0, target), initial)
	assert_eq(Pose.sample(9.0, target), final)


func test_pose_has_no_teleports_at_phase_boundaries() -> void:
	for boundary: float in [0.16, 0.40, Pose.CONTACT, Pose.RELEASE, 0.78]:
		var before := Pose.sample(boundary - 0.00001, Vector2(790, -310))
		var after := Pose.sample(boundary + 0.00001, Vector2(790, -310))
		for key: String in ["root", "hip", "tip", "rear_grip", "front_grip", "ankle_near"]:
			assert_lt(before[key].distance_to(after[key]), 0.1, key)


func test_art_silhouettes_are_valid_meshes_inside_the_source_atlas() -> void:
	for id: String in Art.PARTS:
		var points := Art.points(Art.PARTS[id].outline)
		assert_gt(Geometry2D.triangulate_polygon(points).size(), 0, id)
		for vertex: Vector2 in points:
			assert_true(Rect2(0, 0, 1254, 1254).has_point(vertex), id)


func test_real_bones_and_weapon_transform_match_contact_on_scaled_stage() -> void:
	var parent := Node2D.new()
	parent.position = Vector2(13, 19)
	parent.scale = Vector2.ONE * 0.75
	add_child_autofree(parent)
	var rig := Rig.new()
	rig.position = Vector2(200, 590)
	rig.scale = Vector2.ONE * 0.90
	parent.add_child(rig)
	var target := Vector2(790, -310)
	rig.set_pose(0.56, target)
	assert_lt(rig.tip_global().distance_to(rig.to_global(target)), 0.001)
	var lance: Bone2D = rig._bones.lance
	assert_lt(lance.to_global(Vector2(Pose.REAR_TO_TIP, 0)).distance_to(rig.tip_global()), 0.001)
	for side: String in ["far", "near"]:
		var forearm: Bone2D = rig._bones["forearm_" + side]
		assert_lt(
			forearm.to_global(Vector2(Pose.FOREARM, 0)).distance_to(rig.grip_global(side == "far")),
			0.001
		)
	assert_eq(rig._bones.size(), 15)
	assert_true(rig._skeleton is Skeleton2D)
	var source_scale := rig.scale
	for frame in 5:
		rig.set_pose(0.54, target)
		rig.set_pose(1.0, target)
	assert_eq(rig.scale, source_scale)
	assert_eq(rig._skeleton.position, Vector2.ZERO)


func test_preview_is_separate_and_scrubbing_does_not_start_playback() -> void:
	var lab = Lab.instantiate()
	add_child_autofree(lab)
	lab.seek(0.56)
	assert_false(lab.playing)
	assert_eq(lab._label.text, "KONTAKT GROTEM")
	lab.toggle_play()
	assert_true(lab.playing)
	lab.toggle_play()
	assert_false(lab.playing)
	assert_null(lab.get_node_or_null("App"))


func test_rendered_boot_soles_reach_the_same_floor_at_contact() -> void:
	var rig := Rig.new()
	add_child_autofree(rig)
	rig.position = Vector2(320, 600)
	rig.scale = Vector2.ONE * 0.9
	rig.set_pose(0.56, Vector2(790, -310))
	for side: String in ["near", "far"]:
		var mesh: Polygon2D = rig._bones["foot_" + side].get_child(0)
		var sole := -INF
		for vertex: Vector2 in mesh.polygon:
			sole = maxf(sole, mesh.to_global(vertex).y)
		assert_almost_eq(sole, 600.0, 0.01, side + " boot must not float above the floor")
