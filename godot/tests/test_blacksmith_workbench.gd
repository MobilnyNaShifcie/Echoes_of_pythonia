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


func test_empty_anvil_and_opening_do_not_modify_the_player() -> void:
	var session = _session()
	var before := _snapshot(session)
	var screen = await _mount(session)
	var view = screen.blacksmith_workbench.upgrade_view
	assert_true(view.model.selection().is_empty())
	assert_true(view.action_button.disabled)
	assert_true(view.get_node("%EmptyHint").visible)
	assert_eq(view.get_node("%ItemName").text, "Umieść przedmiot do ulepszenia")
	assert_false(screen.mode_selector.is_visible_in_tree())
	assert_false(screen.get_node("%BackButton").is_visible_in_tree())
	assert_false(screen.close_service_button.is_visible_in_tree())
	assert_eq(_snapshot(session), before)


func test_equipped_and_backpack_selection_only_borrows_the_same_instance() -> void:
	var session = _session()
	var before := _snapshot(session)
	var screen = await _mount(session)
	var bench = screen.blacksmith_workbench
	for item in [
		session.player.equipment.get_item("weapon"), session.player.inventory.equipment_items[0]
	]:
		bench.upgrade_view.select_item(Model.payload(item))
		assert_same(bench.upgrade_view.model.selection().item, item)
		assert_true(bench.upgrade_view.anvil.occupied)
		assert_eq(item.upgrade_level, 0)
	assert_eq(bench.upgrade_view.get_node("%Source").text, "Źródło: Plecak")
	assert_eq(_snapshot(session), before)


func test_invalid_stack_forged_or_stale_drag_data_are_rejected() -> void:
	var session = _session()
	var screen = await _mount(session)
	var view = screen.blacksmith_workbench.upgrade_view
	var before := _snapshot(session)
	for data in [
		null,
		"not an item",
		{},
		{"kind": "stack", "item_id": "whetstone"},
		{"kind": "upgrade_equipment", "instance_id": "not-owned"}
	]:
		assert_false(view.anvil._can_drop_data(Vector2.ZERO, data))
		view.anvil._drop_data(Vector2.ZERO, data)
	assert_true(view.model.selection().is_empty())
	assert_eq(_snapshot(session), before)
	var found := false
	for slot in screen.blacksmith_workbench.picker.backpack.get_children():
		if slot is InventoryItemSlot and slot.item_quantity > 0:
			found = true
			assert_true(slot.locked)
			assert_true(slot.drag_payload.is_empty())
			assert_string_contains(slot.lock_reason, "nie podlega ulepszaniu")
	assert_true(found)


func test_unaffordable_resources_disable_confirmation_and_report_exact_shortage() -> void:
	for missing in ["material", "gold"]:
		var session = _session()
		if missing == "material":
			session.player.inventory.remove_item(
				"whetstone", session.player.inventory.count("whetstone")
			)
		else:
			session.player.gold = 0
		var screen = await _mount(session)
		var bench = screen.blacksmith_workbench
		bench.picker.select_equipped("weapon")
		var before := _snapshot(session)
		assert_true(bench.upgrade_view.action_button.disabled)
		bench.upgrade_view.perform_upgrade()
		assert_eq(_snapshot(session), before)
		var checked := false
		for tile in bench.upgrade_view.get_node("%Materials").get_children():
			if tile.resource_id == ("whetstone" if missing == "material" else "gold"):
				checked = true
				assert_eq(tile.owned, 0)
				assert_eq(tile.get_node("%Availability").text, "Brakuje %d" % tile.required)
		assert_true(checked)


