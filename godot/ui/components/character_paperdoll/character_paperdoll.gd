class_name CharacterPaperdoll
extends Control

@export var accent_color := Color(0.36, 0.47, 0.62, 0.72)
@export var caption := "MIEJSCE NA GRAFIKĘ POSTACI"
@export_range(0.5, 2.0, 0.05) var character_zoom := 1.0
@export var character_offset := Vector2.ZERO
@export_range(0.0, 1.0, 0.01) var character_anchor_x := 0.5
@export_range(0.5, 1.0, 0.01) var character_clip_bottom_ratio := 1.0
@export_range(-0.25, 0.25, 0.01) var character_clip_bottom_slope := 0.0

var _character_texture: Texture2D
var _character_image: Image


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	queue_redraw()


func show_character(texture: Texture2D, fallback_caption := "MIEJSCE NA GRAFIKĘ POSTACI") -> void:
	_character_texture = texture
	_character_image = texture.get_image() if texture != null else null
	caption = fallback_caption
	queue_redraw()


func character_texture() -> Texture2D:
	return _character_texture


func character_visible_rect() -> Rect2:
	if _character_texture == null:
		return Rect2()
	var texture_size := _character_texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return Rect2()
	var draw_rect := _character_draw_rect(texture_size)
	var source_rect := Rect2(Vector2.ZERO, texture_size)
	if _character_image != null:
		var used_rect := _character_image.get_used_rect()
		if used_rect.has_area():
			source_rect = Rect2(used_rect)
	var visible_rect := Rect2(
		draw_rect.position + source_rect.position / texture_size * draw_rect.size,
		source_rect.size / texture_size * draw_rect.size,
	)
	var clip_ratio := clampf(character_clip_bottom_ratio, 0.5, 1.0)
	var clip_slope := absf(clampf(character_clip_bottom_slope, -0.25, 0.25))
	var clip_bottom := draw_rect.position.y + draw_rect.size.y * (clip_ratio + clip_slope * 0.5)
	visible_rect.size.y = minf(visible_rect.end.y, clip_bottom) - visible_rect.position.y
	return visible_rect.intersection(Rect2(Vector2.ZERO, size))


func is_character_point_visible(point: Vector2, alpha_threshold := 0.08) -> bool:
	if _character_texture == null or _character_image == null:
		return false
	var texture_size := _character_texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return false
	var draw_rect := _character_draw_rect(texture_size)
	if not draw_rect.has_point(point):
		return false
	var texture_position := (point - draw_rect.position) / draw_rect.size
	var clip_ratio := clampf(
		(
			character_clip_bottom_ratio
			+ clampf(character_clip_bottom_slope, -0.25, 0.25) * (0.5 - texture_position.x)
		),
		0.5,
		1.0,
	)
	if texture_position.y > clip_ratio:
		return false
	var pixel := Vector2i(
		clampi(
			int(texture_position.x * float(_character_image.get_width())),
			0,
			_character_image.get_width() - 1
		),
		clampi(
			int(texture_position.y * float(_character_image.get_height())),
			0,
			_character_image.get_height() - 1
		),
	)
	return _character_image.get_pixelv(pixel).a >= alpha_threshold


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
	var draw_rect := _character_draw_rect(texture_size)
	var clip_ratio := clampf(character_clip_bottom_ratio, 0.5, 1.0)
	var clip_slope := clampf(character_clip_bottom_slope, -0.25, 0.25)
	if is_equal_approx(clip_ratio, 1.0) and is_zero_approx(clip_slope):
		draw_texture_rect(_character_texture, draw_rect, false)
		return
	if not is_zero_approx(clip_slope):
		_draw_character_texture_with_sloped_clip(
			draw_rect,
			texture_size,
			clip_ratio,
			clip_slope,
		)
		return
	var clipped_draw_rect := Rect2(
		draw_rect.position,
		Vector2(draw_rect.size.x, draw_rect.size.y * clip_ratio),
	)
	var source_rect := Rect2(
		Vector2.ZERO,
		Vector2(texture_size.x, texture_size.y * clip_ratio),
	)
	draw_texture_rect_region(_character_texture, clipped_draw_rect, source_rect)


func _character_draw_rect(texture_size: Vector2) -> Rect2:
	var available := Vector2(maxf(1.0, size.x - 16.0), maxf(1.0, size.y - 16.0))
	var fit_scale := minf(available.x / texture_size.x, available.y / texture_size.y)
	var draw_size := texture_size * fit_scale * character_zoom
	var draw_center := Vector2(size.x * clampf(character_anchor_x, 0.0, 1.0), size.y * 0.5)
	return Rect2(draw_center - draw_size * 0.5 + character_offset, draw_size)


func _draw_character_texture_with_sloped_clip(
	draw_rect: Rect2,
	texture_size: Vector2,
	base_ratio: float,
	slope: float,
) -> void:
	const STRIP_COUNT := 96
	for strip_index in STRIP_COUNT:
		var source_left := texture_size.x * float(strip_index) / float(STRIP_COUNT)
		var source_right := texture_size.x * float(strip_index + 1) / float(STRIP_COUNT)
		var horizontal_ratio := (float(strip_index) + 0.5) / float(STRIP_COUNT)
		var strip_clip_ratio := clampf(
			base_ratio + slope * (0.5 - horizontal_ratio),
			0.5,
			1.0,
		)
		var draw_left := draw_rect.position.x + draw_rect.size.x * source_left / texture_size.x
		var draw_right := draw_rect.position.x + draw_rect.size.x * source_right / texture_size.x
		var strip_draw_rect := Rect2(
			Vector2(draw_left, draw_rect.position.y),
			Vector2(draw_right - draw_left, draw_rect.size.y * strip_clip_ratio),
		)
		var strip_source_rect := Rect2(
			Vector2(source_left, 0.0),
			Vector2(source_right - source_left, texture_size.y * strip_clip_ratio),
		)
		draw_texture_rect_region(_character_texture, strip_draw_rect, strip_source_rect)


func _draw_limb(from: Vector2, to: Vector2, color: Color) -> void:
	draw_line(from, to, Color(0.055, 0.075, 0.105, 0.42), 25.0)
	draw_line(from, to, color, 2.0)
