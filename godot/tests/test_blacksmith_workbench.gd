extends "res://tests/fixtures/blacksmith_ui_test_base.gd"


func test_empty_anvil_and_opening_do_not_modify_the_player() -> void:
	var session = _session()
	var before := _snapshot(session)
	var screen = await _mount(session)
	var view = screen.blacksmith_workbench.upgrade_view
	assert_true(view.model.selection().is_empty())
	assert_true(view.action_button.disabled)
	assert_null(view.get_node_or_null("%EmptyHint"))
	assert_false(view.get_node("%ItemName").visible)
	assert_false(view.action_button.visible)
	assert_false(view.get_node("%ResourceScroll").visible)
	assert_gt(view.anvil.size.y, view.size.y * 0.85)
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
	assert_eq(bench.upgrade_view.model.selection().source, "Plecak")
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
				assert_eq(tile.get_node("%Owned").text, "0 / %d" % tile.required)
				assert_string_contains(tile.tooltip_text, "Potrzeba: %d" % tile.required)
				assert_null(tile.get_node_or_null("%Availability"))
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
	assert_null(picker.get_node_or_null("%AllButton"))
	assert_eq(picker.get_node("Header").get_child_count(), 2)
	assert_true(picker.get_node("%EquippedButton").button_pressed)
	assert_false(picker.get_node("%BackpackButton").button_pressed)
	assert_eq(picker._source, "equipped")
	assert_false(picker.get_node("%BackpackPanel").visible)
	assert_true(picker.character_panel.is_visible_in_tree())
	assert_eq(picker.character_panel.slot_buttons.size(), 11)
	picker.select_equipped("weapon")
	var view = screen.blacksmith_workbench.upgrade_view
	view.set_target_level(5)
	var selected_id: String = view.model.selected_id
	picker.get_node("%BackpackButton").pressed.emit()
	assert_false(picker.character_panel.is_visible_in_tree())
	assert_false(picker.character_panel.nameplate_label.is_visible_in_tree())
	for slot: Control in picker.character_panel.slot_buttons.values():
		assert_false(slot.is_visible_in_tree())
	assert_true(picker.get_node("%BackpackPanel").visible)
	picker.select_equipped("weapon")
	assert_eq(view.model.selected_id, selected_id)
	assert_eq(view.model.target_level, 5)
	var bag_item = session.player.inventory.equipment_items[0]
	picker._select(Model.payload(bag_item))
	view.set_target_level(4)
	picker.get_node("%EquippedButton").pressed.emit()
	assert_same(view.model.selection().item, bag_item)
	assert_eq(view.model.target_level, 4)
	assert_true(picker.character_panel.is_visible_in_tree())
	assert_false(picker.backpack.is_visible_in_tree())
	assert_same(picker.character_panel.character_visual.character_texture(), texture)
	assert_eq(_snapshot(session), before)
	screen._show_ambient_view()
	screen._open_service()
	assert_eq(picker._source, "equipped", "Every fresh opening defaults to equipped.")


func test_real_click_drag_and_cancel_do_not_equip_or_purchase_automatically() -> void:
	for dimensions in [Vector2i(1920, 1080), Vector2i(1366, 768)]:
		await _exercise_pointer_selection(dimensions)


