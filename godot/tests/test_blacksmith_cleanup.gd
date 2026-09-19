extends "res://tests/fixtures/blacksmith_ui_test_base.gd"


func test_clean_workbench_has_no_duplicate_labels_or_empty_footer() -> void:
	var session = _session()
	var screen = await _mount(session)
	var bench = screen.blacksmith_workbench
	var view = bench.upgrade_view
	for path in [
		"%ClearButton",
		"%Source",
		"%Result",
		"%BlockReason",
		"%NoRequirements",
		"%EmptyHint",
		"Content/ResourcesHeading"
	]:
		assert_null(view.get_node_or_null(path), path)
	assert_null(bench.get_node_or_null("%ResourcesLabel"))
	assert_null(bench.get_node_or_null("Margin/Layout/BodyScroll/Columns/ForgeView/ForgeLabel"))
	assert_false(view.action_button.visible)
	assert_false(view.get_node("%LevelRail").visible)
	assert_gt(view.anvil.size.y, view.size.y * 0.85)
	bench.picker.select_equipped("weapon")
	assert_false(view.comparison_label.visible)
	assert_eq(view.comparison_label.text, "")
	session.player.inventory.remove_item("whetstone", session.player.inventory.count("whetstone"))
	view.refresh()
	assert_true(view.action_button.disabled)
	assert_string_contains(view.action_button.tooltip_text, "Osełka")
	assert_null(view.get_node_or_null("%BlockReason"))


func test_roundtrip_drag_restores_exact_source_and_cancels_safely_at_all_sizes() -> void:
	for dimensions in [Vector2i(1920, 1080), Vector2i(1366, 768), Vector2i(1280, 720)]:
		var session = _session()
		var screen = await _mount(session, dimensions)
		var bench = screen.blacksmith_workbench
		var view = bench.upgrade_view
		var picker = bench.picker
		var viewport: Viewport = screen.get_viewport()
		var before := _snapshot(session)
		for source in ["equipped", "backpack"]:
			picker._filter(source)
			await wait_process_frames(5)
			var item = (
				session.player.equipment.get_item("weapon")
				if source == "equipped"
				else session.player.inventory.equipment_items[0]
			)
			var slot: InventoryItemSlot = (
				picker.character_panel.slot_buttons.weapon
				if source == "equipped"
				else _backpack_slot(picker, item.instance_id)
			)
			var original_position := slot.global_position
			await _drag(
				viewport,
				slot.get_global_rect().get_center(),
				view.anvil.get_global_rect().get_center()
			)
			assert_true(viewport.gui_is_drag_successful())
			assert_same(view.model.selection().item, item)
			slot = (
				picker.character_panel.slot_buttons.weapon
				if source == "equipped"
				else _backpack_slot(picker, item.instance_id)
			)
			assert_null(slot.item_texture)
			assert_true(slot.drag_payload.is_empty())
			assert_eq(slot.global_position, original_position)
			assert_eq(_snapshot(session), before)
			await _drag(viewport, _anvil_drag_point(view), Vector2(25, 500))
			assert_false(viewport.gui_is_drag_successful())
			assert_true(view.get_node("%PreviewIcon").visible)
			assert_same(view.model.selection().item, item)
			assert_eq(_snapshot(session), before)
			# Return onto a different occupied cell: restore the source, never swap equipment.
			var target: Vector2 = (
				picker.character_panel.slot_buttons.chest.get_global_rect().get_center()
				if source == "equipped"
				else picker.backpack.global_position + Vector2(30, 30)
			)
			await _drag(viewport, _anvil_drag_point(view), target)
			assert_true(viewport.gui_is_drag_successful())
			assert_true(view.model.selected_id.is_empty())
			assert_false(view.anvil.occupied)
			slot = (
				picker.character_panel.slot_buttons.weapon
				if source == "equipped"
				else _backpack_slot(picker, item.instance_id)
			)
			assert_same(slot.item_texture, item.definition.icon)
			assert_eq(slot.global_position, original_position)
			assert_eq(_snapshot(session), before)


