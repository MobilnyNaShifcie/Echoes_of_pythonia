extends "res://tests/fixtures/blacksmith_ui_test_base.gd"


func test_anvil_background_and_slots_do_not_move_between_selection_states() -> void:
	for dimensions in [Vector2i(1920, 1080), Vector2i(1366, 768), Vector2i(1280, 720)]:
		var session = _session()
		var screen = await _mount(session, dimensions)
		var view = screen.blacksmith_workbench.upgrade_view
		var picker = screen.blacksmith_workbench.picker
		var baseline := _frame(view, picker)
		var player_before := _snapshot(session)
		assert_false(view.get_node("%LevelControls").visible)
		assert_false(view.get_node("%UpgradeDetails").visible)
		for item in _owned_items(session):
			view.select_item(Model.payload(item))
			for target in [1, 10]:
				view.set_target_level(target)
				await wait_process_frames(4)
				assert_eq(_frame(view, picker), baseline, item.item_id)
				assert_true(view.get_node("%LevelControls").visible)
				assert_true(view.get_node("%UpgradeDetails").visible)
			view.return_item(view.anvil.return_payload)
			await wait_process_frames(4)
			assert_eq(_frame(view, picker), baseline, "Returning must not reframe the stage.")
			assert_false(view.get_node("%UpgradeDetails").visible)
		# Switching sources with an occupied anvil cannot resize either layer.
		picker.select_equipped("weapon")
		for source in ["backpack", "equipped"]:
			picker._filter(source)
			await wait_process_frames(4)
			assert_eq(_frame(view, picker), baseline)
		assert_eq(_snapshot(session), player_before)


func test_overlay_does_not_cover_items_or_surface_and_stays_within_panel() -> void:
	for dimensions in [Vector2i(1920, 1080), Vector2i(1366, 768), Vector2i(1280, 720)]:
		var session = _session()
		# Exercise the tallest allowed comparison on the widest artwork too.
		var lance = session.player.equipment.get_item("weapon")
		lance.definition = lance.definition.duplicate()
		lance.definition.attack = 20
		lance.definition.defense = 20
		lance.definition.max_hp = 100
		var screen = await _mount(session, dimensions)
		var view = screen.blacksmith_workbench.upgrade_view
		for item in _owned_items(session):
			view.select_item(Model.payload(item))
			for target in [1, 10]:
				view.set_target_level(target)
				await wait_process_frames(4)
				var details: Control = view.get_node("%UpgradeDetails")
				var levels: Control = view.get_node("%LevelControls")
				var icon: TextureRect = view.get_node("%PreviewIcon")
				var icon_bounds := _visual_bounds(icon)
				assert_true(view.get_global_rect().encloses(details.get_global_rect()))
				assert_true(view.anvil.get_global_rect().encloses(icon_bounds), item.item_id)
				assert_gte(icon_bounds.position.y, levels.get_global_rect().end.y, item.item_id)
				assert_lte(icon_bounds.end.y, details.global_position.y, item.item_id)
				assert_lt(
					view.anvil.global_position.y + view.anvil.contact_point.y,
					details.global_position.y
				)
				assert_almost_eq(
					details.get_global_rect().end.y, view.anvil.get_global_rect().end.y, 0.01
				)
				assert_true(
					details.get_global_rect().encloses(view.action_button.get_global_rect())
				)
				assert_eq(details.mouse_filter, Control.MOUSE_FILTER_STOP)
				assert_eq(details.get_parent().mouse_filter, Control.MOUSE_FILTER_IGNORE)
		# At +10 the compact details can shrink, but the scenery must not.
		var frame := _frame(view, screen.blacksmith_workbench.picker)
		lance.upgrade_level = 10
		view.select_item(Model.payload(lance))
		await wait_process_frames(4)
		assert_eq(_frame(view, screen.blacksmith_workbench.picker), frame)


func _owned_items(session) -> Array:
	var items: Array = session.player.inventory.equipment_items.duplicate()
	for slot in session.player.equipment.slots:
		var item = session.player.equipment.get_item(slot)
		if item != null:
			items.append(item)
	return items


func _frame(view, picker) -> Dictionary:
	var slots := {}
	for slot in picker.character_panel.slot_buttons:
		slots[slot] = picker.character_panel.slot_buttons[slot].get_global_rect()
	return {
		"stage": view.anvil.get_global_rect(),
		"art": view.anvil.get_node("AnvilArt").get_global_rect(),
		"backdrop": view.anvil.get_node("ForgeBackdrop").get_global_rect(),
		"contact": view.anvil.contact_point,
		"panel": view.get_global_rect(),
		"slots": slots,
	}
