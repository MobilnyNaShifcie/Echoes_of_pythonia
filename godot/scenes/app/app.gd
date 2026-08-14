extends Control

const GameSessionClass := preload("res://core/game/game_session.gd")
const CharacterSheetScreenClass := preload("res://ui/screens/character_sheet/character_sheet.gd")
const CityHubScreenClass := preload("res://ui/screens/city_hub/city_hub.gd")
const CityServiceScreenClass := preload("res://ui/screens/city_service/city_service.gd")
const ClassSelectionScreenClass := preload("res://ui/screens/class_selection/class_selection.gd")
const CombatScreenClass := preload("res://ui/screens/combat/combat.gd")
const EquipmentScreenClass := preload("res://ui/screens/equipment/equipment.gd")
const GuildScreenClass := preload("res://ui/screens/guild/guild.gd")
const MainMenuScreenClass := preload("res://ui/screens/main_menu/main_menu.gd")
const NewGameScreenClass := preload("res://ui/screens/new_game/new_game.gd")
const PrologueScreenClass := preload("res://ui/screens/prologue/prologue.gd")
const SessionReadyScreenClass := preload("res://ui/screens/session_ready/session_ready.gd")
const WorldMapScreenClass := preload("res://ui/screens/world_map/world_map.gd")
const CHARACTER_SHEET_SCENE := preload("res://ui/screens/character_sheet/character_sheet.tscn")
const CITY_HUB_SCENE := preload("res://ui/screens/city_hub/city_hub.tscn")
const CITY_SERVICE_SCENE := preload("res://ui/screens/city_service/city_service.tscn")
const CLASS_SELECTION_SCENE := preload("res://ui/screens/class_selection/class_selection.tscn")
const COMBAT_SCENE := preload("res://ui/screens/combat/combat.tscn")
const EQUIPMENT_SCENE := preload("res://ui/screens/equipment/equipment.tscn")
const GUILD_SCENE := preload("res://ui/screens/guild/guild.tscn")
const MAIN_MENU_SCENE := preload("res://ui/screens/main_menu/main_menu.tscn")
const NEW_GAME_SCENE := preload("res://ui/screens/new_game/new_game.tscn")
const PROLOGUE_SCENE := preload("res://ui/screens/prologue/prologue.tscn")
const SESSION_READY_SCENE := preload("res://ui/screens/session_ready/session_ready.tscn")
const WORLD_MAP_SCENE := preload("res://ui/screens/world_map/world_map.tscn")

var _current_session: GameSessionClass

@onready var screen_host: Control = %ScreenHost
@onready var app_status_label: Label = %AppStatusLabel


func _ready() -> void:
	_show_main_menu()


func _show_main_menu() -> void:
	var menu: MainMenuScreenClass = _replace_screen(MAIN_MENU_SCENE)
	menu.configure(_current_session != null)
	menu.continue_requested.connect(_continue_session)
	menu.new_game_requested.connect(_show_new_game)
	menu.project_status_requested.connect(_show_project_status)
	menu.exit_requested.connect(get_tree().quit)
	app_status_label.text = "Gotowe"


func _show_new_game() -> void:
	var new_game: NewGameScreenClass = _replace_screen(NEW_GAME_SCENE)
	new_game.canceled.connect(_show_main_menu)
	new_game.session_created.connect(_on_session_created)
	app_status_label.text = "Tworzenie nowej gry"


func _on_session_created(session: GameSessionClass) -> void:
	_current_session = session
	app_status_label.text = "Aktywna sesja: %s" % session.player.display_name
	_continue_session()


func _continue_session() -> void:
	if _current_session == null:
		_show_main_menu()
	elif _current_session.prologue_completed:
		_show_city_hub()
	else:
		_show_prologue()


func _show_prologue() -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var prologue: PrologueScreenClass = _replace_screen(PROLOGUE_SCENE)
	prologue.configure(_current_session)
	prologue.tutorial_battle_requested.connect(_show_combat.bind("prologue_scarecrow", "prologue"))
	prologue.prologue_completed.connect(_show_city_hub)
	app_status_label.text = "Prolog: Droga do Varenhold"


