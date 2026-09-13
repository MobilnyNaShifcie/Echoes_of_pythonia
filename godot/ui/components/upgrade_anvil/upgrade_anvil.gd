extends Control
## Code-native anvil contour and contained item preview; no new raster artwork.
signal item_dropped(data: Dictionary)
var accepts_item: Callable
var occupied := false
var _hovered := false


func _ready() -> void:
	resized.connect(queue_redraw)
	mouse_entered.connect(_set_hover.bind(true))
	mouse_exited.connect(_set_hover.bind(false))


func show_item(texture: Texture2D) -> void:
	occupied = texture != null
	%PreviewIcon.texture = texture
	%EmptyHint.visible = not occupied
	queue_redraw()


func _set_hover(value: bool) -> void:
	_hovered = value
	queue_redraw()


func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return accepts_item.is_valid() and accepts_item.call(data)


func _drop_data(_position: Vector2, data: Variant) -> void:
	if _can_drop_data(Vector2.ZERO, data):
		item_dropped.emit(data)


func _draw() -> void:
	var center := size * Vector2(0.5, 0.51)
	var radius := minf(size.x * 0.3, size.y * 0.51)
	if occupied:
		for index in range(12, 0, -1):
			draw_circle(center, radius * index / 12.0, Color(1, 0.36, 0.045, 0.012), true)
		for multiplier: float in [0.86, 1.0]:
			draw_arc(center, radius * multiplier, 0, TAU, 96, Color(0.65, 0.39, 0.12, 0.3), 1, true)
	# Normalized vector geometry follows the container; the item rests on its top edge.
	var points := PackedVector2Array(
		[
			Vector2(0.11, 0.72),
			Vector2(0.85, 0.72),
			Vector2(0.85, 0.83),
			Vector2(0.62, 0.82),
			Vector2(0.57, 0.9),
			Vector2(0.64, 0.96),
			Vector2(0.36, 0.96),
			Vector2(0.43, 0.9),
			Vector2(0.38, 0.82),
			Vector2(0.22, 0.80),
		]
	)
	for index in points.size():
		points[index] *= size
	draw_colored_polygon(points, Color(0.085, 0.085, 0.079, 0.95))
	points.append(points[0])
	var edge := Color(0.8, 0.51, 0.22, 0.85) if occupied else Color(0.51, 0.45, 0.34, 0.7)
	draw_polyline(points, edge, 2, true)
	if occupied:
		draw_line(
			size * Vector2(0.15, 0.72), size * Vector2(0.85, 0.72), Color(1, 0.59, 0.19), 2, true
		)
	if _hovered and get_viewport().gui_is_dragging():
		draw_rect(Rect2(Vector2(1, 1), size - Vector2(2, 2)), edge, false, 2)
