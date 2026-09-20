extends "res://tests/fixtures/blacksmith_ui_test_base.gd"
const Catalog := preload("res://core/items/item_catalog.gd")


func test_all_regional_costs_are_visible_without_scrolling_at_supported_sizes() -> void:
	for dimensions in [Vector2i(1920, 1080), Vector2i(1366, 768), Vector2i(1280, 720)]:
		var session = _session()
		var item = session.player.equipment.get_item("weapon")
		# Worst case: widest artwork, three comparison rows and every material profile.
		item.definition = item.definition.duplicate()
		item.definition.attack = 20
		item.definition.defense = 20
		item.definition.max_hp = 100
		var screen = await _mount(session, dimensions)
		var view = screen.blacksmith_workbench.upgrade_view
		var anvil_frame: Rect2 = view.anvil.get_node("AnvilArt").get_global_rect()
		var panel_frame: Rect2 = view.get_global_rect()
		for power in range(1, 8):
			item.generated_item_power = power
			var before := _snapshot(session)
			view.select_item(Model.payload(item))
			for target in [10, 1, 4, 7, 10]:
				view.set_target_level(target)
				await wait_process_frames(6)
				_assert_requirements(view)
				var details: Control = view.get_node("%UpgradeDetails")
				assert_true(panel_frame.encloses(details.get_global_rect()))
				assert_true(
					details.get_global_rect().encloses(view.action_button.get_global_rect())
				)
				assert_lte(
					_visual_bounds(view.get_node("%PreviewIcon")).end.y, details.global_position.y
				)
				assert_eq(view.anvil.get_node("AnvilArt").get_global_rect(), anvil_frame)
				assert_eq(view.get_global_rect(), panel_frame)
				assert_eq(_snapshot(session), before)


func test_each_upgrade_step_uses_only_its_canonical_materials() -> void:
	var session = _session()
	var screen = await _mount(session)
	var view = screen.blacksmith_workbench.upgrade_view
	var item = session.player.equipment.get_item("weapon")
	for power in range(1, 8):
		item.generated_item_power = power
		for level in range(10):
			item.upgrade_level = level
			var before := _snapshot(session)
			view.select_item(Model.payload(item))
			await wait_process_frames(4)
			_assert_requirements(view)
			assert_eq(view.model.plan().materials, Upgrades.get_upgrade_cost(level, item).materials)
			assert_eq(_snapshot(session), before)


func test_reported_armor_has_regional_materials_and_no_whetstone_for_last_step() -> void:
	var session = _session()
	session.player.inventory.add("sunken_knight_armor")
	var item = session.player.inventory.equipment_items.back()
	var screen = await _mount(session)
	var view = screen.blacksmith_workbench.upgrade_view
	view.select_item(Model.payload(item))
	view.set_target_level(10)
	await wait_process_frames(4)
	assert_eq(view.model.plan().gold, 5075)
	assert_eq(
		view.model.plan().materials,
		{
			"whetstone": 4,
			"grinding_stone": 15,
			"sunken_plate": 12,
			"common_essence": 3,
			"silentwater_heart": 5,
		}
	)
	_assert_requirements(view)
	item.upgrade_level = 9
	view.select_item(Model.payload(item))
	await wait_process_frames(4)
	assert_eq(view.model.plan().materials, {"grinding_stone": 4, "silentwater_heart": 2})
	_assert_requirements(view)
	assert_eq(view.get_node("%Materials").get_child_count(), 3)


func test_missing_late_material_blocks_upgrade_and_success_refreshes_same_instance() -> void:
	var session = _session()
	var item = session.player.equipment.get_item("weapon")
	item.generated_item_power = 4
	var plan := Upgrades.get_upgrade_plan(item, 10)
	session.player.gold = plan.gold
	for id: String in plan.materials:
		session.player.inventory.remove_item(id, session.player.inventory.count(id))
		session.player.inventory.add(id, plan.materials[id])
	session.player.inventory.remove_item("crown_fragment", 1)
	var screen = await _mount(session)
	var view = screen.blacksmith_workbench.upgrade_view
	view.select_item(Model.payload(item))
	view.set_target_level(10)
	await wait_process_frames(4)
	_assert_requirements(view)
	assert_true(view.action_button.disabled)
	var before := _snapshot(session)
	view.perform_upgrade()
	assert_eq(_snapshot(session), before)
	session.player.inventory.add("crown_fragment", 1)
	view.refresh()
	await wait_process_frames(4)
	_assert_requirements(view)
	assert_false(view.action_button.disabled)
	var instance_id: String = item.instance_id
	var inventory_count: int = session.player.inventory.equipment_items.size()
	view.perform_upgrade()
	await wait_process_frames(4)
	assert_eq(item.upgrade_level, 10)
	assert_eq(item.instance_id, instance_id)
	assert_same(session.player.equipment.get_item("weapon"), item)
	assert_eq(session.player.inventory.equipment_items.size(), inventory_count)
	assert_eq(session.player.gold, 0)
	for id: String in plan.materials:
		assert_eq(session.player.inventory.count(id), 0, id)
	assert_false(view.get_node("%ResourceScroll").visible)
	assert_false(view.action_button.visible)
	assert_eq(view.get_node("%Materials").get_child_count(), 0)


func _assert_requirements(view) -> void:
	var plan: Dictionary = view.model.plan()
	var expected: Dictionary = plan.materials.duplicate()
	expected["gold"] = plan.gold
	var tiles: Array[Node] = view.get_node("%Materials").get_children()
	var resources: ScrollContainer = view.get_node("%ResourceScroll")
	assert_eq(tiles.size(), expected.size())
	assert_false(resources.get_v_scroll_bar().is_visible_in_tree())
	assert_false(resources.get_h_scroll_bar().is_visible_in_tree())
	var seen := {}
	for tile in tiles:
		assert_false(seen.has(tile.resource_id), "No duplicate material cards.")
		seen[tile.resource_id] = true
		assert_true(expected.has(tile.resource_id))
		assert_eq(tile.required, int(expected.get(tile.resource_id, -1)))
		var owned: int = (
			view.model.session.player.gold
			if tile.resource_id == "gold"
			else view.model.session.player.inventory.count(tile.resource_id)
		)
		assert_eq(tile.owned, owned)
		assert_eq(tile.get_node("%Owned").text, "%d / %d" % [owned, tile.required])
		assert_eq(
			tile.get_node("%Owned").get_theme_color("font_color"),
			Color(0.48, 0.87, 0.59) if owned >= tile.required else Color(1, 0.43, 0.37)
		)
		assert_true(tile.is_visible_in_tree())
		assert_true(resources.get_global_rect().encloses(tile.get_global_rect()), tile.resource_id)
		assert_not_null(tile.get_node("%ResourceIcon").texture)
		if tile.resource_id != "gold":
			assert_same(
				tile.get_node("%ResourceIcon").texture,
				Catalog.get_definition(tile.resource_id).icon
			)
			assert_eq(
				tile.get_node("%ResourceName").text,
				Catalog.get_definition(tile.resource_id).display_name
			)
		assert_string_contains(tile.tooltip_text, tile.get_node("%ResourceName").text)
		assert_string_contains(tile.tooltip_text, "Potrzeba: %d" % tile.required)
		for path in ["%ResourceName", "%Owned", "%ResourceIcon"]:
			assert_true(
				tile.get_global_rect().encloses(tile.get_node(path).get_global_rect()), path
			)
