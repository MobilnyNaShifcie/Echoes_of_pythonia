extends GutTest
const Screen := preload("res://ui/screens/city_economy/city_economy.tscn")
const Fixture := preload("res://tests/fixtures/equipment_layout_fixture.gd")
const Model := preload("res://ui/screens/blacksmith_workbench/upgrade_view_model.gd")
const Upgrades := preload("res://core/economy/upgrade_service.gd")
const Saves := preload("res://core/save/save_game_service.gd")
const App := preload("res://scenes/app/app.tscn")
const ThemeResource := preload("res://ui/theme/game_theme.tres")


func after_each() -> void:
	# UI refreshes dispose replaced cells at the end of a frame, as in the running game.
	await wait_process_frames(3)


func _session():
	var session = Fixture.create_session()
	session.player.gold = 10000
	var plan := Upgrades.get_upgrade_plan(session.player.equipment.get_item("weapon"), 10)
	for item_id: String in plan.materials:
		session.player.inventory.add(item_id, int(plan.materials[item_id]) + 5)
	return session


func _mount(session, dimensions := Vector2i(1920, 1080)):
	var viewport := SubViewport.new()
	viewport.size = dimensions
	var factor := minf(float(dimensions.x) / 1920.0, float(dimensions.y) / 1080.0)
	viewport.size_2d_override = Vector2i(Vector2(dimensions) / factor)
	viewport.size_2d_override_stretch = true
	add_child_autofree(viewport)
	var screen = Screen.instantiate()
	screen.theme = ThemeResource
	screen.configure(session, "blacksmith")
	viewport.add_child(screen)
	screen._open_service()
	await wait_process_frames(8)
	return screen


func _snapshot(session) -> Dictionary:
	var data := Saves.new("user://blacksmith_snapshot_not_written")._serialize_session(session)
	# Wall-clock export metadata is not player state; crossing a second must not fail this test.
	data.erase("saved_at_unix")
	return data


func _backpack_slot(picker, instance_id: String) -> InventoryItemSlot:
	for child in picker.backpack.get_children():
		if (
			child is InventoryItemSlot
			and not child.is_queued_for_deletion()
			and child.item_metadata.get("instance_id") == instance_id
		):
			return child
	return null


func _anvil_drag_point(view) -> Vector2:
	var icon: TextureRect = view.get_node("%PreviewIcon")
	return icon.get_global_transform() * (icon.size * 0.5)


func _move(viewport: Viewport, point: Vector2, previous := Vector2.ZERO, held := false) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.relative = point - previous
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	viewport.push_input(motion, true)


func _click(viewport: Viewport, point: Vector2) -> void:
	_move(viewport, point)
	await wait_process_frames(1)
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	viewport.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	viewport.push_input(event, true)
	await wait_process_frames(3)


func _drag(viewport: Viewport, start: Vector2, finish: Vector2) -> void:
	await _start_drag(viewport, start, finish)
	await _release_drag(viewport, finish)


func _start_drag(viewport: Viewport, start: Vector2, finish: Vector2) -> void:
	_move(viewport, start)
	await wait_process_frames(1)
	var event := InputEventMouseButton.new()
	event.position = start
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.pressed = true
	viewport.push_input(event, true)
	_move(viewport, start + Vector2(25, 0), start, true)
	await wait_process_frames(2)
	assert_true(viewport.gui_is_dragging())
	_move(viewport, finish, start + Vector2(25, 0), true)
	await wait_process_frames(2)


func _release_drag(viewport: Viewport, finish: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = finish
	event.button_mask = 0
	event.pressed = false
	viewport.push_input(event, true)
	await wait_process_frames(4)
