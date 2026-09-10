extends SceneTree
## Rendered integration check: real pointer events through App, with an isolated in-memory save.
const App := preload("res://scenes/app/app.tscn")
const NewGame := preload("res://core/game/new_game_service.gd")
const OUTPUT := "res://../output/ui_refresh_20260907/npc_navigation/"
var _failures := 0
var _checks := 0


class MemorySave:
	extends SaveGameService

	func save_session(_session: GameSession) -> Dictionary:
		return {"ok": true, "message": "Navigation fixture only"}


func _init() -> void:
	if not InputMap.has_action("dialogic_default_action"):
		InputMap.add_action("dialogic_default_action")
	_run.call_deferred()


func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1920, 1080)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var app = App.instantiate()
	app._save_service = MemorySave.new()
	viewport.add_child(app)
	var session = NewGame.new().create_session("Aria", 1)
	session.player.gold = 5000
	session.black_market.unlocked = true
	app._current_session = session
	for service_id in ["merchant", "blacksmith", "workshop", "inn"]:
		app._show_city_service(service_id)
		var npc = app.screen_host.get_child(0)
		npc._focus_npc()
		await _settle()
		await _click(npc.open_service_button)
		_check(npc._interaction_state == "service", service_id + " open")
		if service_id == "merchant":
			await _hover(npc.close_service_button)
			await _capture(viewport, "oren_close_hover")
		await _click(npc.close_service_button)
		_check(npc._interaction_state == "focused", service_id + " close")
		await _click(npc.open_service_button)
		await _click(npc.get_node("%BackButton"))
		_check(app.screen_host.get_child(0) is CityHubScreen, service_id + " return to city")
	app._show_guild()
	var guild = app.screen_host.get_child(0)
	guild._focus_guildmaster()
	await _settle()
	await _click(guild.get_node("%OpenBoardButton"))
	_check(guild.board_body.visible, "guild open")
	await _click(guild.get_node("%CloseBoardButton"))
	_check(guild.guild_action_panel.visible, "guild close")
	await _hover(guild.get_node("%BackButton"))
	await _capture(viewport, "guild_back_hover")
	await _click(guild.get_node("%BackButton"))
	_check(app.screen_host.get_child(0) is CityHubScreen, "guild return to city")
	app._show_black_market()
	await _settle()
	var market = app.screen_host.get_child(0)
	await _click(market.sell_tab)
	_check(market.sell_panel.visible, "black market book sales")
	await _click(market.buy_tab)
	_check(not market.sell_panel.visible, "black market display")
	await _hover(market.get_node("%BackButton"))
	await _capture(viewport, "black_market_back_hover")
	await _click(market.get_node("%BackButton"))
	_check(app.screen_host.get_child(0) is CityHubScreen, "black market return to city")
	await _capture(viewport, "returned_to_city")
	app.queue_free()
	await _settle()
	viewport.queue_free()
	await process_frame
	print("NPC POINTER CHECKS: %d / %d passed" % [_checks - _failures, _checks])
	quit(0 if _failures == 0 else 1)


func _hover(button: Button) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = button.get_global_rect().get_center()
	button.get_viewport().push_input(motion, true)
	await _settle()
	_check(button.get_viewport().gui_get_hovered_control() == button, "hover " + button.text)


func _click(button: Button) -> void:
	await _hover(button)
	var viewport := button.get_viewport()
	var press := InputEventMouseButton.new()
	press.position = button.get_global_rect().get_center()
	press.button_index = MOUSE_BUTTON_LEFT
	press.pressed = true
	viewport.push_input(press, true)
	var release := press.duplicate() as InputEventMouseButton
	release.pressed = false
	viewport.push_input(release, true)
	await _settle()


func _settle() -> void:
	for frame in 5:
		await process_frame


func _capture(viewport: SubViewport, name: String) -> void:
	await RenderingServer.frame_post_draw
	_check(
		viewport.get_texture().get_image().save_png(OUTPUT + name + ".png") == OK, "capture " + name
	)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures += 1
		push_error("NPC POINTER FAILURE: " + message)
	else:
		print("PASS: " + message)
