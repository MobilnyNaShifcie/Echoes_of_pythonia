extends GutTest

const APP_SCENE := preload("res://scenes/app/app.tscn")
const CityHubScreenClass := preload("res://ui/screens/city_hub/city_hub.gd")
const CombatScreenClass := preload("res://ui/screens/combat/combat.gd")
const GuildScreenClass := preload("res://ui/screens/guild/guild.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const PrologueScreenClass := preload("res://ui/screens/prologue/prologue.gd")
const WorldMapScreenClass := preload("res://ui/screens/world_map/world_map.gd")


func test_new_session_starts_prologue_and_completed_prologue_opens_city() -> void:
	var app = APP_SCENE.instantiate()
	add_child(app)
	var session = NewGameServiceClass.new().create_session("Aria", 1)

	app._on_session_created(session)
	await get_tree().process_frame
	assert_eq(app.screen_host.get_child(0).get_script(), PrologueScreenClass)

	session.prologue_completed = true
	app._continue_session()
	await get_tree().process_frame
	assert_eq(app.screen_host.get_child(0).get_script(), CityHubScreenClass)
	app.free()


func test_city_routes_to_guild_map_and_real_combat_screen() -> void:
	var app = APP_SCENE.instantiate()
	add_child(app)
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.prologue_completed = true
	app._on_session_created(session)
	await get_tree().process_frame

	app._show_guild()
	await get_tree().process_frame
	assert_eq(app.screen_host.get_child(0).get_script(), GuildScreenClass)
	app._show_world_map()
	await get_tree().process_frame
	assert_eq(app.screen_host.get_child(0).get_script(), WorldMapScreenClass)
	app._show_combat("wolf", "expedition")
	await get_tree().process_frame
	assert_eq(app.screen_host.get_child(0).get_script(), CombatScreenClass)
	app.free()
