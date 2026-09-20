class_name CombatDie
extends Control
## A lit, bevelled cube projected into CanvasItem: no viewport, physics or RNG.
## Opposite faces sum to seven; the largest settled face is the reported result.
const FACES := [
	[1, Vector3(0, 0, 1), Vector3(1, 0, 0), Vector3(0, 1, 0)],
	[6, Vector3(0, 0, -1), Vector3(-1, 0, 0), Vector3(0, 1, 0)],
	[3, Vector3(1, 0, 0), Vector3(0, 0, -1), Vector3(0, 1, 0)],
	[4, Vector3(-1, 0, 0), Vector3(0, 0, 1), Vector3(0, 1, 0)],
	[2, Vector3(0, 1, 0), Vector3(1, 0, 0), Vector3(0, 0, -1)],
	[5, Vector3(0, -1, 0), Vector3(1, 0, 0), Vector3(0, 0, 1)],
]
const GOLD := Color(0.7, 0.46, 0.2)
const IVORY := Color(0.98, 0.88, 0.71)
var value := 1
var rolling := false
var roll_progress := 1.0
var _pose := Basis.IDENTITY
var _lift := 0.0
var _shift := 0.0
var _squash := 0.0


func _ready() -> void:
	set_value(value)
	resized.connect(queue_redraw)


func set_value(next_value: int, settled := true) -> void:
	value = clampi(next_value, 1, 6)
	sample_roll(1.0 if settled else 0.0)


func sample_roll(progress: float, index := 0) -> void:
	roll_progress = clampf(progress, 0.0, 1.0)
	rolling = roll_progress < 1.0
	var t := roll_progress
	var remaining := pow(1.0 - t, 2.2)
	var direction := 1.0 if index % 2 == 0 else -1.0
	var turns := Vector3(8.4 + index * 0.7, -6.2 * direction, 3.5 * direction)
	_pose = Basis.from_euler(turns * remaining) * settled_pose(value)
	_lift = 0.0
	if t < 0.6:
		_lift = sin(PI * t / 0.6) * 14.0
	elif t < 0.85:
		_lift = sin(PI * (t - 0.6) / 0.25) * 5.0
	_shift = sin(TAU * t) * 5.0 * (1.0 - t) * direction
	_squash = (
		(exp(-pow((t - 0.6) / 0.035, 2)) + 0.5 * exp(-pow((t - 0.85) / 0.025, 2))) * 0.09
		if rolling
		else 0.0
	)
	tooltip_text = "Kość k6 w ruchu" if rolling else "Kość k6 — wynik %d" % value
	queue_redraw()


static func settled_pose(result: int) -> Basis:
	var face := Basis.IDENTITY
	match result:
		2:
			face = Basis(Vector3.RIGHT, PI / 2)
		3:
			face = Basis(Vector3.UP, -PI / 2)
		4:
			face = Basis(Vector3.UP, PI / 2)
		5:
			face = Basis(Vector3.RIGHT, -PI / 2)
		6:
			face = Basis(Vector3.UP, PI)
	return Basis.from_euler(Vector3(0.24, -0.29, -0.045)) * face


static func pip_positions(result: int) -> Array[Vector2]:
	var pips: Array[Vector2] = []
	if result in [1, 3, 5]:
		pips.append(Vector2.ZERO)
	if result >= 2:
		pips.append(Vector2(-0.44, 0.44))
		pips.append(Vector2(0.44, -0.44))
	if result >= 4:
		pips.append(Vector2(0.44, 0.44))
		pips.append(Vector2(-0.44, -0.44))
	if result == 6:
		pips.append(Vector2(-0.44, 0))
		pips.append(Vector2(0.44, 0))
	return pips


func _draw() -> void:
	var center := Vector2(size.x * 0.5, size.y * 0.56)
	var radius := minf(size.x, size.y) * 0.25
	for layer in 3:
		var shadow := PackedVector2Array()
		for step in 32:
			var angle := TAU * step / 32.0
			shadow.append(
				(
					Vector2(size.x * 0.5, size.y * 0.91)
					+ Vector2(cos(angle) * (28.0 - layer * 4), sin(angle) * (5.0 - layer))
				)
			)
		draw_colored_polygon(shadow, Color(0.0, 0.0, 0.0, 0.13 + layer * 0.04))
	center += Vector2(_shift, -_lift)
	for face: Array in _visible_faces():
		_draw_face(face, center, radius)


func _visible_faces() -> Array[Array]:
	var faces: Array[Array] = []
	for face: Array in FACES:
		var normal: Vector3 = _pose * face[1]
		if normal.z > 0.001:
			faces.append(face)
	faces.sort_custom(func(a: Array, b: Array) -> bool: return (_pose * a[1]).z < (_pose * b[1]).z)
	return faces


func _draw_face(face: Array, center: Vector2, radius: float) -> void:
	var normal: Vector3 = _pose * face[1]
	var brightness := clampf(0.58 + normal.dot(Vector3(-0.4, 0.7, 1).normalized()) * 0.42, 0.4, 1.0)
	var outer := PackedVector2Array()
	for corner: Vector2 in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		outer.append(_project(face, corner, center, radius))
	draw_colored_polygon(outer, Color(0.36, 0.21, 0.1))
	var bevel := PackedVector2Array()
	var colors := PackedColorArray()
	for corner: Vector2 in [
		Vector2(-0.76, -0.94),
		Vector2(0.76, -0.94),
		Vector2(0.94, -0.76),
		Vector2(0.94, 0.76),
		Vector2(0.76, 0.94),
		Vector2(-0.76, 0.94),
		Vector2(-0.94, 0.76),
		Vector2(-0.94, -0.76)
	]:
		bevel.append(_project(face, corner, center, radius))
		var light := clampf(brightness + corner.y * 0.07 - corner.x * 0.03, 0.4, 1.0)
		colors.append(IVORY * Color(light, light, light, 1))
	draw_polygon(bevel, colors)
	bevel.append(bevel[0])
	draw_polyline(bevel, GOLD.lightened(brightness * 0.25), 1.2, true)
	for pip: Vector2 in pip_positions(int(face[0])):
		_draw_pip(face, pip, center, radius, brightness)


func _draw_pip(face: Array, pip: Vector2, center: Vector2, radius: float, light: float) -> void:
	var rim := PackedVector2Array()
	var inset := PackedVector2Array()
	var width := 0.18 if int(face[0]) == 1 else 0.145
	for step in 20:
		var direction := Vector2.from_angle(TAU * step / 20.0)
		rim.append(_project(face, pip + direction * width, center, radius))
		inset.append(_project(face, pip + direction * (width - 0.035), center, radius))
	draw_colored_polygon(rim, Color(0.53, 0.3, 0.14) * Color(light, light, light, 1))
	draw_colored_polygon(inset, Color(0.3, 0.025, 0.065))


func _project(face: Array, point: Vector2, center: Vector2, radius: float) -> Vector2:
	var vertex: Vector3 = _pose * (face[1] + face[2] * point.x + face[3] * point.y)
	return center + Vector2(vertex.x * (1.0 + _squash), -vertex.y * (1.0 - _squash)) * radius
