extends SceneTree
## Isolated render fixtures; no real save is loaded or written.
const App := preload("res://scenes/app/app.tscn")
const NewGame := preload("res://core/game/new_game_service.gd")
const Achievements := preload("res://core/progression/achievement_service.gd")
const OUTPUT := "res://../output/ui_refresh_20260907/previews/"


class MemorySave:
	extends SaveGameService

	func save_session(_session: GameSession) -> Dictionary:
		return {"ok": true, "message": "Preview only"}


func _init() -> void:
	if not InputMap.has_action("dialogic_default_action"):
		InputMap.add_action("dialogic_default_action")
	call_deferred("_render")


func _render() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1080)]:
		var viewport := SubViewport.new()
		viewport.size = dimensions
		var factor := minf(float(dimensions.x) / 1920.0, float(dimensions.y) / 1080.0)
		viewport.size_2d_override = Vector2i(Vector2(dimensions) / factor)
		viewport.size_2d_override_stretch = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var app = App.instantiate()
		app._save_service = MemorySave.new()
		viewport.add_child(app)
		var session = NewGame.new().create_session("Aria", 1, null, "female")
		while session.player.level < 12:
			session.player.gain_experience(session.player.experience_remaining_to_next_level())
		session.player.choose_class("mage")
		session.player.spend_attribute_points("intelligence", 24)
		session.player.spend_attribute_points("vitality", 12)
		session.player.spend_attribute_points("endurance", 12)
		session.player.gold = 5000
		session.player.stats.current_hp = 30
		session.black_market.unlocked = true
		Achievements.record_victory(session, "wolf", "sunny")
		session.player.inventory.add("strong_healing_potion", 3)
		app._current_session = session
		app._show_city_hub()
		await _capture(viewport, "city_closed", dimensions)
		var city = app.screen_host.get_child(0)
		city.navigation_drawer.pinned = true
		city.navigation_drawer.set_open(true, true)
		await _capture(viewport, "city_open", dimensions)
		for service_id in ["merchant", "blacksmith", "workshop", "inn"]:
			app._show_city_service(service_id)
			var npc = app.screen_host.get_child(0)
			await _capture(viewport, service_id + "_ambient", dimensions)
			npc._open_service()
			await _capture(viewport, service_id + "_service", dimensions)
		app._show_guild()
		await _capture(viewport, "guild_ambient", dimensions)
		app.screen_host.get_child(0).show_story_board()
		await _capture(viewport, "guild_board", dimensions)
		app._show_achievements()
		await _capture(viewport, "achievements", dimensions)
		app._show_skills()
		await _capture(viewport, "skills", dimensions)
		app._show_black_market()
		await _capture(viewport, "black_market", dimensions)
		session.player.stats.restore_full()
		for enemy_id in ["wolf", "ice_crab", "plains_spirit"]:
			app._show_combat(enemy_id, "expedition")
			var combat = app.screen_host.get_child(0)
			combat.set_reduced_motion(true)
			await _capture(viewport, "combat_" + enemy_id, dimensions)
			combat.get_node("Page/Lower").drawer.pinned = true
			combat.get_node("Page/Lower").drawer.set_open(true, true)
			await _capture(viewport, "combat_open_" + enemy_id, dimensions)
		app.free()
		viewport.queue_free()
		await process_frame
	print("UI REFRESH PREVIEWS COMPLETE")
	quit()


func _capture(viewport: SubViewport, stage: String, dimensions: Vector2i) -> void:
	for frame in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := OUTPUT + "%s_%dx%d.png" % [stage, dimensions.x, dimensions.y]
	var error := viewport.get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Preview save failed: %s" % error)
		quit(1)
	print("CAPTURE ", path)
