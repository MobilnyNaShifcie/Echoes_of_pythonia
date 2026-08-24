class_name NewGameScreen
extends Control

signal canceled
signal session_created(session: GameSessionClass)

const GameSessionClass := preload("res://core/game/game_session.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const CombatPresentationCatalogClass := preload(
	"res://ui/presentation/combat_presentation_catalog.gd"
)
const GENDER_OPTIONS := [
	{
		"code": "female",
		"name": "Kobieta",
		"role": "Poszukiwaczka",
		"placeholder": "POSZUKIWACZKA\nGRAFIKA W PRZYGOTOWANIU",
	},
	{
		"code": "male",
		"name": "Mężczyzna",
		"role": "Poszukiwacz",
		"placeholder": "POSZUKIWACZ\nGRAFIKA W PRZYGOTOWANIU",
	},
]

var _service := NewGameServiceClass.new()
var _selected_gender_code := ""

@onready var name_input: LineEdit = %NameInput
@onready var slot_selector: OptionButton = %SlotSelector
@onready var gender_selector: ItemList = %GenderSelector
@onready var role_name_label: Label = %RoleNameLabel
@onready var gender_details_label: Label = %GenderDetailsLabel
@onready var starter_info: Label = %StarterInfo
@onready var character_preview: CharacterPaperdoll = %CharacterPreview
@onready var validation_label: Label = %ValidationLabel
@onready var create_button: Button = %CreateButton


func _ready() -> void:
	_populate_save_slots()
	_populate_genders()
	name_input.text_changed.connect(_on_name_changed)
	name_input.text_submitted.connect(_on_name_submitted)
	gender_selector.item_selected.connect(_on_gender_selected)
	%BackButton.pressed.connect(canceled.emit)
	create_button.pressed.connect(_create_new_session)
	_update_validation()
	name_input.grab_focus()


func _populate_save_slots() -> void:
	slot_selector.clear()
	for slot in range(1, NewGameServiceClass.SAVE_SLOT_COUNT + 1):
		slot_selector.add_item("Slot %d — pusty" % slot, slot)


func _populate_genders() -> void:
	gender_selector.clear()
	for option: Dictionary in GENDER_OPTIONS:
		var row := gender_selector.add_item(option.name)
		gender_selector.set_item_metadata(row, option.code)


func _on_name_changed(raw_name: String) -> void:
	_update_validation(raw_name)


func _on_gender_selected(index: int) -> void:
	_selected_gender_code = str(gender_selector.get_item_metadata(index))
	var option := _gender_option(_selected_gender_code)
	if option.is_empty():
		_update_validation()
		return
	role_name_label.text = option.role
	gender_details_label.text = (
		"Płeć określa wariant wyglądu bohatera. " + "Nie zmienia statystyk ani zasad walki."
	)
	starter_info.text = (
		"Zaczynasz jako %s. Drogę bohatera wybierzesz po osiągnięciu poziomu 5." % option.role
	)
	(
		character_preview
		. show_character(
			CombatPresentationCatalogClass.hero_texture("none", _selected_gender_code),
			option.placeholder,
		)
	)
	_update_validation()


func _update_validation(raw_name := "") -> void:
	if raw_name.is_empty() and not name_input.text.is_empty():
		raw_name = name_input.text
	var name_error := _service.get_player_name_error(raw_name)
	var gender_error := _service.get_gender_error(_selected_gender_code)
	create_button.disabled = not name_error.is_empty() or not gender_error.is_empty()
	if raw_name.is_empty():
		validation_label.text = "Od 2 do 20 znaków. Spacje na końcach zostaną usunięte."
		validation_label.modulate = Color(0.55, 0.63, 0.73)
	elif not name_error.is_empty():
		validation_label.text = name_error
		validation_label.modulate = Color(0.91, 0.43, 0.42)
	elif not gender_error.is_empty():
		validation_label.text = "Imię jest gotowe. Wybierz płeć postaci."
		validation_label.modulate = Color(0.84, 0.68, 0.31)
	else:
		validation_label.text = "Postać jest gotowa do rozpoczęcia podróży."
		validation_label.modulate = Color(0.42, 0.78, 0.56)


func _on_name_submitted(_submitted_name: String) -> void:
	if not create_button.disabled:
		_create_new_session()


func _create_new_session() -> void:
	var selected_slot := slot_selector.get_selected_id()
	var session := _service.create_session(
		name_input.text, selected_slot, null, _selected_gender_code
	)
	if session == null:
		validation_label.text = "Nie udało się utworzyć gry. Sprawdź podane dane."
		validation_label.modulate = Color(0.91, 0.43, 0.42)
		return
	session_created.emit(session)


func _gender_option(gender_code: String) -> Dictionary:
	for option: Dictionary in GENDER_OPTIONS:
		if option.code == gender_code:
			return option
	return {}
