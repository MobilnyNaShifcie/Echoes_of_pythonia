extends GutTest
## Standalone screen fixtures; deliberately no application or disk save service.

const Market := preload("res://ui/screens/black_market/black_market.tscn")
const NewGame := preload("res://core/game/new_game_service.gd")


func _market(gold := 200000):
	var session = NewGame.new().create_session("Aria", 1)
	session.black_market.unlocked = true
	session.player.gold = gold
	var market = Market.instantiate()
	add_child_autofree(market)
	market.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	market.size = Vector2(1920, 1080)
	market.configure(session, "2026-09-05")
	return market


func test_price_boards_hang_from_front_lip_at_multiple_aspect_ratios() -> void:
	var market = _market()
	for screen_size in [Vector2(1920, 1080), Vector2(1600, 900), Vector2(1280, 800), Vector2(2560, 1080)]:
		market.size = screen_size
		await get_tree().process_frame
		market._layout_offer_slots()
		var factor: float = maxf(screen_size.x / market.SOURCE_ART_SIZE.x, screen_size.y / market.SOURCE_ART_SIZE.y)
		var origin: Vector2 = (screen_size - market.SOURCE_ART_SIZE * factor) * 0.5
		for index in market.offer_slots.size():
			var slot = market.offer_slots[index]
			var sign = slot.price_sign
			var mount: Vector2 = sign.get_global_transform_with_canvas() * sign.camera.unproject_position(Vector3.ZERO)
			var expected: Vector2 = origin + market.SOURCE_PRICE_ANCHORS[index] * factor
			assert_lt(mount.distance_to(expected), 0.1, "Rope mounts stay attached to the artwork at every aspect")
			assert_gt(mount.y, origin.y + market.SOURCE_PAD_CENTERS[index].y * factor, "Mounts are on the front lip, beyond the display mat")
			var board: Node3D = sign.stand.get_node("HangingBoard")
			var board_center: Vector2 = sign.get_global_transform_with_canvas() * sign.camera.unproject_position(board.global_position)
			assert_gt(board_center.y,mount.y+20*factor,"The board visibly hangs below its two cords")
			for part in ["LeftCord","RightCord","LeftEyelet","RightEyelet","LeftMount","RightMount"]:
				assert_true(sign.stand.get_node(part) is MeshInstance3D)
			assert_null(sign.stand.get_node_or_null("Foot"),"No tabletop pedestal left behind")
			assert_null(sign.stand.get_node_or_null("ContactShadow"),"No horizontal sign shadow on the mat")
			assert_true(sign.price_text is Label3D,"Price is written on the hanging board itself")
			assert_lt(sign.get_index(), slot.model_view.get_index(), "Item occludes sign, not the reverse")
			assert_almost_eq(sign.scale.x,sign.scale.y,0.0001,"Sign and cords keep natural proportions")


func test_price_matches_negotiated_offer_and_sold_state() -> void:
	var market = _market()
	var slot = market.offer_slots[2]
	market._session.black_market.buy_negotiated_prices[slot.offer_id] = 6000
	market._render()
	market._select_offer(slot.offer_id)
	assert_eq(slot.price_sign.price_text.text, "6 000 zł")
	assert_string_contains(market.price_label.text, "6 000")
	market._purchase_offer(slot.offer_id)
	assert_eq(slot.price_sign.price_text.text, "SPRZEDANE")
	assert_true(slot.price_sign.visible)
	assert_false(slot.model_view.visible)
	assert_eq(market._session.player.gold, 194000)


func test_sign_stays_on_counter_during_drag_and_empty_slot_hides_it() -> void:
	var market = _market()
	await get_tree().process_frame
	var slot = market.offer_slots[2]
	var sign = slot.price_sign
	var before: Rect2 = sign.get_global_rect()
	slot._begin_drag_visual(Vector2(70, 35))
	assert_same(sign.get_parent(), slot)
	assert_eq(sign.get_global_rect(), before)
	assert_true(sign.visible)
	slot.notification(Control.NOTIFICATION_DRAG_END)
	slot.clear_offer()
	assert_false(sign.visible)


func test_idle_instruction_removed_but_transaction_feedback_preserved() -> void:
	var market = _market(0)
	assert_null(market.get_node_or_null("ResultPanel"), "No bottom instruction panel")
	assert_eq(market.result_label.text, "")
	assert_false(market.result_label.visible)
	market._purchase_offer(market.offer_slots[0].offer_id)
	assert_true(market.result_label.visible, "Insufficient funds must still be explained")
	assert_false(market.result_label.text.is_empty())
	assert_true(market.get_node("DetailPanel").is_ancestor_of(market.result_label))
	market.show_book_sales()
	assert_false(market.offer_layer.visible)
	assert_false(market.result_label.visible)
	market.show_buy_offers()
	assert_true(market.offer_layer.visible)
