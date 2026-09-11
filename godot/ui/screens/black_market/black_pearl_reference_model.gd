extends RefCounted
## Same reference-driven method as the elixir: fixed illustration UVs on a
## closed volume, separate curved gold fittings, raised edging and contact shadow.
## Designed for the counter camera. Unseen rear surfaces reuse the front texture.

const ART := preload("res://assets/items/materials/black_pearl.png")
const ART_SIZE := Vector2(1330, 1182)
# The approved silhouette occupies 1142 px, vs 1506 px in the elixir reference.
# Both therefore have the same projected model height before counter perspective.
const PIXEL_SCALE := 1506.0 * 0.00104 / 1142.0
const AXIS_X := 665.0
const FLOOR_PIXEL := 1030.0
const PITCH := 0.3399
const YAW := 0.05449
const PEARL_CENTER := Vector2(649, 477)
const PEARL_RADIUS := Vector2(475, 456)
const PEARL_DEPTH := 450.0

# Individually traced fittings. These are closed, curved solids, not cutout cards.
const CRADLE := [
	Vector2(138, 760),
	Vector2(183, 797),
	Vector2(215, 800),
	Vector2(296, 770),
	Vector2(423, 866),
	Vector2(551, 911),
	Vector2(672, 920),
	Vector2(810, 894),
	Vector2(913, 844),
	Vector2(1086, 645),
	Vector2(1218, 729),
	Vector2(1257, 772),
	Vector2(1267, 851),
	Vector2(1242, 930),
	Vector2(1182, 997),
	Vector2(1089, 1056),
	Vector2(969, 1109),
	Vector2(842, 1144),
	Vector2(723, 1157),
	Vector2(650, 1152),
	Vector2(613, 1139),
	Vector2(577, 1147),
	Vector2(509, 1128),
	Vector2(405, 1098),
	Vector2(293, 1055),
	Vector2(200, 1009),
	Vector2(141, 957),
	Vector2(113, 891),
	Vector2(113, 825)
]
const LEFT_REAR_CLAW := [
	Vector2(179, 540),
	Vector2(145, 569),
	Vector2(112, 611),
	Vector2(98, 656),
	Vector2(100, 701),
	Vector2(122, 759),
	Vector2(170, 812),
	Vector2(220, 839),
	Vector2(251, 798),
	Vector2(212, 747),
	Vector2(193, 691),
	Vector2(174, 636),
	Vector2(170, 582)
]
const LEFT_FRONT_CLAW := [
	Vector2(352, 484),
	Vector2(360, 482),
	Vector2(361, 490),
	Vector2(346, 522),
	Vector2(325, 558),
	Vector2(309, 617),
	Vector2(288, 672),
	Vector2(277, 742),
	Vector2(281, 797),
	Vector2(304, 842),
	Vector2(340, 869),
	Vector2(353, 885),
	Vector2(317, 912),
	Vector2(273, 927),
	Vector2(221, 935),
	Vector2(188, 906),
	Vector2(181, 852),
	Vector2(182, 783),
	Vector2(190, 710),
	Vector2(207, 643),
	Vector2(239, 578),
	Vector2(276, 531),
	Vector2(323, 495)
]
const RIGHT_REAR_CLAW := [
	Vector2(1064, 443),
	Vector2(1093, 413),
	Vector2(1124, 384),
	Vector2(1140, 372),
	Vector2(1161, 378),
	Vector2(1190, 409),
	Vector2(1224, 458),
	Vector2(1247, 509),
	Vector2(1266, 574),
	Vector2(1272, 638),
	Vector2(1265, 703),
	Vector2(1248, 753),
	Vector2(1215, 789),
	Vector2(1173, 812),
	Vector2(1116, 828),
	Vector2(1071, 835),
	Vector2(977, 807),
	Vector2(1001, 769),
	Vector2(1040, 721),
	Vector2(1072, 665),
	Vector2(1094, 608),
	Vector2(1107, 553),
	Vector2(1113, 504),
	Vector2(1104, 469)
]
const RIGHT_FRONT_CLAW := [
	Vector2(1070, 789),
	Vector2(1127, 758),
	Vector2(1171, 721),
	Vector2(1205, 680),
	Vector2(1224, 639),
	Vector2(1238, 683),
	Vector2(1230, 746),
	Vector2(1212, 806),
	Vector2(1184, 862),
	Vector2(1145, 915),
	Vector2(1097, 964),
	Vector2(1036, 1007),
	Vector2(966, 1047),
	Vector2(886, 1080),
	Vector2(790, 1109),
	Vector2(704, 1137),
	Vector2(648, 1154),
	Vector2(619, 1150),
	Vector2(625, 1124),
	Vector2(642, 1094),
	Vector2(673, 1068),
	Vector2(706, 1030),
	Vector2(744, 1000),
	Vector2(797, 971),
	Vector2(844, 940),
	Vector2(874, 908),
	Vector2(879, 876),
	Vector2(877, 844),
	Vector2(886, 832),
	Vector2(925, 824),
	Vector2(983, 807)
]

var host
var pearl_material: StandardMaterial3D
var gold_material: StandardMaterial3D
var _source_image: Image
var _pearl_uv_cache := {}


