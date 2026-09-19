extends GutTest
## Prices belong only to the selected-item details, never the offer cards.
const Market = preload("res://ui/screens/black_market/black_market.tscn")
const NewGame = preload("res://core/game/new_game_service.gd")
const Service = preload("res://core/economy/black_market_service.gd")
const Catalog = preload("res://core/items/item_catalog.gd")


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


func test_four_equal_cards_have_full_height_rarity_frames_and_no_price_footer() -> void:
	var market = _market()
	for screen_size in [
		Vector2(1920, 1080), Vector2(1366, 768), Vector2(1280, 720), Vector2(2560, 1080)
	]:
		market.size = screen_size
		await wait_process_frames(3)
		market._layout_market()
		var window: Rect2 = market.offer_window.get_global_rect()
		assert_true(market.get_global_rect().encloses(window))
		var rectangles: Array[Rect2] = []
		for card in market.offer_slots:
			var rect: Rect2 = card.get_global_rect()
			assert_true(window.encloses(rect))
			var frame: Rect2 = card.rarity_frame_rect()
			assert_eq(frame.position, Vector2(8, 8))
			assert_eq(card.size - frame.end, Vector2(8, 8))
			assert_true(frame.encloses(card.icon_rect.get_rect()))
			assert_true(frame.encloses(card.quantity_label.get_rect()))
			assert_eq(card.find_children("*", "Label", true, false).size(), 2)
			assert_eq(card.find_children("*", "TextureRect", true, false).size(), 1)
			assert_eq(card.get_child_count(), 3, "Only art, quantity and sold state; no price row")
			assert_eq(card.icon_rect.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
			for previous in rectangles:
				assert_almost_eq(rect.size.x, previous.size.x, 0.1)
				assert_almost_eq(rect.size.y, previous.size.y, 0.1)
				assert_false(rect.intersects(previous))
			rectangles.append(rect)
		assert_eq(market.offer_layer.columns, 2)
		assert_almost_eq(rectangles[0].position.y, rectangles[1].position.y, 0.1)
		assert_almost_eq(rectangles[2].position.y, rectangles[3].position.y, 0.1)
		assert_almost_eq(rectangles[0].position.x, rectangles[2].position.x, 0.1)
		assert_gt(rectangles[2].position.y, rectangles[0].end.y)
	assert_eq(market.find_children("*", "Node3D", true, false).size(), 0)


func test_price_matches_negotiated_offer_and_sold_state() -> void:
	var market = _market()
	var card = market.offer_slots[2]
	market._session.black_market.buy_negotiated_prices[card.offer_id] = 6000
	market._render()
	card.pressed.emit()
	assert_true(market.get_node("%PriceCoin").visible)
	assert_eq(market.price_label.text, "6 000")
	assert_false(card.tooltip_text.contains("6 000"))
	assert_false(card.tooltip_text.contains("Cena:"))
	market.action_button.pressed.emit()
	assert_true(card.sold_label.visible)
	assert_true(card.disabled)
	assert_eq(market._session.player.gold, 194000)


func test_card_clear_removes_stale_art_and_quantity() -> void:
	var market = _market()
	var card = market.offer_slots[2]
	card.clear_offer()
	assert_null(card.icon_rect.texture)
	assert_eq(card.tooltip_text, "")
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


func test_selecting_each_card_updates_only_the_single_detail_price() -> void:
	var market = _market()
	for card in market.offer_slots:
		card.pressed.emit()
		var offer = Service.find_offer(market._session.black_market, card.offer_id)
		assert_eq(market.price_label.text, market._group_digits(offer.base_price))
		assert_true(market.get_node("%PriceCoin").is_visible_in_tree())
		var definition = Catalog.get_definition(card.item_id)
		assert_eq(card.tooltip_text, "%s\n%s" % [definition.display_name, definition.description])
		assert_eq(card.find_children("*", "Label", true, false).size(), 2)
	assert_eq(market._session.player.gold, 200000, "Selection is not a purchase")