func _exercise_pointer_selection(dimensions: Vector2i) -> void:
	var session = _session()
	var screen = await _mount(session, dimensions)
	var bench = screen.blacksmith_workbench
	var viewport: Viewport = screen.get_viewport()
	var button: Button = bench.picker.character_panel.slot_buttons.weapon
	var before := _snapshot(session)
	await _click(viewport, button.get_global_rect().get_center())
	assert_eq(
		bench.upgrade_view.model.selected_id,
		session.player.equipment.get_item("weapon").instance_id
	)
	bench.upgrade_view.clear_selection()
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
	var anvil = bench.upgrade_view.anvil
	await _drag(viewport, anvil.global_position + anvil.contact_point, Vector2(25, 500))
	assert_false(viewport.gui_is_drag_successful())
	assert_eq(_snapshot(session), before)
	await _click(viewport, bench.picker.get_node("%BackpackButton").get_global_rect().get_center())
	var backpack_item = session.player.inventory.equipment_items[0]
	var backpack_button := _backpack_slot(bench.picker, backpack_item.instance_id)
	assert_not_null(backpack_button)
	if backpack_button != null:
		await _click(viewport, backpack_button.get_global_rect().get_center())
		assert_same(bench.upgrade_view.model.selection().item, backpack_item)
		bench.upgrade_view.clear_selection()
		await wait_process_frames(4)
		backpack_button = _backpack_slot(bench.picker, backpack_item.instance_id)
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
				bench.picker.character_panel
			]:
				if not control.is_visible_in_tree():
					continue
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
		assert_true(bounds.encloses(bench.picker.character_panel.get_global_rect()))
		var resources: Control = bench.upgrade_view.get_node("%ResourceScroll")
		var tiles: Array[Node] = bench.upgrade_view.get_node("%Materials").get_children()
		assert_eq(tiles[1].resource_id, "gold", "The total gold cost remains in the first row.")
		assert_true(resources.get_global_rect().encloses(tiles[1].get_global_rect()))
		bench.picker.get_node("%BackpackButton").pressed.emit()
		await wait_process_frames(8)
		var panel: Control = bench.picker.get_node("%BackpackPanel")
		var scroll: ScrollContainer = bench.picker.get_node("%BackpackScroll")
		var grid: InventoryGridView = bench.picker.backpack
		assert_true(bounds.encloses(panel.get_global_rect()))
		assert_gt(panel.size.y, bench.picker.size.y * 0.85)
		assert_gt(scroll.size.y, panel.size.y * 0.85)
		assert_gt(scroll.size.x, panel.size.x * 0.9)
		assert_gte(grid.cell_size.x, 96.0)
		assert_gte(grid.visible_rows, 5)
		assert_lte(grid.custom_minimum_size.x, scroll.size.x)
		assert_false(bench.picker.character_panel.is_visible_in_tree())
		var equipped: Button = bench.picker.get_node("%EquippedButton")
		var backpack: Button = bench.picker.get_node("%BackpackButton")
		assert_almost_eq(equipped.size.x, backpack.size.x, 1.0)
		assert_gt(
			backpack.get_theme_stylebox("pressed").bg_color.get_luminance(),
			equipped.get_theme_stylebox("normal").bg_color.get_luminance()
		)


func test_expanded_backpack_adapts_columns_and_scrolls_without_changing_ownership() -> void:
	var session = _session()
	var item_id: String = session.player.inventory.equipment_items[0].item_id
	session.player.inventory.add(item_id, 100)
	var before := _snapshot(session)
	var picker = preload("res://ui/components/equipment_picker/equipment_picker.tscn").instantiate()
	add_child_autofree(picker)
	picker.configure(session)
	picker.get_node("%BackpackButton").pressed.emit()
	picker.size = Vector2(760, 900)
	await wait_process_frames(8)
	var narrow_columns: int = picker.backpack.columns
	picker.size = Vector2(1100, 900)
	await wait_process_frames(8)
	assert_gt(picker.backpack.columns, narrow_columns)
	var scroll: ScrollContainer = picker.get_node("%BackpackScroll")
	assert_gt(picker.backpack.size.y, scroll.size.y)
	assert_lte(picker.backpack.custom_minimum_size.x, scroll.size.x)
	scroll.scroll_vertical = 100000
	await wait_process_frames(3)
	assert_gt(scroll.scroll_vertical, 0)
	assert_eq(
		picker.backpack.entry_count(),
		session.player.inventory.equipment_items.size() + session.player.inventory.stacks.size()
	)
	assert_string_contains(
		picker.get_node("%BackpackSummary").text,
		"Zajęte miejsca: %d" % picker.backpack.entry_count()
	)
	assert_string_contains(picker.get_node("%BackpackSummary").text, "Udźwig")
	assert_eq(_snapshot(session), before)


