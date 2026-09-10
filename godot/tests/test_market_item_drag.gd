extends GutTest

const Market = preload("res://ui/screens/black_market/black_market.tscn")
const NewGame = preload("res://core/game/new_game_service.gd")


func _market(gold: int):
	var session = NewGame.new().create_session("Aria", 1)
	session.black_market.unlocked = true
	session.player.gold = gold
	var market = Market.instantiate()
	add_child_autofree(market)
	market.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
	market.size = Vector2(1920,1080)
	market.configure(session, "2026-09-05")
	return market


func _elixir_slot(market):
	for slot in market.offer_slots:
		if slot.item_id == "grandmaster_elixir":
			return slot
	return null


func test_drag_moves_same_live_world_and_cancel_restores_it() -> void:
	var market = _market(200000)
	await get_tree().process_frame
	var slot = _elixir_slot(market)
	assert_not_null(slot)
	var view = slot.model_view
	var world = view.model
	var visual_size: Vector2 = view.size
	assert_almost_eq(visual_size.x / slot.size.x, 1.5, 0.01, "Elixir is displayed 50 percent larger")
	assert_true(slot._has_point(view.position + Vector2(view.size.x * 0.5, 20)), "The enlarged upper bottle remains grabbable")
	slot._begin_drag_visual(Vector2(70,35))
	assert_false(view.get_parent() == slot, "No copy remains on counter")
	assert_same(slot.model_view, view)
	assert_same(slot.model_view.model, world, "The live 3D world moves unchanged")
	assert_eq(view.size, visual_size, "No miniature drag icon")
	assert_false(world.get_node("ContactShadow").visible)
	var motion := InputEventMouseMotion.new()
	motion.position = Vector2(950,350)
	slot._input(motion)
	slot._process(0.0)
	assert_eq(view.position, motion.position + slot._grab_offset, "Held model follows pointer at original grab point")
	slot.notification(Control.NOTIFICATION_DRAG_END)
	assert_same(view.get_parent(), slot)
	assert_true(view.visible)
	assert_true(world.get_node("ContactShadow").visible)
	assert_eq(market._session.player.gold, 200000, "Cancel never charges")
	await get_tree().process_frame
	var camera: Camera3D = view.viewport_3d.get_camera_3d()
	var foot: Vector2 = view.position + camera.unproject_position(Vector3(0,0.035,0))
	assert_lt(foot.distance_to(slot._counter_anchor), 0.1, "Bottle foot returns to the pad center")


func test_failed_purchase_returns_item_despite_accepted_drop() -> void:
	var market = _market(0)
	var slot = _elixir_slot(market)
	slot._begin_drag_visual(Vector2(70,35))
	market.inventory_drop_target._drop_data(Vector2.ZERO, {"kind":"black_market_offer", "offer_id":slot.offer_id})
	slot.notification(Control.NOTIFICATION_DRAG_END)
	assert_false(slot.disabled)
	assert_true(slot.model_view.visible)
	assert_same(slot.model_view.get_parent(), slot)
	assert_gt(slot.model_view.model.get_child_count(), 0)
	assert_eq(market._session.player.gold, 0)


func test_purchased_held_item_never_reappears_after_drag_end() -> void:
	var market = _market(200000)
	var slot = _elixir_slot(market)
	var offer: String = slot.offer_id
	slot._begin_drag_visual(Vector2(70,35))
	market.inventory_drop_target._drop_data(Vector2.ZERO, {"kind":"black_market_offer", "offer_id":offer})
	slot.notification(Control.NOTIFICATION_DRAG_END)
	assert_true(slot.disabled)
	assert_false(slot.model_view.visible)
	assert_eq(slot.model_view.model.get_child_count(), 0)
	assert_true(offer in market._session.black_market.purchased_offer_ids)


