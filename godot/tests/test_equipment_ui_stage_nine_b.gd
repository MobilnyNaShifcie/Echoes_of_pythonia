extends GutTest

const CITY_ECONOMY_SCENE := preload("res://ui/screens/city_economy/city_economy.tscn")
const EQUIPMENT_SCENE := preload("res://ui/screens/equipment/equipment.tscn")
const ItemGridLayoutClass := preload("res://ui/components/inventory_grid/item_grid_layout.gd")
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
	session.player.level = 2
	session.player.inventory.add("sharpened_sword")
	session.player.inventory.add("wolf_fur", 2)
	var screen = EQUIPMENT_SCENE.instantiate()
	screen.configure(session)
	add_child_autofree(screen)

	assert_not_null(
		screen.get_node("Page/Workspace/PaperdollPanel/Content/Paperdoll/Stage/CharacterVisual")
	)
	assert_eq(screen.slot_buttons.size(), 11)
	assert_eq(screen.slot_buttons.weapon.text, "◆\nBR")
	assert_string_contains(screen.slot_buttons.weapon.tooltip_text, "Stary Miecz +0")
	var slot_style: StyleBoxFlat = screen.slot_buttons.weapon.get_theme_stylebox("normal")
	assert_lt(slot_style.bg_color.a, 0.5)
	assert_gt(slot_style.border_color.a, slot_style.bg_color.a)
	assert_eq(screen.inventory_grid.entry_count(), 2)
	var sword_cell: InventoryItemSlot = screen.inventory_grid.get_child(0)
	assert_gt(sword_cell.size.y, sword_cell.size.x)
	var before_tooltip := sword_cell.tooltip_text
	assert_eq(sword_cell.drag_payload.kind, "equipment")
	assert_eq(sword_cell.tooltip_text, before_tooltip)
	assert_string_contains(sword_cell.tooltip_text, "Ostrzony Miecz +0")


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
	assert_string_contains(screen.inventory_grid.get_child(0).text, "×70")


func test_oren_uses_npc_portrait_grid_tooltips_and_drag_purchase() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.gold = 100
	var screen = CITY_ECONOMY_SCENE.instantiate()
	add_child_autofree(screen)
	screen.configure(session, "merchant")

	assert_string_contains(screen.npc_role_label.text, "OREN")
	assert_eq(screen.service_grid.entry_count(), 6)
	assert_false(screen.item_list.is_visible_in_tree())
	var first_cell: InventoryItemSlot = screen.service_grid.get_child(0)
	assert_false(first_cell.tooltip_text.is_empty())
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
		"quartermaster": "KWATERMISTRZ",
	}
	for service_id: String in expected_roles:
		var session = NewGameServiceClass.new().create_session("Aria", 1)
		session.player.inventory.add("wolf_fur")
		var screen = CITY_ECONOMY_SCENE.instantiate()
		add_child_autofree(screen)
		screen.configure(session, service_id)
		assert_string_contains(screen.npc_role_label.text, expected_roles[service_id])
		assert_gt(screen.service_grid.entry_count(), 0)
		assert_true(screen.transaction_drop_zone.is_visible_in_tree())
		assert_string_contains(screen.drop_hint_label.text, "PRZECIĄGNIJ")
		assert_false(screen.service_grid.get_child(0).tooltip_text.is_empty())
