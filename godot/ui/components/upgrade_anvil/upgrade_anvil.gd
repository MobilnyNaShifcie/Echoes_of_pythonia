extends Control
## One clipped presentation stage. Contact points share the anvil's scale on resize.
signal item_dropped(data: Dictionary)
signal return_requested(data: Dictionary)
signal drag_state_changed(active: bool)
const Presentation := preload("res://ui/components/upgrade_anvil/forge_item_presentation.gd")
var accepts_item: Callable
var occupied := false
var contact_point := Vector2.ZERO
var return_payload: Dictionary = {}
var dragging := false
var _hovered := false
var _item_id := ""


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	resized.connect(_layout_art)
	mouse_entered.connect(_set_hover.bind(true))
	mouse_exited.connect(_set_hover.bind(false))
	_layout_art.call_deferred()


func show_item(texture: Texture2D, item_id := "") -> void:
	occupied = texture != null
	_item_id = item_id
	%PreviewIcon.texture = Presentation.texture_for(item_id, texture) if occupied else null
	%PreviewIcon.visible = occupied and not dragging
	mouse_default_cursor_shape = Control.CURSOR_DRAG if occupied else Control.CURSOR_ARROW
	tooltip_text = (
		"Przeciągnij przedmiot z powrotem do wyposażenia lub plecaka. Backspace: zwróć."
		if occupied
		else "Przeciągnij przedmiot na kowadło."
	)
	_layout_art()


func _layout_art() -> void:
	if not is_node_ready():
		return
	# The lower plinth intentionally continues beyond the clipped stage, grounding it.
	var art: TextureRect = $AnvilArt
	var factor := size.x * 0.92 / 1442.0
	art.size = Vector2(1442, 843) * factor
	var icon: TextureRect = %PreviewIcon
	icon.rotation = 0
	var item_size := Vector2.ZERO
	if occupied and _item_id != "caprice_lance":
		var source_size := icon.texture.get_size()
		var limit := Vector2(size.x * 0.42, size.y * 0.39)
		item_size = source_size * minf(limit.x / source_size.x, limit.y / source_size.y)
	var surface_y := maxf(size.y * 0.26, item_size.y + 16.0)
	if not occupied:
		surface_y = maxf(24.0, size.y - art.size.y - 24.0) + 45.0 * factor
	art.position = Vector2(size.x * 0.04, surface_y - 45.0 * factor)
	contact_point = Vector2(size.x * 0.5, surface_y)
	if occupied and _item_id == "caprice_lance":
		var item_scale := size.x * 0.94 / 2103.0
		icon.size = Vector2(2103, 580) * item_scale
		icon.pivot_offset = Vector2(1060, 220) * item_scale
		icon.position = contact_point - icon.pivot_offset
		icon.rotation = 0.10
	else:
		# Fit actual visible bounds, not a square placed partly above the clipped stage.
		icon.size = item_size
		icon.pivot_offset = Vector2.ZERO
		icon.position = contact_point - Vector2(item_size.x * 0.5, item_size.y)
	queue_redraw()


func _get_drag_data(at_position: Vector2) -> Variant:
	if not occupied or return_payload.is_empty():
		return null
	var icon: TextureRect = %PreviewIcon
	var local_point := icon.get_transform().affine_inverse() * at_position
	if not Rect2(Vector2.ZERO, icon.size).has_point(local_point):
		return null
	var preview := Control.new()
	# Godot attaches the preview near its source; draw it above both sibling panels.
	preview.z_as_relative = false
	preview.z_index = 4095
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sprite := TextureRect.new()
	sprite.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sprite.texture = icon.texture
	sprite.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	sprite.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	sprite.size = icon.size
	sprite.position = icon.position - at_position
	sprite.pivot_offset = icon.pivot_offset
	sprite.rotation = icon.rotation
	preview.add_child(sprite)
	set_drag_preview(preview)
	dragging = true
	icon.hide()
	drag_state_changed.emit(true)
	return return_payload.duplicate()


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and dragging:
		dragging = false
		if is_node_ready():
			%PreviewIcon.visible = occupied
			drag_state_changed.emit(false)


func _gui_input(event: InputEvent) -> void:
	if (
		event is InputEventKey
		and event.pressed
		and not event.echo
		and event.keycode == KEY_BACKSPACE
	):
		if occupied:
			return_requested.emit(return_payload.duplicate())
			accept_event()


func _set_hover(value: bool) -> void:
	_hovered = value
	queue_redraw()


func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return accepts_item.is_valid() and accepts_item.call(data)


func _drop_data(_position: Vector2, data: Variant) -> void:
	if _can_drop_data(Vector2.ZERO, data):
		item_dropped.emit(data)


func _draw() -> void:
	if _hovered and get_viewport().gui_is_dragging():
		var edge := Color(1.0, 0.59, 0.19, 0.95)
		draw_rect(Rect2(Vector2(1, 1), size - Vector2(2, 2)), edge, false, 3.0)