func test_target_control_uses_canonical_multi_level_totals_without_mutating_preview() -> void:
	var session = _session()
	var screen = await _mount(session)
	var view = screen.blacksmith_workbench.upgrade_view
	var item = session.player.equipment.get_item("weapon")
	view.select_item(Model.payload(item))
	var before := _snapshot(session)
	for target in range(1, 11):
		view.set_target_level(target)
		assert_eq(view.model.plan(), Upgrades.get_upgrade_plan(item, target))
		assert_eq(view.action_button.text, "Ulepsz do +%d" % target)
		for stat: Dictionary in view.model.comparison():
			assert_gt(float(stat.delta), 0.0)
			assert_almost_eq(float(stat.after) - float(stat.before), float(stat.delta), 0.001)
		assert_eq(_snapshot(session), before)
	view.set_target_level(99)
	assert_eq(view.model.target_level, 10)
	view.set_target_level(-1)
	assert_eq(view.model.target_level, 1)
	view.get_node("%PlusButton").pressed.emit()
	assert_eq(view.model.target_level, 2)
	view.get_node("%MinusButton").pressed.emit()
	assert_eq(view.model.target_level, 1)


func test_single_and_multi_level_upgrades_are_atomic_without_loss_or_duplication() -> void:
	for source in ["equipped", "backpack"]:
		for levels in [1, 5]:
			var session = _session()
			var screen = await _mount(session)
			var bench = screen.blacksmith_workbench
			var item = (
				session.player.equipment.get_item("weapon")
				if source == "equipped"
				else session.player.inventory.equipment_items[0]
			)
			var initial_id: String = item.instance_id
			var before: int = session.player.inventory.equipment_items.size()
			var gold: int = session.player.gold
			var plan := Upgrades.get_upgrade_plan(item, levels)
			var stacks: Dictionary = session.player.inventory.stacks.duplicate(true)
			bench.upgrade_view.select_item(Model.payload(item))
			bench.upgrade_view.set_target_level(levels)
			watch_signals(screen)
			bench.upgrade_view.action_button.pressed.emit()
			assert_eq(item.upgrade_level, levels)
			assert_eq(item.instance_id, initial_id)
			assert_eq(session.player.inventory.equipment_items.size(), before)
			assert_same(Model.resolve(session.player, initial_id).item, item)
			assert_eq(session.player.gold, gold - int(plan.gold))
			for id: String in plan.materials:
				assert_eq(
					session.player.inventory.count(id), int(stacks[id]) - int(plan.materials[id])
				)
			assert_signal_emit_count(screen, "state_changed", 1)
			assert_string_contains(screen.summary_label.text, str(session.player.gold))


func test_maximum_level_is_visible_but_cannot_be_upgraded() -> void:
	var session = _session()
	var item = session.player.equipment.get_item("weapon")
	item.upgrade_level = 10
	session.player.recalculate_stats()
	var screen = await _mount(session)
	var bench = screen.blacksmith_workbench
	bench.picker.select_equipped("weapon")
	assert_eq(bench.upgrade_view.action_button.text, "Maksymalny poziom")
	assert_true(bench.upgrade_view.action_button.disabled)
	assert_true(bench.upgrade_view.get_node("%PlusButton").disabled)
	var before := _snapshot(session)
	bench.upgrade_view.perform_upgrade()
	assert_eq(_snapshot(session), before)


func test_ownership_and_cost_are_rechecked_at_confirmation() -> void:
	var session = _session()
	var screen = await _mount(session)
	var view = screen.blacksmith_workbench.upgrade_view
	var item = session.player.inventory.equipment_items[0]
	view.select_item(Model.payload(item))
	session.player.inventory.equipment_items.erase(item)
	var before := _snapshot(session)
	view.perform_upgrade()
	assert_eq(_snapshot(session), before)
	assert_eq(item.upgrade_level, 0)
	view.select_item(Model.payload(session.player.equipment.get_item("weapon")))
	session.player.gold = 0
	before = _snapshot(session)
	view.perform_upgrade()
	assert_eq(_snapshot(session), before)


