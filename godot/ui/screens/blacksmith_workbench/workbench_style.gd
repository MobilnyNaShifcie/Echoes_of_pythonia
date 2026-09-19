extends RefCounted
## Local service theme: no changes to the other inventory or NPC screens.
const GOLD := Color(0.85, 0.67, 0.32)
const TEXT := Color(0.94, 0.92, 0.85)
const MUTED := Color(0.63, 0.62, 0.59)


static func heading_font() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Georgia", "Noto Serif", "DejaVu Serif"])
	font.font_weight = 700
	return font


static func style_primary(button: Button) -> void:
	button.add_theme_font_override("font", heading_font())
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := panel(1.0, 10)
		style.bg_color = Color("#dcac49")
		style.border_color = Color("#f5d986")
		style.set_border_width_all(2)
		if state == "hover":
			style.bg_color = Color("#f2c767")
		elif state == "pressed":
			style.bg_color = Color("#bb8830")
		elif state == "disabled":
			style.bg_color = Color("#393026")
			style.border_color = Color("#72603e")
		button.add_theme_stylebox_override(state, style)
		var color := Color("#18110a") if state != "disabled" else Color("#b5a384")
		var key: String = "font_color" if state == "normal" else "font_" + state + "_color"
		button.add_theme_color_override(key, color)
	button.add_theme_color_override("font_focus_color", Color("#18110a"))


static func panel(alpha := 0.94, margin := 18.0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.038, 0.037, 0.035, alpha)
	style.border_color = Color(0.62, 0.47, 0.23, 0.8)
	style.set_border_width_all(1)
	style.set_corner_radius_all(6)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style


static func create_theme() -> Theme:
	var result := Theme.new()
	result.default_font_size = 18
	result.set_color("font_color", "Label", TEXT)
	result.set_color("default_color", "RichTextLabel", TEXT)
	result.set_stylebox("panel", "PanelContainer", panel())
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]:
		var style := panel(0.92, 12)
		if state in ["hover", "pressed", "hover_pressed"]:
			style.bg_color = Color(0.17, 0.115, 0.047, 0.95)
			style.border_color = GOLD
		if state == "disabled":
			style.bg_color = Color(0.05, 0.05, 0.047, 0.85)
			style.border_color = Color(0.28, 0.27, 0.23)
		if state == "focus":
			style.bg_color = Color.TRANSPARENT
			style.border_color = GOLD.lightened(0.2)
		result.set_stylebox(state, "Button", style)
	result.set_color("font_color", "Button", TEXT)
	for state: String in ["hover", "pressed", "focus", "hover_pressed"]:
		result.set_color("font_" + state + "_color", "Button", GOLD.lightened(0.25))
	result.set_color("font_disabled_color", "Button", MUTED)
	return result
