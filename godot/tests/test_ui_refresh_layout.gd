extends GutTest
const NewGame := preload("res://core/game/new_game_service.gd")
const City := preload("res://ui/screens/city_hub/city_hub.tscn")
const Combat := preload("res://ui/screens/combat/combat.tscn")
const Economy := preload("res://ui/screens/city_economy/city_economy.tscn")
const Guild := preload("res://ui/screens/guild/guild.tscn")
const Achievements := preload("res://ui/screens/achievements/achievements.tscn")
const AchievementService := preload("res://core/progression/achievement_service.gd")


func test_drawer_hover_opens_and_leaving_closes_without_moving_the_art() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	add_child(viewport)
	var screen = City.instantiate()
	screen.configure(_session())
	viewport.add_child(screen)
	await _settle()
	var drawer = screen.navigation_drawer
	var original: Rect2 = screen.base_map.get_global_rect()
	var motion := InputEventMouseMotion.new()
	motion.position = drawer.handle.get_global_rect().get_center()
	viewport.push_input(motion, true)
	await _settle()
	assert_true(drawer.opened)
	assert_false(drawer.pinned)
	motion.position = Vector2(1200, 100)
	viewport.push_input(motion, true)
	drawer._process(0.7)
	assert_false(drawer.opened)
	assert_false(screen.get_node("Layout/MenuPanel").is_visible_in_tree())
	assert_eq(screen.base_map.get_global_rect(), original)
	viewport.free()


func test_reused_combat_scene_keeps_closed_commands_out_of_keyboard_navigation() -> void:
	var screen = _screen(Combat)
	screen.configure(_session(), "wolf", "expedition")
	await _settle()
	var lower = screen.get_node("Page/Lower")
	lower.drawer.set_open(true, true)
	screen.configure(_session(), "ice_crab", "expedition")
	await _settle()
	assert_false(lower.visible)
	assert_false(lower.drawer.opened)
	assert_true(lower.drawer.handle.visible)
	screen.free()


func test_immediate_navigation_cancels_unattached_drawer_handles_safely() -> void:
	for index in 30:
		var city = _screen(City)
		city.configure(_session())
		remove_child(city)
		city.queue_free()
		var replacement := Button.new()
		replacement.name = "Replacement"
		add_child(replacement)
		await get_tree().process_frame
		assert_eq(replacement.get_parent(), self)
		replacement.free()


func test_city_drawer_opens_pins_closes_without_resizing_the_city_art() -> void:
	var screen = _screen(City)
	screen.configure(_session())
	await _settle()
	var drawer = screen.navigation_drawer
	assert_false(drawer.opened)
	assert_false(screen.get_node("Layout/MenuPanel").is_visible_in_tree())
	assert_null(screen.get_node_or_null("Layout/City/QuickActionsDock"))
	var city_rect: Rect2 = screen.base_map.get_global_rect()
	drawer.handle.grab_focus()
	assert_true(drawer.opened)
	drawer.handle.pressed.emit()
	assert_true(drawer.pinned)
	drawer._process(3.0)
	assert_true(drawer.opened)
	assert_eq(screen.base_map.get_global_rect(), city_rect)
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	drawer._unhandled_key_input(escape)
	assert_false(drawer.opened)
	assert_false(drawer.pinned)
	assert_false(screen.get_node("Layout/MenuPanel").visible)
	drawer.handle.pressed.emit()
	assert_true(drawer.opened)
	assert_eq(screen.base_map.get_global_rect(), city_rect)
	screen.free()