func test_filters_do_not_change_equipment_or_the_hero_art() -> void:
	var session = _session()
	var screen = await _mount(session)
	var picker = screen.blacksmith_workbench.picker
	var before := _snapshot(session)
	var texture: Texture2D = picker.character_panel.character_visual.character_texture()
	picker.get_node("%EquippedButton").pressed.emit()
	assert_false(picker.get_node("%BackpackPanel").visible)
	picker.get_node("%BackpackButton").pressed.emit()
	assert_true(picker.character_panel.visible)
	assert_true(picker.get_node("%BackpackPanel").visible)
	picker.select_equipped("weapon")
	assert_true(screen.blacksmith_workbench.upgrade_view.model.selection().is_empty())
	picker.get_node("%AllButton").pressed.emit()
	picker.select_equipped("weapon")
	assert_false(screen.blacksmith_workbench.upgrade_view.model.selection().is_empty())
	assert_same(picker.character_panel.character_visual.character_texture(), texture)
	assert_eq(_snapshot(session), before)


func test_real_click_drag_and_cancel_do_not_equip_or_purchase_automatically() -> void:
	var session = _session()
	var screen = await _mount(session)
	var bench = screen.blacksmith_workbench
	var viewport: Viewport = screen.get_viewport()
	var button: Button = bench.picker.character_panel.slot_buttons.weapon
	var before := _snapshot(session)
	await _click(viewport, button.get_global_rect().get_center())
	assert_eq(
		bench.upgrade_view.model.selected_id,
		session.player.equipment.get_item("weapon").instance_id
	)
	bench.upgrade_view.get_node("%ClearButton").pressed.emit()
	await wait_process_frames(5)
	await _drag(
		viewport,
		button.get_global_rect().get_center(),
		bench.upgrade_view.anvil.get_global_rect().get_center()
	)
	assert_true(viewport.gui_is_drag_successful())
	assert_eq(_snapshot(session), before)
	assert_same(
		session.player.equipment.get_item("weapon"), bench.upgrade_view.model.selection().item
	)
	await _drag(viewport, button.get_global_rect().get_center(), Vector2(25, 500))
	assert_false(viewport.gui_is_drag_successful())
	assert_eq(_snapshot(session), before)
	var backpack_item = session.player.inventory.equipment_items[0]
	var backpack_button: InventoryItemSlot
	for child in bench.picker.backpack.get_children():
		if (
			child is InventoryItemSlot
			and child.item_metadata.get("instance_id") == backpack_item.instance_id
		):
			backpack_button = child
	assert_not_null(backpack_button)
	if backpack_button != null:
		await _drag(
			viewport,
			backpack_button.get_global_rect().get_center(),
			bench.upgrade_view.anvil.get_global_rect().get_center()
		)
		assert_true(viewport.gui_is_drag_successful())
		assert_same(bench.upgrade_view.model.selection().item, backpack_item)
		assert_eq(bench.upgrade_view.model.selection().source, "Plecak")
		assert_eq(_snapshot(session), before)


func test_navigation_and_escape_restore_the_existing_garran_screen() -> void:
	var screen = await _mount(_session())
	var bench = screen.blacksmith_workbench
	var viewport: Viewport = screen.get_viewport()
	await _click(viewport, bench.get_node("%ServicesButton").get_global_rect().get_center())
	assert_eq(screen._interaction_state, "focused")
	assert_false(bench.visible)
	assert_true(screen.npc_action_panel.visible)
	screen._open_service()
	await wait_process_frames(4)
	await _click(viewport, bench.get_node("%CloseButton").get_global_rect().get_center())
	assert_eq(screen._interaction_state, "ambient")
	assert_true(screen.get_node("%BackButton").is_visible_in_tree())
	screen._open_service()
	await wait_process_frames(4)
	bench.get_node("%ServicesButton").grab_focus()
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	viewport.push_input(escape, true)
	await wait_process_frames(3)
	assert_eq(screen._interaction_state, "ambient")
	assert_false(bench.visible)