func test_upgraded_instances_refresh_in_both_tabs_without_changing_the_active_source() -> void:
	var session = _session()
	var screen = await _mount(session)
	var bench = screen.blacksmith_workbench
	var picker = bench.picker
	var equipped = session.player.equipment.get_item("weapon")
	var bag_item = session.player.inventory.equipment_items[0]
	var count: int = session.player.inventory.equipment_items.size()
	for item in [equipped, bag_item]:
		picker._filter("equipped" if item == equipped else "backpack")
		picker._select(Model.payload(item))
		# Confirm while viewing the other source: selection must remain on the anvil.
		picker._filter("backpack" if item == equipped else "equipped")
		var source: String = picker._source
		var instance_id: String = item.instance_id
		bench.upgrade_view.perform_upgrade()
		await wait_process_frames(4)
		assert_eq(picker._source, source)
		assert_eq(item.instance_id, instance_id)
		assert_eq(item.upgrade_level, 1)
		var slot: InventoryItemSlot = (
			picker.character_panel.slot_buttons.weapon
			if item == equipped
			else _backpack_slot(picker, instance_id)
		)
		assert_string_contains(slot.tooltip_text, "+1")
		assert_eq(slot.item_metadata.instance_id, instance_id)
		assert_null(
			slot.item_texture, "Selected equipment stays visually on the anvil after upgrading."
		)
		bench.upgrade_view.return_item(bench.upgrade_view.anvil.return_payload)
		await wait_process_frames(4)
		slot = (
			picker.character_panel.slot_buttons.weapon
			if item == equipped
			else _backpack_slot(picker, instance_id)
		)
		assert_same(slot.item_texture, item.definition.icon)
		assert_string_contains(slot.tooltip_text, "+1")
		assert_eq(
			slot.get_theme_stylebox("normal").border_color,
			InventoryItemSlot.RARITY_FRAME_COLORS[slot.rarity]
		)
		assert_same(Model.resolve(session.player, instance_id).item, item)
		assert_eq(session.player.inventory.equipment_items.size(), count)
	assert_same(session.player.equipment.get_item("weapon"), equipped)
	assert_true(session.player.inventory.equipment_items.has(bag_item))


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


func test_visual_level_rail_selects_targets_without_an_upgrade_or_player_mutation() -> void:
	var session = _session()
	var screen = await _mount(session)
	var view = screen.blacksmith_workbench.upgrade_view
	var rail = view.get_node("%LevelRail")
	assert_eq(rail.buttons.size(), 11)
	for button in rail.buttons:
		assert_true(button.disabled)
	var item = session.player.equipment.get_item("weapon")
	view.select_item(Model.payload(item))
	var before := _snapshot(session)
	await wait_process_frames(5)
	assert_eq(rail.current_level, 0)
	assert_eq(rail.target_level, 1)
	assert_true(rail.buttons[0].disabled)
	await _click(screen.get_viewport(), rail.buttons[5].get_global_rect().get_center())
	assert_eq(view.model.target_level, 5)
	assert_eq(rail.target_level, 5)
	assert_eq(view.model.plan(), Upgrades.get_upgrade_plan(item, 5))
	assert_eq(_snapshot(session), before)
	rail.buttons[10].grab_focus()
	var accept := InputEventAction.new()
	accept.action = "ui_accept"
	accept.pressed = true
	screen.get_viewport().push_input(accept, true)
	accept = accept.duplicate()
	accept.pressed = false
	screen.get_viewport().push_input(accept, true)
	await wait_process_frames(3)
	assert_eq(view.model.target_level, 10)
	assert_eq(_snapshot(session), before)
	view.set_target_level(1)
	view.perform_upgrade()
	assert_eq(rail.current_level, 1)
	assert_eq(rail.target_level, 2)
	assert_true(rail.buttons[1].disabled)
	item.upgrade_level = 10
	view.refresh()
	for button in rail.buttons:
		assert_true(button.disabled)


