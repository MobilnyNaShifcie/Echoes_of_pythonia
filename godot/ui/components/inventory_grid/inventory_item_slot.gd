class_name InventoryItemSlot
extends Button

signal metadata_selected(metadata: Dictionary)
signal metadata_hovered(metadata: Dictionary)
signal metadata_activated(metadata: Dictionary)

const TOOLTIP_WIDTH := 380.0
const TOOLTIP_ICON_SIZE := 76.0
const TOOLTIP_TEXT_WIDTH := 268.0
const RARITY_FRAME_COLORS := {
	"common": Color(0.32, 0.35, 0.4, 0.78),
	"uncommon": Color(0.29, 0.66, 0.44, 0.9),
	"rare": Color(0.58, 0.38, 0.78, 0.92),
	"epic": Color(0.8, 0.47, 0.22, 0.94),
}

var item_metadata: Dictionary = {}
var drag_payload: Dictionary = {}
var item_texture: Texture2D
var item_quantity := 0
var placeholder_text := "?"
var rarity := "common"
var slot_caption := ""


func _ready() -> void:
	pressed.connect(_emit_selected)
	mouse_entered.connect(_emit_hovered)
	focus_entered.connect(_emit_hovered)
	gui_input.connect(_on_gui_input)
	_render_item()


func configure(entry: Dictionary) -> void:
	item_metadata = entry.get("metadata", {}).duplicate(true)
	drag_payload = entry.get("drag_payload", {}).duplicate(true)
	placeholder_text = str(entry.get("placeholder", "?"))
	var icon_value = entry.get("icon")
	item_texture = icon_value if icon_value is Texture2D else null
	item_quantity = maxi(0, int(entry.get("quantity", 0)))
	rarity = str(entry.get("rarity", "common")).to_lower()
	if not RARITY_FRAME_COLORS.has(rarity):
		rarity = "common"
	slot_caption = str(entry.get("slot_caption", ""))
	tooltip_text = str(entry.get("tooltip", ""))
	disabled = bool(entry.get("disabled", false))
	var accessible_name := str(entry.get("accessible_name", entry.get("title", placeholder_text)))
	tooltip_text = tooltip_text if not tooltip_text.is_empty() else accessible_name
	_render_item()
	_apply_rarity_frame()


func _get_drag_data(_at_position: Vector2) -> Variant:
	if drag_payload.is_empty() or disabled:
		return null
	var preview := PanelContainer.new()
	preview.custom_minimum_size = Vector2(72, 72)
	if item_texture != null:
		var texture_rect := TextureRect.new()
		texture_rect.texture = item_texture
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		preview.add_child(texture_rect)
	else:
		var label := Label.new()
		label.text = placeholder_text
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		preview.add_child(label)
	set_drag_preview(preview)
	return drag_payload.duplicate(true)


func _make_custom_tooltip(for_text: String) -> Object:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(TOOLTIP_WIDTH, 0)
	panel.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	panel.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var content := HBoxContainer.new()
	content.add_theme_constant_override("separation", 12)
	content.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	content.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	if item_texture != null:
		var texture_rect := TextureRect.new()
		texture_rect.custom_minimum_size = Vector2(TOOLTIP_ICON_SIZE, TOOLTIP_ICON_SIZE)
		texture_rect.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		texture_rect.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
		texture_rect.texture = item_texture
		texture_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		texture_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		content.add_child(texture_rect)
	var label := Label.new()
	label.custom_minimum_size = Vector2(
		TOOLTIP_TEXT_WIDTH if item_texture != null else TOOLTIP_WIDTH, 0
	)
	label.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	label.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.text = for_text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.88, 0.91, 0.96))
	label.add_theme_font_size_override("font_size", 16)
	content.add_child(label)
	panel.add_child(content)
	return panel


func _render_item() -> void:
	text = "" if item_texture != null else placeholder_text
	var icon_rect := get_node_or_null("ItemIcon") as TextureRect
	if icon_rect != null:
		icon_rect.texture = item_texture
		icon_rect.visible = item_texture != null
	var quantity_label := get_node_or_null("QuantityBadge") as Label
	if quantity_label != null:
		quantity_label.visible = item_quantity > 1
		quantity_label.text = "×%d" % item_quantity if item_quantity > 1 else ""
	var caption_label := get_node_or_null("SlotCaption") as Label
	if caption_label != null:
		caption_label.visible = not slot_caption.is_empty()
		caption_label.text = slot_caption


func _apply_rarity_frame() -> void:
	var rarity_color: Color = RARITY_FRAME_COLORS[rarity]
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var base_style := get_theme_stylebox(state)
		if not base_style is StyleBoxFlat:
			continue
		var style := base_style.duplicate() as StyleBoxFlat
		style.border_color = rarity_color.lightened(0.2) if state != "normal" else rarity_color
		add_theme_stylebox_override(state, style)


func _emit_selected() -> void:
	metadata_selected.emit(item_metadata.duplicate(true))


func _emit_hovered() -> void:
	metadata_hovered.emit(item_metadata.duplicate(true))


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click and event.pressed and not disabled:
			metadata_activated.emit(item_metadata.duplicate(true))
			accept_event()
