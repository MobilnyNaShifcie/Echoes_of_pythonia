extends SceneTree
## In-memory fixture; never reads or writes the player's save.
const Market = preload("res://ui/screens/black_market/black_market.tscn")
const NewGame = preload("res://core/game/new_game_service.gd")
const Offer = preload("res://core/economy/black_market_offer.gd")
const OUTPUT := "res://../output/counter_rest/"


func _init() -> void:
	if not InputMap.has_action("dialogic_default_action"):
		InputMap.add_action("dialogic_default_action")
	call_deferred("render_preview")


func render_preview() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for group in [
		["grandmaster_elixir", "black_pearl", "spark_of_life", "leviathan_scale"],
		["hearth_core", "azhar_sigil", "mastery_attack_speed_book", "grandmaster_elixir"],
	]:
		var session = NewGame.new().create_session("Aria", 1)
		session.black_market.unlocked = true
		session.black_market.rotation_key = "2026-09-06"
		session.player.gold = 200000
		for i in group.size():
			session.black_market.offers.append(Offer.new("2026-09-06:%d" % i, group[i], 1, 7500))
		var market = Market.instantiate()
		root.add_child(market)
		market.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		market.configure(session, "2026-09-06")
		await create_timer(0.5).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUTPUT + group[0] + ".png")
		market.queue_free()
		await process_frame
	print("COUNTER REST PREVIEW COMPLETE")
	quit()
