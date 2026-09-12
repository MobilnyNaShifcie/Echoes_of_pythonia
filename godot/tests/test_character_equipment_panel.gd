extends GutTest

const PanelScene := preload(
	"res://ui/components/character_equipment_panel/character_equipment_panel.tscn"
)
const ScreenScene := preload("res://ui/screens/equipment/equipment.tscn")
const Fixture := preload("res://tests/fixtures/equipment_layout_fixture.gd")
const Saves := preload("res://core/save/save_game_service.gd")
const Items := preload("res://core/items/item_catalog.gd")
const Presentations := preload("res://ui/presentation/combat_presentation_catalog.gd")
const LEFT := ["weapon", "chest", "hands", "belt", "feet"]
const RIGHT := ["off_hand", "earrings", "necklace", "bracelet", "ring"]


func test_reusable_panel_keeps_all_slots_symmetric_and_clear_of_the_full_character() -> void:
	var session = Fixture.create_session()
	var panel = PanelScene.instantiate()
	add_child_autofree(panel)
	panel.character_visual.show_character(Presentations.hero_texture_for_player(session.player))
	panel.show_identity("Aria", 9, "Pierrot")
	for dimensions: Vector2 in [Vector2(734, 810), Vector2(730, 704), Vector2(980, 900)]:
		panel.size = dimensions
		for frame in 5:
			await get_tree().process_frame
		_assert_geometry(panel)
		assert_eq(panel.character_visual.character_zoom, 1.0)
		assert_eq(panel.character_visual.character_clip_bottom_ratio, 1.0)
		assert_eq(
			panel.character_visual.character_texture().resource_path,
			"res://assets/combat/heroes/pierrot.png"
		)


func _assert_geometry(panel) -> void:
	var center_x: float = panel.get_global_rect().get_center().x
	var head: Control = panel.slot_buttons.head
	var hero: Rect2 = panel.character_visual.character_visible_rect()
	hero.position += panel.character_visual.global_position
	assert_eq(panel.slot_buttons.size(), 11)
	assert_almost_eq(head.get_global_rect().get_center().x, center_x, 1.0)
	assert_lt(head.get_global_rect().end.y, hero.position.y)
	var last_y := 0.0
	var step := 0.0
	for index in LEFT.size():
		var left: Control = panel.slot_buttons[LEFT[index]]
		var right: Control = panel.slot_buttons[RIGHT[index]]
		assert_almost_eq(left.global_position.y, right.global_position.y, 1.0)
		assert_almost_eq(
			center_x - left.get_global_rect().get_center().x,
			right.get_global_rect().get_center().x - center_x,
			1.0
		)
		if index == 1:
			step = left.global_position.y - last_y
		elif index > 1:
			assert_almost_eq(left.global_position.y - last_y, step, 1.0)
		last_y = left.global_position.y
	for button: Control in panel.slot_buttons.values():
		assert_eq(button.size, head.size)
		assert_eq(button.size.x, button.size.y)
		assert_false(button.get_global_rect().intersects(hero))
		assert_true(panel.get_global_rect().encloses(button.get_global_rect()))
		var label: Label = button.get_node("SlotCaption")
		assert_true(button.get_global_rect().encloses(label.get_global_rect()))
	assert_true(panel.get_global_rect().encloses(hero))
	assert_lt(hero.end.y, panel.nameplate_label.global_position.y)
	assert_true(panel.get_global_rect().encloses(panel.nameplate_label.get_global_rect()))


func test_each_item_keeps_its_own_slot_icon_caption_and_rarity_border() -> void:
	var session = Fixture.create_session()
	var screen = _screen(session)
	for slot: String in screen.slot_buttons:
		var button: InventoryItemSlot = screen.slot_buttons[slot]
		var item = session.player.equipment.get_item(slot)
		assert_eq(button.slot_caption, screen.SLOT_NAMES[slot])
		assert_eq(button.text, "◇" if item == null else "")
		if item != null:
			assert_eq(button.item_texture, item.definition.icon)
			assert_eq(
				button.get_theme_stylebox("normal").border_color,
				button.RARITY_FRAME_COLORS[button.rarity]
			)
		assert_almost_eq(button.get_theme_stylebox("normal").bg_color.a, 0.38, 0.001)
	assert_ne(screen.slot_buttons.earrings.item_texture, screen.slot_buttons.bracelet.item_texture)
	assert_ne(screen.slot_buttons.earrings, screen.slot_buttons.necklace)
	assert_ne(screen.slot_buttons.necklace, screen.slot_buttons.bracelet)


