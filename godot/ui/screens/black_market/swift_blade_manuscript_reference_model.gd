extends RefCounted
## A closed, layered book reconstructed from the approved inventory illustration.
## Fixed UVs, separate leather, pages, curved spine and raised metalwork. The
## single-reference rear reuses the cover art; this is authored for the counter.

const ART := preload("res://assets/items/books/mastery_attack_speed_book.png")
const ART_SIZE := Vector2(1199, 1312)
const PIXEL_SCALE := 1506.0 * 0.00104 / 1290.0
const AXIS_X := 610.0
const FLOOR_PIXEL := 1180.0
const PITCH := 0.3399
const YAW := 0.05449

const COVER := [Vector2(141, 156), Vector2(818, 13), Vector2(1170, 855), Vector2(377, 1042)]
const PAGES := [Vector2(168, 181), Vector2(795, 48), Vector2(1139, 871), Vector2(369, 1054)]
const SPINE_PATH := [
	Vector2(133, 192),
	Vector2(118, 246),
	Vector2(138, 323),
	Vector2(166, 431),
	Vector2(195, 540),
	Vector2(226, 651),
	Vector2(255, 759),
	Vector2(285, 869),
	Vector2(313, 978),
	Vector2(307, 1084),
	Vector2(290, 1153),
	Vector2(318, 1183)
]
const SPINE_WIDTHS := [29.0, 64.0, 59.0, 60.0, 61.0, 62.0, 61.0, 60.0, 57.0, 47.0, 27.0, 16.0]
const CORNERS := [
	[
		Vector2(139, 149),
		Vector2(281, 120),
		Vector2(257, 149),
		Vector2(253, 168),
		Vector2(269, 180),
		Vector2(239, 188),
		Vector2(224, 211),
		Vector2(226, 233),
		Vector2(243, 246),
		Vector2(217, 245),
		Vector2(202, 261),
		Vector2(189, 286)
	],
	[
		Vector2(658, 43),
		Vector2(814, 7),
		Vector2(828, 17),
		Vector2(888, 152),
		Vector2(851, 117),
		Vector2(826, 115),
		Vector2(809, 126),
		Vector2(815, 103),
		Vector2(803, 84),
		Vector2(774, 72),
		Vector2(745, 71),
		Vector2(712, 83),
		Vector2(714, 68),
		Vector2(699, 53)
	],
	[
		Vector2(348, 854),
		Vector2(375, 882),
		Vector2(393, 889),
		Vector2(412, 882),
		Vector2(406, 909),
		Vector2(430, 936),
		Vector2(461, 944),
		Vector2(489, 938),
		Vector2(493, 960),
		Vector2(541, 980),
		Vector2(545, 995),
		Vector2(375, 1042),
		Vector2(383, 1018)
	],
	[
		Vector2(1096, 686),
		Vector2(1106, 690),
		Vector2(1174, 840),
		Vector2(1167, 855),
		Vector2(983, 897),
		Vector2(976, 885),
		Vector2(1007, 862),
		Vector2(1018, 838),
		Vector2(1015, 822),
		Vector2(1005, 815),
		Vector2(1041, 815),
		Vector2(1069, 804),
		Vector2(1082, 782),
		Vector2(1080, 756),
		Vector2(1052, 735),
		Vector2(1085, 726)
	]
]
const BLADES := [
	[
		Vector2(382, 527),
		Vector2(480, 502),
		Vector2(571, 469),
		Vector2(638, 425),
		Vector2(689, 367),
		Vector2(721, 305),
		Vector2(740, 244),
		Vector2(747, 279),
		Vector2(746, 319),
		Vector2(735, 358),
		Vector2(717, 392),
		Vector2(685, 428),
		Vector2(641, 457),
		Vector2(581, 482),
		Vector2(500, 505)
	],
	[
		Vector2(489, 602),
		Vector2(575, 573),
		Vector2(655, 539),
		Vector2(723, 501),
		Vector2(778, 458),
		Vector2(824, 416),
		Vector2(806, 454),
		Vector2(779, 488),
		Vector2(745, 519),
		Vector2(705, 544),
		Vector2(652, 564),
		Vector2(582, 586)
	],
	[
		Vector2(458, 686),
		Vector2(540, 666),
		Vector2(607, 644),
		Vector2(649, 620),
		Vector2(665, 601),
		Vector2(665, 589),
		Vector2(651, 581),
		Vector2(628, 579),
		Vector2(651, 573),
		Vector2(675, 578),
		Vector2(689, 591),
		Vector2(691, 609),
		Vector2(681, 631),
		Vector2(661, 646),
		Vector2(624, 661),
		Vector2(567, 673)
	]
]
const FLOURISHES := [
	[Vector2(329, 490), Vector2(521, 434), Vector2(530, 436), Vector2(530, 444), Vector2(511, 452)],
	[
		Vector2(476, 435),
		Vector2(498, 412),
		Vector2(523, 401),
		Vector2(549, 399),
		Vector2(568, 407),
		Vector2(573, 420),
		Vector2(565, 439),
		Vector2(545, 454),
		Vector2(555, 437),
		Vector2(559, 421),
		Vector2(550, 411),
		Vector2(533, 410),
		Vector2(513, 415)
	],
	[Vector2(389, 574), Vector2(576, 528), Vector2(588, 530), Vector2(584, 537), Vector2(551, 545)],
	[
		Vector2(481, 535),
		Vector2(558, 510),
		Vector2(601, 504),
		Vector2(624, 508),
		Vector2(634, 519),
		Vector2(632, 534),
		Vector2(615, 550),
		Vector2(622, 532),
		Vector2(618, 519),
		Vector2(603, 516),
		Vector2(574, 520)
	],
	[Vector2(421, 652), Vector2(617, 599), Vector2(630, 600), Vector2(627, 609), Vector2(593, 620)]
]
const INNER_GUARDS := [
	[
		Vector2(273, 201),
		Vector2(309, 211),
		Vector2(361, 178),
		Vector2(339, 213),
		Vector2(339, 234),
		Vector2(361, 246),
		Vector2(329, 249),
		Vector2(308, 265),
		Vector2(294, 290),
		Vector2(293, 250)
	],
	[
		Vector2(660, 126),
		Vector2(704, 132),
		Vector2(747, 117),
		Vector2(751, 146),
		Vector2(777, 179),
		Vector2(747, 163),
		Vector2(722, 162),
		Vector2(710, 171),
		Vector2(708, 150),
		Vector2(690, 137)
	],
	[
		Vector2(430, 812),
		Vector2(477, 837),
		Vector2(523, 815),
		Vector2(519, 843),
		Vector2(534, 866),
		Vector2(503, 861),
		Vector2(482, 876),
		Vector2(463, 897),
		Vector2(463, 862)
	],
	[
		Vector2(884, 729),
		Vector2(928, 734),
		Vector2(956, 713),
		Vector2(967, 689),
		Vector2(971, 740),
		Vector2(987, 773),
		Vector2(965, 770),
		Vector2(944, 779),
		Vector2(914, 801),
		Vector2(919, 771),
		Vector2(910, 749)
	]
]

