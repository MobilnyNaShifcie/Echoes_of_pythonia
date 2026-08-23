class_name InventoryGridView
extends Control

signal entry_selected(metadata: Dictionary)
signal entry_hovered(metadata: Dictionary)
signal entry_activated(metadata: Dictionary)
signal data_dropped(data: Dictionary)

const ItemGridLayoutClass := preload("res://ui/components/inventory_grid/item_grid_layout.gd")
const ITEM_SLOT_SCENE := preload("res://ui/components/inventory_grid/inventory_item_slot.tscn")

@export_range(1, 12) var columns := 8
@export_range(1, 20) var visible_rows := 6
@export var cell_size := Vector2(68, 68)
@export var gap := 5.0
@export var accepts_drops := false

var _entries: Array[Dictionary] = []
var _content_rows := 6


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_refresh_minimum_size()
	queue_redraw()


func set_entries(entries: Array[Dictionary]) -> void:
	_entries = entries.duplicate(true)
	_rebuild()


func entry_count() -> int:
	return _entries.size()


func _rebuild() -> void:
	for child in get_children():
		child.queue_free()
	var placements := ItemGridLayoutClass.pack(_entries, columns, visible_rows)
	_content_rows = visible_rows
	for placement: Dictionary in placements:
		var footprint: Vector2i = placement.footprint
		_content_rows = maxi(_content_rows, int(placement.row) + footprint.y)
		var slot: InventoryItemSlot = ITEM_SLOT_SCENE.instantiate()
		slot.position = _cell_position(int(placement.column), int(placement.row))
		slot.size = Vector2(
			cell_size.x * footprint.x + gap * (footprint.x - 1),
			cell_size.y * footprint.y + gap * (footprint.y - 1)
		)
		slot.configure(placement)
		slot.metadata_selected.connect(entry_selected.emit)
		slot.metadata_hovered.connect(entry_hovered.emit)
		slot.metadata_activated.connect(entry_activated.emit)
		add_child(slot)
	_refresh_minimum_size()
	queue_redraw()


func _refresh_minimum_size() -> void:
	custom_minimum_size = Vector2(
		columns * cell_size.x + maxi(0, columns - 1) * gap,
		_content_rows * cell_size.y + maxi(0, _content_rows - 1) * gap
	)


func _cell_position(column: int, row: int) -> Vector2:
	return Vector2(column * (cell_size.x + gap), row * (cell_size.y + gap))


func _draw() -> void:
	var fill := Color(0.025, 0.038, 0.058, 0.32)
	var border := Color(0.18, 0.25, 0.35, 0.72)
	for row in _content_rows:
		for column in columns:
			var rect := Rect2(_cell_position(column, row), cell_size)
			draw_rect(rect, fill, true)
			draw_rect(rect, border, false, 1.0)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return accepts_drops and data is Dictionary and not data.is_empty()


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if _can_drop_data(Vector2.ZERO, data):
		data_dropped.emit((data as Dictionary).duplicate(true))
