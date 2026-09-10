extends Node2D
## Isolated female cutout prototype. The approved idle/class portraits are untouched.

const Pose := preload("res://ui/presentation/rigs/pierrot_thrust_pose.gd")
const Art := preload("res://ui/presentation/rigs/pierrot_cutout_art.gd")
const ATLAS := preload("res://assets/combat/rigs/pierrot_prototype/parts-source.png")
const LANCE := preload("res://assets/combat/rigs/pierrot_prototype/lance-source.png")

var debug_bones := false
var pose: Dictionary = {}
var _skeleton: Skeleton2D
var _bones: Dictionary = {}
var _weapon: Bone2D


func _ready() -> void:
	# Debug drawing must sit above the absolute-z textured bones, not behind them.
	z_index = 50
	_skeleton = Skeleton2D.new()
	_skeleton.name = "PierrotSkeleton"
	add_child(_skeleton)
	_build()
	set_pose(0.0, Vector2(650, -310))
	for bone: Bone2D in _bones.values():
		bone.rest = bone.transform


func set_pose(progress: float, target: Vector2) -> void:
	if _skeleton == null:
		return
	pose = Pose.sample(progress, target)
	_skeleton.position = pose.root
	_place("hips", pose.hip, 0.0)
	_place("body", pose.hip, pose.lean)
	_place("head", pose.hip + Vector2(-14, -149).rotated(pose.lean), pose.lean + pose.head_angle)
	_place("cloth", pose.hip + Vector2(0, 6), pose.cloth_angle)
	for side: String in ["far", "near"]:
		_segment("thigh_" + side, pose["hip_" + side], pose["knee_" + side])
		_segment("shin_" + side, pose["knee_" + side], pose["ankle_" + side])
		_place("foot_" + side, pose["ankle_" + side], 0.0)
		_segment("upper_" + side, pose["shoulder_" + side], pose["elbow_" + side])
		_segment(
			"forearm_" + side,
			pose["elbow_" + side],
			pose["rear_grip" if side == "near" else "front_grip"]
		)
	_place("lance", pose.rear_grip, pose.weapon_angle)
	queue_redraw()


func tip_global() -> Vector2:
	return to_global(pose.root + pose.tip)


func grip_global(front: bool) -> Vector2:
	return to_global(pose.root + pose["front_grip" if front else "rear_grip"])


func _build() -> void:
	var hips := _bone("hips", _skeleton, 10, 0)
	var body := _bone("body", hips, 149, 6)
	_mesh(body, "torso")
	_mesh(_bone("head", body, 85, 9), "head")
	_mesh(_bone("cloth", hips, 210, 2), "cloth")
	for side: String in ["far", "near"]:
		var depth := 0 if side == "far" else 3
		var thigh := _bone("thigh_" + side, hips, Pose.THIGH, depth)
		var shin := _bone("shin_" + side, thigh, Pose.SHIN, depth)
		_mesh(thigh, "thigh", Pose.THIGH)
		_mesh(shin, "shin_" + side, Pose.SHIN)
		_mesh(_bone("foot_" + side, shin, 50, depth + 1), "foot_" + side)
		var arm_depth := 4 if side == "far" else 10
		var upper := _bone("upper_" + side, body, Pose.UPPER_ARM, arm_depth)
		_mesh(upper, "upper_arm", Pose.UPPER_ARM)
		_mesh(
			_bone("forearm_" + side, upper, Pose.FOREARM, arm_depth + 2),
			"forearm_" + side,
			Pose.FOREARM
		)
	_weapon = _bone("lance", hips, Pose.REAR_TO_TIP, 11)
	_build_lance()


func _bone(id: String, parent: Node2D, length: float, depth: int) -> Bone2D:
	var bone := Bone2D.new()
	bone.name = id
	bone.set_autocalculate_length_and_angle(false)
	bone.set_length(length)
	bone.set_bone_angle(0.0)
	bone.z_as_relative = false
	bone.z_index = depth
	parent.add_child(bone)
	_bones[id] = bone
	return bone


