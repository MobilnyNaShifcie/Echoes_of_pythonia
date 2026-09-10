extends RefCounted
## Shared small surfaces and typography, retaining the game's gold/blue fantasy identity.


static func panel(alpha := 0.88, accent := Color(0.38, 0.49, 0.6, 0.48)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.035, 0.065, 0.095, alpha)
	style.border_color = accent
	style.set_border_width_all(1)
	style.set_corner_radius_all(12)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style


static func heading(label: Label, font_size := 26) -> void:
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_outline_color", Color(0.01, 0.025, 0.04, 0.85))
	label.add_theme_constant_override("outline_size", 3)


static func quiet_button(button: Button) -> void:
	var style := panel(0.8)
	style.content_margin_top = 7
	style.content_margin_bottom = 7
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_font_size_override("font_size", 15)
	button_feedback(button)


static func button_feedback(button: Button) -> void:
	# Match the existing footprint: hover must not resize compact NPC controls.
	var normal := button.get_theme_stylebox("normal") as StyleBoxFlat
	if normal != null:
		var hover := normal.duplicate() as StyleBoxFlat
		hover.bg_color = Color(0.075, 0.12, 0.17, 0.94)
		hover.border_color = Color(0.88, 0.71, 0.34, 0.85)
		button.add_theme_stylebox_override("hover", hover)
		var pressed := hover.duplicate() as StyleBoxFlat
		pressed.bg_color = Color(0.11, 0.14, 0.17, 0.96)
		button.add_theme_stylebox_override("pressed", pressed)
		button.add_theme_stylebox_override("hover_pressed", pressed)
		var focus := hover.duplicate() as StyleBoxFlat
		focus.bg_color = Color.TRANSPARENT
		button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", Color(0.81, 0.86, 0.92))
	button.add_theme_color_override("font_hover_color", Color(1.0, 0.84, 0.43))
	button.add_theme_color_override("font_focus_color", Color(1.0, 0.84, 0.43))
	button.add_theme_color_override("font_pressed_color", Color(1.0, 0.93, 0.72))
	button.add_theme_color_override("font_hover_pressed_color", Color(1.0, 0.93, 0.72))
	button.add_theme_color_override("font_disabled_color", Color(0.43, 0.49, 0.57, 0.8))
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
