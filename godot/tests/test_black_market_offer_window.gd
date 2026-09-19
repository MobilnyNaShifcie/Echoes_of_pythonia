extends GutTest

const Market = preload("res://ui/screens/black_market/black_market.tscn")
const NewGame = preload("res://core/game/new_game_service.gd")
const Service = preload("res://core/economy/black_market_service.gd")
const Catalog = preload("res://core/items/item_catalog.gd")
const Books = preload("res://core/progression/book_catalog.gd")
const Palette = preload("res://ui/presentation/item_rarity_palette.gd")
const Style = preload("res://ui/presentation/interface_style.gd")


func _mount(dimensions := Vector2i(1920, 1080)):
	var viewport := SubViewport.new()
	viewport.size = dimensions
	add_child_autofree(viewport)
	var screen = Market.instantiate()
	var session = NewGame.new().create_session("Aria", 1)
	session.black_market.unlocked = true
	session.player.gold = 200000
	screen.configure(session, "2026-09-19")
	viewport.add_child(screen)
	await wait_process_frames(3)
	return screen


func _click(control: Control, twice := false) -> void:
	var viewport := control.get_viewport()
	var point := control.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	viewport.push_input(motion, true)
	var press := InputEventMouseButton.new()
	press.position = point
	press.button_index = MOUSE_BUTTON_LEFT
	press.double_click = twice
	press.pressed = true
	viewport.push_input(press, true)
	press = press.duplicate()
	press.pressed = false
	viewport.push_input(press, true)
	await wait_process_frames(3)


func test_entry_has_empty_counter_and_no_visible_offer_ui_or_3d() -> void:
	var screen = await _mount()
	assert_false(screen.offer_window.visible)
	assert_eq(screen.offer_slots.size(), 4)
	assert_null(screen.get_node_or_null("HeaderPanel"))
	assert_null(screen.get_node_or_null("InventoryDropTarget"))
	assert_eq(screen.find_children("*", "SubViewport", true, false).size(), 0)
	assert_true(screen.get_node("%MerchantHint").visible)
	for card in screen.offer_slots:
		assert_false(card.is_visible_in_tree())
		var definition = Catalog.get_definition(card.item_id)
		assert_same(card.icon_rect.texture, definition.icon)
		assert_eq(card._rarity, Palette.color_for(definition.rarity))


func test_pointer_opens_selects_and_closes_at_supported_resolutions() -> void:
	for dimensions in [Vector2i(1920, 1080), Vector2i(1366, 768), Vector2i(1280, 720)]:
		var screen = await _mount(dimensions)
		var before := Service.serialize(screen._session.black_market)
		await _click(screen.merchant_button)
		assert_true(screen.npc_action_panel.visible)
		assert_true(screen.get_global_rect().encloses(screen.npc_action_panel.get_global_rect()))
		assert_false(screen.offer_window.visible, "Merchant opens conversation, not shop")
		await _click(screen.get_node("%OpenServiceButton"))
		assert_true(screen.offer_window.visible)
		assert_false(screen.npc_action_panel.visible)
		await _click(screen.offer_slots[2], true)
		assert_eq(screen._selected_id, screen.offer_slots[2].offer_id)
		assert_eq(screen._session.player.gold, 200000, "Double-click only selects")
		assert_eq(Service.serialize(screen._session.black_market), before)
		await _click(screen.get_node("%CloseButton"))
		assert_false(screen.offer_window.visible)
		assert_true(screen.npc_action_panel.visible)
		await _click(screen.get_node("%CloseInteractionButton"))
		await _click(screen.get_node("%MerchantHint"))
		assert_false(screen.offer_window.visible)
		await _click(screen.get_node("%OpenServiceButton"))
		assert_true(screen.offer_window.visible)
		assert_eq(Service.serialize(screen._session.black_market), before)


func test_escape_returns_to_conversation_then_ambient_then_city() -> void:
	var screen = await _mount()
	watch_signals(screen)
	screen.show_buy_offers()
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	screen.get_viewport().push_input(escape, true)
	await wait_process_frames(2)
	assert_false(screen.offer_window.visible)
	assert_true(screen.npc_action_panel.visible)
	assert_signal_not_emitted(screen, "back_requested")
	screen.get_viewport().push_input(escape, true)
	await wait_process_frames(2)
	assert_false(screen.npc_action_panel.visible)
	assert_signal_not_emitted(screen, "back_requested")
	screen.get_viewport().push_input(escape, true)
	await wait_process_frames(2)
	assert_signal_emit_count(screen, "back_requested", 1)


func test_card_hover_does_not_change_selection_or_geometry() -> void:
	var screen = await _mount()
	screen.show_buy_offers()
	await wait_process_frames(3)
	var id: String = screen._selected_id
	var card = screen.offer_slots[3]
	var rect: Rect2 = card.get_global_rect()
	var motion := InputEventMouseMotion.new()
	motion.position = rect.get_center()
	screen.get_viewport().push_input(motion, true)
	await wait_process_frames(2)
	assert_eq(screen._selected_id, id)
	assert_eq(card.get_global_rect(), rect)
	assert_eq(screen._session.player.gold, 200000)


