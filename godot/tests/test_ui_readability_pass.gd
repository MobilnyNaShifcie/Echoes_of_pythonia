extends GutTest

const AppScript := preload("res://scenes/app/app.gd")
const MAIN_MENU_SCENE := preload("res://ui/screens/main_menu/main_menu.tscn")
const CITY_ECONOMY_SCENE := preload("res://ui/screens/city_economy/city_economy.tscn")
const CITY_HUB_SCENE := preload("res://ui/screens/city_hub/city_hub.tscn")
const COMBAT_SCENE := preload("res://ui/screens/combat/combat.tscn")
const EQUIPMENT_SCENE := preload("res://ui/screens/equipment/equipment.tscn")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")


func test_city_map_uses_invisible_hotspots_and_marker_hover_highlight() -> void:
	var city = CITY_HUB_SCENE.instantiate()
	city.configure(NewGameServiceClass.new().create_session("Aria", 1))
	add_child_autofree(city)
	await get_tree().process_frame

	var hotspot := city.get_node("%BlacksmithHotspot") as Button
	var marker := hotspot.get_node("Marker") as Control
	var glow := marker.get_node("Glow") as Control
	assert_true(hotspot.get_theme_stylebox("normal") is StyleBoxEmpty)
	assert_eq(hotspot.text, "")
	assert_eq(marker.scale, Vector2.ONE)
	assert_eq(glow.modulate.a, 0.0)
	hotspot.mouse_entered.emit()
	assert_same(city._active_marker, marker)
	assert_gt(marker.scale.x, 1.0)
	assert_gt(glow.modulate.a, 0.0)
	assert_string_contains(city.map_location_label.text, "Kuźnia Garrana")
	hotspot.mouse_exited.emit()
	assert_null(city._active_marker)
	assert_eq(marker.scale, Vector2.ONE)
	assert_eq(glow.modulate.a, 0.0)


func test_city_interiors_reveal_services_only_after_focusing_the_npc() -> void:
	for service_id: String in ["merchant", "blacksmith", "workshop", "inn"]:
		var screen = CITY_ECONOMY_SCENE.instantiate()
		add_child_autofree(screen)
		screen.configure(NewGameServiceClass.new().create_session("Aria", 1), service_id)
		await get_tree().process_frame

		var shade := screen.get_node("Page/Body/LocationShade") as ColorRect
		var columns := screen.get_node("Page/Body/Columns") as Control
		var npc_panel := screen.get_node("Page/Body/Columns/NpcPanel") as PanelContainer
		var npc_style := npc_panel.get_theme_stylebox("panel") as StyleBoxFlat
		assert_almost_eq(shade.color.a, 0.2, 0.001, service_id)
		assert_eq(
			columns.get_rect(), Rect2(Vector2.ZERO, screen.get_node("Page/Body").size), service_id
		)
		assert_eq(screen._interaction_state, "ambient", service_id)
		assert_false(screen.service_toolbar.visible, service_id)
		assert_false(screen.catalogue_panel.visible, service_id)
		assert_false(screen.transaction_panel.visible, service_id)
		assert_false(screen.npc_role_label.visible, service_id)
		assert_false(screen.npc_hint_label.visible, service_id)
		assert_false(screen.npc_interaction_hint.visible, service_id)
		assert_false(screen.status_label.visible, service_id)
		await get_tree().process_frame
		var ambient_visual_size: Vector2 = screen.npc_visual.size
		var ambient_visual_position: Vector2 = screen.npc_visual.global_position
		var ambient_character_rect: Rect2 = screen.npc_visual.character_visible_rect()
		var ambient_zoom: float = screen.npc_visual.character_zoom
		var ambient_anchor: float = screen.npc_visual.character_anchor_x
		var ambient_panel_width: float = npc_panel.custom_minimum_size.x
		var visual_rect := Rect2(Vector2.ZERO, screen.get_node("Page/Body").size)
		var hit_rect: Rect2 = screen.npc_hit_area.get_rect()
		assert_true(visual_rect.encloses(hit_rect), service_id)
		assert_lt(hit_rect.get_area(), visual_rect.get_area() * 0.9, service_id)

		screen.npc_hit_area.pressed.emit()
		await get_tree().process_frame
		assert_eq(screen._interaction_state, "focused", service_id)
		assert_true(screen.npc_action_panel.visible, service_id)
		assert_false(screen.catalogue_panel.visible, service_id)
		assert_false(screen.transaction_panel.visible, service_id)
		assert_eq(screen.npc_visual.size, ambient_visual_size, service_id)
		assert_eq(screen.npc_visual.global_position, ambient_visual_position, service_id)
		assert_eq(screen.npc_visual.character_visible_rect(), ambient_character_rect, service_id)
		assert_almost_eq(screen.npc_visual.character_zoom, ambient_zoom, 0.001, service_id)
		assert_almost_eq(screen.npc_visual.character_anchor_x, ambient_anchor, 0.001, service_id)
		assert_false(screen.npc_interaction_hint.visible, service_id)

		screen.open_service_button.pressed.emit()
		await get_tree().process_frame
		assert_eq(screen._interaction_state, "service", service_id)
		assert_true(screen.service_toolbar.visible, service_id)
		assert_eq(screen.catalogue_panel.visible, service_id not in ["merchant", "inn"], service_id)
		assert_eq(screen.transaction_panel.visible, service_id != "merchant", service_id)
		assert_eq(screen.merchant_trade_overlay.visible, service_id == "merchant", service_id)
		assert_eq(npc_panel.custom_minimum_size.x, ambient_panel_width, service_id)
		assert_almost_eq(npc_style.bg_color.a, 0.0, 0.001, service_id)
		assert_eq(screen.npc_visual.size, ambient_visual_size, service_id)
		assert_eq(screen.npc_visual.global_position, ambient_visual_position, service_id)
		assert_eq(screen.npc_visual.character_visible_rect(), ambient_character_rect, service_id)
		assert_almost_eq(screen.npc_visual.character_zoom, ambient_zoom, 0.001, service_id)
		assert_almost_eq(screen.npc_visual.character_anchor_x, ambient_anchor, 0.001, service_id)

		screen.close_service_button.pressed.emit()
		assert_eq(screen._interaction_state, "focused", service_id)
		assert_true(screen.npc_action_panel.visible, service_id)
		assert_false(screen.service_toolbar.visible, service_id)


