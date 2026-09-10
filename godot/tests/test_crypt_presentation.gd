extends GutTest

const App = preload("res://scenes/app/app.tscn")
const Combat = preload("res://ui/screens/combat/combat.tscn")
const Dungeon = preload("res://ui/screens/dungeon/dungeon.tscn")
const NewGame = preload("res://core/game/new_game_service.gd")
const RunState = preload("res://core/dungeons/dungeon_run_state.gd")
const Art = preload("res://ui/presentation/dungeon_presentation_catalog.gd")
const Presentation = preload("res://ui/presentation/combat_presentation_catalog.gd")
const Visual = preload("res://ui/components/combatant_visual/combatant_visual.gd")
const CRYPT := "sunken_order_crypt"
const BACKGROUND := (
	"res://assets/combat/backgrounds/dungeons/" + "sunken_order_crypt/sunken_vestibule.png"
)


func test_crypt_art_is_explicit_and_never_replaces_other_contexts() -> void:
	var texture := Art.background_texture(CRYPT)
	assert_not_null(texture)
	assert_eq(texture.resource_path, BACKGROUND)
	for period: String in ["day", "night"]:
		assert_eq(
			Presentation.battlefield_texture("silentwater_marshes", period, "dungeon", CRYPT),
			texture
		)
		assert_ne(
			Presentation.battlefield_texture("silentwater_marshes", period, "expedition", CRYPT),
			texture
		)
	assert_null(Art.background_texture("black_fleet_wreck"))
	assert_null(Art.background_texture("unknown"))
	assert_null(Presentation.battlefield_texture("silentwater_marshes", "day", "dungeon"))
	assert_null(Presentation.battlefield_texture("silentwater_marshes", "day", "prologue", CRYPT))


func test_crypt_battle_uses_art_without_applying_surface_weather() -> void:
	for enemy_id: String in ["drowned_dead", "sunken_knight"]:
		for hour: int in [8, 22]:
			var session = NewGame.new().create_session("Art QA", 1)
			session.current_location_id = "silentwater_marshes"
			session.hour = hour
			var screen = Combat.instantiate()
			screen.configure(session, enemy_id, "dungeon", "rain", null, "Przedsionek", "", CRYPT)
			add_child(screen)
			assert_eq(screen.battlefield_texture.texture, Art.background_texture(CRYPT))
			assert_true(screen.battlefield_texture.visible)
			assert_false(screen.battlefield_placeholder.visible)
			assert_eq(screen.enemy_visual.mode(), Visual.Mode.STATIC_TEXTURE)
			assert_true(screen._enemy.weather_note.is_empty())
			assert_false(screen._uses_surface_weather())
			assert_false(screen.attack_button.disabled)
			screen.free()


func test_reconfiguration_cannot_leave_stale_crypt_art() -> void:
	var session = NewGame.new().create_session("Art QA", 1)
	session.current_location_id = "silentwater_marshes"
	var screen = Combat.instantiate()
	add_child(screen)
	screen.configure(session, "sunken_knight", "dungeon", "sunny", null, "", "", CRYPT)
	assert_eq(screen.battlefield_texture.texture, Art.background_texture(CRYPT))
	screen.configure(session, "sunken_knight", "expedition")
	assert_eq(screen._dungeon_id, "")
	assert_eq(
		screen.battlefield_texture.texture,
		Presentation.battlefield_texture("silentwater_marshes", "day", "expedition")
	)
	screen.configure(
		session, "cursed_sailor", "dungeon", "sunny", null, "", "", "black_fleet_wreck"
	)
	assert_null(screen.battlefield_texture.texture)
	assert_true(screen.battlefield_placeholder.visible)
	screen.free()


