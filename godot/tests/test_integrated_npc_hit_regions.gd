extends GutTest

const ECONOMY_SCENE := preload("res://ui/screens/city_economy/city_economy.tscn")
const GUILD_SCENE := preload("res://ui/screens/guild/guild.tscn")
const MARKET_SCENE := preload("res://ui/screens/black_market/black_market.tscn")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const SIZES := [
	Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080), Vector2i(2560, 1080)
]


func _mount(scene: PackedScene, viewport_size: Vector2i, service_id := "") -> Control:
	var viewport := SubViewport.new()
	viewport.size = viewport_size
	add_child_autofree(viewport)
	var screen := scene.instantiate() as Control
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	if scene == MARKET_SCENE:
		session.black_market.unlocked = true
	if service_id.is_empty():
		screen.configure(session)
	else:
		screen.configure(session, service_id)
	viewport.add_child(screen)
	await wait_process_frames(3)
	return screen


# Independent source-to-screen transform: TextureRect KEEP_ASPECT_COVERED, not panel ratios.
func _screen_point(art: TextureRect, uv: Vector2) -> Vector2:
	var original := art.texture.get_size()
	var factor := maxf(art.size.x / original.x, art.size.y / original.y)
	var image_size := original * factor
	return art.global_position + (art.size - image_size) * 0.5 + uv * image_size


func _hits_at(hit: Button, art: TextureRect, uv: Vector2) -> bool:
	return hit._has_point(_screen_point(art, uv) - hit.global_position)


