extends Control
## One clipped presentation stage. Contact points share the anvil's scale on resize.
signal item_dropped(data: Dictionary)
const Presentation := preload("res://ui/components/upgrade_anvil/forge_item_presentation.gd")
var accepts_item: Callable
var occupied := false
var contact_point := Vector2.ZERO
var _hovered := false
var _item_id := ""


func _ready() -> void:
	resized.connect(_layout_art)
	mouse_entered.connect(_set_hover.bind(true))
	mouse_exited.connect(_set_hover.bind(false))
	_layout_art.call_deferred()


func show_item(texture: Texture2D, item_id := "") -> void:
	occupied = texture != null
	_item_id = item_id
	%PreviewIcon.texture = Presentation.texture_for(item_id, texture) if occupied else null
	%EmptyHint.visible = not occupied
	_layout_art()


func _layout_art() -> void:
	if not is_node_ready():
		return
	# The lower plinth intentionally continues beyond the clipped stage, grounding it.
	var art: TextureRect = $AnvilArt
	var factor := size.x * 0.92 / 1442.0
	art.position = Vector2(size.x * 0.04, size.y * 0.24)
	art.size = Vector2(1442, 843) * factor
	contact_point = Vector2(size.x * 0.5, art.position.y + 45.0 * factor)
	var icon: TextureRect = %PreviewIcon
	icon.rotation = 0
	if occupied and _item_id == "caprice_lance":
		var item_scale := size.x * 0.94 / 2103.0
		icon.size = Vector2(2103, 580) * item_scale
		icon.pivot_offset = Vector2(1060, 220) * item_scale
		icon.position = contact_point - icon.pivot_offset
		icon.rotation = 0.10
	else:
		# Existing inventory art stays the fallback; no invented item illustrations.
		var side := minf(size.x * 0.30, size.y * 0.46)
		icon.size = Vector2(side, side)
		icon.pivot_offset = Vector2.ZERO
		icon.position = contact_point - Vector2(side * 0.5, side * 0.90)
	queue_redraw()


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
