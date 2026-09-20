extends Control
## Local, deterministic reaction. Never resolves combat or consumes RNG.
signal impact
signal finished

const IMPACT_POINT := 0.30
var destination := Vector2.ZERO
var progress := 0.0
var tone := "damage"
var _actor: Control
var _target: Control
var _poses: Array[Dictionary] = []
var _tween: Tween
var _impacted := false
var _done := false
var _direction := 1.0


func start(actor: Control, target: Control, event: Dictionary, duration_scale: float) -> void:
	name = "CombatHitEffect"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_actor = actor
	_target = target
	tone = str(event.get("tone", "critical" if event.get("critical", false) else "damage"))
	_direction = 1.0 if str(event.get("target", "enemy")) == "enemy" else -1.0
	# Bleeding, aura and reflected damage must not invent another attack.
	if not bool(event.get("direct_attack", true)):
		_actor = null
	for visual: Control in [_actor, _target]:
		if is_instance_valid(visual):
			_poses.append(
				{"node": visual, "rotation": visual.rotation, "pivot": visual.pivot_offset}
			)
	_sample(0.0)
	_tween = create_tween()
	_tween.tween_method(_sample, 0.0, 1.0, maxf(0.001, 0.56 * duration_scale))
	_tween.tween_callback(_finish)


func _sample(value: float) -> void:
	if _done:
		return
	progress = value
	var advance := sin(PI * minf(value / 0.62, 1.0))
	var recoil := sin(PI * clampf((value - IMPACT_POINT) / (1.0 - IMPACT_POINT), 0.0, 1.0))
	for pose: Dictionary in _poses:
		var visual: Control = pose.node
		if not is_instance_valid(visual):
			continue
		visual.pivot_offset = visual.size * Vector2(0.5, 0.97)
		var angle := advance * 0.034
		if visual == _target:
			angle = recoil * (0.012 if tone == "block" else 0.028)
			if tone == "critical":
				angle *= 1.6
			elif tone == "dodge":
				angle = advance * 0.065
		visual.rotation = float(pose.rotation) + angle * _direction
	if is_instance_valid(_target):
		var rect := painted_rect(_target)
		destination = rect.position + rect.size * Vector2(0.45, 0.45) - global_position
	if value >= IMPACT_POINT and not _impacted:
		_impacted = true
		impact.emit()
	queue_redraw()


func _draw() -> void:
	var phase := clampf((progress - IMPACT_POINT) / 0.5, 0.0, 1.0)
	if progress < IMPACT_POINT or phase >= 1.0:
		return
	var color := Color(1.0, 0.83, 0.48, 1.0 - phase)
	var radius := lerpf(12.0, 54.0 if tone == "critical" else 34.0, phase)
	if tone == "block":
		color = Color(0.67, 0.83, 1.0, 1.0 - phase)
		draw_arc(destination, 38.0 + phase * 12.0, -PI * 0.7, PI * 0.7, 24, color, 3.0, true)
		draw_line(destination + Vector2(-12, -25), destination + Vector2(12, 25), color, 2, true)
	elif tone == "dodge":
		color = Color(0.62, 0.86, 1.0, (1.0 - phase) * 0.65)
		for index in 3:
			var offset := Vector2(-24 - index * 9, -20 + index * 17)
			draw_line(destination + offset, destination + offset + Vector2(32, -8), color, 2, true)
	else:
		for index in 8 if tone == "critical" else 5:
			var direction := Vector2.from_angle(index * TAU / (8.0 if tone == "critical" else 5.0))
			draw_line(
				destination + direction * radius * 0.45,
				destination + direction * radius,
				color,
				3,
				true
			)
		draw_line(
			destination + Vector2(-radius, radius),
			destination + Vector2(radius, -radius),
			color,
			4,
			true
		)


func cancel() -> void:
	if _tween:
		_tween.kill()
	_finish()


func _finish() -> void:
	if _done:
		return
	_done = true
	_restore()
	finished.emit()


func _exit_tree() -> void:
	_restore()


func _restore() -> void:
	for pose: Dictionary in _poses:
		if is_instance_valid(pose.node):
			pose.node.rotation = pose.rotation
			pose.node.pivot_offset = pose.pivot


static func painted_rect(visual: Control) -> Rect2:
	var texture := visual.get("static_texture") as TextureRect
	if texture != null and texture.visible and texture.texture != null:
		return texture.get_global_rect()
	return visual.get_global_rect()
