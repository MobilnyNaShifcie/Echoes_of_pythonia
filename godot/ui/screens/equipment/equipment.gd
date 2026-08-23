class_name EquipmentScreen
extends Control

signal back_requested

const EquipmentItemClass := preload("res://core/items/equipment_item.gd")
const GameSessionClass := preload("res://core/game/game_session.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const EquipmentAffixServiceClass := preload("res://core/items/equipment_affix_service.gd")
const EquipmentSetCatalogClass := preload("res://core/items/equipment_set_catalog.gd")
const EquipmentClassEffectCatalogClass := preload(
	"res://core/items/equipment_class_effect_catalog.gd"
)
const BookCatalogClass := preload("res://core/progression/book_catalog.gd")
const BookServiceClass := preload("res://core/progression/book_service.gd")
const PlayerEquipmentClass := preload("res://core/player/equipment.gd")
const CarryWeightServiceClass := preload("res://core/economy/carry_weight_service.gd")
const UpgradeServiceClass := preload("res://core/economy/upgrade_service.gd")
const ItemGridLayoutClass := preload("res://ui/components/inventory_grid/item_grid_layout.gd")
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
const SLOT_CODES := {
	"weapon": "BR",
	"off_hand": "II",
	"head": "HEŁ",
	"chest": "ZBR",
	"hands": "RĘK",
	"feet": "BUT",
	"belt": "PAS",
	"necklace": "NAS",
	"bracelet": "BRA",
	"earrings": "KOL",
	"ring": "PIE",
}
const EQUIPMENT_TYPE_NAMES := {
	"sword": "Miecz",
	"bow": "Łuk",
	"staff": "Kostur",
	"fate_lance": "Lanca Losu",
	"shield": "Tarcza",
	"quiver": "Kołczan",
	"artifact": "Artefakt",
	"fate_dice": "Kości Losu",
	"fate_cards": "Karty Losu",
}
const CATEGORY_FILTERS := ["all", "equipment", "consumable", "material", "other"]
const CATEGORY_NAMES := ["Wszystko", "Wyposażenie", "Użytkowe", "Materiały", "Pozostałe"]

var _session: GameSessionClass

@onready var hero_stats_label: Label = %HeroStatsLabel
@onready var equipped_list: ItemList = %EquippedList
@onready var inventory_list: ItemList = %InventoryList
@onready var unequip_button: Button = %UnequipButton
@onready var equip_button: Button = %EquipButton
@onready var read_book_button: Button = %ReadBookButton
@onready var details_label: Label = %DetailsLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var category_tabs: TabBar = %CategoryTabs
@onready var inventory_grid: InventoryGridView = %InventoryGrid
@onready var inventory_drop_zone: PanelContainer = %InventoryDropZone
@onready var slot_buttons := {
	PlayerEquipmentClass.WEAPON: %WeaponSlot,
	PlayerEquipmentClass.OFF_HAND: %OffHandSlot,
	PlayerEquipmentClass.HEAD: %HeadSlot,
	PlayerEquipmentClass.CHEST: %ChestSlot,
	PlayerEquipmentClass.HANDS: %HandsSlot,
	PlayerEquipmentClass.FEET: %FeetSlot,
	PlayerEquipmentClass.BELT: %BeltSlot,
	PlayerEquipmentClass.NECKLACE: %NecklaceSlot,
	PlayerEquipmentClass.BRACELET: %BraceletSlot,
	PlayerEquipmentClass.EARRINGS: %EarringsSlot,
	PlayerEquipmentClass.RING: %RingSlot,
}


func _ready() -> void:
	%BackButton.pressed.connect(back_requested.emit)
	equipped_list.item_selected.connect(_on_equipped_selected)
	inventory_list.item_selected.connect(_on_inventory_selected)
	unequip_button.pressed.connect(_unequip_selected)
	equip_button.pressed.connect(_equip_selected)
	read_book_button.pressed.connect(_read_selected_book)
	for tab_name: String in CATEGORY_NAMES:
		category_tabs.add_tab(tab_name)
	category_tabs.tab_changed.connect(_category_changed)
	inventory_grid.entry_selected.connect(_select_inventory_metadata)
	inventory_grid.entry_hovered.connect(_show_inventory_metadata)
	inventory_grid.entry_activated.connect(_activate_inventory_metadata)
	inventory_grid.data_dropped.connect(_backpack_drop_data_from_grid)
	for slot: String in SLOT_ORDER:
		var button: Button = slot_buttons[slot]
		button.pressed.connect(_select_equipped_slot.bind(slot))
		button.mouse_entered.connect(_show_equipped_details.bind(slot))
		(
			button
			. set_drag_forwarding(
				_slot_get_drag_data.bind(slot),
				_slot_can_drop_data.bind(slot),
				_slot_drop_data.bind(slot),
			)
		)
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
	var load := CarryWeightServiceClass.carry_status(player)
	hero_stats_label.text = (
		(
			"%s  •  PŻ %d/%d  •  ATK %d  •  DEF %d  •  MANA %d/%d  •  "
			+ "UNIK %.1f%%  •  Udźwig %.1f/%.1f kg (%s)"
		)
		% [
			player.display_name,
			player.stats.current_hp,
			player.stats.max_hp,
			player.stats.attack,
			player.stats.defense,
			player.stats.current_mana,
			player.stats.max_mana,
			player.stats.dodge,
			load.current_kg,
			load.capacity_kg,
			load.display_name,
		]
	)
	_refresh_equipped_items()
	_refresh_inventory_items()
	_refresh_paperdoll()
	_refresh_inventory_grid()
	unequip_button.disabled = true
	equip_button.disabled = true
	read_book_button.disabled = true
	details_label.text = "Najedź na przedmiot, aby zobaczyć jego opis i statystyki."


func _category_changed(_index: int) -> void:
	_refresh_inventory_grid()


func _refresh_paperdoll() -> void:
	for slot: String in SLOT_ORDER:
		var button: InventoryItemSlot = slot_buttons[slot]
		var item: EquipmentItemClass = _session.player.equipment.get_item(slot)
		button.text = "%s\n%s" % ["◇" if item == null else "◆", SLOT_CODES[slot]]
		button.tooltip_text = (
			"%s — puste\nPrzeciągnij tutaj pasujący przedmiot." % SLOT_NAMES[slot]
			if item == null
			else "%s\n\n%s" % [SLOT_NAMES[slot], _format_item_details(item)]
		)


func _refresh_inventory_grid() -> void:
	if _session == null:
		return
	var filter_id: String = CATEGORY_FILTERS[category_tabs.current_tab]
	var entries: Array[Dictionary] = []
	var items = _session.player.inventory.equipment_items
	for index in items.size():
		if filter_id not in ["all", "equipment"]:
			continue
		var item: EquipmentItemClass = items[index]
		var metadata := {"kind": "equipment", "index": index}
		(
			entries
			. append(
				{
					"title": item.formatted_name(),
					"placeholder": _item_placeholder(item.formatted_name()),
					"tooltip": _format_item_details(item, true),
					"metadata": metadata,
					"drag_payload": metadata,
					"footprint": ItemGridLayoutClass.footprint_for("equipment", item.slot),
				}
			)
		)
	var stack_ids: Array = _session.player.inventory.stacks.keys()
	stack_ids.sort()
	for item_id: String in stack_ids:
		var definition = ItemCatalogClass.get_definition(item_id)
		if not _stack_matches_filter(definition.category, filter_id):
			continue
		var quantity := _session.player.inventory.count(item_id)
		(
			entries
			. append(
				{
					"title": definition.display_name,
					"placeholder":
					"%s\n×%d" % [_item_placeholder(definition.display_name), quantity],
					"tooltip": _format_stack_details(item_id),
					"metadata": {"kind": "stack", "item_id": item_id},
					"footprint": ItemGridLayoutClass.footprint_for(definition.category),
				}
			)
		)
	inventory_grid.set_entries(entries)


func _select_equipped_slot(slot: String) -> void:
	for index in equipped_list.item_count:
		if str(equipped_list.get_item_metadata(index)) == slot:
			equipped_list.select(index)
			_on_equipped_selected(index)
			return


func _select_inventory_metadata(metadata: Dictionary) -> void:
	for index in inventory_list.item_count:
		if inventory_list.get_item_metadata(index) == metadata:
			inventory_list.select(index)
			_on_inventory_selected(index)
			return


func _show_equipped_details(slot: String) -> void:
	var item: EquipmentItemClass = _session.player.equipment.get_item(slot)
	if item != null:
		details_label.text = _format_item_details(item)


func _show_inventory_metadata(metadata: Dictionary) -> void:
	if metadata.get("kind", "") == "equipment":
		var index := int(metadata.get("index", -1))
		if index >= 0 and index < _session.player.inventory.equipment_items.size():
			details_label.text = _format_item_details(
				_session.player.inventory.equipment_items[index], true
			)
		return
	if metadata.get("kind", "") == "stack":
		details_label.text = _format_stack_details(str(metadata.get("item_id", "")))


func _activate_inventory_metadata(metadata: Dictionary) -> void:
	_select_inventory_metadata(metadata)
	if metadata.get("kind", "") == "equipment":
		_equip_selected()
	elif BookCatalogClass.is_book(str(metadata.get("item_id", ""))):
		_read_selected_book()


func _inventory_get_drag_data(_position: Vector2, metadata: Dictionary) -> Variant:
	if metadata.get("kind", "") != "equipment":
		return null
	return metadata.duplicate(true)


func _slot_get_drag_data(_position: Vector2, slot: String) -> Variant:
	if _session.player.equipment.get_item(slot) == null:
		return null
	return {"kind": "equipped", "slot": slot}


func _slot_can_drop_data(_position: Vector2, data: Variant, slot: String) -> bool:
	if not data is Dictionary or data.get("kind", "") != "equipment":
		return false
	var index := int(data.get("index", -1))
	var items = _session.player.inventory.equipment_items
	return index >= 0 and index < items.size() and items[index].slot == slot


func _slot_drop_data(_position: Vector2, data: Variant, slot: String) -> void:
	if not _slot_can_drop_data(Vector2.ZERO, data, slot):
		return
	_select_inventory_metadata(data)
	_equip_selected()


func _empty_drag_data(_position: Vector2) -> Variant:
	return null


func _backpack_can_drop_data(_position: Vector2, data: Variant) -> bool:
	return data is Dictionary and data.get("kind", "") == "equipped"


func _backpack_drop_data(_position: Vector2, data: Variant) -> void:
	_backpack_drop_data_from_grid(data)


func _backpack_drop_data_from_grid(data: Variant) -> void:
	if not _backpack_can_drop_data(Vector2.ZERO, data):
		return
	_select_equipped_slot(str(data.get("slot", "")))
	_unequip_selected()


func _inventory_cell_can_drop_data(_position: Vector2, data: Variant) -> bool:
	return _backpack_can_drop_data(Vector2.ZERO, data)


func _inventory_cell_drop_data(_position: Vector2, data: Variant) -> void:
	_backpack_drop_data_from_grid(data)


func _stack_matches_filter(category: String, filter_id: String) -> bool:
	if filter_id == "all":
		return true
	if filter_id == "other":
		return category not in ["consumable", "material"]
	return category == filter_id


func _short_name(value: String) -> String:
	return value if value.length() <= 22 else value.left(20) + "…"


func _item_placeholder(display_name: String) -> String:
	var words := display_name.replace("+", " ").split(" ", false)
	var code := ""
	for word: String in words:
		if word.is_empty() or word.is_valid_int():
			continue
		code += word.left(1).to_upper()
		if code.length() >= 2:
			break
	return code if not code.is_empty() else "?"


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
	read_book_button.disabled = true
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
		var item_id: String = metadata.item_id
		read_book_button.disabled = true
		if BookCatalogClass.is_book(item_id):
			var read_error := BookServiceClass.get_read_error(_session.player, item_id)
			read_book_button.disabled = not read_error.is_empty()
			feedback_label.text = (
				read_error if not read_error.is_empty() else "Księga jest gotowa do przeczytania."
			)
		details_label.text = _format_stack_details(item_id)
		return
	read_book_button.disabled = true
	var inventory_index: int = metadata.get("index", -1)
	var items = _session.player.inventory.equipment_items
	if inventory_index < 0 or inventory_index >= items.size():
		equip_button.disabled = true
		return
	var item: EquipmentItemClass = items[inventory_index]
	var error := _session.player.get_equip_error(inventory_index)
	equip_button.disabled = not error.is_empty()
	feedback_label.text = error if not error.is_empty() else "Przedmiot spełnia wymagania."
	details_label.text = _format_item_details(item, true)


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


func _read_selected_book() -> void:
	var selected := inventory_list.get_selected_items()
	if selected.is_empty():
		return
	var metadata: Dictionary = inventory_list.get_item_metadata(selected[0])
	var item_id := str(metadata.get("item_id", ""))
	if metadata.get("kind", "") != "stack" or not BookCatalogClass.is_book(item_id):
		return
	var result := BookServiceClass.read(_session.player, item_id)
	feedback_label.text = result.message
	_refresh()


func _format_item_details(item: EquipmentItemClass, compare_with_equipped := false) -> String:
	var definition = item.definition
	var effective := _item_stats(item)
	var required_class: String = (
		definition.required_class_name
		if not definition.required_class_code.is_empty()
		else "dowolna Droga"
	)
	var lines: Array[String] = [
		item.formatted_name(),
		(
			"Miejsce: %s  •  Typ: %s  •  Moc przedmiotu: %d  •  Waga: %.1f kg"
			% [
				SLOT_NAMES[item.slot],
				EQUIPMENT_TYPE_NAMES.get(definition.equipment_type, "ogólne"),
				item.item_power,
				CarryWeightServiceClass.item_unit_weight(item.item_id),
			]
		),
		"Wymagania: poziom %d  •  %s" % [definition.required_level, required_class],
		"Premie: %s" % _format_stats(effective),
	]
	if not item.affixes.is_empty():
		lines.append("Afiksy:")
		for affix in item.affixes:
			lines.append("• %s" % EquipmentAffixServiceClass.formatted_affix(affix))
	if not definition.set_id.is_empty():
		var set_definition := EquipmentSetCatalogClass.get_definition(definition.set_id)
		var equipped_count := 0
		for required_item_id: String in set_definition.required_items:
			for equipped_item in _session.player.equipment.slots.values():
				if equipped_item != null and equipped_item.item_id == required_item_id:
					equipped_count += 1
		(
			lines
			. append(
				(
					"Zestaw: %s (%d/%d)%s"
					% [
						set_definition.display_name,
						equipped_count,
						set_definition.required_items.size(),
						(
							" — premia aktywna"
							if equipped_count == set_definition.required_items.size()
							else ""
						),
					]
				)
			)
		)
	if not definition.class_effect_id.is_empty():
		var class_effect := EquipmentClassEffectCatalogClass.get_definition(
			definition.class_effect_id
		)
		var effect_status := (
			"aktywny"
			if _session.player.has_active_equipment_effect(definition.class_effect_id)
			else "wymaga klasy %s i założenia przedmiotu" % class_effect.class_name
		)
		lines.append(
			(
				"Efekt klasowy — %s (%s): %s"
				% [class_effect.display_name, effect_status, class_effect.description]
			)
		)
	if compare_with_equipped:
		var current: EquipmentItemClass = _session.player.equipment.get_item(item.slot)
		if current == null:
			lines.append("Porównanie: miejsce jest obecnie puste.")
		else:
			var current_stats := _item_stats(current)
			lines.append("Porównanie z: %s" % current.formatted_name())
			lines.append("Zmiana: %s" % _format_stat_delta(effective, current_stats))
	lines.append("")
	lines.append(definition.description)
	return "\n".join(lines)


func _format_stats(stats: Dictionary) -> String:
	var parts: Array[String] = []
	if stats.attack > 0:
		parts.append("ATK +%d" % stats.attack)
	if stats.defense > 0:
		parts.append("DEF +%d" % stats.defense)
	if stats.max_hp > 0:
		parts.append("PŻ +%d" % stats.max_hp)
	if stats.max_mana > 0:
		parts.append("MANA +%d" % stats.max_mana)
	if stats.magic_power > 0:
		parts.append("MOC MAG. +%d" % stats.magic_power)
	if stats.dodge > 0:
		parts.append("UNIK +%.1f%%" % stats.dodge)
	if stats.health_regen > 0:
		parts.append("REGEN. PŻ +%d" % stats.health_regen)
	var percent_names := {
		"crit_chance": "SZANSA KRYT.",
		"crit_damage": "OBR. KRYT.",
		"skill_damage": "OBR. UMIEJ.",
		"armor_penetration": "PRZEBICIE",
		"damage_vs_elite": "OBR. VS ELITA",
		"damage_vs_boss": "OBR. VS BOSS",
	}
	for stat_id: String in percent_names:
		if float(stats.get(stat_id, 0.0)) > 0.0:
			parts.append("%s +%.1f%%" % [percent_names[stat_id], stats[stat_id]])
	if stats.has("elemental_resistances"):
		var names := {
			"fire": "OGIEŃ",
			"wind": "WIATR",
			"frost": "MRÓZ",
			"earth": "ZIEMIA",
			"water": "WODA",
		}
		for damage_type: String in names:
			var value := int(stats.elemental_resistances.get(damage_type, 0))
			if value > 0:
				parts.append("ODP. %s +%d%%" % [names[damage_type], value])
	return ", ".join(parts) if not parts.is_empty() else "brak premii"


func _format_stat_delta(candidate: Dictionary, current: Dictionary) -> String:
	var parts: Array[String] = []
	_append_integer_delta(parts, "ATK", int(candidate.attack) - int(current.attack))
	_append_integer_delta(parts, "DEF", int(candidate.defense) - int(current.defense))
	_append_integer_delta(parts, "PŻ", int(candidate.max_hp) - int(current.max_hp))
	_append_integer_delta(parts, "MANA", int(candidate.max_mana) - int(current.max_mana))
	_append_integer_delta(parts, "MOC MAG.", int(candidate.magic_power) - int(current.magic_power))
	_append_integer_delta(
		parts, "REGEN. PŻ", int(candidate.health_regen) - int(current.health_regen)
	)
	var dodge_delta := float(candidate.dodge) - float(current.dodge)
	if not is_zero_approx(dodge_delta):
		parts.append("UNIK %s%%" % _signed_float(dodge_delta))
	var percent_names := {
		"crit_chance": "SZANSA KRYT.",
		"crit_damage": "OBR. KRYT.",
		"skill_damage": "OBR. UMIEJ.",
		"armor_penetration": "PRZEBICIE",
		"damage_vs_elite": "OBR. VS ELITA",
		"damage_vs_boss": "OBR. VS BOSS",
	}
	for stat_id: String in percent_names:
		var delta := float(candidate.get(stat_id, 0.0)) - float(current.get(stat_id, 0.0))
		if not is_zero_approx(delta):
			parts.append("%s %s%%" % [percent_names[stat_id], _signed_float(delta)])
	var resistance_names := {
		"fire": "ODP. OGIEŃ",
		"wind": "ODP. WIATR",
		"frost": "ODP. MRÓZ",
		"earth": "ODP. ZIEMIA",
		"water": "ODP. WODA",
	}
	for damage_type: String in resistance_names:
		var resistance_delta := (
			int(candidate.elemental_resistances[damage_type])
			- int(current.elemental_resistances[damage_type])
		)
		_append_integer_delta(parts, resistance_names[damage_type], resistance_delta)
	return ", ".join(parts) if not parts.is_empty() else "bez zmiany statystyk"


func _item_stats(item: EquipmentItemClass) -> Dictionary:
	var stats := UpgradeServiceClass.effective_stats(item).duplicate(true)
	stats["health_regen"] = 0
	for stat_id: String in [
		"crit_chance",
		"crit_damage",
		"skill_damage",
		"armor_penetration",
		"damage_vs_elite",
		"damage_vs_boss",
	]:
		stats[stat_id] = 0.0
	var affix_bonuses := EquipmentAffixServiceClass.bonuses_for(item)
	for stat_id: String in ["attack", "defense", "max_hp", "max_mana", "health_regen"]:
		stats[stat_id] += roundi(affix_bonuses.get(stat_id, 0.0))
	for stat_id: String in [
		"dodge",
		"crit_chance",
		"crit_damage",
		"skill_damage",
		"armor_penetration",
		"damage_vs_elite",
		"damage_vs_boss",
	]:
		stats[stat_id] += float(affix_bonuses.get(stat_id, 0.0))
	for damage_type: String in ["fire", "wind", "frost", "earth", "water"]:
		stats.elemental_resistances[damage_type] += roundi(
			affix_bonuses.get("%s_resistance" % damage_type, 0.0)
		)
	return stats


func _append_integer_delta(parts: Array[String], stat_name: String, value: int) -> void:
	if value != 0:
		parts.append("%s %s" % [stat_name, _signed_integer(value)])


func _signed_integer(value: int) -> String:
	return "+%d" % value if value > 0 else str(value)


func _signed_float(value: float) -> String:
	return "+%.1f" % value if value > 0.0 else "%.1f" % value


func _format_stack_details(item_id: String) -> String:
	var definition = ItemCatalogClass.get_definition(item_id)
	var effect := "Materiał lub przedmiot fabularny."
	var effects: Array[String] = []
	var book = BookCatalogClass.get_definition(item_id)
	if book != null:
		var kind := "Księga Mistrzostwa" if book.book_type == "mastery" else "Księga Ścieżki"
		(
			effects
			. append(
				(
					"%s  •  Status: %s  •  Ceny: kupno %d, sprzedaż %d złota"
					% [
						kind,
						BookServiceClass.status_for(_session.player, item_id),
						book.buy_price,
						book.sell_price,
					]
				)
			)
		)
	if definition.heal_hp > 0:
		effects.append("Leczenie: %d PŻ" % definition.heal_hp)
	if definition.heal_hp_percent > 0.0:
		effects.append("Leczenie: %.0f%% maksymalnych PŻ" % definition.heal_hp_percent)
	if definition.restore_mana > 0:
		effects.append("Odnowienie: %d Many" % definition.restore_mana)
	if definition.restore_mana_percent > 0.0:
		effects.append("Odnowienie: %.0f%% maksymalnej Many" % definition.restore_mana_percent)
	if not effects.is_empty():
		effect = "  •  ".join(effects)
	return (
		"%s\nKategoria: %s  •  Liczba: %d  •  Waga stosu: %.2f kg\n%s\n\n%s"
		% [
			definition.display_name,
			_category_name(definition.category),
			_session.player.inventory.count(item_id),
			CarryWeightServiceClass.stack_weight(item_id, _session.player.inventory.count(item_id)),
			effect,
			definition.description,
		]
	)


func _category_name(category: String) -> String:
	return (
		{
			"consumable": "przedmiot użytkowy",
			"material": "materiał",
			"key": "wejściówka",
			"quest": "przedmiot fabularny",
			"book": "księga",
		}
		. get(category, category)
	)
