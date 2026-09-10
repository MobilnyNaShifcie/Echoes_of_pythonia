extends SceneTree
## Standalone market only: no app/save service, no save-file access.

func _init():
	if not InputMap.has_action("dialogic_default_action"):
		InputMap.add_action("dialogic_default_action")
	call_deferred("render_preview")

func render_preview():
	var session = load("res://core/game/new_game_service.gd").new().create_session("Aria", 1)
	session.black_market.unlocked = true
	session.player.gold = 200000
	var market = load("res://ui/screens/black_market/black_market.tscn").instantiate()
	root.add_child(market)
	market.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	market.configure(session, "2026-09-05")
	await create_timer(1).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../output/market_elixir_centered.png")
	var slot = market.offer_slots[2]
	var motion := InputEventMouseMotion.new()
	motion.position = slot.global_position + Vector2(90,40)
	root.push_input(motion)
	var data = slot._get_drag_data(Vector2(90,40))
	slot.force_drag(data, null)
	motion = InputEventMouseMotion.new()
	motion.position = Vector2(1200,430)
	root.push_input(motion)
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://../output/market_elixir_held.png")
	print("Native drag active: ", root.gui_is_dragging())
	# Release onto empty space: native DRAG_END must put the same instance back.
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.position = Vector2(1200,430)
	release.pressed = false
	root.push_input(release)
	await create_timer(0.3).timeout
	print("Returned to source: ", slot.model_view.get_parent() == slot, "; visible: ", slot.model_view.visible)
	quit()
