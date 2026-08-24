class_name ItemGridLayout
extends RefCounted

const DEFAULT_COLUMNS := 8
const DEFAULT_ROWS := 6


static func footprint_for(category: String, equipment_slot := "") -> Vector2i:
	if category != "equipment":
		return Vector2i.ONE
	match equipment_slot:
		"weapon", "off_hand":
			return Vector2i(1, 2)
		"chest":
			return Vector2i(2, 2)
		_:
			return Vector2i.ONE


static func pack(
	entries: Array[Dictionary], columns := DEFAULT_COLUMNS, rows := DEFAULT_ROWS
) -> Array[Dictionary]:
	var safe_columns := maxi(1, columns)
	var safe_rows := maxi(1, rows)
	var occupied: Array[bool] = []
	occupied.resize(safe_columns * safe_rows)
	occupied.fill(false)
	var placements: Array[Dictionary] = []
	for entry: Dictionary in entries:
		var footprint := _safe_footprint(entry.get("footprint", Vector2i.ONE), safe_columns)
		var cell := _find_free_cell(occupied, safe_columns, safe_rows, footprint)
		while cell.x < 0:
			for _column in safe_columns:
				occupied.append(false)
			safe_rows += 1
			cell = _find_free_cell(occupied, safe_columns, safe_rows, footprint)
		_mark_occupied(occupied, safe_columns, cell, footprint)
		var placement := entry.duplicate(true)
		placement["column"] = cell.x
		placement["row"] = cell.y
		placement["footprint"] = footprint
		placements.append(placement)
	return placements


static func _safe_footprint(value: Variant, columns: int) -> Vector2i:
	var result := Vector2i.ONE
	if value is Vector2i:
		result = value
	elif value is Vector2:
		result = Vector2i(value)
	result.x = clampi(result.x, 1, columns)
	result.y = maxi(1, result.y)
	return result


static func _find_free_cell(
	occupied: Array[bool], columns: int, rows: int, footprint: Vector2i
) -> Vector2i:
	for row in range(rows - footprint.y + 1):
		for column in range(columns - footprint.x + 1):
			if _area_is_free(occupied, columns, Vector2i(column, row), footprint):
				return Vector2i(column, row)
	return Vector2i(-1, -1)


static func _area_is_free(
	occupied: Array[bool], columns: int, cell: Vector2i, footprint: Vector2i
) -> bool:
	for row_offset in footprint.y:
		for column_offset in footprint.x:
			var index := (cell.y + row_offset) * columns + cell.x + column_offset
			if index >= occupied.size() or occupied[index]:
				return false
	return true


static func _mark_occupied(
	occupied: Array[bool], columns: int, cell: Vector2i, footprint: Vector2i
) -> void:
	for row_offset in footprint.y:
		for column_offset in footprint.x:
			occupied[(cell.y + row_offset) * columns + cell.x + column_offset] = true