func test_forge_lance_is_presentation_only_with_unchanged_inventory_icon_and_instances() -> void:
	var session = _session()
	var item = session.player.equipment.get_item("weapon")
	var original_icon: Texture2D = item.definition.icon
	var before := _snapshot(session)
	var screen = await _mount(session)
	var bench = screen.blacksmith_workbench
	bench.picker.select_equipped("weapon")
	var icon: TextureRect = bench.upgrade_view.get_node("%PreviewIcon")
	assert_true(icon.texture is AtlasTexture)
	assert_string_contains(icon.texture.atlas.resource_path, "caprice_lance_forge_v1.png")
	assert_same(item.definition.icon, original_icon)
	assert_same(bench.upgrade_view.model.selection().item, item)
	assert_eq(_snapshot(session), before)
	bench.picker.get_node("%BackpackButton").pressed.emit()
	assert_same(item.definition.icon, original_icon)
	var bag_item = session.player.inventory.equipment_items[0]
	bench.upgrade_view.select_item(Model.payload(bag_item))
	assert_true(icon.texture is AtlasTexture)
	assert_same(
		icon.texture.atlas, bag_item.definition.icon, "Only transparent margins are cropped."
	)
	assert_eq(icon.rotation, 0.0, "The lance transform must not leak to another item.")
	bench.upgrade_view.clear_selection()
	assert_null(icon.texture)
	assert_false(bench.upgrade_view.anvil.occupied)
	assert_eq(_snapshot(session), before)


func test_forge_composition_contains_art_and_controls_at_supported_resolutions() -> void:
	for dimensions in [Vector2i(1920, 1080), Vector2i(1366, 768), Vector2i(1280, 720)]:
		var screen = await _mount(_session(), dimensions)
		var view = screen.blacksmith_workbench.upgrade_view
		view.select_item(Model.payload(view.model.session.player.equipment.get_item("weapon")))
		for target in [1, 10]:
			view.set_target_level(target)
			await wait_process_frames(8)
			var bounds: Rect2 = view.get_global_rect()
			var stage: Control = view.anvil
			assert_true(stage.clip_contents)
			assert_true(
				stage.get_global_rect().encloses(stage.get_node("ForgeBackdrop").get_global_rect())
			)
			var previous_bottom := bounds.position.y
			for control in [
				view.get_node("Content/Heading"),
				view.get_node("%LevelRail"),
				view.get_node("%ItemName"),
				view.get_node("%Transition"),
				view.get_node("%ResourceScroll"),
				view.action_button
			]:
				assert_true(
					bounds.encloses(control.get_global_rect()),
					"%s at %s" % [control.name, dimensions]
				)
				assert_gte(control.global_position.y, previous_bottom)
				previous_bottom = control.get_global_rect().end.y
			var icon: TextureRect = view.get_node("%PreviewIcon")
			var contact: Vector2 = icon.position + icon.pivot_offset
			assert_almost_eq(contact, stage.contact_point, Vector2(0.01, 0.01))
			assert_gt(
				icon.size.x, stage.size.x * 0.9, "Lance must not revert to a tiny inventory icon."
			)
			assert_lt(absf(icon.rotation), 0.15, "The shaft stays nearly horizontal.")
			assert_true(Rect2(Vector2.ZERO, stage.size).has_point(contact))
			var tiles: Array[Node] = view.get_node("%Materials").get_children()
			assert_string_contains(
				tiles[1].get_node("%ResourceIcon").texture.resource_path, "gold_stack.svg"
			)


func test_multi_stat_preview_keeps_readable_rows_and_confirmation_inside_panel() -> void:
	var session = _session()
	var item = session.player.equipment.get_item("weapon")
	# Private fixture resource, never the shared production definition.
	item.definition = item.definition.duplicate()
	item.definition.attack = 20
	item.definition.defense = 20
	item.definition.max_hp = 100
	var screen = await _mount(session, Vector2i(1366, 768))
	var view = screen.blacksmith_workbench.upgrade_view
	view.select_item(Model.payload(item))
	var before := _snapshot(session)
	view.set_target_level(10)
	await wait_process_frames(8)
	assert_eq(view.model.comparison().size(), 3)
	assert_gte(view.comparison_label.size.y, 78.0)
	assert_true(view.get_global_rect().encloses(view.action_button.get_global_rect()))
	assert_lte(
		_visual_bounds(view.get_node("%PreviewIcon")).end.y,
		view.get_node("%UpgradeDetails").global_position.y
	)
	assert_eq(_snapshot(session), before)
