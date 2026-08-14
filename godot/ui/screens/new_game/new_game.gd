class_name NewGameScreen
extends Control

signal canceled
signal session_created(session: GameSessionClass)

const GameSessionClass := preload("res://core/game/game_session.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")

var _service := NewGameServiceClass.new()

@onready var name_input: LineEdit = %NameInput
@onready var slot_selector: OptionButton = %SlotSelector
@onready var validation_label: Label = %ValidationLabel
@onready var create_button: Button = %CreateButton


func _ready() -> void:
	_populate_save_slots()
	name_input.text_changed.connect(_on_name_changed)
	name_input.text_submitted.connect(_on_name_submitted)
	%BackButton.pressed.connect(canceled.emit)
	create_button.pressed.connect(_create_new_session)
	_on_name_changed(name_input.text)
	name_input.grab_focus()


func _populate_save_slots() -> void:
	slot_selector.clear()
	for slot in range(1, NewGameServiceClass.SAVE_SLOT_COUNT + 1):
		slot_selector.add_item("Slot %d — pusty" % slot, slot)


func _on_name_changed(raw_name: String) -> void:
	var error := _service.get_player_name_error(raw_name)
	create_button.disabled = not error.is_empty()
	if raw_name.is_empty():
		validation_label.text = "Od 2 do 20 znaków. Spacje na końcach zostaną usunięte."
		validation_label.modulate = Color(0.55, 0.63, 0.73)
	elif error.is_empty():
		validation_label.text = "Imię jest gotowe."
		validation_label.modulate = Color(0.42, 0.78, 0.56)
	else:
		validation_label.text = error
		validation_label.modulate = Color(0.91, 0.43, 0.42)


func _on_name_submitted(_submitted_name: String) -> void:
	if not create_button.disabled:
		_create_new_session()


func _create_new_session() -> void:
	var selected_slot := slot_selector.get_selected_id()
	var session := _service.create_session(name_input.text, selected_slot)
	if session == null:
		validation_label.text = "Nie udało się utworzyć gry. Sprawdź podane dane."
		validation_label.modulate = Color(0.91, 0.43, 0.42)
		return
	session_created.emit(session)
