extends GutTest
## The counter drag-to-buy interaction was intentionally replaced by explicit card selection.
const Market = preload("res://ui/screens/black_market/black_market.tscn")
const NewGame = preload("res://core/game/new_game_service.gd")


func _market(gold := 200000):
	var session = NewGame.new().create_session("Aria", 1)
	session.black_market.unlocked = true
	session.player.gold = gold
	var market = Market.instantiate()
	add_child_autofree(market)
	market.configure(session, "2026-09-05")
	market.show_buy_offers()
	return market


func test_selecting_card_never_buys_or_creates_drag_world() -> void:
	var market = _market()
	for card in market.offer_slots:
		card.pressed.emit()
		assert_eq(market._selected_id, card.offer_id)
		assert_eq(card.find_children("*", "SubViewport", true, false).size(), 0)
	assert_eq(market._session.player.gold, 200000)
	assert_true(market._session.black_market.purchased_offer_ids.is_empty())


func test_failed_purchase_leaves_illustration_and_offer_available() -> void:
	var market = _market(0)
	var card = market.offer_slots[2]
	var texture = card.icon_rect.texture
	card.pressed.emit()
	market.action_button.pressed.emit()
	assert_false(card.disabled)
	assert_same(card.icon_rect.texture, texture)
	assert_false(card.sold_label.visible)
	assert_eq(market._session.player.gold, 0)
	assert_true(market.result_label.visible)


func test_purchased_offer_stays_sold_after_closing_and_reopening() -> void:
	var market = _market()
	var card = market.offer_slots[2]
	card.pressed.emit()
	market.action_button.pressed.emit()
	market.close_offers()
	market.show_buy_offers()
	assert_true(card.disabled)
	assert_true(card.sold_label.visible)


func test_closing_window_is_not_a_transaction() -> void:
	var market = _market()
	watch_signals(market)
	market.close_offers()
	assert_false(market.offer_window.visible)
	assert_eq(market._session.player.gold, 200000)
	assert_signal_not_emitted(market, "state_changed")
	assert_eq(market.find_children("*", "SubViewport", true, false).size(), 0)


func test_pearl_card_buys_original_two_pearl_lot_only_once() -> void:
	var market = _market()
	var card = market.offer_slots[1]
	assert_eq(card.item_id, "black_pearl")
	assert_eq(card.quantity_label.text, "×2")
	card.pressed.emit()
	market.action_button.pressed.emit()
	market._perform_action()
	assert_eq(market._session.player.inventory.count("black_pearl"), 2)
	assert_eq(market._session.player.gold, 193000)


func test_manuscript_card_retains_catalogue_icon_and_original_identity() -> void:
	var market = _market()
	var card = market.offer_slots[0]
	assert_eq(card.item_id, "mastery_attack_speed_book")
	assert_string_contains(card.icon_rect.texture.resource_path, "mastery_attack_speed_book.png")
	card.pressed.emit()
	market.action_button.pressed.emit()
	assert_eq(market._session.player.inventory.count("mastery_attack_speed_book"), 1)
	assert_true(card.disabled)
