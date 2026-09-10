class_name NpcAlphaHitButton
extends Button

@export_range(0.01, 1.0, 0.01) var alpha_threshold := 0.08
@export_range(0.0, 16.0, 1.0) var hit_padding := 5.0
@export var use_alpha_mask := true

var art_source: TextureRect
var art_uv_polygon := PackedVector2Array()


func configure_art_region(source: TextureRect, uv_polygon: PackedVector2Array) -> void:
	art_source = source
	art_uv_polygon = uv_polygon
	use_alpha_mask = false
	if art_uv_polygon.size() < 3:
		return
	var uv_bounds := Rect2(art_uv_polygon[0], Vector2.ZERO)
	for uv: Vector2 in art_uv_polygon:
		uv_bounds = uv_bounds.expand(uv)
	var drawn := art_draw_rect(source)
	var bounds := (
		Rect2(drawn.position + uv_bounds.position * drawn.size, uv_bounds.size * drawn.size)
		. intersection(source.get_global_rect())
	)
	set_anchors_preset(Control.PRESET_TOP_LEFT)
	size = bounds.size
	global_position = bounds.position


static func art_draw_rect(source: TextureRect) -> Rect2:
	var bounds := source.get_global_rect()
	if source.texture == null or source.stretch_mode != TextureRect.STRETCH_KEEP_ASPECT_COVERED:
		return bounds
	var texture_size := source.texture.get_size()
	var scale_factor := maxf(bounds.size.x / texture_size.x, bounds.size.y / texture_size.y)
	var drawn_size := texture_size * scale_factor
	return Rect2(bounds.position + (bounds.size - drawn_size) * 0.5, drawn_size)


func _has_point(point: Vector2) -> bool:
	if is_instance_valid(art_source) and art_uv_polygon.size() >= 3:
		return _has_art_point(point)
	if not use_alpha_mask:
		return Rect2(Vector2.ZERO, size).has_point(point)
	var paperdoll := get_parent() as CharacterPaperdoll
	if paperdoll == null:
		return Rect2(Vector2.ZERO, size).has_point(point)
	var paperdoll_point := position + point
	for offset: Vector2 in [
		Vector2.ZERO,
		Vector2(hit_padding, 0.0),
		Vector2(-hit_padding, 0.0),
		Vector2(0.0, hit_padding),
		Vector2(0.0, -hit_padding),
	]:
		if paperdoll.is_character_point_visible(paperdoll_point + offset, alpha_threshold):
			return true
	return false


func _has_art_point(point: Vector2) -> bool:
	var drawn := art_draw_rect(art_source)
	if not Rect2(Vector2.ZERO, size).has_point(point) or not drawn.has_area():
		return false
	var uv := (global_position + point - drawn.position) / drawn.size
	return Geometry2D.is_point_in_polygon(uv, art_uv_polygon)