func test_bargaining_updates_same_card_once_without_changing_delivery() -> void:
	var screen = await _mount()
	screen.show_buy_offers()
	var card = screen.offer_slots[0]
	var offer = Service.find_offer(screen._session.black_market, card.offer_id)
	var rotation: String = screen._session.black_market.rotation_key
	await _click(screen.bargain_button)
	var price := Service.effective_buy_price(screen._session.black_market, offer)
	assert_eq(card.price_label.text, screen._group_digits(price))
	assert_true(card.price_coin.visible)
	assert_true(screen.bargain_button.disabled)
	assert_eq(screen._session.player.gold, 200000)
	await _click(screen.bargain_button)
	assert_eq(Service.effective_buy_price(screen._session.black_market, offer), price)
	await _click(screen.action_button)
	assert_eq(screen._session.player.gold, 200000 - price)
	assert_eq(screen._session.black_market.rotation_key, rotation)
	assert_true(card.disabled)


func test_book_sales_and_empty_state_still_work_in_same_window() -> void:
	var screen = await _mount()
	var id: String = Books.BOOK_ORDER[0]
	screen._session.player.inventory.add(id, 1)
	screen.show_buy_offers()
	await _click(screen.sell_tab)
	assert_true(screen.sell_panel.visible)
	assert_false(screen.offer_layer.visible)
	assert_eq(screen.offer_list.item_count, 1)
	var before: int = screen._session.player.gold
	var price := Service.effective_book_sell_price(screen._session.black_market, id)
	await _click(screen.action_button)
	assert_eq(screen._session.player.inventory.count(id), 0)
	assert_eq(screen._session.player.gold, before + price)
	assert_eq(screen.offer_list.item_count, 0)
	assert_true(screen.action_button.disabled)
	assert_true(screen.bargain_button.disabled)
	assert_false(screen.get_node("%DetailIconFrame").visible)
	await _click(screen.buy_tab)
	assert_true(screen.offer_layer.visible)
	assert_eq(screen.offer_slots.size(), 4)


func test_feedback_tolerates_hint_removed_during_screen_teardown() -> void:
	var screen = await _mount()
	screen.get_node("%MerchantHint").free()
	screen._merchant_feedback(false)
	assert_null(screen.get_node_or_null("%MerchantHint"))


func test_dragging_card_outside_window_cannot_purchase() -> void:
	var screen = await _mount()
	screen.show_buy_offers()
	await wait_process_frames(3)
	var viewport: Viewport = screen.get_viewport()
	var point: Vector2 = screen.offer_slots[0].get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	viewport.push_input(motion, true)
	var press := InputEventMouseButton.new()
	press.position = point
	press.button_index = MOUSE_BUTTON_LEFT
	press.button_mask = MOUSE_BUTTON_MASK_LEFT
	press.pressed = true
	viewport.push_input(press, true)
	motion.relative = Vector2(30, 20)
	motion.position += motion.relative
	motion.button_mask = MOUSE_BUTTON_MASK_LEFT
	viewport.push_input(motion, true)
	await wait_process_frames(2)
	assert_false(viewport.gui_is_dragging())
	press.position = Vector2(100, 900)
	press.pressed = false
	press.button_mask = 0
	viewport.push_input(press, true)
	await wait_process_frames(2)
	assert_eq(screen._session.player.gold, 200000)
	assert_true(screen._session.black_market.purchased_offer_ids.is_empty())


func test_long_descriptions_and_names_are_bounded_with_full_tooltips() -> void:
	var screen = await _mount(Vector2i(1366, 768))
	screen.show_buy_offers()
	var definition = Catalog.get_definition("hearth_core").duplicate()
	definition.display_name = "Zażółć gęślą jaźń — bardzo długa nazwa przedmiotu ".repeat(8)
	definition.description = "Pełny opis z polskimi znakami: ąęółżźćńś. ".repeat(40)
	var rect: Rect2 = screen.offer_window.get_global_rect()
	screen._render_definition(definition)
	await wait_process_frames(3)
	assert_eq(screen.offer_window.get_global_rect(), rect)
	for label in [screen.title_label, screen.description_label]:
		assert_true(rect.encloses(label.get_global_rect()))
		assert_eq(label.text_overrun_behavior, TextServer.OVERRUN_TRIM_ELLIPSIS)
		assert_eq(label.tooltip_text, label.text)


func test_conversation_uses_same_panel_and_buttons_as_other_city_npcs() -> void:
	var screen = await _mount()
	screen.show_conversation()
	await wait_process_frames(2)
	var panel: StyleBoxFlat = screen.npc_action_panel.get_theme_stylebox("panel")
	var expected := Style.panel()
	assert_eq(panel.bg_color, expected.bg_color)
	assert_eq(panel.corner_radius_top_left, expected.corner_radius_top_left)
	var button: Button = screen.get_node("%OpenServiceButton")
	assert_eq(button.get_theme_font_size("font_size"), 15)
	assert_eq(button.get_theme_stylebox("normal").bg_color, Style.panel(0.8).bg_color)
	assert_eq(screen.npc_action_panel.size.x, 442.0)
	assert_eq(screen.npc_action_panel.size.y, 342.0)
	assert_eq(screen.get_node("NpcActionPanel/Content/Eyebrow").text, "ROZMOWA")
