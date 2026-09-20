extends RefCounted
## Atlas coordinates address the approved painted skin, never player-facing text.
const ATLAS := preload("res://assets/ui/combat/victory_atlas_v1.png")
const REGIONS := {
	"banner": Rect2(12, 72, 1230, 430),
	"rewards": Rect2(55, 530, 1145, 173),
	"loot": Rect2(28, 720, 380, 286),
	"plaque": Rect2(410, 796, 588, 106),
	"medal": Rect2(999, 720, 236, 290),
	"achievement": Rect2(10, 1065, 704, 130),
	"button": Rect2(714, 1058, 535, 138),
}
static var _cached_font: SystemFont


static func texture(piece: String) -> AtlasTexture:
	var result := AtlasTexture.new()
	result.atlas = ATLAS
	result.region = REGIONS[piece]
	result.filter_clip = true
	return result


static func font() -> SystemFont:
	# Retain the face while the shared Continue button switches its theme back.
	# Releasing its last Font reference during reshaping trips TextServerAdvanced.
	if _cached_font == null:
		_cached_font = SystemFont.new()
		_cached_font.font_names = PackedStringArray(["Georgia", "Noto Serif", "DejaVu Serif"])
	return _cached_font


static func button(control: Button) -> void:
	control.add_theme_font_override("font", font())
	control.add_theme_font_size_override("font_size", 40)
	control.add_theme_color_override("font_color", Color("f5df9f"))
	control.add_theme_color_override("font_hover_color", Color("fff0c2"))
	control.add_theme_color_override("font_pressed_color", Color("d5af68"))
	control.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state: String in ["normal", "hover", "pressed", "disabled"]:
		var box := StyleBoxTexture.new()
		box.texture = texture("button")
		box.modulate_color = (
			Color(1.2, 1.15, 1.05)
			if state == "hover"
			else Color(0.75, 0.75, 0.75) if state == "pressed" else Color.WHITE
		)
		box.set_content_margin_all(0)
		control.add_theme_stylebox_override(state, box)
	var focus := StyleBoxFlat.new()
	focus.bg_color = Color.TRANSPARENT
	focus.border_color = Color("ffe09a")
	focus.set_border_width_all(2)
	focus.set_corner_radius_all(6)
	focus.set_content_margin_all(0)
	control.add_theme_stylebox_override("focus", focus)
