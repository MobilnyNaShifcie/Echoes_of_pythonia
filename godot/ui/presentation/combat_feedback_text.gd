extends Label
## Short-lived, non-interactive feedback anchored to the painted silhouette.
const HitEffect := preload("res://ui/presentation/combat_hit_effect.gd")
var target: Control
var hud: Control
var lane := 0
var reduced := false
var lifetime := 0.95
var _elapsed := 0.0


func setup(
	visual: Control, message: String, tone: String, color: Color, limited_motion: bool
) -> void:
	target = visual
	reduced = limited_motion
	lifetime = 1.6 if reduced else 0.95
	text = message.replace("  •  ", "\n")
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 40 if tone == "critical" else 32)
	add_theme_color_override("font_color", color)
	add_theme_color_override("font_outline_color", Color(0.035, 0.022, 0.03, 1))
	add_theme_constant_override("outline_size", 8)
	_update_position()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= lifetime or not is_instance_valid(target):
		queue_free()
		return
	if not reduced:
		modulate.a = 1.0 - clampf((_elapsed - 0.55) / 0.4, 0.0, 1.0)
	_update_position()


func _update_position() -> void:
	if not is_instance_valid(target):
		return
	var host := get_parent() as Control
	if host == null:
		return
	size = get_minimum_size().max(Vector2(220, 50))
	var rect := HitEffect.painted_rect(target)
	var point := rect.position + Vector2(rect.size.x * 0.5, -size.y * 0.7)
	point -= host.global_position + Vector2(size.x * 0.5, 0)
	if not reduced:
		point.y -= 26.0 * minf(_elapsed / 0.55, 1.0)
	# Stack downward below the HUD, never over HP/mana or another reaction.
	if is_instance_valid(hud):
		point.y = maxf(point.y, hud.get_global_rect().end.y - host.global_position.y + 12)
	point.y += lane * 120
	position = point.clamp(Vector2(8, 8), (host.size - size - Vector2(8, 8)).max(Vector2(8, 8)))
