extends RefCounted
## Parchment-specific presentation, scoped to Mirela's service.
const INK := Color("#352a19")
const MUTED := Color("#6c5836")
const GOLD := Color("#c09a4b")
const GREEN := Color("#234a36")
const READY := Color("#28583c")
const MISSING := Color("#9a352a")


static func serif() -> SystemFont:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Georgia", "Noto Serif", "DejaVu Serif"])
	return font


static func place(node: Control, parent: Node, rect: Rect2) -> void:
	parent.add_child(node)
	node.position = rect.position
	node.size = rect.size


static func label(parent: Node, text: String, rect: Rect2, font_size := 26) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_override("font", serif())
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", INK)
	node.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(node, parent, rect)
	return node


static func image(parent: Node, texture: Texture2D, rect: Rect2) -> TextureRect:
	var node := TextureRect.new()
	node.texture = texture
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(node, parent, rect)
	return node


static func box(fill: Color, border: Color, width := 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(4)
	return style


static func button(parent: Node, text: String, rect: Rect2, solid := false) -> Button:
	var node := Button.new()
	node.text = text
	node.add_theme_font_override("font", serif())
	node.add_theme_font_size_override("font_size", 28)
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	style_button(node, solid)
	place(node, parent, rect)
	return node


static func style_button(node: Button, solid := false) -> void:
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var fill := GREEN if solid else Color(0.28, 0.23, 0.13, 0.035)
		var ink := Color("#f6e4b4") if solid else INK
		if state in ["hover", "pressed", "hover_pressed"]:
			fill = GREEN.lightened(0.10) if solid else Color(0.45, 0.34, 0.16, 0.17)
		if state == "disabled":
			fill = Color("#73694f") if solid else Color.TRANSPARENT
			ink = Color("#e0d2ae") if solid else Color("#998569")
		node.add_theme_stylebox_override(state, box(fill, GOLD if solid else Color.TRANSPARENT, 2))
		var key: String = "font_color" if state == "normal" else "font_" + state + "_color"
		node.add_theme_color_override(key, ink)
	node.add_theme_color_override("font_focus_color", Color("#f6e4b4") if solid else INK)
	node.add_theme_stylebox_override("focus", box(Color.TRANSPARENT, GOLD.lightened(0.2), 3))


static func divider(parent: Node, rect: Rect2) -> void:
	var line := ColorRect.new()
	line.color = Color(0.46, 0.33, 0.13, 0.40)
	line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	place(line, parent, rect)
