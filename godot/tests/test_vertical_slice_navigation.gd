extends GutTest

const APP_SCENE := preload("res://scenes/app/app.tscn")
const CharacterMenuScreenClass := preload("res://ui/screens/character_menu/character_menu.gd")
const CharacterSheetScreenClass := preload("res://ui/screens/character_sheet/character_sheet.gd")
const CityHubScreenClass := preload("res://ui/screens/city_hub/city_hub.gd")
const CityEconomyScreenClass := preload("res://ui/screens/city_economy/city_economy.gd")
const ClassSelectionScreenClass := preload("res://ui/screens/class_selection/class_selection.gd")
const CombatScreenClass := preload("res://ui/screens/combat/combat.gd")
const EquipmentScreenClass := preload("res://ui/screens/equipment/equipment.gd")
const GuildScreenClass := preload("res://ui/screens/guild/guild.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const PrologueScreenClass := preload("res://ui/screens/prologue/prologue.gd")
const ProgressionScreenClass := preload("res://ui/screens/progression/progression.gd")
const SkillsScreenClass := preload("res://ui/screens/skills/skills.gd")
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
	app._show_city_service("merchant")
	await get_tree().process_frame
	assert_eq(app.screen_host.get_child(0).get_script(), CityEconomyScreenClass)
	app._show_combat("wolf", "expedition")
	await get_tree().process_frame
	assert_eq(app.screen_host.get_child(0).get_script(), CombatScreenClass)
	assert_eq(app.app_status_label.text, "Walka: Wilk")
	app.free()


func test_combat_floating_hud_and_result_fit_canvas_at_720p() -> void:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_child(host)
	var app = APP_SCENE.instantiate()
	host.add_child(app)
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.prologue_completed = true
	app._on_session_created(session)
	await get_tree().process_frame
	app._show_combat("wolf", "expedition")
	await get_tree().process_frame
	var combat = app.screen_host.get_child(0)
	combat.result_label.text = (
		"Zwycięstwo  •  +14 EXP  •  +10 złota\n" + "Łup: Futro Wilka, Kieł Wilka\nMisja: Wilki 1/2"
	)
	combat.result_panel.visible = true
	await get_tree().process_frame
	var continue_size: Vector2 = combat.continue_button.size
	combat.result_label.text += "\n" + "Dodatkowy wpis do raportu zwycięstwa.\n".repeat(3)
	await get_tree().process_frame
	var canvas: Rect2 = app.screen_host.get_global_rect()

	assert_gte(
		combat.encounter_label.get_global_rect().position.y,
		canvas.position.y,
	)
	assert_lte(
		combat.result_panel.get_global_rect().end.y,
		canvas.end.y,
	)
	assert_eq(combat.continue_button.size, continue_size)
	host.free()


func test_economy_overlays_fit_canvas_at_720p() -> void:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_child(host)
	var app = APP_SCENE.instantiate()
	host.add_child(app)
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.prologue_completed = true
	app._on_session_created(session)
	app._show_city_service("merchant")
	await get_tree().process_frame
	var economy = app.screen_host.get_child(0)
	var canvas: Rect2 = app.screen_host.get_global_rect()

	assert_gte(
		economy.title_label.get_global_rect().position.y,
		canvas.position.y,
	)
	assert_lte(
		economy.status_label.get_global_rect().end.y,
		canvas.end.y,
	)
	assert_lte(
		economy.get_global_rect().end.x,
		app.screen_host.get_global_rect().end.x,
	)
	host.free()


func test_world_map_fills_canvas_with_art_and_overlay_layers() -> void:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_child(host)
	var app = APP_SCENE.instantiate()
	host.add_child(app)
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.prologue_completed = true
	app._on_session_created(session)
	app._show_world_map()
	await get_tree().process_frame
	var world_map = app.screen_host.get_child(0)
	var canvas: Rect2 = app.screen_host.get_global_rect()

	assert_gte(
		world_map.title_label.get_global_rect().position.y,
		canvas.position.y,
	)
	assert_lte(
		world_map.get_global_rect().end.y,
		canvas.end.y,
	)
	assert_eq(world_map.get_node("Page/Body").get_child_count(), 2)
	assert_false(world_map.threats_label.is_visible_in_tree())
	assert_false(world_map.weather_label.is_visible_in_tree())
	host.free()


func test_character_progression_screens_fit_at_720p() -> void:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_child(host)
	var app = APP_SCENE.instantiate()
	host.add_child(app)
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.prologue_completed = true
	session.player.unspent_attribute_points = 4
	app._on_session_created(session)
	await get_tree().process_frame

	var canvas: Rect2 = app.screen_host.get_global_rect()
	app._show_character_sheet()
	await get_tree().process_frame
	var character_menu = app.screen_host.get_child(0)
	assert_eq(character_menu.get_script(), CharacterMenuScreenClass)
	assert_eq(character_menu.active_section(), CharacterMenuScreenClass.SECTION_CHARACTER)
	var sheet = character_menu.view_for_section(CharacterMenuScreenClass.SECTION_CHARACTER)
	assert_eq(sheet.get_script(), CharacterSheetScreenClass)
	assert_lte(
		character_menu.get_global_rect().end.y,
		canvas.end.y,
	)

	app._show_equipment()
	await get_tree().process_frame
	character_menu = app.screen_host.get_child(0)
	assert_eq(character_menu.get_script(), CharacterMenuScreenClass)
	assert_eq(character_menu.active_section(), CharacterMenuScreenClass.SECTION_EQUIPMENT)
	var equipment = character_menu.view_for_section(CharacterMenuScreenClass.SECTION_EQUIPMENT)
	assert_eq(equipment.get_script(), EquipmentScreenClass)
	assert_lte(
		character_menu.get_global_rect().end.y,
		canvas.end.y,
	)

	app._show_class_selection()
	await get_tree().process_frame
	var class_selection = app.screen_host.get_child(0)
	assert_eq(class_selection.get_script(), ClassSelectionScreenClass)
	assert_lte(
		class_selection.get_node("Page/MainStage").get_global_rect().end.y,
		canvas.end.y,
	)

	app._show_skills()
	await get_tree().process_frame
	character_menu = app.screen_host.get_child(0)
	assert_eq(character_menu.active_section(), CharacterMenuScreenClass.SECTION_SKILLS)
	var skills = character_menu.view_for_section(CharacterMenuScreenClass.SECTION_SKILLS)
	assert_eq(skills.get_script(), SkillsScreenClass)
	assert_lte(
		character_menu.get_global_rect().end.y,
		canvas.end.y,
	)

	app._show_progression()
	await get_tree().process_frame
	character_menu = app.screen_host.get_child(0)
	assert_eq(character_menu.active_section(), CharacterMenuScreenClass.SECTION_PROGRESSION)
	var progression = character_menu.view_for_section(CharacterMenuScreenClass.SECTION_PROGRESSION)
	assert_eq(progression.get_script(), ProgressionScreenClass)
	assert_lte(
		character_menu.get_global_rect().end.y,
		canvas.end.y,
	)
	host.free()