func _hover(viewport: Viewport, position: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = position
	viewport.push_input(motion, true)
	await wait_process_frames(1)


func _click(viewport: Viewport, position: Vector2) -> void:
	await _hover(viewport, position)
	var press := InputEventMouseButton.new()
	press.position = position
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	viewport.push_input(press, true)
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	viewport.push_input(release, true)
	await wait_process_frames(2)


func test_oren_hit_region_tracks_the_art_without_hitting_the_counter() -> void:
	for viewport_size: Vector2i in SIZES:
		var screen = await _mount(ECONOMY_SCENE, viewport_size, "merchant")
		var art: TextureRect = screen.location_background
		var hit: Button = screen.npc_hit_area
		assert_eq(hit.get_parent(), art.get_parent(), "Not clipped by the legacy portrait panel.")
		for uv: Vector2 in [Vector2(0.442, 0.32), Vector2(0.44, 0.46), Vector2(0.507, 0.621)]:
			assert_true(_hits_at(hit, art, uv), "Oren at %s: %s" % [viewport_size, uv])
		for uv: Vector2 in [Vector2(0.4, 0.29), Vector2(0.50, 0.37), Vector2(0.44, 0.70)]:
			assert_false(_hits_at(hit, art, uv), "Room/counter at %s: %s" % [viewport_size, uv])
		await _hover(screen.get_viewport(), _screen_point(art, Vector2(0.44, 0.46)))
		assert_true(screen.npc_integrated_highlight.visible)
		await _click(screen.get_viewport(), _screen_point(art, Vector2(0.44, 0.46)))
		assert_true(screen.npc_action_panel.visible, "Actual Oren click at %s" % viewport_size)
		await _click(
			screen.get_viewport(), screen.open_service_button.get_global_rect().get_center()
		)
		assert_true(screen.merchant_trade_overlay.visible)
		assert_true(hit.disabled)
		assert_false(screen.npc_integrated_highlight.visible)
		await _click(
			screen.get_viewport(), screen.close_service_button.get_global_rect().get_center()
		)
		assert_false(screen.merchant_trade_overlay.visible, "Pointer closes Oren's inventory.")
		assert_false(hit.disabled)


func test_guildmaster_is_clickable_and_his_feet_stay_in_the_ambient_frame() -> void:
	for viewport_size: Vector2i in SIZES:
		var guild = await _mount(GUILD_SCENE, viewport_size)
		var art: TextureRect = guild.interior
		var hit: Button = guild.guildmaster_hit_area
		for uv: Vector2 in [Vector2(0.285, 0.37), Vector2(0.27, 0.55), Vector2(0.374, 0.523)]:
			assert_true(_hits_at(hit, art, uv), "Guildmaster at %s: %s" % [viewport_size, uv])
		for uv: Vector2 in [Vector2(0.22, 0.37), Vector2(0.38, 0.40), Vector2(0.44, 0.46)]:
			assert_false(_hits_at(hit, art, uv), "Room/notice board must not be the NPC hit area.")
		assert_true(
			guild.hall_presentation.get_global_rect().has_point(
				_screen_point(art, Vector2(0.246, 0.957))
			),
			"Boots are not cropped at %s" % viewport_size
		)
		assert_eq(guild.guildmaster_highlight.get_rect(), art.get_rect())
		await _click(guild.get_viewport(), _screen_point(art, Vector2(0.27, 0.55)))
		assert_true(
			guild.guild_action_panel.visible, "Actual guildmaster click at %s" % viewport_size
		)
		await _click(
			guild.get_viewport(), guild.get_node("%OpenBoardButton").get_global_rect().get_center()
		)
		await wait_process_frames(2)
		assert_true(guild.board_body.visible)
		assert_true(
			guild.hall_presentation.get_global_rect().has_point(
				_screen_point(art, Vector2(0.285, 0.332))
			),
			"The board header must retain the guildmaster's head."
		)
		assert_gt(guild.quest_list.item_count, 0)
		assert_true(hit.disabled)
		assert_false(guild.guildmaster_highlight.visible)
		await _click(
			guild.get_viewport(), guild.get_node("%CloseBoardButton").get_global_rect().get_center()
		)
		assert_true(guild.guild_action_panel.visible)
		assert_false(hit.disabled)


func test_art_hit_regions_follow_resizing_an_existing_screen() -> void:
	var merchant = await _mount(ECONOMY_SCENE, Vector2i(1280, 720), "merchant")
	var guild = await _mount(GUILD_SCENE, Vector2i(1280, 720))
	for viewport_size: Vector2i in SIZES:
		merchant.get_viewport().size = viewport_size
		guild.get_viewport().size = viewport_size
		await wait_process_frames(3)
		assert_true(
			_hits_at(merchant.npc_hit_area, merchant.location_background, Vector2(0.44, 0.32))
		)
		assert_true(_hits_at(guild.guildmaster_hit_area, guild.interior, Vector2(0.285, 0.37)))
		assert_eq(guild.guildmaster_highlight.get_rect(), guild.interior.get_rect())


func test_economy_navigation_receives_pointer_in_every_interaction_state() -> void:
	for service_id in ["merchant", "blacksmith", "workshop", "inn"]:
		for viewport_size: Vector2i in [Vector2i(1280, 720), Vector2i(2560, 1080)]:
			var screen = await _mount(ECONOMY_SCENE, viewport_size, service_id)
			watch_signals(screen)
			var back: Button = screen.get_node("%BackButton")
			for state in ["ambient", "focused", "service"]:
				screen._set_interaction_state(state)
				await wait_process_frames(3)
				await _hover(screen.get_viewport(), back.get_global_rect().get_center())
				assert_eq(
					screen.get_viewport().gui_get_hovered_control(),
					back,
					"Back is not occluded: %s / %s / %s" % [service_id, state, viewport_size]
				)
				await _click(screen.get_viewport(), back.get_global_rect().get_center())
			assert_signal_emit_count(screen, "back_requested", 3)
			await _click(
				screen.get_viewport(), screen.close_service_button.get_global_rect().get_center()
			)
			assert_eq(
				screen._interaction_state, "focused", "Close %s service by pointer" % service_id
			)
			await _click(
				screen.get_viewport(),
				screen.close_interaction_button.get_global_rect().get_center()
			)
			assert_eq(
				screen._interaction_state, "ambient", "Leave %s counter by pointer" % service_id
			)


func test_guild_back_receives_pointer_with_and_without_board() -> void:
	for viewport_size: Vector2i in SIZES:
		var guild = await _mount(GUILD_SCENE, viewport_size)
		watch_signals(guild)
		var back: Button = guild.get_node("%BackButton")
		for state in ["ambient", "focused", "board"]:
			guild._set_interaction_state(state)
			await wait_process_frames(3)
			await _hover(guild.get_viewport(), back.get_global_rect().get_center())
			assert_eq(
				guild.get_viewport().gui_get_hovered_control(),
				back,
				"Guild Back is not occluded: %s / %s" % [state, viewport_size]
			)
			await _click(guild.get_viewport(), back.get_global_rect().get_center())
		assert_signal_emit_count(guild, "back_requested", 3)


func test_merchant_stock_selection_purchase_and_mode_picker_still_receive_pointer() -> void:
	var screen = await _mount(ECONOMY_SCENE, Vector2i(1920, 1080), "merchant")
	screen._session.player.gold = 100
	screen._focus_npc()
	await wait_process_frames(3)
	await _click(screen.get_viewport(), screen.open_service_button.get_global_rect().get_center())
	var grid: Control = screen.merchant_stock_grid
	watch_signals(grid)
	await _click(screen.get_viewport(), grid.get_child(1).get_global_rect().get_center())
	await _click(screen.get_viewport(), grid.get_child(0).get_global_rect().get_center())
	assert_signal_emit_count(
		grid, "entry_selected", 2, "Slots remain interactive inside the overlay."
	)
	await _click(
		screen.get_viewport(), screen.merchant_action_button.get_global_rect().get_center()
	)
	assert_eq(screen._session.player.gold, 75)
	assert_eq(screen._session.player.inventory.count("weak_healing_potion"), 1)
	await _click(screen.get_viewport(), screen.mode_selector.get_global_rect().get_center())
	assert_true(screen.mode_selector.get_popup().visible, "Offer mode picker is not blocked.")
	screen.mode_selector.get_popup().hide()
	await _click(screen.get_viewport(), screen.close_service_button.get_global_rect().get_center())
	assert_eq(screen._interaction_state, "focused")


func test_black_market_tabs_and_back_receive_pointer() -> void:
	for viewport_size: Vector2i in [Vector2i(1920, 1080), Vector2i(2560, 1080)]:
		var market = await _mount(MARKET_SCENE, viewport_size)
		watch_signals(market)
		await _click(market.get_viewport(), market.sell_tab.get_global_rect().get_center())
		assert_true(market.sell_panel.visible)
		await _click(
			market.get_viewport(), market.get_node("%BackButton").get_global_rect().get_center()
		)
		await _click(market.get_viewport(), market.buy_tab.get_global_rect().get_center())
		assert_false(market.sell_panel.visible)
		await _click(
			market.get_viewport(), market.get_node("%BackButton").get_global_rect().get_center()
		)
		assert_signal_emit_count(market, "back_requested", 2)


func test_navigation_hover_highlights_text_without_changing_button_geometry() -> void:
	var screen = await _mount(ECONOMY_SCENE, Vector2i(1920, 1080), "merchant")
	screen._open_service()
	await wait_process_frames(3)
	for button: Button in [screen.close_service_button, screen.get_node("%BackButton")]:
		var rect := button.get_global_rect()
		await _hover(screen.get_viewport(), rect.get_center())
		assert_eq(screen.get_viewport().gui_get_hovered_control(), button)
		assert_eq(button.get_draw_mode(), BaseButton.DRAW_HOVER)
		assert_ne(button.get_theme_color("font_hover_color"), button.get_theme_color("font_color"))
		assert_ne(button.get_theme_color("font_focus_color"), button.get_theme_color("font_color"))
		assert_ne(
			button.get_theme_color("font_disabled_color"),
			button.get_theme_color("font_hover_color")
		)
		assert_eq(button.get_global_rect(), rect, "Hover must not move or resize the button.")
