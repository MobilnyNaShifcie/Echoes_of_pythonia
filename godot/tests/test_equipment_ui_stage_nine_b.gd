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

	assert_not_null(
		screen.get_node("Page/Workspace/PaperdollPanel/Content/Paperdoll/Stage/CharacterVisual")
	)
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


func test_equipment_layout_places_close_columns_on_both_sides_of_the_character() -> void:
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

	var head: Control = screen.slot_buttons.head
	var chest: Control = screen.slot_buttons.chest
	var belt: Control = screen.slot_buttons.belt
	var feet: Control = screen.slot_buttons.feet
	var paperdoll_stage := screen.get_node(
		"Page/Workspace/PaperdollPanel/Content/Paperdoll"
	) as PanelContainer
	var stage_style := paperdoll_stage.get_theme_stylebox("panel") as StyleBoxFlat
	assert_lte(stage_style.bg_color.a, 0.2)
	var body_left: float = screen.character_visual.position.x
	for body_slot: Control in [head, chest, belt, feet]:
		assert_lt(body_slot.position.x + body_slot.size.x, body_left + 132.0)
		assert_gt(body_slot.position.x, body_left)
	assert_lt(head.position.y, chest.position.y)
	assert_lt(chest.position.y, screen.slot_buttons.hands.position.y)
	assert_lt(screen.slot_buttons.hands.position.y, belt.position.y)
	assert_lt(belt.position.y, feet.position.y)
	var left_equipment_slots: Array[Control] = [
		head, chest, screen.slot_buttons.hands, belt, feet,
	]
	for slot_index: int in range(left_equipment_slots.size() - 1):
		var current_slot: Control = left_equipment_slots[slot_index]
		var next_slot: Control = left_equipment_slots[slot_index + 1]
		assert_almost_eq(
			next_slot.position.y - (current_slot.position.y + current_slot.size.y),
			10.0,
			1.0,
		)
	assert_lt(screen.slot_buttons.weapon.position.x, head.position.x)
	assert_almost_eq(screen.slot_buttons.hands.position.x, head.position.x, 1.0)
	assert_lte(chest.position.x + chest.size.x, body_left + 90.0)
	assert_gt(screen.slot_buttons.weapon.position.x, 100.0)
	var left_column_gap: float = chest.position.x - (
		screen.slot_buttons.weapon.position.x + screen.slot_buttons.weapon.size.x
	)
	assert_gte(left_column_gap, 0.0)
	assert_lte(left_column_gap, 5.0)

	var offhand: Control = screen.slot_buttons.off_hand
	var mirrored_offhand_x: float = paperdoll_stage.size.x - (
		screen.slot_buttons.weapon.position.x + screen.slot_buttons.weapon.size.x
	)
	assert_almost_eq(offhand.position.x, mirrored_offhand_x, 1.0)
	assert_almost_eq(offhand.position.y, screen.slot_buttons.weapon.position.y, 1.0)
	assert_almost_eq(offhand.size.x, screen.slot_buttons.weapon.size.x, 1.0)
	assert_almost_eq(offhand.size.y, screen.slot_buttons.weapon.size.y, 1.0)
	var earrings: Control = screen.slot_buttons.earrings
	var necklace: Control = screen.slot_buttons.necklace
	var bracelet: Control = screen.slot_buttons.bracelet
	var ring: Control = screen.slot_buttons.ring
	for regular_slot: Control in [
		head, chest, screen.slot_buttons.hands, belt, feet,
		earrings, necklace, bracelet, ring,
	]:
		assert_almost_eq(regular_slot.size.x, 74.0, 1.0)
		assert_almost_eq(regular_slot.size.y, 74.0, 1.0)
	assert_almost_eq(screen.slot_buttons.weapon.size.x, 76.0, 1.0)
	assert_almost_eq(screen.slot_buttons.weapon.size.y, 116.0, 1.0)
	assert_almost_eq(offhand.size.x, 76.0, 1.0)
	assert_almost_eq(offhand.size.y, 116.0, 1.0)
	assert_almost_eq(earrings.position.x, bracelet.position.x, 1.0)
	assert_almost_eq(necklace.position.x, ring.position.x, 1.0)
	assert_lt(earrings.position.x, necklace.position.x)
	assert_lte(necklace.position.x - (earrings.position.x + earrings.size.x), 12.0)
	assert_lt(offhand.position.y, earrings.position.y)
	assert_almost_eq(earrings.position.y, necklace.position.y, 1.0)
	assert_lt(earrings.position.y, bracelet.position.y)
	assert_almost_eq(bracelet.position.y, ring.position.y, 1.0)
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
	assert_string_contains(tooltip.find_child("LockDescription", true, false).text, "Twój poziom: 0")
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
		assert_gt(screen.service_grid.entry_count(), 0)
		assert_false(screen.transaction_drop_zone.is_visible_in_tree())
		screen.npc_hit_area.pressed.emit()
		screen.open_service_button.pressed.emit()
		assert_eq(screen.transaction_drop_zone.is_visible_in_tree(), service_id != "merchant")
		assert_eq(screen.merchant_trade_overlay.is_visible_in_tree(), service_id == "merchant")
		assert_string_contains(screen.drop_hint_label.text, "PRZECIĄGNIJ")
		assert_false(screen.service_grid.get_child(0).tooltip_text.is_empty())
