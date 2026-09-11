class_name BlackMarketOfferSlot
extends Button

signal offer_selected(offer_id: String)
signal offer_activated(offer_id: String)

var offer_id := ""
var item_id := ""
var _item_texture: Texture2D
var _sold := false
const ModelView := preload("res://ui/screens/black_market/market_item_3d.gd")
const REFERENCE_DISPLAY_SCALE := 1.5
const REFERENCE_ITEMS := [
	"grandmaster_elixir",
	"black_pearl",
	"mastery_attack_speed_book",
	"hearth_core",
	"azhar_sigil",
	"leviathan_scale",
	"spark_of_life"
]
var model_view: SubViewportContainer
var _dragging := false
var _drag_layer: CanvasLayer
var _drag_root: Control
var _grab_offset := Vector2.ZERO
var _drag_pointer := Vector2.ZERO
var _quantity := 1
var _counter_anchor := Vector2(INF, INF)

const DISPLAY_TINT := Color(0.78, 0.69, 0.57, 0.94)
const HOVER_TINT := Color(1.0, 0.88, 0.64, 1.0)
const DISPLAY_ROTATIONS := {
	"azhar_sigil": deg_to_rad(3.0),
	"black_pearl": deg_to_rad(-2.0),
	"hearth_core": deg_to_rad(-4.0),
	"leviathan_scale": deg_to_rad(-16.0),
}

@onready var glow: TextureRect = %Glow
@onready var shadow: TextureRect = %ItemShadow
@onready var icon_rect: TextureRect = %ItemIcon
@onready var quantity_label: Label = %QuantityLabel
@onready var price_sign = $PricePlate
@onready var sold_label: Label = %SoldLabel


func _ready() -> void:
	model_view = ModelView.new()
	model_view.name = "LiveModel3D"
	add_child(model_view)
	move_child(price_sign, 0)
	move_child(model_view, 1)
	model_view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	model_view.offset_bottom = -34
	model_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(120, 110)
	pressed.connect(_emit_selected)
	mouse_entered.connect(_on_hover_started)
	mouse_exited.connect(_on_hover_ended)
	focus_entered.connect(_on_focus_started)
	focus_exited.connect(_on_focus_ended)
	gui_input.connect(_on_gui_input)
	resized.connect(_apply_item_pose)
	model_view.viewport_3d.size_changed.connect(_align_to_counter)
	set_process(false)


func configure(entry: Dictionary) -> void:
	offer_id = str(entry.get("offer_id", ""))
	item_id = str(entry.get("item_id", ""))
	_sold = bool(entry.get("sold", false))
	var texture_value = entry.get("icon")
	_item_texture = texture_value if texture_value is Texture2D else null
	icon_rect.texture = _item_texture
	icon_rect.visible = false
	shadow.visible = false
	model_view.build("" if _sold else item_id)
	model_view.visible = not _sold
	_quantity = int(entry.get("quantity", 1))
	quantity_label.visible = _quantity > 1 and not _sold and not _dragging
	quantity_label.text = "×%d" % _quantity
	sold_label.visible = _sold
	disabled = _sold or offer_id.is_empty()
	tooltip_text = str(entry.get("tooltip", ""))
	var price := int(entry.get("effective_price", 0))
	price_sign.set_price(price if price > 0 else int(entry.get("base_price", 0)), _sold)
	price_sign.visible = true
	modulate = Color(0.48, 0.48, 0.48, 0.72) if _sold else Color.WHITE
	_apply_item_pose()
	_set_highlight(false)


func clear_offer() -> void:
	offer_id = ""
	item_id = ""
	_sold = false
	_item_texture = null
	icon_rect.texture = null
	icon_rect.visible = false
	shadow.visible = false
	model_view.build("")
	quantity_label.visible = false
	price_sign.visible = false
	sold_label.visible = false
	disabled = true
	tooltip_text = ""
	_apply_item_pose()
	_set_highlight(false)


func _apply_item_pose() -> void:
	icon_rect.pivot_offset = icon_rect.size * 0.5
	icon_rect.rotation = float(DISPLAY_ROTATIONS.get(item_id, 0.0))
	if not _dragging:
		model_view.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		model_view.position = Vector2.ZERO
		var display_scale := REFERENCE_DISPLAY_SCALE if item_id in REFERENCE_ITEMS else 1.0
		# Enlarge the render area, not the camera zoom: the whole cork stays visible.
		model_view.size = Vector2(size.x, maxf(1.0, size.y - 34.0)) * display_scale
		call_deferred("_align_to_counter")


