class_name MainMenuScreen
extends Control

signal continue_requested
signal new_game_requested
signal load_requested
signal save_requested
signal fullscreen_requested
signal project_status_requested
signal exit_requested

const InterfaceStyle := preload("res://ui/presentation/interface_style.gd")

var _has_active_session := false
var _has_saved_session := false
var _feedback_tween: Tween

@onready var continue_button: Button = %ContinueButton
@onready var load_button: Button = %LoadButton
@onready var save_button: Button = %SaveButton
@onready var display_mode_button: Button = %DisplayModeButton
@onready var save_feedback: Label = %SaveFeedback


func _ready() -> void:
	for child in get_node("MenuPanel/Margin/Menu").get_children():
		if child is Button:
			InterfaceStyle.button_feedback(child)
	%ContinueButton.pressed.connect(continue_requested.emit)
	%NewGameButton.pressed.connect(new_game_requested.emit)
	%LoadButton.pressed.connect(load_requested.emit)
	%SaveButton.pressed.connect(save_requested.emit)
	%DisplayModeButton.pressed.connect(fullscreen_requested.emit)
	%ProjectStatusButton.pressed.connect(project_status_requested.emit)
	%ExitButton.pressed.connect(exit_requested.emit)
	_update_availability()
	%NewGameButton.grab_focus()


func configure(has_active_session: bool, has_saved_session := false) -> void:
	_has_active_session = has_active_session
	_has_saved_session = has_saved_session
	if is_node_ready():
		_update_availability()


func set_display_mode(fullscreen: bool, unavailable_message := "") -> void:
	display_mode_button.text = "Tryb okienkowy" if fullscreen else "Pełny ekran"
	display_mode_button.button_pressed = fullscreen
	display_mode_button.disabled = not unavailable_message.is_empty()
	display_mode_button.tooltip_text = (
		unavailable_message
		if not unavailable_message.is_empty()
		else "Przełącz tryb pełnoekranowy (Alt+Enter lub F11)."
	)


func _update_availability() -> void:
	continue_button.disabled = not _has_active_session
	load_button.disabled = not _has_saved_session
	save_button.disabled = not _has_active_session


func show_save_result(succeeded: bool, message: String) -> void:
	# Keep feedback in the existing menu hint, not the hidden application footer.
	save_feedback.text = message if succeeded else "Nie zapisano gry.\n" + message
	save_feedback.tooltip_text = save_feedback.text
	save_feedback.add_theme_color_override(
		"font_color", Color(0.53, 0.87, 0.69) if succeeded else Color(0.99, 0.56, 0.52)
	)
	if _feedback_tween != null:
		_feedback_tween.kill()
	save_feedback.modulate.a = 0.55
	_feedback_tween = create_tween()
	_feedback_tween.tween_property(save_feedback, "modulate:a", 1.0, 0.16)
