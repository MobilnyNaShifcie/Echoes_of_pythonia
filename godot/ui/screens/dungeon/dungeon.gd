class_name DungeonScreen
extends Control

signal start_requested(dungeon_id: String)
signal action_requested(action: String)
signal exit_requested(region_id: String)

const DungeonCatalogClass := preload("res://core/dungeons/dungeon_catalog.gd")
const DungeonRunStateClass := preload("res://core/dungeons/dungeon_run_state.gd")
const DungeonServiceClass := preload("res://core/dungeons/dungeon_service.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")

var _session
var _dungeon_id := ""
var _run: DungeonRunStateClass

@onready var eyebrow_label: Label = %EyebrowLabel
@onready var title_label: Label = %TitleLabel
@onready var resources_label: Label = %ResourcesLabel
@onready var description_label: Label = %DescriptionLabel
@onready var message_label: Label = %MessageLabel
@onready var rules_label: Label = %RulesLabel
@onready var loot_label: Label = %LootLabel
@onready var actions: VBoxContainer = %Actions


func configure(session, dungeon_id: String, run: DungeonRunStateClass = null) -> void:
	_session = session
	_dungeon_id = dungeon_id
	_run = run
	if is_node_ready():
		_render()


func show_message(message: String) -> void:
	message_label.text = message
	message_label.add_theme_color_override("font_color", Color(0.94, 0.43, 0.48))


func _ready() -> void:
	_render()


func _render() -> void:
	if _session == null or _dungeon_id.is_empty():
		return
	var view := (
		DungeonServiceClass.entrance_view(_session, _dungeon_id)
		if _run == null
		else DungeonServiceClass.view(_run, _session)
	)
	eyebrow_label.text = str(view.get("eyebrow", "LOCH SOLO"))
	title_label.text = str(view.get("title", "Loch"))
	resources_label.text = str(view.get("resources", ""))
	description_label.text = str(view.get("description", ""))
	message_label.text = str(view.get("message", ""))
	message_label.remove_theme_color_override("font_color")
	rules_label.text = (
		"PŻ i Mana przechodzą między komnatami. Wycofanie zabezpiecza łup. "
		+ "Porażka usuwa tylko niezabezpieczone przedmioty; zdobyte EXP i złoto pozostają. "
		+ "Walka odbywa się SOLO i bez wpływu pogody powierzchni."
	)
	loot_label.text = _format_loot(view.get("loot", []), str(view.get("outcome", "")))
	for child in actions.get_children():
		child.queue_free()
	for entry: Dictionary in view.get("actions", []):
		var button := Button.new()
		button.custom_minimum_size = Vector2(0, 46)
		button.text = str(entry.label)
		button.pressed.connect(_on_action.bind(str(entry.id)))
		actions.add_child(button)


func _on_action(action: String) -> void:
	if action == "start":
		start_requested.emit(_dungeon_id)
		return
	if action == "exit":
		var dungeon = DungeonCatalogClass.get_definition(_dungeon_id)
		exit_requested.emit(dungeon.region_id)
		return
	action_requested.emit(action)


func _format_loot(loot: Array, outcome: String) -> String:
	if outcome.is_empty():
		return ""
	var heading := "UTRACONY ŁUP" if outcome == "defeated" else "ŁUP Z WYPRAWY"
	if loot.is_empty():
		return "%s\n• brak" % heading
	var lines: Array[String] = [heading]
	for entry: Dictionary in loot:
		var definition = ItemCatalogClass.get_definition(str(entry.item_id))
		var quantity := int(entry.quantity)
		lines.append(
			"• %s%s" % [definition.display_name, " ×%d" % quantity if quantity > 1 else ""]
		)
	return "\n".join(lines)
