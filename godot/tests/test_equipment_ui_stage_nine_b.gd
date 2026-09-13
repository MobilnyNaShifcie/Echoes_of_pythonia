extends GutTest

const CITY_ECONOMY_SCENE := preload("res://ui/screens/city_economy/city_economy.tscn")
const EQUIPMENT_SCENE := preload("res://ui/screens/equipment/equipment.tscn")
const INVENTORY_GRID_SCENE := preload("res://ui/components/inventory_grid/inventory_grid_view.tscn")
const ItemGridLayoutClass := preload("res://ui/components/inventory_grid/item_grid_layout.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")


func test_visual_grid_packs_large_items_without_overlap_and_is_deterministic() -> void:
	var entries: Array[Dictionary] = [
		{"id": "sword", "footprint": Vector2i(1, 2)},
		{"id": "armor", "footprint": Vector2i(2, 2)},
		{"id": "material", "footprint": Vector2i.ONE},
		{"id": "potion", "footprint": Vector2i.ONE},
	]
	var first := ItemGridLayoutClass.pack(entries, 4, 2)
	var second := ItemGridLayoutClass.pack(entries, 4, 2)

	assert_eq(first, second)
	assert_eq(Vector2i(first[0].column, first[0].row), Vector2i(0, 0))
	assert_eq(first[0].footprint, Vector2i(1, 2))
	assert_eq(Vector2i(first[1].column, first[1].row), Vector2i(1, 0))
	assert_eq(first[1].footprint, Vector2i(2, 2))
	assert_eq(Vector2i(first[2].column, first[2].row), Vector2i(3, 0))
	assert_eq(Vector2i(first[3].column, first[3].row), Vector2i(3, 1))


func test_equipment_uses_central_art_slot_transparent_slots_and_hover_details() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.gender_code = "female"
	session.player.level = 2
	session.player.inventory.add("sharpened_sword")
	session.player.inventory.add("wolf_fur", 2)
	var screen = EQUIPMENT_SCENE.instantiate()
	screen.configure(session)
	add_child_autofree(screen)

	assert_eq(screen.character_visual, screen.equipment_panel.character_visual)
	assert_not_null(screen.character_visual.character_texture())
	assert_eq(
		screen.character_visual.character_texture().resource_path,
		"res://assets/combat/heroes/seeker_female.png",
	)
	assert_eq(screen.slot_buttons.size(), 11)
	assert_eq(screen.slot_buttons.weapon.text, "")
	assert_not_null(screen.slot_buttons.weapon.item_texture)
	assert_string_contains(screen.slot_buttons.weapon.tooltip_text, "Stary Miecz +0")
	var slot_style: StyleBoxFlat = screen.slot_buttons.weapon.get_theme_stylebox("normal")
	assert_lt(slot_style.bg_color.a, 0.5)
	assert_gt(slot_style.border_color.a, slot_style.bg_color.a)
	assert_eq(screen.slot_buttons.off_hand.slot_caption, "Druga ręka")
	assert_eq(screen.slot_buttons.bracelet.slot_caption, "Bransoleta")
	assert_eq(screen.slot_buttons.ring.slot_caption, "Pierścień")
	assert_eq(screen.inventory_grid.entry_count(), 2)
	var sword_cell: InventoryItemSlot = screen.inventory_grid.get_child(0)
	assert_gt(sword_cell.size.y, sword_cell.size.x)
	var before_tooltip := sword_cell.tooltip_text
	assert_eq(sword_cell.drag_payload.kind, "equipment")
	assert_eq(sword_cell.tooltip_text, before_tooltip)
	assert_string_contains(sword_cell.tooltip_text, "Ostrzony Miecz +0")


func test_equipment_restores_neutral_seeker_art_for_legacy_unspecified_gender() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	assert_eq(session.player.gender_code, "unspecified")
	assert_eq(session.player.character_class_code, "none")
	var screen = EQUIPMENT_SCENE.instantiate()
	screen.configure(session)
	add_child_autofree(screen)

	assert_not_null(screen.character_visual.character_texture())
	assert_eq(
		screen.character_visual.character_texture().resource_path,
		"res://assets/combat/heroes/seeker_female.png",
	)