func _show_city_hub() -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var hub: CityHubScreenClass = _replace_screen(CITY_HUB_SCENE)
	hub.world_map_requested.connect(_show_world_map)
	hub.guild_requested.connect(_show_guild)
	hub.hero_requested.connect(_show_character_sheet)
	hub.classes_requested.connect(_show_class_selection)
	hub.service_requested.connect(_show_city_service)
	hub.main_menu_requested.connect(_show_main_menu)
	hub.configure(_current_session)
	app_status_label.text = "Varenhold: %s" % _current_session.player.display_name


func _show_session_ready() -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var ready_screen: SessionReadyScreenClass = _replace_screen(SESSION_READY_SCENE)
	ready_screen.configure(_current_session)
	ready_screen.back_to_menu_requested.connect(_show_main_menu)
	ready_screen.character_sheet_requested.connect(_show_character_sheet)
	app_status_label.text = "Aktywna sesja: %s" % _current_session.player.display_name


func _show_character_sheet() -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var character_sheet: CharacterSheetScreenClass = _replace_screen(CHARACTER_SHEET_SCENE)
	character_sheet.configure(_current_session)
	character_sheet.back_requested.connect(_show_city_hub)
	character_sheet.equipment_requested.connect(_show_equipment)
	app_status_label.text = "Karta postaci: %s" % _current_session.player.display_name


func _show_equipment() -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var equipment_screen: EquipmentScreenClass = _replace_screen(EQUIPMENT_SCENE)
	equipment_screen.configure(_current_session)
	equipment_screen.back_requested.connect(_show_character_sheet)
	app_status_label.text = "Ekwipunek: %s" % _current_session.player.display_name


func _show_guild() -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var guild: GuildScreenClass = _replace_screen(GUILD_SCENE)
	guild.configure(_current_session)
	guild.back_requested.connect(_show_city_hub)
	app_status_label.text = "Gildia Poszukiwaczy: ranga F"


func _show_class_selection() -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var class_screen: ClassSelectionScreenClass = _replace_screen(CLASS_SELECTION_SCENE)
	class_screen.configure(_current_session)
	class_screen.back_requested.connect(_show_city_hub)
	class_screen.class_chosen.connect(_show_city_hub)
	app_status_label.text = "Drogi bohatera: od poziomu 5"


func _show_city_service(service_id: String) -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var service: CityServiceScreenClass = _replace_screen(CITY_SERVICE_SCENE)
	service.configure(_current_session, service_id)
	service.back_requested.connect(_show_city_hub)
	service.world_map_requested.connect(_show_world_map)
	app_status_label.text = "Varenhold: %s" % service_id


func _show_world_map() -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var world_map: WorldMapScreenClass = _replace_screen(WORLD_MAP_SCENE)
	world_map.configure(_current_session)
	world_map.back_requested.connect(_show_city_hub)
	world_map.encounter_requested.connect(_show_expedition_combat)
	app_status_label.text = "Wyprawa: Zmierzchowe Równiny"


func _show_expedition_combat(enemy_id: String) -> void:
	_show_combat(enemy_id, "expedition")


func _show_combat(enemy_id: String, context: String) -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var combat: CombatScreenClass = _replace_screen(COMBAT_SCENE)
	combat.configure(_current_session, enemy_id, context)
	combat.finished.connect(_on_combat_finished)
	app_status_label.text = "Walka: %s" % enemy_id


func _on_combat_finished(context: String, result: String) -> void:
	if context == "prologue":
		_show_prologue()
	elif result == "defeat":
		_show_city_hub()
	else:
		_show_world_map()


func _show_project_status() -> void:
	app_status_label.text = (
		"v0.25.0: prolog, Varenhold, misja fabularna, " + "Równiny i walka turowa w Godot 4"
	)


func _replace_screen(scene: PackedScene) -> Control:
	for child in screen_host.get_children():
		screen_host.remove_child(child)
		child.queue_free()
	var screen := scene.instantiate() as Control
	screen_host.add_child(screen)
	return screen
