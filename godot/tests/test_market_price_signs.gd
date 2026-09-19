extends GutTest
## Prices now belong to offer cards, not hanging 3D boards.
const Market = preload("res://ui/screens/black_market/black_market.tscn")
const NewGame = preload("res://core/game/new_game_service.gd")


func _market(gold := 200000):
	var session = NewGame.new().create_session("Aria", 1)
	session.black_market.unlocked = true
	session.player.gold = gold
	var market = Market.instantiate()
	add_child_autofree(market)
	market.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	market.size = Vector2(1920, 1080)
	market.configure(session, "2026-09-05")
	market.show_buy_offers()
	return market


func test_four_equal_cards_and_prices_remain_inside_window_at_multiple_sizes() -> void:
	var market = _market()
	for screen_size in [
		Vector2(1920, 1080), Vector2(1366, 768), Vector2(1280, 720), Vector2(2560, 1080)
	]:
		market.size = screen_size
		await wait_process_frames(3)
		market._layout_market()
		var window: Rect2 = market.offer_window.get_global_rect()
		assert_true(market.get_global_rect().encloses(window))
		var previous := Rect2()
		for card in market.offer_slots:
			var rect: Rect2 = card.get_global_rect()
			assert_true(window.encloses(rect))
			assert_true(rect.encloses(card.price_label.get_global_rect()))
			assert_eq(card.icon_rect.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
			if previous.size.x > 0:
				assert_almost_eq(rect.size.x, previous.size.x, 0.1)
				assert_gt(rect.position.x, previous.end.x)
			previous = rect
	assert_eq(market.find_children("*", "Node3D", true, false).size(), 0)


func test_price_matches_negotiated_offer_and_sold_state() -> void:
	var market = _market()
	var card = market.offer_slots[2]
	market._session.black_market.buy_negotiated_prices[card.offer_id] = 6000
	market._render()
	card.pressed.emit()
	assert_eq(card.price_label.text, "6 000 zł")
	assert_string_contains(market.price_label.text, "6 000")
	market.action_button.pressed.emit()
	assert_true(card.sold_label.visible)
	assert_true(card.disabled)
	assert_eq(market._session.player.gold, 194000)


func test_card_clear_removes_stale_art_price_and_quantity() -> void:
	var market = _market()
	var card = market.offer_slots[2]
	card.clear_offer()
	assert_null(card.icon_rect.texture)
	assert_eq(card.price_label.text, "—")
	assert_false(card.quantity_label.visible)
	assert_true(card.disabled)


func test_no_counter_drop_target_or_header_but_transaction_feedback_remains() -> void:
	var market = _market(0)
	assert_null(market.get_node_or_null("HeaderPanel"))
	assert_null(market.get_node_or_null("InventoryDropTarget"))
	assert_false(market.result_label.visible)
	market.action_button.pressed.emit()
	assert_true(market.result_label.visible)
	assert_false(market.result_label.text.is_empty())
	assert_true(market.offer_window.is_ancestor_of(market.result_label))
	market.show_book_sales()
	assert_false(market.offer_layer.visible)
	assert_false(market.result_label.visible)
	market.show_buy_offers()
	assert_true(market.offer_layer.visible)