func test_full_layout_at_both_resolutions_has_no_clipped_action_slots_or_backpack() -> void:
	for dimensions in [Vector2i(1920, 1080), Vector2i(1366, 768)]:
		var screen = await _mount(_session(), dimensions)
		var bench = screen.blacksmith_workbench
		var bounds: Rect2 = screen.get_global_rect()
		for selected in [false, true]:
			if selected:
				bench.picker.select_equipped("weapon")
			await wait_process_frames(6)
			for control: Control in [
				bench.upgrade_view,
				bench.picker,
				bench.upgrade_view.action_button,
				bench.get_node("%CloseButton"),
				bench.picker.get_node("%BackpackPanel")
			]:
				assert_true(
					bounds.encloses(control.get_global_rect()),
					"%s at %s" % [control.name, dimensions]
				)
			assert_false(
				bench.upgrade_view.get_global_rect().intersects(bench.picker.get_global_rect())
			)
			assert_eq(bench.picker.character_panel.slot_buttons.size(), 11)
			var rects: Array[Rect2] = []
			for button: Control in bench.picker.character_panel.slot_buttons.values():
				var rect := button.get_global_rect()
				assert_true(bounds.encloses(rect))
				assert_almost_eq(rect.size.x, rect.size.y, 0.01)
				for other: Rect2 in rects:
					assert_false(other.intersects(rect))
				rects.append(rect)
			var visual = bench.picker.character_panel.character_visual
			var hero: Rect2 = visual.character_visible_rect()
			hero.position += visual.global_position
			assert_true(bounds.encloses(hero))
			for rect: Rect2 in rects:
				assert_false(rect.intersects(hero))
		bench.upgrade_view.set_target_level(10)
		await wait_process_frames(6)
		assert_true(bounds.encloses(bench.upgrade_view.action_button.get_global_rect()))
		assert_true(bounds.encloses(bench.picker.get_node("%BackpackPanel").get_global_rect()))
		var resources: Control = bench.upgrade_view.get_node("Content/ResourceScroll")
		var tiles: Array[Node] = bench.upgrade_view.get_node("%Materials").get_children()
		assert_eq(tiles[1].resource_id, "gold", "The total gold cost remains in the first row.")
		assert_true(resources.get_global_rect().encloses(tiles[1].get_global_rect()))


func test_real_app_autosave_and_reload_keep_the_upgraded_instances() -> void:
	var session = _session()
	var saves := Saves.new("user://blacksmith_workbench_test_" + str(Time.get_ticks_usec()))
	var app = App.instantiate()
	app._save_service = saves
	add_child_autofree(app)
	app._current_session = session
	app._show_city_service("blacksmith")
	var screen = app.screen_host.get_child(0)
	screen._open_service()
	var bench = screen.blacksmith_workbench
	for item in [
		session.player.equipment.get_item("weapon"), session.player.inventory.equipment_items[0]
	]:
		bench.upgrade_view.select_item(Model.payload(item))
		bench.upgrade_view.set_target_level(3)
		bench.upgrade_view.perform_upgrade()
		var result := saves.load_session(1)
		assert_true(result.ok, result.message)
		if not result.ok:
			return
		var restored := Model.resolve(result.session.player, item.instance_id)
		assert_false(restored.is_empty())
		assert_eq(restored.item.upgrade_level, 3)
		assert_eq(restored.item.item_id, item.item_id)
		assert_eq(restored.source, Model.resolve(session.player, item.instance_id).source)
		assert_eq(result.session.player.gold, session.player.gold)
		assert_eq(result.session.player.inventory.stacks, session.player.inventory.stacks)
		assert_eq(result.session.player.stats.attack, session.player.stats.attack)
		assert_eq(
			result.session.player.inventory.equipment_items.size(),
			session.player.inventory.equipment_items.size()
		)


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
	event = event.duplicate()
	event.position = finish
	event.button_mask = 0
	event.pressed = false
	viewport.push_input(event, true)
	await wait_process_frames(4)
