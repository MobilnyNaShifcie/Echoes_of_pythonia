extends GutTest

const BlackMarketServiceClass := preload("res://core/economy/black_market_service.gd")
const BookCatalogClass := preload("res://core/progression/book_catalog.gd")
const CityHubScreenClass := preload("res://ui/screens/city_hub/city_hub.gd")
const CityServiceScreenClass := preload("res://ui/screens/city_service/city_service.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const BlackMarketScreenClass := preload("res://ui/screens/black_market/black_market.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")
const APP_SCENE := preload("res://scenes/app/app.tscn")
const BLACK_MARKET_SCENE := preload("res://ui/screens/black_market/black_market.tscn")
const CITY_HUB_SCENE := preload("res://ui/screens/city_hub/city_hub.tscn")
const CITY_SERVICE_SCENE := preload("res://ui/screens/city_service/city_service.tscn")


func test_informant_requires_rank_c_and_one_of_two_dungeon_milestones() -> void:
	var session = _session()
	session.guild_reputation = 700
	assert_false(BlackMarketServiceClass.informant_eligible(session))
	session.guild_milestones.append("boss:azhar")
	assert_false(BlackMarketServiceClass.informant_eligible(session))
	session.guild_milestones.append("dungeon:sunken_order_crypt")
	assert_true(BlackMarketServiceClass.informant_eligible(session))
	session.guild_reputation = 699
	assert_false(BlackMarketServiceClass.informant_eligible(session))


func test_fifth_eligible_day_is_guaranteed_and_same_day_does_not_reroll() -> void:
	var session = _eligible_session()
	session.day = 5
	session.black_market.informant_failed_checks = 4
	var first := BlackMarketServiceClass.check_informant_for_day(session, _rng(1))
	assert_true(first.checked)
	assert_true(first.present)
	assert_true(first.guaranteed)
	assert_eq(session.black_market.informant_last_check_day, 5)
	assert_eq(session.black_market.informant_failed_checks, 0)

	var repeated := BlackMarketServiceClass.check_informant_for_day(session, _rng(999))
	assert_false(repeated.checked)
	assert_true(repeated.present)
	assert_eq(session.black_market.informant_last_check_day, 5)


func test_informant_permanently_unlocks_market_and_writes_journal() -> void:
	var session = _eligible_session()
	session.day = 7
	session.black_market.informant_present_day = 7
	session.black_market.informant_last_check_day = 7
	var result := BlackMarketServiceClass.unlock(session)

	assert_true(result.ok)
	assert_true(session.black_market.unlocked)
	assert_eq(session.black_market.informant_present_day, 0)
	assert_string_contains(session.adventure_log.entries[-1], "Odkryto drogę")
	assert_false(BlackMarketServiceClass.unlock(session).ok)


func test_daily_rotation_has_four_stable_valid_offers_and_resets_state() -> void:
	var session = _unlocked_session()
	var market = session.black_market
	assert_true(BlackMarketServiceClass.ensure_rotation(market, "Aria", "2026-08-16"))
	assert_eq(market.offers.size(), 4)
	var first_payload := BlackMarketServiceClass.serialize(market)
	assert_false(BlackMarketServiceClass.ensure_rotation(market, "Aria", "2026-08-16"))
	assert_eq(BlackMarketServiceClass.serialize(market), first_payload)
	for offer in market.offers:
		assert_not_null(ItemCatalogClass.get_definition(offer.item_id))
		assert_gt(offer.base_price, 0)
		assert_gt(offer.quantity, 0)

	market.purchased_offer_ids.append(market.offers[0].offer_id)
	market.buy_negotiated_prices[market.offers[1].offer_id] = 1234
	market.sale_negotiated_prices[BookCatalogClass.BOOK_ORDER[0]] = 4321
	assert_true(BlackMarketServiceClass.ensure_rotation(market, "Aria", "2026-08-17"))
	assert_true(market.purchased_offer_ids.is_empty())
	assert_true(market.buy_negotiated_prices.is_empty())
	assert_true(market.sale_negotiated_prices.is_empty())
	assert_eq(market.rotation_key, "2026-08-17")


func test_buy_bargain_is_one_attempt_and_purchase_is_single_stock() -> void:
	var session = _unlocked_session()
	session.player.gold = 200000
	BlackMarketServiceClass.ensure_rotation(
		session.black_market, session.player.display_name, "2026-08-16"
	)
	var offer = session.black_market.offers[0]
	var bargain := BlackMarketServiceClass.bargain_buy(
		session.black_market, offer, _rng_for_first_roll_below(0.30)
	)
	assert_true(bargain.ok)
	assert_true(bargain.success)
	assert_lt(bargain.new_price, bargain.old_price)
	assert_false(BlackMarketServiceClass.bargain_buy(session.black_market, offer, _rng(2)).ok)
	var before_count: int = session.player.inventory.count(offer.item_id)
	var purchase := BlackMarketServiceClass.buy(session, offer.offer_id)
	assert_true(purchase.ok, purchase.message)
	assert_eq(session.player.inventory.count(offer.item_id), before_count + offer.quantity)
	assert_eq(purchase.paid, bargain.new_price)
	assert_false(BlackMarketServiceClass.buy(session, offer.offer_id).ok)


func test_book_sale_bargain_changes_price_and_sells_one_copy() -> void:
	var session = _unlocked_session()
	var item_id: String = BookCatalogClass.BOOK_ORDER[0]
	session.player.inventory.add(item_id, 2)
	var bargain := BlackMarketServiceClass.bargain_book_sale(
		session.black_market, item_id, _rng_for_first_roll_below(0.30)
	)
	assert_true(bargain.ok)
	assert_true(bargain.success)
	assert_gt(bargain.new_price, bargain.old_price)
	var gold_before: int = session.player.gold
	var sale := BlackMarketServiceClass.sell_book(session, item_id)
	assert_true(sale.ok, sale.message)
	assert_eq(session.player.inventory.count(item_id), 1)
	assert_eq(session.player.gold, gold_before + bargain.new_price)
	assert_false(
		BlackMarketServiceClass.bargain_book_sale(session.black_market, item_id, _rng(3)).ok
	)


func test_schema_eleven_preserves_market_and_schema_ten_gets_locked_default() -> void:
	var session = _unlocked_session()
	BlackMarketServiceClass.ensure_rotation(
		session.black_market, session.player.display_name, "2099-08-16"
	)
	session.player.gold = 200000
	var offer = session.black_market.offers[0]
	BlackMarketServiceClass.bargain_buy(session.black_market, offer, _rng(4))
	BlackMarketServiceClass.buy(session, offer.offer_id)
	var service := SaveGameServiceClass.new("user://stage_five_d_not_written")
	var payload: Dictionary = service._serialize_session(session)

	assert_eq(payload.schema_version, 15)
	var loaded := service._deserialize_payload(payload, 1)
	assert_true(loaded.ok, loaded.message)
	assert_true(loaded.session.black_market.unlocked)
	assert_eq(loaded.session.black_market.rotation_key, "2099-08-16")
	assert_eq(loaded.session.black_market.offers.size(), 4)
	assert_eq(
		loaded.session.black_market.purchased_offer_ids,
		session.black_market.purchased_offer_ids,
	)
	assert_eq(
		loaded.session.black_market.buy_negotiated_prices,
		session.black_market.buy_negotiated_prices,
	)

	var legacy := payload.duplicate(true)
	legacy.schema_version = 10
	legacy.session.erase("black_market")
	var migrated := service._deserialize_payload(legacy, 1)
	assert_true(migrated.ok, migrated.message)
	assert_false(migrated.session.black_market.unlocked)
	assert_true(migrated.session.black_market.offers.is_empty())


func test_save_rejects_tampered_offer_and_duplicate_purchased_state() -> void:
	var session = _unlocked_session()
	BlackMarketServiceClass.ensure_rotation(
		session.black_market, session.player.display_name, "2099-08-16"
	)
	var service := SaveGameServiceClass.new("user://stage_five_d_invalid_not_written")
	var payload: Dictionary = service._serialize_session(session)
	payload.session.black_market.offers[0].base_price = 1
	var tampered := service._deserialize_payload(payload, 1)
	assert_false(tampered.ok)
	assert_string_contains(tampered.message, "zmienioną ofertę")

	payload = service._serialize_session(session)
	var offer_id: String = payload.session.black_market.offers[0].offer_id
	payload.session.black_market.purchased_offer_ids = [offer_id, offer_id]
	var duplicate := service._deserialize_payload(payload, 1)
	assert_false(duplicate.ok)
	assert_string_contains(duplicate.message, "powtórzoną wykupioną ofertę")


func test_informant_city_flow_and_black_market_screen_need_no_terminal() -> void:
	var session = _eligible_session()
	session.black_market.informant_failed_checks = 4
	var inn = CITY_SERVICE_SCENE.instantiate() as CityServiceScreenClass
	add_child_autofree(inn)
	inn.configure(session, "inn", _rng(1))
	assert_true(inn.informant_button.visible)
	inn.informant_button.pressed.emit()
	assert_true(session.black_market.unlocked)

	var city = CITY_HUB_SCENE.instantiate() as CityHubScreenClass
	city.configure(session)
	add_child_autofree(city)
	assert_false(city.black_market_button.disabled)
	assert_eq(city.black_market_button.text, "Czarny Rynek")

	var market = BLACK_MARKET_SCENE.instantiate()
	add_child_autofree(market)
	market.configure(session, "2099-08-16")
	assert_eq(market.offer_list.item_count, 4)
	assert_false(market.bargain_button.disabled)
	market.show_book_sales()
	assert_eq(market.offer_list.item_count, 0)


func test_app_routes_unlocked_city_button_to_market_placeholder() -> void:
	var session = _unlocked_session()
	session.prologue_completed = true
	var app = APP_SCENE.instantiate()
	add_child_autofree(app)
	app._on_session_created(session)
	app._show_black_market()
	await get_tree().process_frame
	assert_true(app.screen_host.get_child(0) is BlackMarketScreenClass)
	assert_string_contains(app.app_status_label.text, "Czarny Rynek")


func _eligible_session():
	var session = _session()
	session.guild_reputation = 700
	session.guild_milestones.append("dungeon:sunken_order_crypt")
	return session


func _unlocked_session():
	var session = _eligible_session()
	session.black_market.unlocked = true
	return session


func _session():
	return NewGameServiceClass.new().create_session("Aria", 1, _rng(1))


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func _rng_for_first_roll_below(limit: float) -> RandomNumberGenerator:
	for seed_value in 10000:
		var probe := _rng(seed_value)
		if probe.randf() < limit:
			return _rng(seed_value)
	return _rng(1)
