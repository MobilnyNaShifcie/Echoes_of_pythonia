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
@export var stretch_cells_to_width := false
@export var stretch_cells_to_height := false

var _entries: Array[Dictionary] = []
var _content_rows := 6


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	clip_contents = true
	resized.connect(_layout_slots)
	_refresh_minimum_size()
	_layout_slots()
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
		# The shared slot scene is also used as a standalone 68 px equipment slot.
		# Grid-owned slots must be allowed to shrink (the compact loot row uses 44 px cells).
		slot.custom_minimum_size = Vector2.ZERO
		slot.set_meta("grid_column", int(placement.column))
		slot.set_meta("grid_row", int(placement.row))
		slot.set_meta("grid_footprint", footprint)
		slot.configure(placement)
		slot.metadata_selected.connect(entry_selected.emit)
		slot.metadata_hovered.connect(entry_hovered.emit)
		slot.metadata_activated.connect(entry_activated.emit)
		add_child(slot)
	_refresh_minimum_size()
	_layout_slots()
	queue_redraw()


func _refresh_minimum_size() -> void:
	custom_minimum_size = Vector2(
		columns * cell_size.x + maxi(0, columns - 1) * gap,
		_content_rows * cell_size.y + maxi(0, _content_rows - 1) * gap
	)


func _layout_slots() -> void:
	var effective_cell := _effective_cell_size()
	for child in get_children():
		if not child is InventoryItemSlot:
			continue
		var slot := child as InventoryItemSlot
		var column := int(slot.get_meta("grid_column", 0))
		var row := int(slot.get_meta("grid_row", 0))
		var footprint: Vector2i = slot.get_meta("grid_footprint", Vector2i.ONE)
		slot.position = _cell_position(column, row, effective_cell)
		slot.size = Vector2(
			effective_cell.x * footprint.x + gap * (footprint.x - 1),
			effective_cell.y * footprint.y + gap * (footprint.y - 1)
		)
	queue_redraw()


func _effective_cell_size() -> Vector2:
	var result := cell_size
	if stretch_cells_to_width and size.x > 0.0:
		var available_width := size.x - maxi(0, columns - 1) * gap
		result.x = maxf(cell_size.x, available_width / columns)
	if stretch_cells_to_height and size.y > 0.0:
		var available_height := size.y - maxi(0, _content_rows - 1) * gap
		result.y = maxf(cell_size.y, available_height / _content_rows)
	return result


func _cell_position(column: int, row: int, effective_cell := Vector2.ZERO) -> Vector2:
	var used_cell := effective_cell if effective_cell != Vector2.ZERO else _effective_cell_size()
	return Vector2(column * (used_cell.x + gap), row * (used_cell.y + gap))


func _draw() -> void:
	var fill := Color(0.021, 0.03, 0.043, 0.86)
	var border := Color(0.2, 0.27, 0.35, 0.72)
	var inner_light := Color(0.34, 0.39, 0.45, 0.18)
	var effective_cell := _effective_cell_size()
	for row in _content_rows:
		for column in columns:
			var rect := Rect2(
				_cell_position(column, row, effective_cell) + Vector2(2, 2),
				effective_cell - Vector2(4, 4),
			)
			draw_rect(rect, fill, true)
			draw_rect(rect, border, false, 1.0)
			draw_line(
				rect.position + Vector2(1, 1), rect.end - Vector2(1, rect.size.y - 1), inner_light
			)
			draw_line(
				rect.position + Vector2(1, 1), rect.end - Vector2(rect.size.x - 1, 1), inner_light
			)


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return accepts_drops and data is Dictionary and not data.is_empty()


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if _can_drop_data(Vector2.ZERO, data):
		data_dropped.emit((data as Dictionary).duplicate(true))
