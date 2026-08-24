class_name LoadGameScreen
extends Control

signal canceled
signal session_loaded(session: GameSessionClass)

const GameSessionClass := preload("res://core/game/game_session.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")
const TerminalSaveV15ImporterClass := preload("res://core/save/terminal_save_v15_importer.gd")

var _save_service: SaveGameServiceClass
var _terminal_importer: TerminalSaveV15ImporterClass
var _summaries: Array[Dictionary] = []
var _terminal_sources: Array[Dictionary] = []

@onready var slot_selector: OptionButton = %SlotSelector
@onready var details_label: Label = %DetailsLabel
@onready var load_button: Button = %LoadButton
@onready var terminal_source_selector: OptionButton = %TerminalSourceSelector
@onready var import_details_label: Label = %ImportDetailsLabel
@onready var import_button: Button = %ImportButton


func _ready() -> void:
	slot_selector.item_selected.connect(_on_slot_selected)
	load_button.pressed.connect(_on_load_pressed)
	terminal_source_selector.item_selected.connect(_on_terminal_source_selected)
	import_button.pressed.connect(_on_import_pressed)
	%BackButton.pressed.connect(canceled.emit)
	_refresh()
	call_deferred("_focus_slot_selector")


func configure(
	save_service: SaveGameServiceClass, terminal_source_paths: Array[String] = []
) -> void:
	_save_service = save_service
	_terminal_importer = TerminalSaveV15ImporterClass.new(save_service, terminal_source_paths)
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	slot_selector.clear()
	_summaries.clear()
	if _save_service == null:
		details_label.text = "Usługa zapisów nie jest dostępna."
		load_button.disabled = true
		_refresh_terminal_sources()
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
	_refresh_terminal_sources()


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
	_update_import_state()


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


func _refresh_terminal_sources() -> void:
	terminal_source_selector.clear()
	_terminal_sources.clear()
	if _terminal_importer == null:
		terminal_source_selector.add_item("Nie znaleziono zapisów terminalowych v15")
		terminal_source_selector.disabled = true
		import_details_label.text = "Importer jest dostępny po uruchomieniu usługi zapisów."
		import_button.disabled = true
		return
	_terminal_sources = _terminal_importer.discover_sources()
	if _terminal_sources.is_empty():
		terminal_source_selector.add_item("Nie znaleziono zapisów terminalowych v15")
		terminal_source_selector.disabled = true
		import_details_label.text = (
			"Oryginalne zapisy pozostają nietknięte. " + "Import tworzy wyłącznie nową kopię."
		)
		import_button.disabled = true
		return
	terminal_source_selector.disabled = false
	for source: Dictionary in _terminal_sources:
		var label: String = str(source.path).get_file()
		if source.ok:
			label += " — %s, poziom %d, dzień %d" % [source.player_name, source.level, source.day]
		else:
			label += " — nieobsługiwany"
		terminal_source_selector.add_item(label)
	terminal_source_selector.select(0)
	_on_terminal_source_selected(0)


func _on_terminal_source_selected(index: int) -> void:
	if index < 0 or index >= _terminal_sources.size():
		import_details_label.text = "Wybierz terminalowy zapis v15."
		import_button.disabled = true
		return
	var source := _terminal_sources[index]
	import_details_label.text = (
		source.message
		+ (
			" Import utworzy nową kopię i raport; plik źródłowy nie zostanie zmieniony."
			if source.ok
			else ""
		)
	)
	_update_import_state()


func _update_import_state() -> void:
	var source_index := terminal_source_selector.selected
	var slot_index := slot_selector.selected
	if (
		_save_service == null
		or _terminal_importer == null
		or source_index < 0
		or source_index >= _terminal_sources.size()
		or slot_index < 0
		or slot_index >= _summaries.size()
	):
		import_button.disabled = true
		return
	import_button.disabled = (
		not _terminal_sources[source_index].ok or _summaries[slot_index].exists
	)


func _on_import_pressed() -> void:
	var source_index := terminal_source_selector.selected
	var slot_index := slot_selector.selected
	if (
		_terminal_importer == null
		or source_index < 0
		or source_index >= _terminal_sources.size()
		or slot_index < 0
		or slot_index >= _summaries.size()
	):
		return
	var source_path := str(_terminal_sources[source_index].path)
	var target_slot := int(_summaries[slot_index].slot)
	var result := _terminal_importer.import_copy(source_path, target_slot)
	if not result.ok:
		import_details_label.text = result.message
		_update_import_state()
		return
	_refresh()
	import_details_label.text = result.message + " Raport: %s" % result.report_path


func _focus_slot_selector() -> void:
	if slot_selector != null and slot_selector.is_visible_in_tree():
		slot_selector.grab_focus()