func _mesh(bone: Bone2D, part: String, length := 0.0) -> void:
	var data: Dictionary = Art.PARTS[part]
	var uv := Art.points(data.outline)
	var vertices := PackedVector2Array()
	var factor: float = data.get("scale", 1.0)
	var angle := 0.0
	if length > 0.0:
		var delta: Vector2 = data.end - data.anchor
		factor = length / delta.length()
		angle = delta.angle()
	for point: Vector2 in uv:
		vertices.append((point - data.anchor).rotated(-angle) * factor)
	var mesh := Polygon2D.new()
	mesh.name = part + "Mesh"
	mesh.texture = ATLAS
	mesh.polygon = vertices
	mesh.uv = uv
	mesh.antialiased = true
	bone.add_child(mesh)


func _build_lance() -> void:
	# Pixel-space silhouette of the generated 2172x724 lance sheet.
	var uv := Art.points(
		[
			43,
			350,
			146,
			327,
			170,
			310,
			168,
			307,
			178,
			319,
			208,
			324,
			231,
			335,
			282,
			341,
			1482,
			341,
			1510,
			326,
			1515,
			301,
			1523,
			321,
			1556,
			317,
			1585,
			289,
			1585,
			308,
			1626,
			297,
			1641,
			280,
			1661,
			300,
			1715,
			292,
			1744,
			257,
			1750,
			271,
			1787,
			289,
			1820,
			300,
			1818,
			287,
			1836,
			305,
			1870,
			309,
			1893,
			299,
			1906,
			310,
			2137,
			350,
			1907,
			392,
			1894,
			403,
			1872,
			393,
			1835,
			403,
			1823,
			414,
			1821,
			400,
			1784,
			418,
			1750,
			432,
			1744,
			444,
			1738,
			417,
			1714,
			408,
			1660,
			403,
			1641,
			420,
			1626,
			406,
			1585,
			394,
			1584,
			409,
			1557,
			384,
			1525,
			381,
			1515,
			400,
			1510,
			375,
			1480,
			364,
			281,
			360,
			233,
			365,
			209,
			377,
			181,
			382,
			167,
			398,
			170,
			379,
			147,
			375
		]
	)
	var mesh := Polygon2D.new()
	mesh.name = "LanceMesh"
	mesh.texture = LANCE
	mesh.uv = uv
	var vertices := PackedVector2Array()
	var source_grip := Vector2(742, 350)
	var factor := Pose.REAR_TO_TIP / (2137.0 - source_grip.x)
	for point: Vector2 in uv:
		vertices.append((point - source_grip) * factor)
	mesh.polygon = vertices
	mesh.antialiased = true
	_weapon.add_child(mesh)


func _place(id: String, point: Vector2, angle: float) -> void:
	var bone: Bone2D = _bones[id]
	var parent := bone.get_parent() as Node2D
	bone.transform = (
		parent.global_transform.affine_inverse()
		* _skeleton.global_transform
		* Transform2D(angle, point)
	)


func _segment(id: String, start: Vector2, end: Vector2) -> void:
	_place(id, start, (end - start).angle())


func _draw() -> void:
	if not debug_bones or pose.is_empty():
		return
	var root_offset: Vector2 = pose.root
	for side: String in ["far", "near"]:
		for chain: Array in [["hip_", "knee_", "ankle_"], ["shoulder_", "elbow_"]]:
			for index in chain.size() - 1:
				draw_line(
					root_offset + pose[chain[index] + side],
					root_offset + pose[chain[index + 1] + side],
					Color.CYAN,
					1.5,
					true
				)
		var hand: Vector2 = pose["rear_grip" if side == "near" else "front_grip"]
		draw_line(root_offset + pose["elbow_" + side], root_offset + hand, Color.CYAN, 1.5, true)
		draw_circle(root_offset + hand, 4.0, Color.YELLOW)
	draw_circle(root_offset + pose.tip, 5.0, Color.ORANGE_RED)
