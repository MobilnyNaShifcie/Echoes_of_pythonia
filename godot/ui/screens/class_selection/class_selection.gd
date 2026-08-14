class_name ClassSelectionScreen
extends Control

signal back_requested
signal class_chosen

const GameSessionClass := preload("res://core/game/game_session.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const PlayerClassCatalogClass := preload("res://core/player/player_class_catalog.gd")

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
	for definition in PlayerClassCatalogClass.get_playable_definitions():
		var row := class_list.add_item(
			"%s  •  Bazowa Mana %d" % [definition.display_name, definition.base_mana]
		)
		class_list.set_item_metadata(row, definition.class_code)
	if class_list.item_count > 0:
		class_list.select(0)
		_on_class_selected(0)


func _on_class_selected(index: int) -> void:
	_selected_code = class_list.get_item_metadata(index)
	var definition = _get_definition(_selected_code)
	var equipment_names: Array[String] = []
	for item_id: String in definition.starter_equipment_ids:
		equipment_names.append(ItemCatalogClass.get_definition(item_id).display_name)
	if _selected_code == "warrior":
		equipment_names.push_front("Aktualna broń")
	details_label.text = (
		"%s\n\n%s\n\nGłówne atrybuty: %s\nBazowa Mana: %d\nSprzęt Drogi: %s"
		% [
			definition.display_name,
			definition.description,
			definition.primary_attributes,
			definition.base_mana,
			" + ".join(equipment_names),
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


func _get_definition(class_code: String):
	return PlayerClassCatalogClass.get_definition(class_code)