func test_equipment_and_backpack_use_separate_layers_and_spaced_inventory_cells() -> void:
	var screen = EQUIPMENT_SCENE.instantiate()
	screen.configure(NewGameServiceClass.new().create_session("Aria", 1))
	add_child_autofree(screen)

	var equipment_panel := screen.get_node("Page/Workspace/PaperdollPanel") as PanelContainer
	var backpack_panel := screen.get_node("Page/Workspace/BackpackPanel") as PanelContainer
	var inventory_well := screen.get_node("%InventoryDropZone") as PanelContainer
	var equipment_style := equipment_panel.get_theme_stylebox("panel") as StyleBoxFlat
	var backpack_style := backpack_panel.get_theme_stylebox("panel") as StyleBoxFlat
	var well_style := inventory_well.get_theme_stylebox("panel") as StyleBoxFlat
	assert_ne(equipment_style.bg_color, backpack_style.bg_color)
	assert_lt(well_style.bg_color.get_luminance(), backpack_style.bg_color.get_luminance())
	assert_gte(well_style.content_margin_left, 12.0)
	assert_gte(screen.inventory_grid.gap, 7.0)


func test_compact_loot_cells_do_not_force_their_standalone_68_pixel_minimum() -> void:
	var host := Control.new()
	host.size = Vector2(1920, 1080)
	add_child_autofree(host)
	var combat = COMBAT_SCENE.instantiate()
	combat.configure(NewGameServiceClass.new().create_session("Aria", 1), "slime", "expedition")
	host.add_child(combat)
	combat.loot_presentation.set_drops([{"item_id": "slime_gel", "quantity": 1}])
	await get_tree().process_frame

	var loot_grid: InventoryGridView = combat.loot_presentation.loot_grid
	var loot_slot := loot_grid.get_child(0) as InventoryItemSlot
	assert_eq(loot_slot.custom_minimum_size, Vector2.ZERO)
	assert_eq(loot_slot.size, Vector2(44, 44))
	assert_lte(loot_slot.get_rect().end.x, loot_grid.size.x)
	assert_lte(loot_slot.get_rect().end.y, loot_grid.size.y)


func test_app_exposes_fullscreen_control_and_recognizes_both_fullscreen_modes() -> void:
	var menu := MAIN_MENU_SCENE.instantiate()
	var button := menu.get_node("%DisplayModeButton") as Button
	assert_eq(button.text, "Pełny ekran")
	assert_string_contains(button.tooltip_text, "Alt+Enter")
	assert_false(AppScript.is_fullscreen_mode(DisplayServer.WINDOW_MODE_WINDOWED))
	assert_true(AppScript.is_fullscreen_mode(DisplayServer.WINDOW_MODE_FULLSCREEN))
	assert_true(AppScript.is_fullscreen_mode(DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN))
	assert_eq(AppScript.fullscreen_unavailable_message(false), "")
	assert_string_contains(
		AppScript.fullscreen_unavailable_message(true), "Embed Game on Next Play"
	)
	menu.free()
