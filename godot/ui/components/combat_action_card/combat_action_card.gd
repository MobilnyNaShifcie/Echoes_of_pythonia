class_name CombatActionCard
extends Button

var action_id := ""
var state_text := "GOTOWA"


func configure(
	identifier: String,
	position: int,
	display_name: String,
	cost_text: String,
	description: String,
	available: bool,
	accent: Color,
	badge_text := "AKCJA",
	visual_state := "GOTOWA",
) -> void:
	action_id = identifier
	state_text = visual_state
	text = (
		"◇  SLOT %d  •  %s\n%s\n%s\n[%s]"
		% [position, badge_text, display_name.to_upper(), cost_text, visual_state]
	)
	tooltip_text = description
	disabled = not available
	add_theme_color_override("font_color", Color(0.9, 0.93, 0.97))
	add_theme_color_override("font_hover_color", Color.WHITE)
	add_theme_color_override("font_disabled_color", Color(0.38, 0.43, 0.51))
	add_theme_stylebox_override("normal", _card_style(accent, 0.55, Color(0.025, 0.04, 0.065)))
	add_theme_stylebox_override("hover", _card_style(accent, 0.95, Color(0.045, 0.065, 0.1)))
	add_theme_stylebox_override("pressed", _card_style(accent, 1.0, Color(0.06, 0.075, 0.11)))
	add_theme_stylebox_override("focus", _card_style(accent, 1.0, Color(0.04, 0.06, 0.095)))
	add_theme_stylebox_override(
		"disabled", _card_style(Color(0.25, 0.29, 0.36), 0.45, Color(0.02, 0.027, 0.04))
	)


func visual_state() -> String:
	return state_text


func _card_style(border_color: Color, border_alpha: float, background: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = Color(border_color, border_alpha)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12.0
	style.content_margin_top = 10.0
	style.content_margin_right = 12.0
	style.content_margin_bottom = 10.0
	return style