func test_identity_is_dynamic_and_opening_or_resizing_does_not_change_save_data() -> void:
	var session = Fixture.create_session()
	var saves := Saves.new("user://equipment_layout_not_written")
	var before: Dictionary = saves._serialize_session(session).session.player
	var screen = _screen(session)
	assert_eq(screen.equipment_panel.nameplate_label.text, "ARIA  •  POZIOM 9  •  PIERROT")
	screen.equipment_panel.size = Vector2(780, 820)
	await get_tree().process_frame
	assert_eq(saves._serialize_session(session).session.player, before)
	session.player.display_name = "Test"
	session.player.level = 10
	screen.configure(session)
	assert_eq(screen.equipment_panel.nameplate_label.text, "TEST  •  POZIOM 10  •  PIERROT")


func test_long_polish_identity_keeps_panel_and_slots_fixed_without_changing_player_data() -> void:
	var session = Fixture.create_session()
	var full_name := "Żaneta Źdźbło Łucja Ćma Świątek"
	session.player.display_name = full_name
	# Presentation-only stress input, not a new class or a mutation of the class catalog.
	var full_class: String = session.player.character_class_name + " — pełna nazwa klasy".repeat(12)
	var saves := Saves.new("user://equipment_layout_not_written")
	var saved_player: Dictionary = saves._serialize_session(session).session.player
	var panel = PanelScene.instantiate()
	add_child_autofree(panel)
	var center: Control = panel.character_visual.get_parent()
	var plaque: Control = panel.nameplate_label.get_parent()
	for dimensions: Vector2 in [
		Vector2(734, 810), Vector2(730, 704), Vector2(980, 900), Vector2(1800, 900)
	]:
		panel.show_identity("Aria", session.player.level, "Pierrot")
		panel.size = dimensions
		await wait_process_frames(5)
		var panel_before: Rect2 = panel.get_global_rect()
		var minimum_before: Vector2 = panel.get_combined_minimum_size()
		var geometry_before := _slot_and_column_geometry(panel)
		panel.show_identity(session.player.display_name, session.player.level, full_class)
		await wait_process_frames(5)
		assert_eq(panel.get_global_rect(), panel_before, "Long text must not resize the panel.")
		assert_eq(panel.get_combined_minimum_size(), minimum_before)
		assert_eq(_slot_and_column_geometry(panel), geometry_before)
		assert_true(panel_before.encloses(plaque.get_global_rect()))
		assert_gte(plaque.global_position.x, center.global_position.x)
		assert_lte(plaque.get_global_rect().end.x, center.get_global_rect().end.x)
		assert_almost_eq(plaque.get_global_rect().get_center().x, panel_before.get_center().x, 1.0)
		assert_true(plaque.get_global_rect().encloses(panel.nameplate_label.get_global_rect()))
		var expected := (
			"%s  •  POZIOM %d  •  %s"
			% [full_name.to_upper(), session.player.level, full_class.to_upper()]
		)
		assert_eq(panel.nameplate_label.text, expected, "Keep the complete presentation string.")
		assert_eq(plaque.tooltip_text, expected, "Full identity remains available on hover.")
		assert_true(panel.nameplate_label.clip_text)
		assert_eq(panel.nameplate_label.text_overrun_behavior, TextServer.OVERRUN_TRIM_ELLIPSIS)
		var font: Font = panel.nameplate_label.get_theme_font("font")
		var font_size: int = panel.nameplate_label.get_theme_font_size("font_size")
		assert_gt(
			font.get_string_size(expected, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x,
			panel.nameplate_label.size.x,
			"The stress input really exercises ellipsis overflow, not just ordinary text."
		)
		assert_eq(session.player.display_name, full_name)
		assert_eq(saves._serialize_session(session).session.player, saved_player)
		# A wide window must not leave a large cached minimum that prevents later shrinking.
		panel.size = Vector2(730, panel_before.size.y)
		await wait_process_frames(5)
		assert_eq(panel.size, Vector2(730, panel_before.size.y))
		assert_lte(plaque.size.x, center.size.x)
		panel.size = panel_before.size
		await wait_process_frames(5)
		assert_eq(_slot_and_column_geometry(panel), geometry_before)
		panel.show_identity("Aria", session.player.level, "Pierrot")
		await wait_process_frames(5)
		assert_eq(panel.get_global_rect(), panel_before)
		assert_eq(_slot_and_column_geometry(panel), geometry_before)
		assert_lt(plaque.size.x, center.size.x, "Ordinary text keeps the small centered plaque.")


func _slot_and_column_geometry(panel) -> Dictionary:
	var geometry := {}
	for slot: String in panel.slot_buttons:
		geometry[slot] = panel.slot_buttons[slot].get_global_rect()
	for column: String in ["LeftEquipmentVBox", "RightEquipmentVBox"]:
		geometry[column] = (
			panel.get_node("Margin/Layout/EquipmentBodyHBox/" + column).get_global_rect()
		)
	return geometry


func test_jewelry_drag_swap_and_unequip_preserve_separate_instances_and_stats() -> void:
	var session = Fixture.create_session()
	var previous = session.player.equipment.get_item("earrings")
	var bracelet = session.player.equipment.get_item("bracelet")
	var replacement = Items.create_equipment_item("nature_earrings")
	session.player.inventory.add_equipment_instance(replacement)
	var screen = _screen(session)
	var payload := {
		"kind": "equipment", "index": session.player.inventory.equipment_items.size() - 1
	}
	assert_false(screen._slot_can_drop_data(Vector2.ZERO, payload, "bracelet"))
	assert_false(screen._slot_can_drop_data(Vector2.ZERO, payload, "necklace"))
	assert_true(screen._slot_can_drop_data(Vector2.ZERO, payload, "earrings"))
	screen._slot_drop_data(Vector2.ZERO, payload, "earrings")
	assert_same(session.player.equipment.get_item("earrings"), replacement)
	assert_same(session.player.equipment.get_item("bracelet"), bracelet)
	assert_true(session.player.inventory.equipment_items.has(previous))
	var mana_before: int = session.player.stats.max_mana
	var drag: Dictionary = screen._slot_get_drag_data(Vector2.ZERO, "earrings")
	assert_eq(drag, {"kind": "equipped", "slot": "earrings"})
	screen._backpack_drop_data(Vector2.ZERO, drag)
	assert_null(session.player.equipment.get_item("earrings"))
	assert_same(session.player.equipment.get_item("bracelet"), bracelet)
	assert_lt(session.player.stats.max_mana, mana_before)
	assert_eq(screen.slot_buttons.earrings.text, "◇")
	assert_null(screen._slot_get_drag_data(Vector2.ZERO, "earrings"))


func test_backpack_double_click_equips_and_equipped_hover_keeps_custom_tooltip() -> void:
	var session = Fixture.create_session()
	var screen = _screen(session)
	screen._select_equipped_slot("bracelet")
	screen.unequip_button.pressed.emit()
	for frame in 2:
		await get_tree().process_frame
	var target: InventoryItemSlot
	for child in screen.inventory_grid.get_children():
		if child is InventoryItemSlot and child.tooltip_text.contains("Bransoleta Natury"):
			target = child
	assert_not_null(target)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.double_click = true
	event.pressed = true
	target.gui_input.emit(event)
	assert_eq(session.player.equipment.get_item("bracelet").item_id, "nature_bracelet")
	screen.slot_buttons.bracelet.mouse_entered.emit()
	assert_string_contains(screen.details_label.text, "Bransoleta Natury")
	var tooltip = screen.slot_buttons.bracelet._make_custom_tooltip(
		screen.slot_buttons.bracelet.tooltip_text
	)
	add_child_autofree(tooltip)
	assert_not_null(tooltip.find_child("ItemDescription", true, false))
	assert_string_contains(screen.slot_buttons.earrings.tooltip_text, "Kolczyki Natury")


func test_save_load_round_trip_keeps_all_equipment_identifiers_and_instances() -> void:
	var session = Fixture.create_session()
	var saves := Saves.new("user://equipment_layout_not_written")
	var payload: Dictionary = saves._serialize_session(session)
	var result := saves._deserialize_payload(payload, 1)
	assert_true(result.ok, result.message)
	var screen = _screen(result.session)
	for slot: String in screen.SLOT_ORDER:
		var old = session.player.equipment.get_item(slot)
		var restored = result.session.player.equipment.get_item(slot)
		if old == null:
			assert_null(restored)
		else:
			assert_eq(restored.item_id, old.item_id)
			assert_eq(restored.instance_id, old.instance_id)
	assert_eq(result.session.player.stats.attack, session.player.stats.attack)
	assert_eq(result.session.player.stats.max_mana, session.player.stats.max_mana)
	# Existing model permits lance + dice. There is no separate two-handed slot rule.
	assert_eq(result.session.player.equipment.get_item("weapon").item_id, "caprice_lance")
	assert_eq(result.session.player.equipment.get_item("off_hand").item_id, "worn_fate_dice")


func _screen(session):
	var screen = ScreenScene.instantiate()
	screen.configure(session)
	add_child_autofree(screen)
	return screen


func test_real_pointer_reaches_all_slots_and_drags_jewelry_in_both_directions() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	add_child_autofree(viewport)
	var session = Fixture.create_session()
	var screen = ScreenScene.instantiate()
	screen.configure(session)
	viewport.add_child(screen)
	await wait_process_frames(5)
	for button: Control in screen.slot_buttons.values():
		_pointer_move(viewport, button.get_global_rect().get_center())
		await wait_process_frames(1)
		assert_eq(viewport.gui_get_hovered_control(), button)
	var earrings = session.player.equipment.get_item("earrings")
	var bracelet = session.player.equipment.get_item("bracelet")
	await _pointer_drag(
		viewport,
		screen.slot_buttons.earrings.get_global_rect().get_center(),
		screen.inventory_grid.get_global_rect().get_center()
	)
	assert_null(session.player.equipment.get_item("earrings"))
	assert_same(session.player.equipment.get_item("bracelet"), bracelet)
	var source: InventoryItemSlot
	for child in screen.inventory_grid.get_children():
		if child is InventoryItemSlot and child.tooltip_text.contains("Kolczyki Natury"):
			source = child
	assert_not_null(source)
	if source == null:
		return
	await _pointer_drag(
		viewport,
		source.get_global_rect().get_center(),
		screen.slot_buttons.earrings.get_global_rect().get_center()
	)
	assert_same(session.player.equipment.get_item("earrings"), earrings)
	assert_same(session.player.equipment.get_item("bracelet"), bracelet)
	assert_false(viewport.gui_is_dragging())


func _pointer_move(
	viewport: Viewport, point: Vector2, previous := Vector2.ZERO, held := false
) -> void:
	var event := InputEventMouseMotion.new()
	event.position = point
	event.relative = point - previous
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	viewport.push_input(event, true)


func _pointer_drag(viewport: Viewport, start: Vector2, finish: Vector2) -> void:
	_pointer_move(viewport, start)
	await wait_process_frames(1)
	var event := InputEventMouseButton.new()
	event.position = start
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	event.pressed = true
	viewport.push_input(event, true)
	var step := start + Vector2(25, 0)
	_pointer_move(viewport, step, start, true)
	await wait_process_frames(2)
	assert_true(viewport.gui_is_dragging(), "Real pointer starts the forwarded drag.")
	_pointer_move(viewport, finish, step, true)
	await wait_process_frames(1)
	event = event.duplicate()
	event.position = finish
	event.button_mask = 0
	event.pressed = false
	viewport.push_input(event, true)
	await wait_process_frames(3)
	assert_true(viewport.gui_is_drag_successful(), "Real pointer drops onto the correct target.")