var host
var leather: StandardMaterial3D
var silver: StandardMaterial3D
var paper: StandardMaterial3D
var source_image: Image
var uv_cache := {}
var rest_transform := Transform3D.IDENTITY
var resting_footprint := Vector2.ZERO


func build(view) -> void:
	host = view
	source_image = ART.get_image()
	if source_image.is_compressed():
		source_image.decompress()
	leather = _material(0.02, 0.86)
	silver = _material(0.25, 0.68)
	paper = _material(0.0, 0.95)
	# Back cover and pages are actual volumes between the two offset covers.
	var back: Array = []
	for pixel: Vector2 in COVER:
		back.append(pixel + Vector2(-23, 151))
	_solid(back, "BackLeatherCover", leather, -185, 22)
	_page_block()
	_solid(COVER, "EmbossedLeatherCover", leather, 0, 24)
	_spine()
	for i in CORNERS.size():
		_solid(CORNERS[i], "SilverCorner%d" % i, silver, 9, 14)
	for i in BLADES.size():
		_solid(BLADES[i], "SwiftBladeRelief%d" % i, silver, 10, 11)
	for i in FLOURISHES.size():
		_solid(FLOURISHES[i], "WindInlay%d" % i, silver, 7, 8)
	for i in INNER_GUARDS.size():
		_solid(INNER_GUARDS[i], "InnerSilverGuard%d" % i, silver, 6, 9)
	_solid(
		[
			Vector2(910, 414),
			Vector2(1012, 398),
			Vector2(1034, 402),
			Vector2(1049, 431),
			Vector2(1067, 472),
			Vector2(1066, 499),
			Vector2(1041, 510),
			Vector2(1020, 487),
			Vector2(942, 505)
		],
		"LeatherClasp",
		leather,
		19,
		30
	)
	_solid(
		[
			Vector2(891, 416),
			Vector2(972, 402),
			Vector2(980, 411),
			Vector2(915, 426),
			Vector2(904, 445),
			Vector2(911, 469),
			Vector2(936, 493),
			Vector2(1006, 482),
			Vector2(1011, 494),
			Vector2(930, 514),
			Vector2(899, 485),
			Vector2(864, 473),
			Vector2(879, 451)
		],
		"SilverBuckle",
		silver,
		33,
		15
	)
	_solid(
		[
			Vector2(931, 429),
			Vector2(946, 441),
			Vector2(972, 451),
			Vector2(952, 467),
			Vector2(947, 483),
			Vector2(931, 470),
			Vector2(907, 462),
			Vector2(923, 448)
		],
		"ClaspDiamond",
		silver,
		43,
		13
	)
	for entry in [
		[Vector2(192, 169), 16.0],
		[Vector2(800, 42), 15.0],
		[Vector2(418, 978), 17.0],
		[Vector2(1118, 815), 17.0],
		[Vector2(943, 452), 10.0]
	]:
		_rivet(
			entry[0],
			entry[1],
			"DomedRivet%d" % host.model.get_child_count(),
			52 if entry[0].x == 943 else 23
		)
	_page_edges()
	_lay_flat_on_counter()
	_resting_ribbon()
	_contact_shadow()