func test_equipment_layout_places_equal_columns_around_the_character() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.experience = 37
	session.player.attributes.strength = 4
	session.player.attributes.vitality = 3
	var screen = EQUIPMENT_SCENE.instantiate()
	screen.configure(session)
	add_child_autofree(screen)
	await get_tree().process_frame

	assert_eq(screen.workspace.get_child(0), screen.stats_panel)
	assert_eq(
		screen.stats_experience_label.text,
		"EXP 37 / %d" % session.player.experience_to_next_level(),
	)
	assert_eq(screen.stats_experience_bar.value, 37.0)
	assert_eq(screen.stats_strength_label.text, "4")
	assert_eq(screen.stats_vitality_label.text, "3")

	var panel: Control = screen.equipment_panel
	var head: Control = screen.slot_buttons.head
	var left: Control = screen.slot_buttons.weapon
	var right: Control = screen.slot_buttons.off_hand
	var center_x := panel.get_global_rect().get_center().x
	assert_almost_eq(head.get_global_rect().get_center().x, center_x, 1.0)
	assert_almost_eq(left.global_position.y, right.global_position.y, 1.0)
	assert_almost_eq(left.size.x, right.size.x, 1.0)
	assert_almost_eq(left.size.y, right.size.y, 1.0)
	assert_lt(head.get_global_rect().end.y, left.global_position.y)
	for button: Control in screen.slot_buttons.values():
		assert_eq(button.size, head.size)
	assert_true(screen.details_label.is_visible_in_tree())
	assert_eq(screen.stats_name_label.text, "Aria")
	assert_string_contains(screen.stats_level_label.text, "POZIOM 0")
	screen._show_equipped_details("weapon")
	assert_not_null(screen.details_icon.texture)
	assert_true(screen.details_icon.visible)


func test_backpack_grid_stretches_cells_to_fill_its_available_rectangle() -> void:
	var grid := INVENTORY_GRID_SCENE.instantiate() as InventoryGridView
	grid.columns = 8
	grid.visible_rows = 6
	grid.cell_size = Vector2(66, 66)
	grid.gap = 5.0
	grid.stretch_cells_to_width = true
	grid.stretch_cells_to_height = true
	grid.size = Vector2(820, 540)
	add_child_autofree(grid)
	grid.set_entries([{"placeholder": "A", "footprint": Vector2i.ONE}])

	var cell := grid.get_child(0) as InventoryItemSlot
	assert_gt(cell.size.x, grid.cell_size.x)
	assert_gt(cell.size.y, grid.cell_size.y)
	assert_almost_eq(cell.size.x * grid.columns + grid.gap * 7.0, grid.size.x, 0.01)
	assert_almost_eq(cell.size.y * grid.visible_rows + grid.gap * 5.0, grid.size.y, 0.01)
	assert_lte(cell.get_rect().end.x, grid.size.x)
	assert_lte(cell.get_rect().end.y, grid.size.y)


func test_equipment_grid_is_visual_only_and_keeps_weight_as_capacity_contract() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	for _index in 70:
		session.player.inventory.add("wolf_fur")
	var before_stacks: Dictionary = session.player.inventory.stacks.duplicate(true)
	var screen = EQUIPMENT_SCENE.instantiate()
	screen.configure(session)
	add_child_autofree(screen)

	assert_eq(session.player.inventory.stacks, before_stacks)
	assert_eq(session.player.inventory.count("wolf_fur"), 70)
	assert_eq(screen.inventory_grid.entry_count(), 1)
	var fur_cell: InventoryItemSlot = screen.inventory_grid.get_child(0)
	assert_eq(fur_cell.text, "")
	assert_eq(fur_cell.get_node("QuantityBadge").text, "×70")


func test_equipment_below_required_level_is_visibly_locked_but_keeps_hover_details() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var necklace = ItemCatalogClass.create_equipment_item("wolf_tooth_necklace")
	session.player.inventory.add_equipment_instance(necklace)
	var screen = EQUIPMENT_SCENE.instantiate()
	screen.configure(session)
	add_child_autofree(screen)

	var cell := screen.inventory_grid.get_child(0) as InventoryItemSlot
	assert_true(cell.locked)
	assert_eq(cell.lock_label, "POZIOM 2")
	assert_string_contains(cell.lock_reason, "Wymagany poziom: 2")
	assert_true(cell.get_node("LockShade").visible)
	assert_true(cell.get_node("LockRequirement").visible)
	assert_string_contains(cell.get_node("LockRequirement").text, "POZIOM 2")
	assert_null(cell._get_drag_data(Vector2.ZERO))
	var tooltip := cell._make_custom_tooltip(cell.tooltip_text) as PanelContainer
	var labels := tooltip.find_children("*", "Label", true, false)
	assert_eq(labels.size(), 3)
	assert_string_contains(tooltip.find_child("ItemDescription", true, false).text, "Ząb Wilka")
	assert_string_contains(tooltip.find_child("LockDescription", true, false).text, "🔒")
	assert_string_contains(
		tooltip.find_child("LockDescription", true, false).text, "Twój poziom: 0"
	)
	assert_string_contains(tooltip.find_child("RarityLabel", true, false).text, "Rzadki")
	var locked_style := cell.get_theme_stylebox("normal") as StyleBoxFlat
	assert_lt(locked_style.border_color.r, locked_style.border_color.b)
	tooltip.free()

	session.player.level = 2
	screen._refresh()
	await get_tree().process_frame
	cell = screen.inventory_grid.get_child(0) as InventoryItemSlot
	assert_false(cell.locked)
	assert_false(cell.get_node("LockRequirement").visible)


