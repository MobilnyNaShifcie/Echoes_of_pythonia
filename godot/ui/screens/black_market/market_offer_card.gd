extends Button
## A catalogue illustration, never a live 3D world or a purchase-on-hover surface.
signal offer_selected(offer_id: String)

const Palette = preload("res://ui/presentation/item_rarity_palette.gd")
const GOLD := Color("e7bd62")
const FRAME_INSET := 8.0
var offer_id := ""
var item_id := ""
var icon_rect: TextureRect
var quantity_label: Label
var sold_label: Label
var _selected := false
var _rarity := Color.GRAY


func _ready() -> void:
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	size_flags_vertical = Control.SIZE_EXPAND_FILL
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	icon_rect = TextureRect.new()
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	add_child(icon_rect)
	icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon_rect.offset_left = 22
	icon_rect.offset_top = 16
	icon_rect.offset_right = -22
	icon_rect.offset_bottom = -16
	quantity_label = Label.new()
	add_child(quantity_label)
	quantity_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	quantity_label.offset_left = -66
	quantity_label.offset_right = -19
	quantity_label.offset_top = -42
	quantity_label.offset_bottom = -13
	quantity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quantity_label.add_theme_font_size_override("font_size", 18)
	var badge := StyleBoxFlat.new()
	badge.bg_color = Color("080d12")
	badge.border_color = GOLD.darkened(0.5)
	badge.set_border_width_all(1)
	badge.set_corner_radius_all(4)
	quantity_label.add_theme_stylebox_override("normal", badge)
	sold_label = Label.new()
	add_child(sold_label)
	sold_label.set_anchors_and_offsets_preset(Control.PRESET_HCENTER_WIDE)
	sold_label.offset_top = -18
	sold_label.offset_bottom = 18
	sold_label.text = "SPRZEDANE"
	sold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	sold_label.add_theme_font_size_override("font_size", 21)
	sold_label.add_theme_stylebox_override("normal", badge)
	for child: Control in get_children():
		child.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pressed.connect(func(): offer_selected.emit(offer_id))
	for event in [mouse_entered, mouse_exited, focus_entered, focus_exited, resized]:
		event.connect(queue_redraw)
	clear_offer()


func configure(entry: Dictionary) -> void:
	offer_id = str(entry.get("offer_id", ""))
	item_id = str(entry.get("item_id", ""))
	icon_rect.texture = entry.get("icon")
	_rarity = Palette.color_for(str(entry.get("rarity", "common")))
	quantity_label.text = "×%d" % int(entry.get("quantity", 1))
	quantity_label.show()
	sold_label.visible = bool(entry.get("sold", false))
	icon_rect.modulate = Color(0.4, 0.4, 0.4, 0.6) if sold_label.visible else Color.WHITE
	disabled = offer_id.is_empty() or sold_label.visible
	tooltip_text = str(entry.get("tooltip", ""))
	queue_redraw()


func clear_offer() -> void:
	offer_id = ""
	item_id = ""
	disabled = true
	icon_rect.texture = null
	quantity_label.hide()
	sold_label.hide()
	tooltip_text = ""
	queue_redraw()


func set_selected(value: bool) -> void:
	_selected = value
	queue_redraw()


func rarity_frame_rect() -> Rect2:
	# Match the whole card, without reserving a separate price footer.
	return Rect2(Vector2.ZERO, size).grow(-FRAME_INSET)


func _draw() -> void:
	var active := _selected or has_focus() or (is_hovered() and not disabled)
	var outer := StyleBoxFlat.new()
	outer.bg_color = Color("17121b") if active else Color("080c10")
	outer.border_color = GOLD if active else Color("68522c")
	outer.set_border_width_all(2 if active else 1)
	outer.set_corner_radius_all(8)
	if active:
		outer.shadow_color = Color(0.86, 0.62, 0.22, 0.23)
		outer.shadow_size = 8
	draw_style_box(outer, Rect2(Vector2.ZERO, size))
	var frame := rarity_frame_rect()
	draw_rect(frame, _rarity.darkened(0.5), false, 1)
	for corner in [
		frame.position,
		Vector2(frame.end.x, frame.position.y),
		frame.end,
		Vector2(frame.position.x, frame.end.y)
	]:
		var direction: Vector2 = (frame.get_center() - corner).sign()
		draw_line(corner, corner + Vector2(15 * direction.x, 0), _rarity, 2, true)
		draw_line(corner, corner + Vector2(0, 15 * direction.y), _rarity, 2, true)
		draw_circle(corner + direction * 5, 2, _rarity, false, 1, true)
