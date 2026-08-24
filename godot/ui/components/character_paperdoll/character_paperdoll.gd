class_name CharacterPaperdoll
extends Control

@export var accent_color := Color(0.36, 0.47, 0.62, 0.72)
@export var caption := "MIEJSCE NA GRAFIKĘ POSTACI"

var _character_texture: Texture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func show_character(texture: Texture2D, fallback_caption := "MIEJSCE NA GRAFIKĘ POSTACI") -> void:
	_character_texture = texture
	caption = fallback_caption
	queue_redraw()


func character_texture() -> Texture2D:
	return _character_texture


func _draw() -> void:
	if _character_texture != null:
		_draw_character_texture()
		return
	var center := Vector2(size.x * 0.5, size.y * 0.46)
	var scale_factor := minf(size.x / 360.0, size.y / 520.0)
	var outline := Color(accent_color, 0.58)
	var fill := Color(0.055, 0.075, 0.105, 0.34)
	var head_center := center + Vector2(0, -154) * scale_factor
	draw_circle(head_center, 39.0 * scale_factor, fill)
	draw_arc(head_center, 39.0 * scale_factor, 0, TAU, 48, outline, 2.0)
	var torso := PackedVector2Array(
		[
			center + Vector2(-72, -106) * scale_factor,
			center + Vector2(72, -106) * scale_factor,
			center + Vector2(50, 92) * scale_factor,
			center + Vector2(-50, 92) * scale_factor,
		]
	)
	draw_colored_polygon(torso, fill)
	for index in torso.size():
		draw_line(torso[index], torso[(index + 1) % torso.size()], outline, 2.0)
	_draw_limb(
		center + Vector2(-60, -86) * scale_factor,
		center + Vector2(-112, 92) * scale_factor,
		outline
	)
	_draw_limb(
		center + Vector2(60, -86) * scale_factor, center + Vector2(112, 92) * scale_factor, outline
	)
	_draw_limb(
		center + Vector2(-28, 86) * scale_factor, center + Vector2(-55, 220) * scale_factor, outline
	)
	_draw_limb(
		center + Vector2(28, 86) * scale_factor, center + Vector2(55, 220) * scale_factor, outline
	)
	if not caption.is_empty():
		draw_string(
			ThemeDB.fallback_font,
			Vector2(maxf(0.0, center.x - 116.0), size.y - 16.0),
			caption,
			HORIZONTAL_ALIGNMENT_CENTER,
			232.0,
			13,
			Color(0.43, 0.52, 0.63, 0.78)
		)


func _draw_character_texture() -> void:
	var texture_size := _character_texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var available := Vector2(maxf(1.0, size.x - 16.0), maxf(1.0, size.y - 16.0))
	var fit_scale := minf(available.x / texture_size.x, available.y / texture_size.y)
	var draw_size := texture_size * fit_scale
	var draw_rect := Rect2((size - draw_size) * 0.5, draw_size)
	draw_texture_rect(_character_texture, draw_rect, false)


func _draw_limb(from: Vector2, to: Vector2, color: Color) -> void:
	draw_line(from, to, Color(0.055, 0.075, 0.105, 0.42), 25.0)
	draw_line(from, to, color, 2.0)