func build(view) -> void:
	host = view
	_source_image = ART.get_image()
	if _source_image.is_compressed():
		_source_image.decompress()
	pearl_material = _reference_material(0.08, 0.68)
	gold_material = _reference_material(0.18, 0.76)
	_build_pearl()
	_build_fitting(CRADLE, "EngravedGoldCradle", 0, 95.0)
	_build_fitting(LEFT_REAR_CLAW, "LeftRearClaw", 1, 65.0)
	_build_fitting(LEFT_FRONT_CLAW, "LeftSweptClaw", 2, 75.0)
	_build_fitting(RIGHT_REAR_CLAW, "RightCrownClaw", 1, 90.0)
	_build_fitting(RIGHT_FRONT_CLAW, "RightSweptClaw", 2, 90.0)
	_build_ridge(
		[
			Vector2(167, 946),
			Vector2(218, 996),
			Vector2(318, 1043),
			Vector2(432, 1080),
			Vector2(547, 1113),
			Vector2(579, 1128)
		],
		5.0,
		0,
		"LowerGoldBead"
	)
	_build_ridge(
		[
			Vector2(675, 1100),
			Vector2(783, 1065),
			Vector2(894, 1026),
			Vector2(998, 969),
			Vector2(1103, 893),
			Vector2(1183, 793)
		],
		5.0,
		2,
		"CarvedRimRelief"
	)
	_build_ridge(
		[
			Vector2(350, 489),
			Vector2(309, 563),
			Vector2(263, 682),
			Vector2(245, 784),
			Vector2(259, 865)
		],
		3.0,
		2,
		"LeftClawBevel"
	)
	var mesh := PlaneMesh.new()
	mesh.size = Vector2(1.65, 1.12)
	var shader := Shader.new()
	shader.code = (
		"shader_type spatial; render_mode unshaded,cull_disabled,depth_dra"
		+ "w_never; void fragment(){float r=length((UV-vec2(0.5))*2.0); ALBE"
		+ "DO=vec3(0.025,0.012,0.006); ALPHA=0.32*(1.0-smoothstep(0.25,1.0,r"
		+ "));}"
	)
	var mat := ShaderMaterial.new()
	mat.shader = shader
	var contact = host.mesh_node(mesh, Vector3(0, 0.01, 0), mat)
	contact.name = "ContactShadow"
	contact.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _reference_material(metallic: float, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ART
	mat.albedo_color = Color(0.42, 0.42, 0.42)
	mat.metallic = metallic
	mat.metallic_specular = 0.12
	mat.roughness = roughness
	# Same restrained real-light / painted-light balance as the elixir.
	mat.emission_enabled = true
	mat.emission_texture = ART
	mat.emission = Color.WHITE
	mat.emission_operator = BaseMaterial3D.EMISSION_OP_MULTIPLY
	mat.emission_energy_multiplier = 0.58
	return mat


func point(pixel: Vector2, depth_pixels: float) -> Vector3:
	var z := depth_pixels * PIXEL_SCALE
	var y := (FLOOR_PIXEL - pixel.y) * PIXEL_SCALE / cos(PITCH) + z * tan(PITCH) + 0.035
	return Vector3((pixel.x - AXIS_X) * PIXEL_SCALE, y, z).rotated(Vector3.UP, YAW)


func _build_pearl() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	const SIDES := 96
	const RINGS := 48
	for row in RINGS:
		for side in SIDES:
			var vertices: Array[Vector3] = []
			var pixels: Array[Vector2] = []
			for corner: Vector2i in [
				Vector2i(side, row),
				Vector2i(side + 1, row),
				Vector2i(side, row + 1),
				Vector2i(side + 1, row + 1)
			]:
				var latitude := PI * corner.y / RINGS
				var angle := TAU * corner.x / SIDES
				var pixel := (
					PEARL_CENTER + Vector2(cos(angle) * sin(latitude), cos(latitude)) * PEARL_RADIUS
				)
				var depth := sin(angle) * sin(latitude) * PEARL_DEPTH
				vertices.append(point(pixel, depth))
				pixels.append(pixel)
			# Rows run from top to bottom, producing outward-facing normals.
			for index in [0, 1, 2, 1, 3, 2]:
				st.set_uv(_opaque_pearl_uv(pixels[index]))
				st.add_vertex(vertices[index])
	_finish(st, "IridescentPearl", pearl_material)


func _opaque_pearl_uv(pixel: Vector2) -> Vector2:
	if _pearl_uv_cache.has(pixel):
		return _pearl_uv_cache[pixel]
	# A cutout PNG has undefined RGB outside its alpha silhouette. Move only edge
	# UVs slightly inward so rotation cannot reveal those black/red fringe pixels.
	var safe_pixel := pixel
	for step in 16:
		# Inset the sampled optical rim too: stretching that bright cutout edge
		# over the sphere's unseen side would create an artificial golden band.
		safe_pixel = PEARL_CENTER + (pixel - PEARL_CENTER) * (0.94 - step * 0.008)
		var opaque := true
		for offset: Vector2i in [
			Vector2i.ZERO, Vector2i(-3, 0), Vector2i(3, 0), Vector2i(0, -3), Vector2i(0, 3)
		]:
			var sample := Vector2i(safe_pixel) + offset
			if _source_image.get_pixel(sample.x, sample.y).a < 0.98:
				opaque = false
				break
		if opaque:
			break
	var uv := safe_pixel / ART_SIZE
	_pearl_uv_cache[pixel] = uv
	return uv


func _fitting_depth(pixel: Vector2, kind: int) -> float:
	var x := (pixel.x - AXIS_X) / 590.0
	var cradle_depth := sqrt(maxf(0.02, 1.0 - x * x)) * 445.0
	if kind == 0:
		return cradle_depth
	var relative := (pixel - PEARL_CENTER) / PEARL_RADIUS
	var sphere_depth := sqrt(maxf(0, 1.0 - relative.length_squared())) * PEARL_DEPTH
	var lower_blend := smoothstep(780.0, 980.0, pixel.y)
	return lerpf(sphere_depth + (16.0 if kind == 1 else 35.0), cradle_depth + 18.0, lower_blend)


func _build_fitting(outline: Array, node_name: String, kind: int, thickness: float) -> void:
	var polygon := PackedVector2Array(outline)
	var indices := Geometry2D.triangulate_polygon(polygon)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, indices.size(), 3):
		_refine_face(
			st,
			polygon[indices[i]],
			polygon[indices[i + 1]],
			polygon[indices[i + 2]],
			kind,
			0,
			true,
			2
		)
		_refine_face(
			st,
			polygon[indices[i]],
			polygon[indices[i + 1]],
			polygon[indices[i + 2]],
			kind,
			-thickness,
			false,
			2
		)
	# Connect front and rear along every edge: none of the gold parts is a plane.
	for i in polygon.size():
		var a := polygon[i]
		var b := polygon[(i + 1) % polygon.size()]
		for step in 4:
			var p := a.lerp(b, step / 4.0)
			var q := a.lerp(b, (step + 1) / 4.0)
			for vertex in [
				[p, 0.0], [q, 0.0], [p, -thickness], [q, 0.0], [q, -thickness], [p, -thickness]
			]:
				var pixel: Vector2 = vertex[0]
				st.set_uv(pixel / ART_SIZE)
				st.add_vertex(point(pixel, _fitting_depth(pixel, kind) + float(vertex[1])))
	_finish(st, node_name, gold_material)