func test_dungeon_background_and_controls_fit_all_target_sizes() -> void:
	for dimensions: Vector2 in [Vector2(1280, 720), Vector2(1920, 1080), Vector2(2560, 1080)]:
		var host := Control.new()
		host.size = dimensions
		add_child(host)
		var screen = Dungeon.instantiate()
		screen.configure(NewGame.new().create_session("Art QA", 1), CRYPT, RunState.new(CRYPT))
		host.add_child(screen)
		await get_tree().process_frame
		await get_tree().process_frame
		assert_eq(screen.background_texture.texture, Art.background_texture(CRYPT))
		assert_eq(screen.background_texture.get_global_rect(), screen.get_global_rect())
		assert_eq(screen.background_texture.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_COVERED)
		assert_eq(screen.background_texture.mouse_filter, Control.MOUSE_FILTER_IGNORE)
		assert_gt(screen.get_node("Page/ArtSpace").size.y, 150.0)
		assert_lte(
			screen.get_node("Page/RulesPanel").get_global_rect().end.y,
			screen.get_global_rect().end.y
		)
		for button: Button in screen.actions.get_children():
			assert_true(screen.get_global_rect().encloses(button.get_global_rect()))
			assert_gte(button.size.y, 46.0)
		host.free()


func test_fighter_silhouettes_stay_below_compact_resource_panels_on_small_canvases() -> void:
	for dimensions: Vector2 in [Vector2(1280, 720), Vector2(1920, 1080), Vector2(2560, 1080)]:
		var host := Control.new()
		host.size = dimensions
		add_child(host)
		var session = NewGame.new().create_session("Art QA", 1)
		session.player.level = 8
		session.player.choose_class("mage")
		var screen = Combat.instantiate()
		screen.configure(session, "sunken_knight", "dungeon", "sunny", null, "", "", CRYPT)
		host.add_child(screen)
		await get_tree().process_frame
		await get_tree().process_frame
		var arena: Control = screen.get_node("Page/Arena")
		for pair: Array in [
			[screen.player_visual, "PlayerPanel"], [screen.enemy_visual, "EnemyPanel"]
		]:
			var actor_rect: Rect2 = pair[0].static_texture.get_global_rect()
			var panel: Control = arena.get_node(pair[1])
			assert_true(arena.get_global_rect().encloses(actor_rect))
			assert_gte(actor_rect.position.y, panel.get_global_rect().end.y)
			assert_gt(actor_rect.size.y, 40.0)
		host.free()


func test_long_finished_loot_scrolls_instead_of_hiding_actions() -> void:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_child(host)
	var run = RunState.new(CRYPT)
	run.outcome = "completed"
	for index in 40:
		run.last_loot.append({"item_id": "order_seal", "quantity": index + 1})
	var screen = Dungeon.instantiate()
	screen.configure(NewGame.new().create_session("Art QA", 1), CRYPT, run)
	host.add_child(screen)
	await get_tree().process_frame
	await get_tree().process_frame
	var scroll: ScrollContainer = screen.get_node("Page/Body/NarrativePanel/NarrativeScroll")
	assert_gt(scroll.get_v_scroll_bar().max_value, scroll.size.y)
	assert_true(screen.get_global_rect().encloses(screen.actions.get_child(0).get_global_rect()))
	host.free()


func test_real_app_routes_crypt_identity_through_combat_and_back() -> void:
	var app = App.instantiate()
	add_child(app)
	var session = NewGame.new().create_session("Art QA", 1)
	session.player.inventory.add("ancient_order_key")
	app._current_session = session
	app._show_dungeon(CRYPT)
	await get_tree().process_frame
	assert_eq(
		app.screen_host.get_child(0).background_texture.texture, Art.background_texture(CRYPT)
	)
	app.screen_host.get_child(0).actions.get_child(0).pressed.emit()
	await get_tree().process_frame
	assert_eq(app._active_dungeon_run.step, "room_one")
	assert_eq(session.player.inventory.count("ancient_order_key"), 0)
	app.screen_host.get_child(0).actions.get_child(0).pressed.emit()
	await get_tree().process_frame
	var combat = app.screen_host.get_child(0)
	assert_eq(combat._dungeon_id, CRYPT)
	assert_eq(combat.battlefield_texture.texture, Art.background_texture(CRYPT))
	assert_false(combat.battlefield_placeholder.visible)
	app._on_dungeon_combat_finished("victory")
	await get_tree().process_frame
	assert_eq(app._active_dungeon_run.step, "pause_after_room_one")
	assert_eq(
		app.screen_host.get_child(0).background_texture.texture, Art.background_texture(CRYPT)
	)
	app.free()