func test_held_item_is_visible_only_in_drag_preview_and_cancel_restores_it() -> void:
	var session = _session()
	var screen = await _mount(session)
	var view = screen.blacksmith_workbench.upgrade_view
	var picker = screen.blacksmith_workbench.picker
	var viewport: Viewport = screen.get_viewport()
	var before := _snapshot(session)
	var outside := Vector2(25, 500)
	for source in ["equipped", "backpack"]:
		picker._filter(source)
		await wait_process_frames(5)
		var item = (
			session.player.equipment.get_item("weapon")
			if source == "equipped"
			else session.player.inventory.equipment_items[0]
		)
		var slot: InventoryItemSlot = (
			picker.character_panel.slot_buttons.weapon
			if source == "equipped"
			else _backpack_slot(picker, item.instance_id)
		)
		await _start_drag(viewport, slot.get_global_rect().get_center(), outside)
		assert_false(slot.get_node("ItemIcon").visible)
		assert_false(view.anvil.occupied)
		assert_eq(_snapshot(session), before)
		await _release_drag(viewport, outside)
		slot = (
			picker.character_panel.slot_buttons.weapon
			if source == "equipped"
			else _backpack_slot(picker, item.instance_id)
		)
		assert_true(slot.get_node("ItemIcon").visible)
		assert_same(slot.item_texture, item.definition.icon)
		view.select_item(Model.payload(item))
		await wait_process_frames(5)
		await _start_drag(viewport, _anvil_drag_point(view), outside)
		assert_false(view.get_node("%PreviewIcon").visible)
		assert_true(view.anvil.dragging)
		assert_true(view.action_button.disabled)
		watch_signals(view)
		view.perform_upgrade()
		assert_signal_not_emitted(view, "operation_completed")
		assert_eq(_snapshot(session), before)
		await _release_drag(viewport, outside)
		assert_true(view.get_node("%PreviewIcon").visible)
		assert_false(view.action_button.disabled)
		view.clear_selection()
		assert_eq(_snapshot(session), before)


func test_return_tokens_swapping_tabs_reopening_and_maximum_level_keep_owned_instances() -> void:
	var session = _session()
	var screen = await _mount(session)
	var bench = screen.blacksmith_workbench
	var view = bench.upgrade_view
	var picker = bench.picker
	var item = session.player.equipment.get_item("weapon")
	var other = session.player.inventory.equipment_items[0]
	var before := _snapshot(session)
	picker.select_equipped("weapon")
	var old_payload: Dictionary = view.anvil.return_payload.duplicate()
	view.select_item(Model.payload(other))
	assert_same(picker.character_panel.slot_buttons.weapon.item_texture, item.definition.icon)
	assert_false(picker._can_drop_data(Vector2.ZERO, old_payload))
	for data in [
		null,
		{},
		Model.payload(other),
		{"kind": "forge_return", "instance_id": other.instance_id, "anvil_id": 0}
	]:
		assert_false(picker._can_drop_data(Vector2.ZERO, data))
	picker._filter("equipped")
	await wait_process_frames(5)
	await _drag(
		screen.get_viewport(),
		_anvil_drag_point(view),
		picker.character_panel.slot_buttons.weapon.get_global_rect().get_center()
	)
	assert_true(screen.get_viewport().gui_is_drag_successful())
	assert_eq(
		picker._source,
		"backpack",
		"Return opens the original source; it never equips the backpack item."
	)
	assert_same(_backpack_slot(picker, other.instance_id).item_texture, other.definition.icon)
	assert_eq(_snapshot(session), before)
	picker._filter("equipped")
	picker.select_equipped("weapon")
	screen._show_ambient_view()
	assert_true(view.model.selected_id.is_empty())
	screen._open_service()
	await wait_process_frames(5)
	assert_same(picker.character_panel.slot_buttons.weapon.item_texture, item.definition.icon)
	assert_eq(_snapshot(session), before)
	item.upgrade_level = 10
	view.select_item(Model.payload(item))
	view.anvil.grab_focus()
	var key := InputEventKey.new()
	key.keycode = KEY_BACKSPACE
	key.pressed = true
	screen.get_viewport().push_input(key, true)
	await wait_process_frames(4)
	assert_true(view.model.selected_id.is_empty())
	assert_same(picker.character_panel.slot_buttons.weapon.item_texture, item.definition.icon)
	assert_same(session.player.equipment.get_item("weapon"), item)


func test_fallback_previews_fit_fully_above_anvil_for_all_owned_equipment() -> void:
	for dimensions in [Vector2i(1920, 1080), Vector2i(1366, 768), Vector2i(1280, 720)]:
		var session = _session()
		var screen = await _mount(session, dimensions)
		var view = screen.blacksmith_workbench.upgrade_view
		var items: Array = session.player.inventory.equipment_items.duplicate()
		for slot in session.player.equipment.slots:
			var item = session.player.equipment.get_item(slot)
			if item != null and item.item_id != "caprice_lance":
				items.append(item)
		var before := _snapshot(session)
		for item in items:
			view.select_item(Model.payload(item))
			await wait_process_frames(3)
			var icon: TextureRect = view.get_node("%PreviewIcon")
			var stage: Control = view.anvil
			assert_true(stage.get_global_rect().encloses(icon.get_global_rect()), item.item_id)
			assert_almost_eq(icon.position.y + icon.size.y, stage.contact_point.y, 0.01)
			var source_size: Vector2 = icon.texture.get_size()
			assert_almost_eq(icon.size.x / icon.size.y, source_size.x / source_size.y, 0.01)
			assert_gt(icon.size.y, 10.0)
		assert_eq(_snapshot(session), before)