func _refine_face(
	st: SurfaceTool,
	a: Vector2,
	b: Vector2,
	c: Vector2,
	kind: int,
	offset: float,
	front: bool,
	subdivisions: int
) -> void:
	if subdivisions > 0:
		var ab := (a + b) * 0.5
		var bc := (b + c) * 0.5
		var ca := (c + a) * 0.5
		for triangle in [[a, ab, ca], [ab, b, bc], [ca, bc, c], [ab, bc, ca]]:
			_refine_face(
				st, triangle[0], triangle[1], triangle[2], kind, offset, front, subdivisions - 1
			)
		return
	var pixels := [a, b, c]
	var vertices := [
		point(a, _fitting_depth(a, kind) + offset),
		point(b, _fitting_depth(b, kind) + offset),
		point(c, _fitting_depth(c, kind) + offset)
	]
	var normal: Vector3 = (vertices[1] - vertices[0]).cross(vertices[2] - vertices[0])
	var facing := normal.dot(Vector3.BACK.rotated(Vector3.UP, YAW))
	var order := [0, 1, 2] if (facing > 0) == front else [0, 2, 1]
	for index in order:
		st.set_uv(pixels[index] / ART_SIZE)
		st.add_vertex(vertices[index])


func _build_ridge(path: Array, width: float, kind: int, node_name: String) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in path.size() - 1:
		for step in 6:
			var a: Vector2 = path[i].lerp(path[i + 1], step / 6.0)
			var b: Vector2 = path[i].lerp(path[i + 1], (step + 1) / 6.0)
			var tangent := (b - a).normalized()
			var normal := Vector2(-tangent.y, tangent.x)
			for side in 12:
				var pixels: Array[Vector2] = []
				var vertices: Array[Vector3] = []
				for corner: Vector2i in [
					Vector2i(side, 0),
					Vector2i(side + 1, 0),
					Vector2i(side, 1),
					Vector2i(side + 1, 1)
				]:
					var angle := TAU * corner.x / 12.0
					var center := a if corner.y == 0 else b
					var pixel := center + normal * cos(angle) * width
					pixels.append(pixel)
					vertices.append(
						point(
							pixel, _fitting_depth(center, kind) + width * 0.75 + sin(angle) * width
						)
					)
				for index in [0, 2, 1, 1, 2, 3]:
					st.set_uv(pixels[index] / ART_SIZE)
					st.add_vertex(vertices[index])
	_finish(st, node_name, gold_material)


func _finish(st: SurfaceTool, node_name: String, mat: Material) -> void:
	st.generate_normals()
	st.index()
	var node = host.mesh_node(st.commit(), Vector3.ZERO, mat)
	node.name = node_name
