extends RefCounted
## Review-only skinning of the approved PNG. No pixels are cut or repainted.
## This continuous mesh supports a restrained idle, NOT an articulated thrust.

const SIZE := Vector2(1024, 1536)
const STEP := 16
const CYCLE := 5.6
const FACE := Rect2(484, 91, 143, 131)
const BONES := [
	{"id": "root", "parent": "", "at": Vector2.ZERO},
	{"id": "chest", "parent": "root", "at": Vector2(551, 378)},
	{"id": "head", "parent": "chest", "at": Vector2(549, 211)},
	{"id": "hair_back", "parent": "head", "at": Vector2(481, 91)},
	{"id": "hair_side", "parent": "head", "at": Vector2(621, 123)},
	{"id": "cloth_left", "parent": "root", "at": Vector2(451, 577)},
	{"id": "cloth_right", "parent": "root", "at": Vector2(676, 628)},
	{"id": "sleeve", "parent": "chest", "at": Vector2(672, 465)},
	{"id": "weapon", "parent": "root", "at": Vector2(354, 533)},
]
static var _left_cloth := PackedVector2Array(
	[
		Vector2(435, 591),
		Vector2(399, 738),
		Vector2(335, 862),
		Vector2(291, 982),
		Vector2(344, 1123),
		Vector2(330, 1338),
		Vector2(229, 1280),
		Vector2(179, 1197),
		Vector2(88, 1290),
		Vector2(31, 1057),
		Vector2(51, 833),
		Vector2(114, 685),
	]
)
static var _right_cloth := PackedVector2Array(
	[
		Vector2(680, 647),
		Vector2(823, 724),
		Vector2(974, 961),
		Vector2(1020, 1331),
		Vector2(937, 1324),
		Vector2(815, 1101),
		Vector2(762, 961),
		Vector2(679, 841),
	]
)


static func weights_at(point: Vector2) -> PackedFloat32Array:
	var weights := PackedFloat32Array()
	weights.resize(BONES.size())
	weights[0] = 1.0
	var chest := 1.0 - smoothstep(470.0, 858.0, point.y)
	chest *= smoothstep(163.0, 264.0, point.x) * (1.0 - smoothstep(796.0, 864.0, point.x))
	_blend(weights, 1, chest)
	var head := 1.0 - smoothstep(242.0, 310.0, point.y)
	head *= smoothstep(267.0, 308.0, point.x) * (1.0 - smoothstep(706.0, 751.0, point.x))
	_blend(weights, 2, head)
	var face_guard := _box_mask(point, FACE.grow(13.0), 26.0)
	var rear_hair := _box_mask(point, Rect2(309, 30, 168, 233), 42.0)
	_blend(weights, 3, rear_hair * head * (1.0 - face_guard))
	var side_hair := _box_mask(point, Rect2(634, 57, 61, 212), 29.0)
	_blend(weights, 4, side_hair * head * (1.0 - face_guard))
	_blend(weights, 5, _inside_mask(point, _left_cloth, 35.0))
	_blend(weights, 6, _inside_mask(point, _right_cloth, 35.0))
	var sleeve := _box_mask(point, Rect2(704, 531, 124, 190), 43.0)
	_blend(weights, 7, sleeve)
	# A rigid corridor encloses the WHOLE painted lance, including its gold guards.
	# Keep a transition outside that corridor so adjacent fabric does not tear.
	var top := Vector2(15, 26)
	var bottom := Vector2(1008, 1468)
	var closest := Geometry2D.get_closest_point_to_segment(point, top, bottom)
	var radius := 20.0
	if point.y < 270.0 or point.y > 900.0:
		radius = 68.0
	var weapon := 1.0 - smoothstep(radius, radius + 32.0, point.distance_to(closest))
	var grip := _ellipse_mask(point, Vector2(344, 520), Vector2(65, 64))
	_blend(weights, 8, maxf(weapon, grip))
	# The face has exactly one influence: no rubbery eye/nose/mouth deformation.
	if FACE.grow(6.0).has_point(point):
		_blend(weights, 2, 1.0)
	# Boot soles never participate in breathing or secondary cloth motion.
	if Rect2(352, 1200, 185, 177).has_point(point) or Rect2(570, 1260, 224, 186).has_point(point):
		_blend(weights, 0, 1.0)
	# Godot's Polygon2D renderer supports four bone influences per vertex.
	var ranked: Array[int] = []
	for index in weights.size():
		ranked.append(index)
	ranked.sort_custom(func(a: int, b: int) -> bool: return weights[a] > weights[b])
	for index in range(4, ranked.size()):
		weights[ranked[index]] = 0.0
	var total := 0.0
	for weight in weights:
		total += weight
	for index in weights.size():
		weights[index] /= total
	return weights


static func pose(phase: float, strength := 1.0) -> Dictionary:
	var p := fposmod(phase, TAU)
	var amount := clampf(strength, 0.0, 1.5)
	var breath := sin(p)
	var drift := sin(p) * 0.72 + sin(p * 2.0) * 0.14
	var lag := sin(p - 0.7) + sin(0.7)
	var result := {}
	for data: Dictionary in BONES:
		result[data.id] = {"offset": Vector2.ZERO, "angle": 0.0}
	result.chest.offset = Vector2(1.7 * drift, -4.6 * breath) * amount
	result.chest.angle = 0.0018 * drift * amount
	result.head.offset = Vector2(0.9 * drift, -0.55 * breath) * amount
	result.head.angle = -0.0035 * drift * amount
	result.hair_back.angle = 0.014 * lag * amount
	result.hair_side.angle = -0.020 * lag * amount
	result.cloth_left.angle = 0.010 * drift * amount
	result.cloth_right.angle = -0.009 * lag * amount
	result.sleeve.angle = 0.012 * lag * amount
	return result


static func _blend(weights: PackedFloat32Array, index: int, amount: float) -> void:
	var blend := clampf(amount, 0.0, 1.0)
	for key in weights.size():
		weights[key] *= 1.0 - blend
	weights[index] += blend


static func _box_mask(point: Vector2, rect: Rect2, feather: float) -> float:
	var outside := Vector2(
		maxf(rect.position.x - point.x, point.x - rect.end.x),
		maxf(rect.position.y - point.y, point.y - rect.end.y)
	)
	return 1.0 - smoothstep(0.0, feather, maxf(outside.x, outside.y))


static func _ellipse_mask(point: Vector2, center: Vector2, radius: Vector2) -> float:
	return 1.0 - smoothstep(0.8, 1.3, ((point - center) / radius).length())


static func _inside_mask(point: Vector2, outline: PackedVector2Array, feather: float) -> float:
	if not Geometry2D.is_point_in_polygon(point, outline):
		return 0.0
	var distance := INF
	for index in outline.size():
		var edge := Geometry2D.get_closest_point_to_segment(
			point, outline[index], outline[(index + 1) % outline.size()]
		)
		distance = minf(distance, point.distance_to(edge))
	return smoothstep(0.0, feather, distance)
