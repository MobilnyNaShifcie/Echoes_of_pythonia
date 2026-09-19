extends SceneTree
## Real app capture; never reads an existing player save.
const App := preload("res://scenes/app/app.tscn")
const Fixture := preload("res://tests/fixtures/equipment_layout_fixture.gd")
const Saves := preload("res://core/save/save_game_service.gd")


func _init() -> void:
	if not InputMap.has_action("dialogic_default_action"):
		InputMap.add_action("dialogic_default_action")
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2 or not args[0].is_absolute_path() or not args[1].is_absolute_path():
		push_error("Expected absolute evidence and isolated save directories")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(args[0])
	for dimensions: Vector2i in [Vector2i(1920, 1080), Vector2i(1366, 768), Vector2i(1280, 720)]:
		var viewport := SubViewport.new()
		viewport.size = dimensions
		var factor := minf(float(dimensions.x) / 1920.0, float(dimensions.y) / 1080.0)
		viewport.size_2d_override = Vector2i(Vector2(dimensions) / factor)
		viewport.size_2d_override_stretch = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var app = App.instantiate()
		app._save_service = Saves.new(args[1])
		viewport.add_child(app)
		var session = Fixture.create_session()
		session.player.gold = 2993
		session.player.inventory.add("whetstone", 3)
		app._current_session = session
		app._show_city_service("blacksmith")
		var screen = app.screen_host.get_child(0)
		screen._open_service()
		await _settle()
		var suffix := "%dx%d.png" % [dimensions.x, dimensions.y]
		var workbench = screen.get_node_or_null("BlacksmithWorkbench")
		if workbench == null:
			await _capture(viewport, args[0].path_join("before_" + suffix))
		else:
			await _capture(viewport, args[0].path_join("empty_" + suffix))
			workbench.picker.select_equipped("weapon")
			await _settle()
			await _capture(viewport, args[0].path_join("selected_" + suffix))
			workbench.upgrade_view.set_target_level(10)
			await _settle()
			await _capture(viewport, args[0].path_join("target10_" + suffix))
			workbench.upgrade_view.set_target_level(1)
			workbench.picker.get_node("%EquippedButton").pressed.emit()
			await _settle()
			await _capture(viewport, args[0].path_join("equipped_" + suffix))
			workbench.picker.get_node("%BackpackButton").pressed.emit()
			await _settle()
			await _capture(viewport, args[0].path_join("backpack_" + suffix))
			workbench.picker._filter("equipped")
			var preview_slots := {"chest": "chest", "boots": "feet", "earrings": "earrings"}
			for label: String in preview_slots:
				var slot: String = preview_slots[label]
				var item = session.player.equipment.get_item(slot)
				assert(item != null)
				workbench.picker.select_equipped(slot)
				await _settle()
				assert(workbench.upgrade_view.model.selected_id == item.instance_id)
				await _capture(viewport, args[0].path_join(label + "_" + suffix))
			workbench.picker.select_equipped("weapon")
			await _settle()
			var icon: TextureRect = workbench.upgrade_view.get_node("%PreviewIcon")
			var start: Vector2 = icon.get_global_transform() * (icon.size * 0.5)
			var finish: Vector2 = workbench.picker.character_panel.get_global_rect().get_center()
			_move(viewport, start)
			await _settle()
			var mouse := InputEventMouseButton.new()
			mouse.position = start
			mouse.button_index = MOUSE_BUTTON_LEFT
			mouse.button_mask = MOUSE_BUTTON_MASK_LEFT
			mouse.pressed = true
			viewport.push_input(mouse, true)
			_move(viewport, start + Vector2(25, 0), start, true)
			await _settle()
			assert(viewport.gui_is_dragging())
			_move(viewport, finish, start + Vector2(25, 0), true)
			await _settle()
			await _capture(viewport, args[0].path_join("drag_return_" + suffix))
			mouse = mouse.duplicate()
			mouse.position = finish
			mouse.button_mask = 0
			mouse.pressed = false
			viewport.push_input(mouse, true)
			await _settle()
			assert(viewport.gui_is_drag_successful())
			assert(workbench.upgrade_view.model.selected_id.is_empty())
			await _capture(viewport, args[0].path_join("returned_" + suffix))
			# Detached fixture definition: verify the largest comparison without touching saves.
			var lance = session.player.equipment.get_item("weapon")
			lance.definition = lance.definition.duplicate()
			lance.definition.attack = 20
			lance.definition.defense = 20
			lance.definition.max_hp = 100
			workbench.picker.select_equipped("weapon")
			workbench.upgrade_view.set_target_level(10)
			await _settle()
			await _capture(viewport, args[0].path_join("multi_stat_" + suffix))
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		app.queue_free()
		await _settle()
		viewport.queue_free()
		await _settle()
		print("BLACKSMITH CAPTURE ", suffix)
	quit(0)


func _capture(viewport: SubViewport, path: String) -> void:
	await RenderingServer.frame_post_draw
	assert(viewport.get_texture().get_image().save_png(path) == OK)


func _move(viewport: Viewport, point: Vector2, previous := Vector2.ZERO, held := false) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.relative = point - previous
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	viewport.push_input(motion, true)


func _settle() -> void:
	for frame in 20:
		await process_frame
