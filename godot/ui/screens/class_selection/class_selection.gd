class_name ClassSelectionScreen
extends Control

signal back_requested
signal class_chosen

const GameSessionClass := preload("res://core/game/game_session.gd")
const CLASSES := [
	{
		"code": "warrior",
		"name": "Wojownik",
		"mana": 12,
		"attributes": "Siła / Wytrzymałość",
		"description": "Ciężkie uderzenia, łamanie obrony i wytrzymałość.",
		"equipment": "Stary Miecz + Tarcza Rekruta",
	},
	{
		"code": "hunter",
		"name": "Łowca",
		"mana": 16,
		"attributes": "Zręczność / Siła",
		"description": "Łuk, techniki strzeleckie, trzystrzałowe sekwencje i odkrywane kombinacje.",
		"equipment": "Łuk Myśliwski + Kołczan Tropiciela",
	},
	{
		"code": "mage",
		"name": "Mag",
		"mana": 24,
		"attributes": "Inteligencja",
		"description": "Zaklęcia żywiołów, Splot Magii i wysoka skuteczność Inteligencji.",
		"equipment": "Kostur Adepta + Kryształ Many",
	},
	{
		"code": "pierrot",
		"name": "Pierrot",
		"mana": 18,
		"attributes": "Szczęście / Zręczność",
		"description": "Lanca Losu, Kości Losu, Chaos i manipulowanie Szczęściem.",
		"equipment": "Lanca Kaprysu + Wytarte Kości Losu",
	},
]

var _session: GameSessionClass
var _selected_code := ""

@onready var class_list: ItemList = %ClassList
@onready var details_label: Label = %DetailsLabel
@onready var lock_label: Label = %LockLabel
@onready var choose_button: Button = %ChooseButton


func _ready() -> void:
	%BackButton.pressed.connect(back_requested.emit)
	class_list.item_selected.connect(_on_class_selected)
	choose_button.pressed.connect(_choose_selected_class)
	_populate_classes()
	_render_lock_state()
	%BackButton.grab_focus()


func configure(session: GameSessionClass) -> void:
	_session = session
	if is_node_ready():
		_render_lock_state()


func _populate_classes() -> void:
	class_list.clear()
	for definition: Dictionary in CLASSES:
		var row := class_list.add_item("%s  •  Bazowa Mana %d" % [definition.name, definition.mana])
		class_list.set_item_metadata(row, definition.code)


func _on_class_selected(index: int) -> void:
	_selected_code = class_list.get_item_metadata(index)
	var definition := _get_definition(_selected_code)
	details_label.text = (
		"%s\n\n%s\n\nGłówne atrybuty: %s\nBazowa Mana: %d\nSprzęt Drogi: %s"
		% [
			definition.name,
			definition.description,
			definition.attributes,
			definition.mana,
			definition.equipment,
		]
	)
	_render_lock_state()


func _choose_selected_class() -> void:
	if _session == null or _selected_code.is_empty():
		return
	var error := _session.player.get_class_choice_error(_selected_code)
	if not error.is_empty():
		lock_label.text = error
		return
	if _session.player.choose_class(_selected_code):
		_session.last_activity = "Wybrano Drogę: %s." % _session.player.character_class_name
		class_chosen.emit()


func _render_lock_state() -> void:
	choose_button.disabled = true
	if _session == null:
		return
	var player := _session.player
	if player.character_class_code != player.CLASS_NONE:
		lock_label.text = "Wybrana Droga: %s. Ten wybór jest stały." % player.character_class_name
		return
	if player.level < 5:
		lock_label.text = (
			"Wybór odblokuje się na poziomie 5. Obecny poziom: %d. Możesz już porównać wszystkie Drogi."
			% player.level
		)
		return
	lock_label.text = "Wybór jest stały dla tej postaci."
	choose_button.disabled = _selected_code.is_empty()


func _get_definition(class_code: String) -> Dictionary:
	for definition: Dictionary in CLASSES:
		if definition.code == class_code:
			return definition
	return {}
