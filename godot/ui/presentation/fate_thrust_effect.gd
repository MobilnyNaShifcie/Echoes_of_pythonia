extends Control
## One presentation-only thrust. Never rolls dice, spends resources or resolves damage.

signal impact
signal finished

const STREAK := preload("res://assets/combat/vfx/pierrot/fate_thrust_streak.png")
const DURATION := 0.92
const IMPACT_POINT := 0.56
const ROSE := Color(1.0, 0.19, 0.43)
const IVORY := Color(1.0, 0.88, 0.84)
const GOLD := Color(1.0, 0.74, 0.35)

var progress := 0.0
var origin := Vector2.ZERO
var destination := Vector2.ZERO
var projectile_tip := Vector2.ZERO
var jackpot := false
var follow_up := false
var _actor: Control
var _target: Control
var _actor_rotation := 0.0
var _actor_pivot := Vector2.ZERO
var _actor_tint := Color.WHITE
var _impact_sent := false
var _done := false
var _tween: Tween


func _init() -> void:
	name = "FateThrustEffect"
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func start(actor: Control, target: Control, event: Dictionary, duration_scale: float) -> void:
	_actor = actor
	_target = target
	_actor_rotation = actor.rotation
	_actor_pivot = actor.pivot_offset
	_actor_tint = actor.modulate
	jackpot = int(event.get("fate_face", 0)) == 6
	follow_up = int(event.get("hit_index", 0)) > 0
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_sample(0.0)
	_tween = create_tween()
	var duration := DURATION * (0.78 if follow_up else 1.0) * duration_scale
	_tween.tween_method(_sample, 0.0, 1.0, maxf(0.001, duration))
	_tween.tween_callback(_finish)


func cancel() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_finish()


func _exit_tree() -> void:
	_restore_actor()


func _finish() -> void:
	if _done:
		return
	_done = true
	_restore_actor()
	hide()
	finished.emit()


func _restore_actor() -> void:
	if is_instance_valid(_actor):
		_actor.rotation = _actor_rotation
		_actor.pivot_offset = _actor_pivot
		_actor.modulate = _actor_tint


func _sample(value: float) -> void:
	progress = value
	if not is_instance_valid(_actor) or not is_instance_valid(_target):
		cancel()
		return
	# A slight anticipation/recoil around the feet; never slide the ground anchor.
	var anticipation := sin(PI * clampf(value / 0.28, 0.0, 1.0))
	var recoil := sin(PI * clampf((value - 0.28) / 0.46, 0.0, 1.0))
	_actor.pivot_offset = Vector2(_actor.size.x * 0.5, _actor.size.y * 0.965)
	_actor.rotation = _actor_rotation - anticipation * 0.012 + recoil * 0.018
	_actor.modulate = _actor_tint.lerp(Color(1.0, 0.82, 0.89), anticipation * 0.2)
	_update_geometry()
	if value >= IMPACT_POINT and not _impact_sent:
		_impact_sent = true
		impact.emit()
	queue_redraw()


func _painted_rect(visual: Control) -> Rect2:
	var painted := visual.get("static_texture") as TextureRect
	if painted != null and painted.visible and painted.texture != null:
		return painted.get_global_rect()
	return visual.get_global_rect()


func _update_geometry() -> void:
	var actor_rect := _painted_rect(_actor)
	var target_rect := _painted_rect(_target)
	var canvas_origin := get_global_rect().position
	origin = actor_rect.position + actor_rect.size * Vector2(0.72, 0.54) - canvas_origin
	destination = target_rect.position + target_rect.size * Vector2(0.45, 0.48) - canvas_origin
	var flight := clampf((progress - 0.28) / (IMPACT_POINT - 0.28), 0.0, 1.0)
	projectile_tip = origin.lerp(destination, flight * flight * (3.0 - 2.0 * flight))


