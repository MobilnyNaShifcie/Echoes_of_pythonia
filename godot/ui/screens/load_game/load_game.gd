class_name LoadGameScreen
extends Control

signal canceled
signal session_loaded(session: GameSessionClass)

const GameSessionClass := preload("res://core/game/game_session.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")

var _save_service: SaveGameServiceClass
var _summaries: Array[Dictionary] = []

@onready var slot_selector: OptionButton = %SlotSelector
@onready var details_label: Label = %DetailsLabel
@onready var load_button: Button = %LoadButton


func _ready() -> void:
	slot_selector.item_selected.connect(_on_slot_selected)
	load_button.pressed.connect(_on_load_pressed)
	%BackButton.pressed.connect(canceled.emit)
	_refresh()


func configure(save_service: SaveGameServiceClass) -> void:
	_save_service = save_service
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	slot_selector.clear()
	_summaries.clear()
	if _save_service == null:
		details_label.text = "Usługa zapisów nie jest dostępna."
		load_button.disabled = true
		return
	_summaries = _save_service.get_slot_summaries()
	var first_valid_index := -1
	for index in _summaries.size():
		var summary := _summaries[index]
		slot_selector.add_item(summary.label)
		slot_selector.set_item_metadata(index, summary.slot)
		if first_valid_index == -1 and summary.valid:
			first_valid_index = index
	var selected_index := first_valid_index if first_valid_index >= 0 else 0
	slot_selector.select(selected_index)
	_on_slot_selected(selected_index)


func _on_slot_selected(index: int) -> void:
	if index < 0 or index >= _summaries.size():
		details_label.text = "Wybierz slot zapisu."
		load_button.disabled = true
		return
	var summary := _summaries[index]
	load_button.disabled = not summary.valid
	if summary.valid:
		details_label.text = "Zapis jest gotowy do wczytania."
	elif summary.exists:
		details_label.text = "Plik istnieje, ale nie można go bezpiecznie odczytać."
	else:
		details_label.text = "Ten slot jest pusty."


func _on_load_pressed() -> void:
	var index := slot_selector.selected
	if _save_service == null or index < 0 or index >= _summaries.size():
		return
	var slot := int(_summaries[index].slot)
	var result := _save_service.load_session(slot)
	if not result.ok:
		details_label.text = result.message
		load_button.disabled = true
		return
	details_label.text = result.message
	session_loaded.emit(result.session)
