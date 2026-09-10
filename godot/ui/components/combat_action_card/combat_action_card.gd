class_name CombatActionCard
extends Button

var action_id := ""
var state_text := "GOTOWA"
var _accent := Color(0.44, 0.57, 0.72)
var _selected := false
var _compact := false

@onready var artwork: TextureRect = %Artwork
@onready var artwork_tint: ColorRect = %ArtworkTint
@onready var placeholder: PanelContainer = %Placeholder
@onready var slot_label: Label = %SlotLabel
@onready var badge_label: Label = %BadgeLabel
@onready var placeholder_label: Label = %PlaceholderLabel
@onready var title_label: Label = %TitleLabel
@onready var mechanic_label: Label = %MechanicLabel
@onready var cost_label: Label = %CostLabel
@onready var state_label: Label = %StateLabel


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
	presentation := {},
) -> void:
	var card_art: Texture2D = presentation.get("artwork")
	var mechanic_text := str(presentation.get("mechanic", ""))
	var inspection_mode := bool(presentation.get("inspection_mode", false))
	_compact = bool(presentation.get("compact", false))
	if _compact:
		custom_minimum_size = Vector2(148, 180)
		size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		size_flags_vertical = Control.SIZE_SHRINK_CENTER
		artwork.set_offsets_preset(Control.PRESET_FULL_RECT)
		artwork.offset_left = 3.0
		artwork.offset_top = 3.0
		artwork.offset_right = -3.0
		artwork.offset_bottom = -3.0
		title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title_label.max_lines_visible = 2
		title_label.add_theme_font_size_override("font_size", 13)
		get_node("Footer").anchor_top = 1.0
		get_node("Footer").offset_top = -76.0
	else:
		custom_minimum_size = Vector2(168, 212)
		size_flags_horizontal = Control.SIZE_FILL
		size_flags_vertical = Control.SIZE_EXPAND_FILL
		artwork.set_offsets_preset(Control.PRESET_FULL_RECT)
		title_label.autowrap_mode = TextServer.AUTOWRAP_OFF
		title_label.max_lines_visible = -1
		get_node("Footer").anchor_top = 1.0
		get_node("Footer").offset_top = -78.0
	action_id = identifier
	# Fit the entire illustration above the caption instead of cropping a portrait into the card.
	artwork.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	artwork.offset_left = 6.0
	artwork.offset_right = -6.0
	artwork.offset_top = 8.0
	artwork.offset_bottom = -78.0 if _compact else -80.0
	state_text = visual_state
	_accent = accent
	# Retain semantic text as a compatibility adapter while child labels own
	# the visible typography.
	text = (
		"◇  SLOT %d  •  %s\n%s\n%s\n[%s]"
		% [position, badge_text, display_name.to_upper(), cost_text, visual_state]
	)
	tooltip_text = description
	disabled = not available and not inspection_mode
	artwork.texture = card_art
	artwork.visible = card_art != null
	placeholder.visible = card_art == null
	slot_label.text = "KARTA %02d" % position
	slot_label.hide()
	badge_label.text = badge_text
	placeholder_label.text = "ILUSTRACJA\nW PRZYGOTOWANIU"
	title_label.text = display_name.to_upper()
	mechanic_label.text = mechanic_text
	mechanic_label.visible = not mechanic_text.is_empty()
	cost_label.text = cost_text
	state_label.text = visual_state
	_apply_visual_state(available)


func visual_state() -> String:
	return state_text


func artwork_texture() -> Texture2D:
	return artwork.texture


func uses_placeholder() -> bool:
	return placeholder.visible


func mechanic_badge() -> String:
	return mechanic_label.text if mechanic_label.visible else ""


func set_selected(selected: bool) -> void:
	_selected = selected
	_refresh_styles()


static func accent_for_class(class_code: String) -> Color:
	match class_code:
		"warrior":
			return Color(0.39, 0.58, 0.78)
		"hunter":
			return Color(0.48, 0.67, 0.39)
		"mage":
			return Color(0.54, 0.43, 0.84)
		"pierrot":
			return Color(0.88, 0.24, 0.5)
	return Color(0.44, 0.57, 0.72)


static func badge_for_skill(skill) -> String:
	if skill.effect.begins_with("fate_") or skill.character_class_code == "pierrot":
		return "LOS"
	if skill.effect in ["guard", "defense_up", "dodge_up", "provoke"]:
		return "OBRONA"
	match skill.damage_type:
		"fire":
			return "OGIEŃ"
		"water":
			return "WODA"
		"lightning":
			return "BŁYSK"
		"earth":
			return "ZIEMIA"
	return "FIZYCZNE"


func _apply_visual_state(available: bool) -> void:
	var readable := Color(0.9, 0.93, 0.97)
	var muted := Color(0.55, 0.62, 0.72)
	var state_color := _accent
	if state_text in ["BLOKADA", "ZAKOŃCZONA", "PODGLĄD"] or not available:
		state_color = muted
	title_label.modulate = readable if available else Color(0.68, 0.72, 0.78)
	badge_label.modulate = _accent if available else muted
	mechanic_label.modulate = _accent if available else muted
	state_label.modulate = state_color
	artwork.modulate = Color.WHITE if available else Color(0.5, 0.52, 0.56, 0.7)
	artwork_tint.color = (
		Color(0.01, 0.018, 0.03, 0.12 if _compact else 0.28)
		if available
		else Color(0.01, 0.018, 0.03, 0.58)
	)
	_refresh_styles()


func _refresh_styles() -> void:
	# The root text remains queryable but is not rendered over the composed card.
	for color_name in [
		"font_color",
		"font_hover_color",
		"font_pressed_color",
		"font_focus_color",
		"font_disabled_color",
	]:
		add_theme_color_override(color_name, Color.TRANSPARENT)
	var border_strength := 1.0 if _selected else 0.62
	add_theme_stylebox_override(
		"normal", _card_style(_accent, border_strength, Color(0.025, 0.04, 0.065))
	)
	add_theme_stylebox_override("hover", _card_style(_accent, 1.0, Color(0.045, 0.065, 0.1)))
	add_theme_stylebox_override("pressed", _card_style(_accent, 1.0, Color(0.06, 0.075, 0.11)))
	add_theme_stylebox_override("focus", _card_style(_accent, 1.0, Color(0.04, 0.06, 0.095)))
	add_theme_stylebox_override(
		"disabled", _card_style(Color(0.25, 0.29, 0.36), 0.55, Color(0.02, 0.027, 0.04))
	)


func _card_style(border_color: Color, border_alpha: float, background: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = Color(border_color, border_alpha)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 0.0
	style.content_margin_top = 0.0
	style.content_margin_right = 0.0
	style.content_margin_bottom = 0.0
	return style
