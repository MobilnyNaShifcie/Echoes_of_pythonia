extends Node2D
## Native weighted idle study. Never loaded by the production combat scene.

const SkinData := preload("res://tools/pierrot_native/portrait_skin.gd")
const SOURCE := preload("res://assets/combat/heroes/pierrot.png")

var strength := 1.0
var phase := 0.0:
	set(value):
		phase = value
		_apply_pose()
var skeleton: Skeleton2D
var mesh: Polygon2D
var player: AnimationPlayer
var bones: Dictionary = {}
var bind_global: Dictionary = {}
var vertex_weights: Array[PackedFloat32Array] = []
var debug_guides := false
var _guide_canvas: Node2D


func _ready() -> void:
	skeleton = Skeleton2D.new()
	skeleton.name = "Skeleton2D"
	add_child(skeleton)
	_build_bones()
	_build_mesh()
	_build_animation()
	_guide_canvas = Node2D.new()
	_guide_canvas.draw.connect(_draw_bone_guides)
	add_child(_guide_canvas)
	apply_rest()


func apply_rest() -> void:
	if player != null:
		player.pause()
	phase = 0.0


func seek(seconds: float) -> void:
	player.pause()
	phase = TAU * clampf(seconds, 0.0, SkinData.CYCLE) / SkinData.CYCLE


func set_strength(value: float) -> void:
	strength = clampf(value, 0.0, 1.5)
	_apply_pose()


func set_playing(active: bool) -> void:
	if active:
		var seconds := fposmod(phase, TAU) / TAU * SkinData.CYCLE
		player.play("idle")
		player.seek(seconds, true)
	else:
		player.pause()


func point_in_pose(point: Vector2) -> Vector2:
	var weights := SkinData.weights_at(point)
	var result := Vector2.ZERO
	for index in SkinData.BONES.size():
		var id: String = SkinData.BONES[index].id
		var transform: Transform2D = (
			skeleton.global_transform.affine_inverse() * bones[id].global_transform
		)
		result += (transform * bind_global[id].affine_inverse() * point) * weights[index]
	return result


func _build_bones() -> void:
	for data: Dictionary in SkinData.BONES:
		var parent: Node2D = skeleton if data.parent.is_empty() else bones[data.parent]
		var bone := Bone2D.new()
		bone.name = data.id
		bone.set_autocalculate_length_and_angle(false)
		bone.set_length(36.0)
		bone.set_bone_angle(-PI * 0.5)
		parent.add_child(bone)
		bone.position = parent.to_local(skeleton.to_global(data.at))
		bone.rest = bone.transform
		bones[data.id] = bone
		bind_global[data.id] = Transform2D(0.0, data.at)


func _build_mesh() -> void:
	mesh = Polygon2D.new()
	mesh.name = "ApprovedPortraitMesh"
	mesh.texture = SOURCE
	mesh.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	add_child(mesh)
	mesh.skeleton = mesh.get_path_to(skeleton)
	var vertices := PackedVector2Array()
	var triangles: Array[PackedInt32Array] = []
	var columns := int(SkinData.SIZE.x / SkinData.STEP) + 1
	var rows := int(SkinData.SIZE.y / SkinData.STEP) + 1
	for y in rows:
		for x in columns:
			var point := Vector2(x * SkinData.STEP, y * SkinData.STEP)
			vertices.append(point)
			vertex_weights.append(SkinData.weights_at(point))
	for y in rows - 1:
		for x in columns - 1:
			var at: int = y * columns + x
			triangles.append(PackedInt32Array([at, at + 1, at + columns]))
			triangles.append(PackedInt32Array([at + 1, at + columns + 1, at + columns]))
	mesh.polygon = vertices
	mesh.uv = vertices
	mesh.polygons = triangles
	for index in SkinData.BONES.size():
		var weights := PackedFloat32Array()
		for vertex in vertex_weights:
			weights.append(vertex[index])
		mesh.add_bone(skeleton.get_path_to(bones[SkinData.BONES[index].id]), weights)


func _build_animation() -> void:
	player = AnimationPlayer.new()
	player.name = "AnimationPlayer"
	add_child(player)
	var animation := Animation.new()
	animation.length = SkinData.CYCLE
	animation.loop_mode = Animation.LOOP_LINEAR
	var track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, NodePath(".:phase"))
	animation.track_insert_key(track, 0.0, 0.0)
	animation.track_insert_key(track, SkinData.CYCLE, TAU)
	var library := AnimationLibrary.new()
	library.add_animation("idle", animation)
	player.add_animation_library("", library)


func _apply_pose() -> void:
	if bones.is_empty():
		return
	var sampled := SkinData.pose(phase, strength)
	for data: Dictionary in SkinData.BONES:
		var bone: Bone2D = bones[data.id]
		bone.transform = bone.rest
		bone.position += sampled[data.id].offset
		bone.rotation += sampled[data.id].angle
	queue_redraw()


func _draw() -> void:
	if _guide_canvas != null:
		_guide_canvas.queue_redraw()


func _draw_bone_guides() -> void:
	if not debug_guides or skeleton == null:
		return
	for data: Dictionary in SkinData.BONES:
		if data.id == "root":
			continue
		var bone: Bone2D = bones[data.id]
		var from := to_local(bone.global_position)
		var to := to_local(bone.to_global(Vector2(0, -36)))
		_guide_canvas.draw_line(from, to, Color(0.35, 0.88, 0.82, 0.9), 2, true)
		_guide_canvas.draw_circle(from, 5, Color(0.92, 0.75, 0.4))
