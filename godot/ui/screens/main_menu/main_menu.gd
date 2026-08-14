class_name MainMenuScreen
extends Control

signal continue_requested
signal new_game_requested
signal load_requested
signal save_requested
signal project_status_requested
signal exit_requested

var _has_active_session := false
var _has_saved_session := false

@onready var continue_button: Button = %ContinueButton
@onready var load_button: Button = %LoadButton
@onready var save_button: Button = %SaveButton


func _ready() -> void:
	%ContinueButton.pressed.connect(continue_requested.emit)
	%NewGameButton.pressed.connect(new_game_requested.emit)
	%LoadButton.pressed.connect(load_requested.emit)
	%SaveButton.pressed.connect(save_requested.emit)
	%ProjectStatusButton.pressed.connect(project_status_requested.emit)
	%ExitButton.pressed.connect(exit_requested.emit)
	_update_availability()
	%NewGameButton.grab_focus()


func configure(has_active_session: bool, has_saved_session := false) -> void:
	_has_active_session = has_active_session
	_has_saved_session = has_saved_session
	if is_node_ready():
		_update_availability()


func _update_availability() -> void:
	continue_button.disabled = not _has_active_session
	load_button.disabled = not _has_saved_session
	save_button.disabled = not _has_active_session
