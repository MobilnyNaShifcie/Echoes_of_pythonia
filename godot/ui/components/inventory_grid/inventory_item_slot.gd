class_name InventoryItemSlot
extends Button

signal metadata_selected(metadata: Dictionary)
signal metadata_hovered(metadata: Dictionary)
signal metadata_activated(metadata: Dictionary)

var item_metadata: Dictionary = {}
var drag_payload: Dictionary = {}


func _ready() -> void:
	pressed.connect(_emit_selected)
	mouse_entered.connect(_emit_hovered)
	focus_entered.connect(_emit_hovered)
	gui_input.connect(_on_gui_input)


func configure(entry: Dictionary) -> void:
	item_metadata = entry.get("metadata", {}).duplicate(true)
	drag_payload = entry.get("drag_payload", {}).duplicate(true)
	text = str(entry.get("placeholder", "?"))
	tooltip_text = str(entry.get("tooltip", ""))
	disabled = bool(entry.get("disabled", false))
	var accessible_name := str(entry.get("accessible_name", entry.get("title", text)))
	tooltip_text = tooltip_text if not tooltip_text.is_empty() else accessible_name


func _get_drag_data(_at_position: Vector2) -> Variant:
	if drag_payload.is_empty() or disabled:
		return null
	var preview := PanelContainer.new()
	preview.custom_minimum_size = Vector2(90, 54)
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview.add_child(label)
	set_drag_preview(preview)
	return drag_payload.duplicate(true)


func _make_custom_tooltip(for_text: String) -> Object:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(380, 0)
	var label := Label.new()
	label.text = for_text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", Color(0.88, 0.91, 0.96))
	label.add_theme_font_size_override("font_size", 16)
	panel.add_child(label)
	return panel


func _emit_selected() -> void:
	metadata_selected.emit(item_metadata.duplicate(true))


func _emit_hovered() -> void:
	metadata_hovered.emit(item_metadata.duplicate(true))


func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.double_click and event.pressed and not disabled:
			metadata_activated.emit(item_metadata.duplicate(true))
			accept_event()
