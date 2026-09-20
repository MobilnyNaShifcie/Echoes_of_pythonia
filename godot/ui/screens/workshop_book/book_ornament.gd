extends Control
## Resolution-independent brass inlay on the interactive craft button, not baked UI.


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	var gold := Color("#c6a35c")
	var inset := Rect2(Vector2(6, 6), size - Vector2(12, 12))
	draw_rect(inset, Color(0.76, 0.61, 0.32, 0.45), false, 1.0, true)
	for x in [24.0, size.x - 24.0]:
		var center := Vector2(x, size.y * 0.5)
		var points := PackedVector2Array(
			[
				center + Vector2(-7, 0),
				center + Vector2(0, -12),
				center + Vector2(7, 0),
				center + Vector2(0, 12),
				center + Vector2(-7, 0)
			]
		)
		draw_polyline(points, gold, 1.2, true)
		draw_circle(center, 2, gold, true, -1, true)
