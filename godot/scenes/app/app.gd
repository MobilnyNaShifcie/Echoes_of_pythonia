extends Control

const GameSessionClass := preload("res://core/game/game_session.gd")
const CharacterSheetScreenClass := preload("res://ui/screens/character_sheet/character_sheet.gd")
const EquipmentScreenClass := preload("res://ui/screens/equipment/equipment.gd")
const MainMenuScreenClass := preload("res://ui/screens/main_menu/main_menu.gd")
const NewGameScreenClass := preload("res://ui/screens/new_game/new_game.gd")
const SessionReadyScreenClass := preload("res://ui/screens/session_ready/session_ready.gd")
const CHARACTER_SHEET_SCENE := preload("res://ui/screens/character_sheet/character_sheet.tscn")
const EQUIPMENT_SCENE := preload("res://ui/screens/equipment/equipment.tscn")
const MAIN_MENU_SCENE := preload("res://ui/screens/main_menu/main_menu.tscn")
const NEW_GAME_SCENE := preload("res://ui/screens/new_game/new_game.tscn")
const SESSION_READY_SCENE := preload("res://ui/screens/session_ready/session_ready.tscn")

var _current_session: GameSessionClass

@onready var screen_host: Control = %ScreenHost
@onready var app_status_label: Label = %AppStatusLabel


func _ready() -> void:
	_show_main_menu()


func _show_main_menu() -> void:
	var menu: MainMenuScreenClass = _replace_screen(MAIN_MENU_SCENE)
	menu.configure(_current_session != null)
	menu.continue_requested.connect(_show_session_ready)
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
	_show_session_ready()


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
	character_sheet.back_requested.connect(_show_session_ready)
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


func _show_project_status() -> void:
	app_status_label.text = "v0.25.0: bohater, statystyki i zarządzanie ekwipunkiem w Godot 4"


func _replace_screen(scene: PackedScene) -> Control:
	for child in screen_host.get_children():
		screen_host.remove_child(child)
		child.queue_free()
	var screen := scene.instantiate() as Control
	screen_host.add_child(screen)
	return screen