func test_combat_overlay_keeps_arena_and_ground_fixed_at_all_screen_ratios() -> void:
	for dimensions: Vector2 in [Vector2(1280, 720), Vector2(1920, 1080), Vector2(2560, 1080)]:
		for enemy in ["wolf", "ice_crab", "plains_spirit", "sand_golem", "leviathan_north"]:
			var screen = _screen(Combat, dimensions)
			screen.configure(_session(), enemy, "expedition")
			screen.set_reduced_motion(true)
			await _settle()
			var arena: Control = screen.get_node("Page/Arena")
			var old_rect := arena.get_global_rect()
			var lower = screen.get_node("Page/Lower")
			assert_false(lower.drawer.opened)
			lower.drawer.pinned = true
			lower.drawer.set_open(true, true)
			await _settle()
			assert_eq(arena.get_global_rect(), old_rect)
			assert_lte(lower.get_global_rect().end.y, dimensions.y)
			assert_gte(lower.global_position.x, 0.0)
			assert_almost_eq(
				screen.player_visual.static_texture.get_global_rect().end.y,
				screen.enemy_visual.static_texture.get_global_rect().end.y,
				0.5,
				enemy
			)
			for card in screen.skill_cards.get_children():
				assert_eq(card.artwork.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
			screen.free()


func test_services_share_square_slots_and_keep_full_background() -> void:
	for service_id in ["merchant", "blacksmith", "workshop", "inn"]:
		var screen = _screen(Economy)
		screen.configure(_session(), service_id)
		await _settle()
		var ambient: Rect2 = screen.location_background.get_global_rect()
		screen._open_service()
		await _settle()
		assert_eq(screen.location_background.get_global_rect(), ambient)
		assert_eq(screen.get_node("Page/Body").size, screen.size)
		assert_false(screen.npc_panel.visible)
		for grid in [screen.service_grid, screen.merchant_stock_grid, screen.merchant_player_grid]:
			assert_eq(grid.cell_size, Vector2(64, 64))
			assert_eq(grid.columns, 6)
			assert_false(grid.stretch_cells_to_width)
			assert_false(grid.stretch_cells_to_height)
		assert_lte(screen.service_toolbar.get_global_rect().end.x, screen.size.x)
		if service_id == "merchant":
			var stock: Control = screen.get_node(
				"Page/Body/MerchantTradeOverlay/InventoryPanels/MerchantStockPanel"
			)
			var player: Control = screen.get_node(
				"Page/Body/MerchantTradeOverlay/InventoryPanels/MerchantPlayerPanel"
			)
			assert_almost_eq(stock.size.x, player.size.x, 1.0)
			assert_eq(stock.size.y, player.size.y)
			assert_eq(
				screen.merchant_stock_grid.global_position.y,
				screen.merchant_player_grid.global_position.y
			)
		screen.free()


func test_inn_rest_is_a_service_without_item_slots_and_still_restores_and_charges() -> void:
	var session = _session()
	session.player.gold = 100
	session.player.stats.current_hp = 1
	var inventory_before: Dictionary = session.player.inventory.stacks.duplicate()
	var screen = _screen(Economy)
	screen.configure(session, "inn")
	screen._open_service()
	await _settle()
	assert_false(screen.catalogue_panel.visible)
	assert_eq(screen.service_grid._entries.size(), 0)
	assert_false(screen.transaction_drop_zone.visible)
	assert_false(screen.quantity_box.get_parent().visible)
	assert_false(screen.action_button.disabled)
	screen.action_button.pressed.emit()
	assert_eq(session.player.stats.current_hp, session.player.stats.max_hp)
	assert_eq(session.player.gold, 75)
	assert_eq(session.hour, 14)
	assert_eq(session.player.inventory.stacks, inventory_before)
	assert_true(screen.action_button.disabled)
	screen.mode_selector.select(1)
	screen.mode_selector.item_selected.emit(1)
	await _settle()
	assert_true(screen.catalogue_panel.visible)
	assert_true(screen.quantity_box.get_parent().visible)
	screen.free()


func test_guild_board_preserves_room_and_guildmaster_position() -> void:
	var screen = _screen(Guild)
	screen.configure(_session())
	await _settle()
	var old_rect: Rect2 = screen.interior.get_global_rect()
	screen.show_story_board()
	await _settle()
	assert_eq(screen.interior.get_global_rect(), old_rect)
	assert_lte(screen.board_body.get_global_rect().end.x, screen.size.x)
	assert_true(screen.action_button.is_visible_in_tree())
	screen.free()


func test_collection_filter_and_title_cards_preserve_unlock_and_equip_rules() -> void:
	var session = _session()
	var screen = _screen(Achievements)
	screen.configure(session)
	await _settle()
	var view = screen.collection_view
	assert_false(screen.achievement_list.is_visible_in_tree())
	assert_eq(view.cards.get_child_count(), 7)
	assert_eq(view.title_cards.get_child_count(), 8)
	for card in view.cards.get_children():
		assert_not_null(card.get_child(0).get_child(0).texture)
	view._filters[1].pressed.emit()
	assert_eq(view.cards.get_child_count(), 0)
	assert_true(view._empty.visible)
	AchievementService.record_victory(session, "wolf", "sunny")
	screen.configure(session)
	assert_eq(view.cards.get_child_count(), 1)
	assert_false(view.title_cards.get_child(1).disabled)
	view.title_cards.get_child(1).pressed.emit()
	assert_false(screen.equip_button.disabled)
	screen.equip_button.pressed.emit()
	assert_eq(session.player.achievement_book.equipped_title, "Łowca")
	assert_true(screen.equip_button.disabled)
	view._filters[2].pressed.emit()
	assert_eq(view.cards.get_child_count(), 6)
	await _settle()
	screen.free()


func _session():
	return NewGame.new().create_session("Aria", 1)


func _screen(scene: PackedScene, dimensions := Vector2(1920, 1080)):
	var screen = scene.instantiate()
	screen.set_anchors_preset(Control.PRESET_TOP_LEFT)
	screen.size = dimensions
	add_child(screen)
	return screen


func _settle() -> void:
	for frame in 6:
		await get_tree().process_frame