func test_oren_uses_npc_portrait_grid_tooltips_and_drag_purchase() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.gold = 100
	session.player.inventory.add("wolf_fur")
	var screen = CITY_ECONOMY_SCENE.instantiate()
	add_child_autofree(screen)
	screen.configure(session, "merchant")

	assert_string_contains(screen.npc_role_label.text, "OREN")
	assert_false(screen.npc_role_label.visible)
	assert_eq(screen.service_grid.entry_count(), 6)
	assert_eq(screen.merchant_stock_grid.entry_count(), 6)
	assert_gt(screen.merchant_player_grid.entry_count(), 0)
	assert_false(screen.item_list.is_visible_in_tree())
	var first_cell: InventoryItemSlot = screen.service_grid.get_child(0)
	assert_false(first_cell.tooltip_text.is_empty())
	var expected_rarities := ["common", "common", "common", "common", "uncommon", "epic"]
	for index in expected_rarities.size():
		assert_eq(screen.service_grid.get_child(index).rarity, expected_rarities[index])
	var common_style := first_cell.get_theme_stylebox("normal") as StyleBoxFlat
	assert_true(common_style.border_color.g <= common_style.border_color.b)
	var drag_data: Dictionary = first_cell.drag_payload.duplicate(true)
	assert_true(screen._transaction_can_drop_data(Vector2.ZERO, drag_data))
	var before_count: int = session.player.inventory.count("weak_healing_potion")
	screen._transaction_drop_data(Vector2.ZERO, drag_data)
	assert_eq(session.player.inventory.count("weak_healing_potion"), before_count + 1)
	assert_eq(session.player.gold, 75)


func test_every_city_service_reuses_the_npc_grid_and_drag_counter() -> void:
	var expected_roles := {
		"merchant": "OREN",
		"blacksmith": "GARRAN",
		"workshop": "MIRELA",
		"inn": "RUNA",
	}
	for service_id: String in expected_roles:
		var session = NewGameServiceClass.new().create_session("Aria", 1)
		session.player.inventory.add("wolf_fur")
		var screen = CITY_ECONOMY_SCENE.instantiate()
		add_child_autofree(screen)
		screen.configure(session, service_id)
		if service_id == "inn":
			screen.mode_selector.select(1)
			screen.mode_selector.item_selected.emit(1)
		assert_string_contains(screen.npc_role_label.text, expected_roles[service_id])
		if service_id != "blacksmith":
			assert_gt(screen.service_grid.entry_count(), 0)
		assert_false(screen.transaction_drop_zone.is_visible_in_tree())
		screen.npc_hit_area.pressed.emit()
		screen.open_service_button.pressed.emit()
		if service_id == "blacksmith":
			var bench = screen.blacksmith_workbench
			assert_true(bench.is_visible_in_tree())
			assert_true(bench.picker.backpack is InventoryGridView)
			assert_gt(bench.picker.backpack.entry_count(), 0)
			var weapon: InventoryItemSlot = bench.picker.character_panel.slot_buttons.weapon
			assert_false(weapon.tooltip_text.is_empty())
			assert_true(bench.upgrade_view.anvil._can_drop_data(Vector2.ZERO, weapon.drag_payload))
			assert_false(screen.transaction_drop_zone.is_visible_in_tree())
			continue
		assert_eq(screen.transaction_drop_zone.is_visible_in_tree(), service_id != "merchant")
		assert_eq(screen.merchant_trade_overlay.is_visible_in_tree(), service_id == "merchant")
		assert_string_contains(screen.drop_hint_label.text, "PRZECIĄGNIJ")
		assert_false(screen.service_grid.get_child(0).tooltip_text.is_empty())