func _draw() -> void:
	if _done or not is_instance_valid(_actor):
		return
	var unit := clampf(size.y / 900.0, 0.55, 1.65)
	var direction := origin.direction_to(destination)
	var angle := direction.angle()
	var tint := GOLD if jackpot else ROSE
	_draw_charge(unit, tint)
	if progress >= 0.26 and progress < 0.69:
		var fade := 1.0 - clampf((progress - IMPACT_POINT) / 0.13, 0.0, 1.0)
		var stretch := smoothstep(0.26, 0.37, progress)
		var length := minf(370.0 * unit, origin.distance_to(destination) * 0.65)
		length *= lerpf(0.32, 1.0, stretch)
		var extent := Vector2(length, length / 3.0)
		# The painted tip lies at 90% of the transparent sprite, on its midline.
		draw_set_transform(projectile_tip, angle)
		draw_texture_rect(
			STREAK, Rect2(-extent * Vector2(0.90, 0.50), extent), false, Color(1.0, 1.0, 1.0, fade)
		)
		draw_set_transform(Vector2.ZERO)
		_draw_trail(direction, unit, fade)
	if progress >= IMPACT_POINT:
		_draw_impact(unit, tint, angle)


func _draw_charge(unit: float, tint: Color) -> void:
	var charge := smoothstep(0.0, 0.20, progress)
	var alpha := charge * (1.0 - smoothstep(0.25, 0.38, progress))
	if alpha <= 0.0:
		return
	var radius := lerpf(40.0, 15.0, charge) * unit
	for index in 4:
		var angle := float(index) * TAU / 4.0 + progress * 1.4
		var center := origin + Vector2.from_angle(angle) * radius
		_diamond(center, Vector2(4.0, 9.0) * unit, angle, Color(tint, alpha * 0.85))
	_diamond(origin, Vector2(5.0, 15.0) * unit * charge, 0.0, Color(IVORY, alpha))


func _draw_trail(direction: Vector2, unit: float, alpha: float) -> void:
	var travelled := origin.distance_to(projectile_tip)
	if travelled < 10.0:
		return
	var perpendicular := direction.orthogonal()
	for index in 2:
		var start := projectile_tip - direction * minf(travelled, (280.0 + index * 70.0) * unit)
		var offset := perpendicular * (8.0 if index == 0 else -8.0) * unit
		var polygon := PackedVector2Array(
			[
				start + offset,
				projectile_tip - direction * 30.0 * unit + offset * 0.2,
				projectile_tip - direction * 65.0 * unit + offset * 0.4,
			]
		)
		draw_colored_polygon(polygon, Color(ROSE if index == 0 else IVORY, alpha * 0.45))


func _draw_impact(unit: float, tint: Color, angle: float) -> void:
	var age := (progress - IMPACT_POINT) / (1.0 - IMPACT_POINT)
	var fade := pow(1.0 - age, 1.6)
	var spread := 1.0 - pow(1.0 - age, 3.0)
	var strength := 1.25 if jackpot else 1.0
	var center := destination
	# A controlled, local diamond burst. No full-screen white flash or camera shake.
	_diamond(
		center,
		Vector2(18.0, 86.0) * unit * strength * (0.65 + spread),
		angle + 0.3,
		Color(tint, fade * 0.75)
	)
	_diamond(
		center,
		Vector2(9.0, 55.0) * unit * strength * (0.65 + spread),
		angle + 0.3,
		Color(IVORY, fade)
	)
	_diamond(
		center,
		Vector2(6.0, 72.0) * unit * strength * (0.65 + spread),
		angle + PI * 0.5,
		Color(IVORY, fade * 0.9)
	)
	for index in 7:
		var ray := float(index) * TAU / 7.0 + 0.23
		var point := center + Vector2.from_angle(ray) * (18.0 + spread * 85.0) * unit
		var dimensions := Vector2(3.0, 10.0 + index % 3 * 3.0) * unit * (1.0 - age * 0.7)
		_diamond(
			point,
			dimensions,
			ray + PI * 0.5,
			Color(GOLD if jackpot and index % 2 == 0 else ROSE, fade)
		)


func _diamond(center: Vector2, dimensions: Vector2, angle: float, color: Color) -> void:
	var points := PackedVector2Array()
	for point in [
		Vector2(0, -dimensions.y),
		Vector2(dimensions.x, 0),
		Vector2(0, dimensions.y),
		Vector2(-dimensions.x, 0)
	]:
		points.append(center + point.rotated(angle))
	draw_colored_polygon(points, color)