func test_closing_screen_during_drag_frees_overlay_and_world() -> void:
	var market = _market(0)
	var slot = _elixir_slot(market)
	slot._begin_drag_visual(Vector2(70,35))
	var view = slot.model_view
	var layer = slot._drag_layer
	market.queue_free()
	await get_tree().process_frame
	await get_tree().process_frame
	assert_false(is_instance_valid(layer))
	assert_false(is_instance_valid(view))


func test_pearl_uses_elixir_scale_moves_as_live_model_and_returns_to_its_pad() -> void:
	var market = _market(200000)
	await get_tree().process_frame
	var slot = market.offer_slots[1]
	assert_eq(slot.item_id, "black_pearl")
	var view = slot.model_view
	var sign = slot.price_sign
	var dimensions: Vector2 = view.size
	assert_almost_eq(dimensions.x / slot.size.x, 1.5, 0.01)
	assert_true(slot._has_point(view.position + Vector2(dimensions.x*0.3, dimensions.y*0.3)), "The wide gold setting can be grabbed")
	var data = slot._get_drag_data(Vector2(90, 45))
	assert_eq(data.item_id, "black_pearl")
	assert_false(view.get_parent() == slot, "No sphere or icon left on the counter")
	assert_same(sign.get_parent(), slot, "Price sign is not part of the held object")
	assert_lt(view.size.distance_to(dimensions), 0.001, "Same displayed size, allowing only subpixel global-transform rounding")
	assert_false(view.model.get_node("ContactShadow").visible)
	slot.notification(Control.NOTIFICATION_DRAG_END)
	await get_tree().process_frame
	assert_same(view.get_parent(), slot)
	assert_true(view.model.get_node("ContactShadow").visible)
	var camera: Camera3D = view.viewport_3d.get_camera_3d()
	var foot: Vector2 = view.position + camera.unproject_position(Vector3(0, 0.035, 0))
	assert_lt(foot.distance_to(slot._counter_anchor), 0.1)
	assert_eq(market._session.player.gold, 200000)
	market._purchase_offer(slot.offer_id)
	assert_false(view.visible)
	assert_eq(view.model.get_child_count(), 0)
	assert_eq(market._session.player.inventory.count("black_pearl"), 2, "Rotation still sells the original two-pearl lot")


func test_manuscript_uses_same_scale_and_live_drag_without_changing_inventory_item() -> void:
	var market = _market(200000)
	await get_tree().process_frame
	var slot = market.offer_slots[0]
	assert_eq(slot.item_id,"mastery_attack_speed_book")
	var view = slot.model_view
	var world = view.model
	var size_before: Vector2 = view.size
	assert_almost_eq(size_before.x/slot.size.x,1.5,0.01)
	assert_true(slot._has_point(view.position+Vector2(size_before.x*0.3,size_before.y*0.3)))
	assert_string_contains(slot._item_texture.resource_path,"mastery_attack_speed_book.png")
	var data = slot._get_drag_data(Vector2(90,45))
	assert_eq(data.item_id,"mastery_attack_speed_book")
	assert_same(slot.model_view.model,world)
	assert_false(view.get_parent()==slot,"Entire book leaves the counter, no duplicate sprite")
	assert_same(slot.price_sign.get_parent(),slot)
	assert_lt(view.size.distance_to(size_before),0.001)
	assert_false(world.get_node("ContactShadow").visible)
	slot.notification(Control.NOTIFICATION_DRAG_END)
	await get_tree().process_frame
	assert_same(view.get_parent(),slot)
	assert_true(world.get_node("ContactShadow").visible)
	var camera: Camera3D = view.viewport_3d.get_camera_3d()
	assert_lt((view.position+camera.unproject_position(Vector3(0,0.035,0))).distance_to(slot._counter_anchor),0.1)
	assert_eq(market._session.player.gold,200000)
	slot._get_drag_data(Vector2(90,45))
	market.inventory_drop_target._drop_data(Vector2.ZERO,data)
	slot.notification(Control.NOTIFICATION_DRAG_END)
	assert_false(view.visible)
	assert_eq(world.get_child_count(),0)
	assert_eq(market._session.player.inventory.count("mastery_attack_speed_book"),1)