func _has_point(point: Vector2) -> bool:
	if Rect2(Vector2.ZERO, size).has_point(point):
		return true
	if (
		item_id in REFERENCE_ITEMS
		and not _dragging
		and not disabled
		and is_instance_valid(model_view)
	):
		# Books and the pearl's gold cradle are wider than the bottle.
		var inset := 0.3 if item_id == "grandmaster_elixir" else 0.18
		var item_area := Rect2(
			model_view.position + Vector2(model_view.size.x * inset, 0),
			Vector2(model_view.size.x * (1.0 - 2.0 * inset), model_view.size.y)
		)
		return item_area.has_point(point)
	return false


func set_counter_anchor(anchor_in_slot: Vector2) -> void:
	_counter_anchor = anchor_in_slot
	_apply_item_pose()


func _align_to_counter() -> void:
	if _dragging or item_id not in REFERENCE_ITEMS or not _counter_anchor.is_finite():
		return
	var camera: Camera3D = model_view.viewport_3d.get_camera_3d()
	if camera:
		# Project the physical model foot, not the middle of its image rectangle.
		var foot_pixel := camera.unproject_position(Vector3(0, 0.035, 0))
		model_view.position = _counter_anchor - foot_pixel


func _get_drag_data(at_position: Vector2) -> Variant:
	if disabled or _sold or offer_id.is_empty() or _dragging:
		return null
	_emit_selected()
	_begin_drag_visual(at_position)
	return {
		"kind": "black_market_offer",
		"offer_id": offer_id,
		"item_id": item_id,
	}


func _begin_drag_visual(at_position: Vector2) -> void:
	if _dragging:
		return
	var display_rect := model_view.get_global_rect()
	var grabbed_position := get_global_transform_with_canvas() * at_position
	_grab_offset = display_rect.position - grabbed_position
	_drag_pointer = grabbed_position
	_dragging = true
	_drag_layer = CanvasLayer.new()
	_drag_layer.name = "HeldMarketItem"
	_drag_layer.layer = 100
	get_viewport().add_child(_drag_layer)
	_drag_root = Control.new()
	_drag_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_drag_layer.add_child(_drag_root)
	# Move the existing viewport/world/model. No sprite, captured texture or clone.
	model_view.reparent(_drag_root, false)
	model_view.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	model_view.size = display_rect.size
	model_view.position = display_rect.position
	_set_contact_shadow(false)
	quantity_label.visible = false
	set_process(true)


func _process(_delta: float) -> void:
	if _dragging and is_instance_valid(_drag_root):
		model_view.position = _drag_pointer + _grab_offset


func _input(event: InputEvent) -> void:
	if _dragging and event is InputEventMouseMotion:
		_drag_pointer = event.position


func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		_finish_drag_visual()


func _finish_drag_visual() -> void:
	if not _dragging:
		return
	_dragging = false
	set_process(false)
	model_view.reparent(self, false)
	move_child(model_view, 1)
	_dispose_drag_layer()
	_apply_item_pose()
	_set_contact_shadow(true)
	# A drop can be accepted by the bag but rejected by the purchase service.
	# Only the real offer state decides whether the item stays sold or returns.
	model_view.visible = not _sold and not offer_id.is_empty()
	quantity_label.visible = _quantity > 1 and model_view.visible
	_set_highlight(false)


func _set_contact_shadow(shown: bool) -> void:
	var contact := model_view.model.get_node_or_null("ContactShadow") as Node3D
	if contact:
		contact.visible = shown


func _dispose_drag_layer() -> void:
	if is_instance_valid(_drag_layer):
		_drag_layer.queue_free()
	_drag_layer = null
	_drag_root = null


func _exit_tree() -> void:
	# The held viewport is outside the screen tree while dragging.
	# Closing the screen must not leave its world or overlay alive.
	_dispose_drag_layer()


func _emit_selected() -> void:
	if not offer_id.is_empty():
		offer_selected.emit(offer_id)


func _on_hover_started() -> void:
	if get_viewport().gui_is_dragging():
		return
	_set_highlight(not disabled)
	_emit_selected()


func _on_hover_ended() -> void:
	_set_highlight(has_focus() and not disabled)


func _on_focus_started() -> void:
	_set_highlight(not disabled)
	_emit_selected()


func _on_focus_ended() -> void:
	_set_highlight(is_hovered() and not disabled)


func _set_highlight(active: bool) -> void:
	glow.visible = false
	model_view.highlight(active)
	icon_rect.modulate = HOVER_TINT if active else DISPLAY_TINT
	shadow.modulate = Color(0.1, 0.045, 0.015, 0.78 if active else 0.56)


func _on_gui_input(event: InputEvent) -> void:
	if (
		event is InputEventMouseButton
		and event.button_index == MOUSE_BUTTON_LEFT
		and event.double_click
		and event.pressed
		and not disabled
	):
		offer_activated.emit(offer_id)
		accept_event()