func _material(metallic: float, roughness: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ART
	mat.albedo_color = Color(0.42, 0.42, 0.42)
	mat.metallic = metallic
	mat.metallic_specular = 0.12
	mat.roughness = roughness
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


func _depth(pixel: Vector2, ribbon := false, spine := false) -> float:
	if ribbon:
		return (pixel.y - FLOOR_PIXEL + 8.0) / sin(PITCH)
	if spine:
		var best_distance := INF
		var best_center := Vector2.ZERO
		var width := 60.0
		for row in SPINE_PATH.size() - 1:
			var a: Vector2 = SPINE_PATH[row]
			var b: Vector2 = SPINE_PATH[row + 1]
			var t := clampf((pixel - a).dot(b - a) / (b - a).length_squared(), 0, 1)
			var center := a.lerp(b, t)
			var distance := center.distance_to(pixel)
			if distance < best_distance:
				best_distance = distance
				best_center = center
				width = lerpf(SPINE_WIDTHS[row], SPINE_WIDTHS[row + 1], t)
		var relative := best_distance / width
		return (
			_depth(best_center)
			- 70.0
			+ sqrt(maxf(0.0, 1.0 - relative * relative)) * (width * 1.15 + 70.0)
		)
	return 95.0 + (pixel.x - AXIS_X) * 0.08 - (FLOOR_PIXEL - pixel.y) * 0.17


func _uv(pixel: Vector2, toward: Vector2) -> Vector2:
	var key := Vector4(pixel.x, pixel.y, toward.x, toward.y)
	if uv_cache.has(key):
		return uv_cache[key]
	var safe := pixel
	for step in 24:
		safe = pixel.lerp(toward, step * 0.018)
		var opaque := true
		for offset: Vector2i in [
			Vector2i.ZERO, Vector2i(-2, 0), Vector2i(2, 0), Vector2i(0, -2), Vector2i(0, 2)
		]:
			var sample := Vector2i(safe) + offset
			if (
				sample.x < 0
				or sample.y < 0
				or sample.x >= 1199
				or sample.y >= 1312
				or source_image.get_pixel(sample.x, sample.y).a < 0.98
			):
				opaque = false
				break
		if opaque:
			break
	var result := safe / ART_SIZE
	uv_cache[key] = result
	return result


func _solid(
	outline: Array,
	node_name: String,
	mat: Material,
	lift: float,
	thickness: float,
	ribbon := false,
	spine := false
) -> void:
	var polygon := PackedVector2Array(outline)
	# Normalize the traced outline before connecting its side walls. Image Y
	# points down; a positive signed area is clockwise in the reference image.
	var signed_area := 0.0
	for i in polygon.size():
		signed_area += polygon[i].cross(polygon[(i + 1) % polygon.size()])
	if signed_area < 0.0:
		polygon.reverse()
	var indices := Geometry2D.triangulate_polygon(polygon)
	assert(not indices.is_empty(), node_name + " must triangulate")
	var center := Vector2.ZERO
	for pixel: Vector2 in outline:
		center += pixel / outline.size()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(0, indices.size(), 3):
		var pixels := [polygon[indices[i]], polygon[indices[i + 1]], polygon[indices[i + 2]]]
		for front: bool in [true, false]:
			_solid_face(
				st,
				pixels,
				center,
				lift - (0.0 if front else thickness),
				front,
				ribbon,
				spine,
				2 if spine else 0
			)
	for i in polygon.size():
		var a := polygon[i]
		var b := polygon[(i + 1) % polygon.size()]
		var divisions := 4 if spine else 1
		for step in divisions:
			var p := a.lerp(b, float(step) / divisions)
			var q := a.lerp(b, float(step + 1) / divisions)
			var vertices := [
				point(p, _depth(p, ribbon, spine) + lift),
				point(q, _depth(q, ribbon, spine) + lift),
				point(p, _depth(p, ribbon, spine) + lift - thickness),
				point(q, _depth(q, ribbon, spine) + lift - thickness)
			]
			for index in [0, 2, 1, 1, 2, 3]:
				st.set_uv(_uv(p if index in [0, 2] else q, center))
				st.add_vertex(vertices[index])
	_finish(st, node_name, mat)


func _solid_face(
	st: SurfaceTool,
	pixels: Array,
	center: Vector2,
	lift: float,
	front: bool,
	ribbon: bool,
	spine: bool,
	divisions: int
) -> void:
	if divisions > 0:
		var ab: Vector2 = (pixels[0] + pixels[1]) * 0.5
		var bc: Vector2 = (pixels[1] + pixels[2]) * 0.5
		var ca: Vector2 = (pixels[2] + pixels[0]) * 0.5
		for triangle in [
			[pixels[0], ab, ca], [ab, pixels[1], bc], [ca, bc, pixels[2]], [ab, bc, ca]
		]:
			_solid_face(st, triangle, center, lift, front, ribbon, spine, divisions - 1)
		return
	var vertices: Array[Vector3] = []
	for pixel: Vector2 in pixels:
		vertices.append(point(pixel, _depth(pixel, ribbon, spine) + lift))
	_triangle(st, vertices, pixels, center, front)


func _triangle(
	st: SurfaceTool, vertices: Array, pixels: Array, center: Vector2, front: bool
) -> void:
	var normal: Vector3 = (vertices[1] - vertices[0]).cross(vertices[2] - vertices[0])
	var facing := normal.dot(Vector3.BACK.rotated(Vector3.UP, YAW))
	# Godot treats clockwise triangles as front-facing. The old reverse winding
	# exposed the underside of a cover when seen from the low tabletop angle.
	for index in [0, 1, 2] if (facing < 0) == front else [0, 2, 1]:
		st.set_uv(_uv(pixels[index], center))
		st.add_vertex(vertices[index])


func _page_block() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var pixels: Array[Vector2] = []
	var vertices: Array[Vector3] = []
	for rear: bool in [false, true]:
		for pixel: Vector2 in PAGES:
			var p := pixel + (Vector2(-22, 115) if rear else Vector2.ZERO)
			pixels.append(p)
			vertices.append(point(p, _depth(pixel) - (160.0 if rear else 24.0)))
	for face in [
		[0, 1, 2, 3], [7, 6, 5, 4], [0, 4, 5, 1], [1, 5, 6, 2], [2, 6, 7, 3], [3, 7, 4, 0]
	]:
		for index in [0, 1, 2, 0, 2, 3]:
			var vertex_index: int = face[index]
			st.set_uv(_uv(pixels[vertex_index], Vector2(705, 1004)))
			st.add_vertex(vertices[vertex_index])
	_finish(st, "LayeredParchmentBlock", paper)


func _spine() -> void:
	var path := SPINE_PATH
	var widths := SPINE_WIDTHS
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for row in path.size() - 1:
		for slice in 4:
			for side in 32:
				var pixels: Array[Vector2] = []
				var vertices: Array[Vector3] = []
				for corner: Vector2i in [
					Vector2i(side, slice),
					Vector2i(side + 1, slice),
					Vector2i(side, slice + 1),
					Vector2i(side + 1, slice + 1)
				]:
					var t := corner.y / 4.0
					var angle := TAU * corner.x / 32.0
					var center: Vector2 = path[row].lerp(path[row + 1], t)
					var tangent := (
						_spine_tangent(path, row)
						. lerp(_spine_tangent(path, row + 1), t)
						. normalized()
					)
					var width := lerpf(widths[row], widths[row + 1], t)
					var pixel := center + Vector2(tangent.y, -tangent.x) * cos(angle) * width
					pixels.append(pixel)
					# The binding wraps the entire page block, including the back cover.
					vertices.append(
						point(pixel, _depth(center) - 70.0 + sin(angle) * (width * 1.15 + 70.0))
					)
				for index in [0, 2, 1, 1, 2, 3]:
					st.set_uv(_uv(pixels[index], path[row].lerp(path[row + 1], 0.5)))
					st.add_vertex(vertices[index])
	# Close both ends of the rounded spine.
	for endpoint in [0, path.size() - 1]:
		var center: Vector2 = path[endpoint]
		var tangent := _spine_tangent(path, endpoint)
		for side in 32:
			var pixels: Array = [center]
			var vertices: Array = [point(center, _depth(center) - 70.0)]
			for edge: int in [side, side + 1]:
				var angle := TAU * edge / 32.0
				var pixel: Vector2 = (
					center + Vector2(tangent.y, -tangent.x) * cos(angle) * widths[endpoint]
				)
				pixels.append(pixel)
				vertices.append(
					point(
						pixel, _depth(center) - 70.0 + sin(angle) * (widths[endpoint] * 1.15 + 70.0)
					)
				)
			_triangle(st, vertices, pixels, center, endpoint == 0)
	_finish(st, "RoundedLeatherSpine", leather)
	var bands := [
		[
			Vector2(82, 331),
			Vector2(96, 309),
			Vector2(129, 288),
			Vector2(162, 282),
			Vector2(174, 293),
			Vector2(178, 310),
			Vector2(153, 313),
			Vector2(126, 324),
			Vector2(104, 345),
			Vector2(87, 375)
		],
		[
			Vector2(128, 574),
			Vector2(153, 540),
			Vector2(191, 518),
			Vector2(223, 510),
			Vector2(240, 521),
			Vector2(245, 539),
			Vector2(209, 545),
			Vector2(179, 560),
			Vector2(151, 591),
			Vector2(137, 622)
		],
		[
			Vector2(183, 829),
			Vector2(213, 803),
			Vector2(252, 786),
			Vector2(282, 785),
			Vector2(298, 798),
			Vector2(306, 819),
			Vector2(268, 822),
			Vector2(237, 835),
			Vector2(209, 861),
			Vector2(193, 888)
		],
		[
			Vector2(230, 1028),
			Vector2(262, 993),
			Vector2(305, 977),
			Vector2(330, 978),
			Vector2(346, 995),
			Vector2(349, 1010),
			Vector2(310, 1014),
			Vector2(279, 1028),
			Vector2(252, 1056),
			Vector2(241, 1090)
		]
	]
	for i in bands.size():
		_solid(bands[i], "RaisedSpineBand%d" % i, leather, 6, 13, false, true)
	_solid(
		[
			Vector2(111, 407),
			Vector2(129, 422),
			Vector2(153, 428),
			Vector2(139, 460),
			Vector2(125, 514),
			Vector2(110, 490),
			Vector2(103, 457)
		],
		"SpineSilverStud0",
		silver,
		9,
		12,
		false,
		true
	)
	_solid(
		[
			Vector2(161, 652),
			Vector2(179, 669),
			Vector2(206, 677),
			Vector2(192, 711),
			Vector2(182, 764),
			Vector2(163, 735),
			Vector2(156, 699)
		],
		"SpineSilverStud1",
		silver,
		9,
		12,
		false,
		true
	)


func _spine_tangent(path: Array, index: int) -> Vector2:
	return (path[mini(index + 1, path.size() - 1)] - path[maxi(index - 1, 0)]).normalized()


func _rivet(center: Vector2, radius: float, node_name: String, lift: float) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for ring in 8:
		for side in 20:
			var pixels: Array[Vector2] = []
			var vertices: Array[Vector3] = []
			for corner: Vector2i in [
				Vector2i(side, ring),
				Vector2i(side + 1, ring),
				Vector2i(side, ring + 1),
				Vector2i(side + 1, ring + 1)
			]:
				var latitude := PI * corner.y / 8.0
				var angle := TAU * corner.x / 20.0
				var pixel := center + Vector2(cos(angle), sin(angle)) * sin(latitude) * radius
				pixels.append(pixel)
				vertices.append(point(pixel, _depth(center) + lift + cos(latitude) * radius * 0.6))
			for index in [0, 2, 1, 1, 2, 3]:
				st.set_uv(_uv(pixels[index], center))
				st.add_vertex(vertices[index])
	_finish(st, node_name, silver)


func _page_edges() -> void:
	# Individual shallow paper seams on the exposed fore-edge, not a plain box.
	for i in 12:
		var t := (i + 1) / 14.0
		var left := Vector2(376, 1056).lerp(Vector2(351, 1165), t)
		var right := Vector2(1126, 890).lerp(Vector2(1101, 990), t)
		var lift := lerpf(-24, -160, t)
		_solid(
			[left, right, right + Vector2(-0.3, 2.0), left + Vector2(-0.3, 2.0)],
			"ParchmentEdge%02d" % i,
			paper,
			lift + 20,
			3
		)


func _contact_shadow() -> void:
	var mesh := PlaneMesh.new()
	mesh.size = resting_footprint + Vector2(0.10, 0.10)
	var shader := Shader.new()
	shader.code = "shader_type spatial; render_mode unshaded,cull_disabled,depth_draw_never; void fragment(){vec2 p=abs(UV-vec2(0.5))*2.0; float r=length(max(p-vec2(0.68),vec2(0.0)))/0.32; ALBEDO=vec3(0.025,0.012,0.006); ALPHA=0.40*(1.0-smoothstep(0.0,1.0,r));}"
	var mat := ShaderMaterial.new()
	mat.shader = shader
	var contact = host.mesh_node(mesh, Vector3(0, 0.004, 0), mat)
	contact.name = "ContactShadow"
	contact.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _lay_flat_on_counter() -> void:
	# Rotate the actual geometry, not the viewport image. The broad covers must
	# be parallel to the table, with the lower cover touching it over its area.
	var a := point(COVER[0], _depth(COVER[0]))
	var b := point(COVER[1], _depth(COVER[1]))
	var d := point(COVER[3], _depth(COVER[3]))
	var cover_normal := (d - a).cross(b - a).normalized()
	var rest_basis := (
		Basis(Vector3.UP, deg_to_rad(6.0)) * Basis(Quaternion(cover_normal, Vector3.UP))
	)
	var minimum := Vector3(INF, INF, INF)
	var maximum := Vector3(-INF, -INF, -INF)
	var back_bottom := INF
	for part: MeshInstance3D in host.model.get_children():
		var vertices: PackedVector3Array = part.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		for vertex in vertices:
			var resting := rest_basis * vertex
			minimum = minimum.min(resting)
			maximum = maximum.max(resting)
			if part.name == "BackLeatherCover":
				back_bottom = minf(back_bottom, resting.y)
	var offset := Vector3(
		-(minimum.x + maximum.x) * 0.5, 0.018 - back_bottom, -(minimum.z + maximum.z) * 0.5
	)
	rest_transform = Transform3D(rest_basis, offset)
	resting_footprint = Vector2(maximum.x - minimum.x, maximum.z - minimum.z)
	for part: MeshInstance3D in host.model.get_children():
		# Bake the pose so exported geometry and the live view have identical
		# ground contact. The rounded binding compresses slightly against the mat.
		var arrays := part.mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		for i in vertices.size():
			vertices[i] = rest_transform * vertices[i]
			vertices[i].y = maxf(vertices[i].y, 0.012)
		arrays[Mesh.ARRAY_VERTEX] = vertices
		_replace_geometry(part, arrays)


func _resting_ribbon() -> void:
	_solid(
		[
			Vector2(408, 1083),
			Vector2(485, 1067),
			Vector2(508, 1140),
			Vector2(527, 1201),
			Vector2(549, 1242),
			Vector2(591, 1277),
			Vector2(550, 1271),
			Vector2(519, 1250),
			Vector2(501, 1267),
			Vector2(490, 1293),
			Vector2(477, 1274),
			Vector2(455, 1220)
		],
		"CrimsonRibbon",
		leather,
		-132,
		5
	)
	var ribbon: MeshInstance3D = host.model.get_node("CrimsonRibbon")
	var arrays := ribbon.mesh.surface_get_arrays(0)
	var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var uvs: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
	for i in vertices.size():
		vertices[i] = rest_transform * vertices[i]
		# Bend the bookmark down from the pages onto the same physical tabletop.
		var drop := smoothstep(1085.0, 1230.0, uvs[i].y * ART_SIZE.y)
		vertices[i].y = lerpf(maxf(vertices[i].y, 0.016), 0.016, drop)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	_replace_geometry(ribbon, arrays)


func _replace_geometry(part: MeshInstance3D, arrays: Array) -> void:
	# SurfaceTool recomputes the normals after the physical rest pose/ribbon fold.
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var st := SurfaceTool.new()
	st.create_from(mesh, 0)
	st.generate_normals()
	part.mesh = st.commit()


func _finish(st: SurfaceTool, node_name: String, mat: Material) -> void:
	st.generate_normals()
	st.index()
	var node = host.mesh_node(st.commit(), Vector3.ZERO, mat)
	node.name = node_name
