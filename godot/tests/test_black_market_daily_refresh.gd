extends GutTest

const Market = preload("res://ui/screens/black_market/black_market.tscn")
const NewGame = preload("res://core/game/new_game_service.gd")
const Service = preload("res://core/economy/black_market_service.gd")
const Books = preload("res://core/progression/book_catalog.gd")
const Saves = preload("res://core/save/save_game_service.gd")


func _market():
	var session = NewGame.new().create_session("Aria", 1)
	session.black_market.unlocked = true
	session.player.gold = 200000
	var market = Market.instantiate()
	market.configure(session, "2026-09-19")
	add_child_autofree(market)
	market.show_buy_offers()
	return market


func test_same_day_reopening_preserves_purchases_negotiations_and_selection() -> void:
	var market = _market()
	market._bargain()
	market._perform_action()
	var before := Service.serialize(market._session.black_market)
	watch_signals(market)
	for attempt in 3:
		market.close_offers()
		market.show_buy_offers()
		assert_false(market._check_daily_rotation())
		assert_eq(Service.serialize(market._session.black_market), before)
	assert_true(market.offer_slots[0].sold_label.visible)
	assert_signal_not_emitted(market, "state_changed")


func test_next_calendar_day_not_next_week_resets_stock_and_negotiations() -> void:
	var market = _market()
	var state = market._session.black_market
	market._bargain()
	market._perform_action()
	state.sale_negotiated_prices[Books.BOOK_ORDER[0]] = 4321
	watch_signals(market)
	var gold: int = market._session.player.gold
	market._rotation_date = "2026-09-20"
	assert_true(market._check_daily_rotation())
	assert_eq(state.rotation_key, "2026-09-20")
	assert_eq(state.offers.size(), 4)
	assert_true(state.purchased_offer_ids.is_empty())
	assert_true(state.buy_negotiated_prices.is_empty())
	assert_true(state.sale_negotiated_prices.is_empty())
	assert_eq(market._session.player.gold, gold)
	assert_eq(market._selected_id, "")
	assert_true(market.action_button.disabled, "New delivery needs explicit selection")
	assert_false(market.get_node("%PriceCoin").visible)
	assert_signal_emit_count(market, "state_changed", 1)
	assert_string_contains(market.delivery_label.text, "2026-09-21")
	assert_false(market._check_daily_rotation())
	assert_signal_emit_count(market, "state_changed", 1)
	market.offer_slots[0].pressed.emit()
	assert_false(market.action_button.disabled)


func test_open_screen_timer_refreshes_delivery_without_leaving_market() -> void:
	var market = _market()
	market._rotation_date = "2026-09-20"
	var timer: Timer = market.get_node("%DailyRefreshTimer")
	assert_false(timer.is_stopped())
	timer.start(0.01)
	# Await the actual timer signal, not a direct call to the refresh method.
	await timer.timeout
	# Let the signal finish before GUT frees its sender at test teardown.
	await wait_process_frames(2)
	assert_true(market.offer_window.visible)
	assert_eq(market._session.black_market.rotation_key, "2026-09-20")
	assert_eq(market.offer_slots[0].offer_id, market._session.black_market.offers[0].offer_id)


func test_stale_purchase_click_cannot_buy_replacement_after_midnight() -> void:
	var market = _market()
	var old_offer = market._session.black_market.offers[0]
	var count: int = market._session.player.inventory.count(old_offer.item_id)
	market._rotation_date = "2026-09-20"
	market.action_button.pressed.emit()
	assert_eq(market._session.player.gold, 200000)
	assert_eq(market._session.player.inventory.count(old_offer.item_id), count)
	assert_true(market._session.black_market.purchased_offer_ids.is_empty())
	assert_true(market.action_button.disabled)
	market.offer_slots[1].pressed.emit()
	var new_offer = market._session.black_market.offers[1]
	var before: int = market._session.player.inventory.count(new_offer.item_id)
	market.action_button.pressed.emit()
	assert_eq(market._session.player.gold, 200000 - new_offer.base_price)
	assert_eq(
		market._session.player.inventory.count(new_offer.item_id), before + new_offer.quantity
	)
	assert_eq(market._session.black_market.purchased_offer_ids, [new_offer.offer_id])


func test_stale_bargaining_click_does_not_use_new_delivery_attempt() -> void:
	var market = _market()
	market._rotation_date = "2026-09-20"
	market.bargain_button.pressed.emit()
	assert_true(market._session.black_market.buy_negotiated_prices.is_empty())
	assert_true(market.bargain_button.disabled)
	market._bargain()
	assert_true(market._session.black_market.buy_negotiated_prices.is_empty())


func test_stale_book_sale_click_does_not_sell_at_an_unreviewed_price() -> void:
	var market = _market()
	var book: String = Books.BOOK_ORDER[0]
	market._session.player.inventory.add(book, 2)
	market.show_book_sales()
	market._bargain()
	market._rotation_date = "2026-09-20"
	market.action_button.pressed.emit()
	assert_eq(market._session.player.inventory.count(book), 2)
	assert_eq(market._session.player.gold, 200000)
	assert_true(market._session.black_market.sale_negotiated_prices.is_empty())
	assert_eq(market._mode, market.MODE_SELL)


func test_reentering_conversation_checks_new_day_before_opening_shop() -> void:
	var market = _market()
	market.close_offers()
	market.close_conversation()
	market._rotation_date = "2026-09-20"
	market.merchant_button.pressed.emit()
	assert_true(market.npc_action_panel.visible)
	assert_false(market.offer_window.visible)
	assert_eq(market._session.black_market.rotation_key, "2026-09-20")
	market.get_node("%OpenBookSalesButton").pressed.emit()
	assert_true(market.sell_panel.visible)
	assert_false(market.npc_action_panel.visible)


func test_application_focus_rechecks_delivery_after_suspension() -> void:
	var market = _market()
	market.get_node("%DailyRefreshTimer").stop()
	market._rotation_date = "2026-09-20"
	market._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
	await wait_process_frames(2)
	assert_eq(market._session.black_market.rotation_key, "2026-09-20")
	assert_true(market.action_button.disabled)


func test_daily_calendar_boundaries_and_save_roundtrip() -> void:
	var market = _market()
	var service := Saves.new("user://black_market_daily_not_written")
	for pair in [
		["2026-09-30", "2026-10-01"],
		["2026-12-31", "2027-01-01"],
		["2028-02-28", "2028-02-29"],
		["2028-02-29", "2028-03-01"],
		["2026-10-25", "2026-10-26"],
	]:
		assert_eq(Service.next_rotation_date(pair[0]), pair[1])
		market._rotation_date = pair[0]
		market._check_daily_rotation()
		market._rotation_date = pair[1]
		assert_true(market._check_daily_rotation())
		var loaded := service._deserialize_payload(service._serialize_session(market._session), 1)
		assert_true(loaded.ok, loaded.message)
		assert_eq(
			Service.serialize(loaded.session.black_market),
			Service.serialize(market._session.black_market)
		)
