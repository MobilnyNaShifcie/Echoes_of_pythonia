class_name EquipmentScreen
extends Control

signal back_requested

const EquipmentItemClass := preload("res://core/items/equipment_item.gd")
const GameSessionClass := preload("res://core/game/game_session.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const PlayerEquipmentClass := preload("res://core/player/equipment.gd")
const SLOT_ORDER := [
	PlayerEquipmentClass.WEAPON,
	PlayerEquipmentClass.OFF_HAND,
	PlayerEquipmentClass.HEAD,
	PlayerEquipmentClass.CHEST,
	PlayerEquipmentClass.HANDS,
	PlayerEquipmentClass.FEET,
	PlayerEquipmentClass.BELT,
	PlayerEquipmentClass.NECKLACE,
	PlayerEquipmentClass.BRACELET,
	PlayerEquipmentClass.EARRINGS,
	PlayerEquipmentClass.RING,
]
const SLOT_NAMES := {
	"weapon": "Broń",
	"off_hand": "Druga ręka",
	"head": "Hełm",
	"chest": "Zbroja",
	"hands": "Rękawice",
	"feet": "Buty",
	"belt": "Pas",
	"necklace": "Naszyjnik",
	"bracelet": "Bransoleta",
	"earrings": "Kolczyki",
	"ring": "Pierścień",
}

var _session: GameSessionClass

@onready var hero_stats_label: Label = %HeroStatsLabel
@onready var equipped_list: ItemList = %EquippedList
@onready var inventory_list: ItemList = %InventoryList
@onready var unequip_button: Button = %UnequipButton
@onready var equip_button: Button = %EquipButton
@onready var details_label: Label = %DetailsLabel
@onready var feedback_label: Label = %FeedbackLabel


func _ready() -> void:
	%BackButton.pressed.connect(back_requested.emit)
	equipped_list.item_selected.connect(_on_equipped_selected)
	inventory_list.item_selected.connect(_on_inventory_selected)
	unequip_button.pressed.connect(_unequip_selected)
	equip_button.pressed.connect(_equip_selected)
	_refresh()
	%BackButton.grab_focus()


func configure(session: GameSessionClass) -> void:
	_session = session
	if is_node_ready():
		_refresh()


func _refresh() -> void:
	if _session == null:
		return
	var player := _session.player
	hero_stats_label.text = (
		"%s  •  PŻ %d/%d  •  ATK %d  •  DEF %d  •  MANA %d/%d  •  UNIK %.1f%%"
		% [
			player.display_name,
			player.stats.current_hp,
			player.stats.max_hp,
			player.stats.attack,
			player.stats.defense,
			player.stats.current_mana,
			player.stats.max_mana,
			player.stats.dodge,
		]
	)
	_refresh_equipped_items()
	_refresh_inventory_items()
	unequip_button.disabled = true
	equip_button.disabled = true
	details_label.text = "Zaznacz przedmiot, aby zobaczyć jego opis i statystyki."


func _refresh_equipped_items() -> void:
	equipped_list.clear()
	for slot: String in SLOT_ORDER:
		var item = _session.player.equipment.get_item(slot)
		var slot_name: String = SLOT_NAMES[slot]
		var row_text := "%s — puste" % slot_name
		if item != null:
			row_text = "%s — %s" % [slot_name, item.formatted_name()]
		var row := equipped_list.add_item(row_text)
		equipped_list.set_item_metadata(row, slot)
		if item == null:
			equipped_list.set_item_disabled(row, true)


func _refresh_inventory_items() -> void:
	inventory_list.clear()
	var items = _session.player.inventory.equipment_items
	var stacks: Dictionary = _session.player.inventory.stacks
	if items.is_empty() and stacks.is_empty():
		var empty_row := inventory_list.add_item("Plecak jest pusty.")
		inventory_list.set_item_disabled(empty_row, true)
		return
	for index in items.size():
		var item: EquipmentItemClass = items[index]
		var row := inventory_list.add_item(
			"%s  [%s]" % [item.formatted_name(), SLOT_NAMES[item.slot]]
		)
		inventory_list.set_item_metadata(row, {"kind": "equipment", "index": index})
	var stack_ids: Array = stacks.keys()
	stack_ids.sort()
	for item_id: String in stack_ids:
		var definition = ItemCatalogClass.get_definition(item_id)
		var stack_row := (
			inventory_list
			. add_item(
				(
					"%s  ×%d  [%s]"
					% [
						definition.display_name,
						stacks[item_id],
						_category_name(definition.category),
					]
				)
			)
		)
		inventory_list.set_item_metadata(stack_row, {"kind": "stack", "item_id": item_id})


func _on_equipped_selected(index: int) -> void:
	inventory_list.deselect_all()
	equip_button.disabled = true
	var slot: String = equipped_list.get_item_metadata(index)
	var item: EquipmentItemClass = _session.player.equipment.get_item(slot)
	unequip_button.disabled = item == null
	if item != null:
		details_label.text = _format_item_details(item)


func _on_inventory_selected(index: int) -> void:
	equipped_list.deselect_all()
	unequip_button.disabled = true
	var metadata: Dictionary = inventory_list.get_item_metadata(index)
	if metadata.get("kind", "") == "stack":
		equip_button.disabled = true
		details_label.text = _format_stack_details(metadata.item_id)
		return
	var inventory_index: int = metadata.get("index", -1)
	var items = _session.player.inventory.equipment_items
	if inventory_index < 0 or inventory_index >= items.size():
		equip_button.disabled = true
		return
	equip_button.disabled = false
	details_label.text = _format_item_details(items[inventory_index])


func _unequip_selected() -> void:
	var selected := equipped_list.get_selected_items()
	if selected.is_empty():
		return
	var slot: String = equipped_list.get_item_metadata(selected[0])
	var item = _session.player.unequip_to_inventory(slot)
	if item == null:
		feedback_label.text = "Tego slotu nie można teraz opróżnić."
		return
	feedback_label.text = "%s trafia do plecaka." % item.formatted_name()
	_refresh()


func _equip_selected() -> void:
	var selected := inventory_list.get_selected_items()
	if selected.is_empty():
		return
	var metadata: Dictionary = inventory_list.get_item_metadata(selected[0])
	if metadata.get("kind", "") != "equipment":
		return
	var inventory_index: int = metadata.get("index", -1)
	var error := _session.player.get_equip_error(inventory_index)
	if not error.is_empty():
		feedback_label.text = error
		return
	var item = _session.player.equip_from_inventory(inventory_index)
	if item == null:
		feedback_label.text = "Nie udało się założyć przedmiotu."
		return
	feedback_label.text = "Założono: %s." % item.formatted_name()
	_refresh()


func _format_item_details(item: EquipmentItemClass) -> String:
	var definition = item.definition
	var stats: Array[String] = []
	if definition.attack > 0:
		stats.append("ATK +%d" % definition.attack)
	if definition.defense > 0:
		stats.append("DEF +%d" % definition.defense)
	if definition.max_hp > 0:
		stats.append("PŻ +%d" % definition.max_hp)
	if definition.max_mana > 0:
		stats.append("MANA +%d" % definition.max_mana)
	if definition.dodge > 0:
		stats.append("UNIK +%.1f%%" % definition.dodge)
	var stats_text := ", ".join(stats) if not stats.is_empty() else "Brak premii"
	return (
		"%s\nSlot: %s  •  Item Power: %d\n%s\n\n%s"
		% [
			item.formatted_name(),
			SLOT_NAMES[item.slot],
			definition.item_power,
			stats_text,
			definition.description,
		]
	)


func _format_stack_details(item_id: String) -> String:
	var definition = ItemCatalogClass.get_definition(item_id)
	var effect := "Materiał lub przedmiot fabularny."
	if definition.heal_hp > 0:
		effect = "Leczenie: %d PŻ" % definition.heal_hp
	return (
		"%s\nKategoria: %s  •  Liczba: %d\n%s\n\n%s"
		% [
			definition.display_name,
			_category_name(definition.category),
			_session.player.inventory.count(item_id),
			effect,
			definition.description,
		]
	)


func _category_name(category: String) -> String:
	return (
		{
			"consumable": "przedmiot użytkowy",
			"material": "materiał",
			"quest": "przedmiot fabularny",
		}
		. get(category, category)
	)
