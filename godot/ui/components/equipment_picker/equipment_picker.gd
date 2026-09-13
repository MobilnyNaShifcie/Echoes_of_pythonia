extends VBoxContainer
## Selection only. The host decides what service to perform on the selected instance.
signal item_selected(data: Dictionary)
const ViewModel := preload("res://ui/screens/blacksmith_workbench/upgrade_view_model.gd")
const EquipmentScreenClass := preload("res://ui/screens/equipment/equipment.gd")
const Presentation := preload("res://ui/presentation/combat_presentation_catalog.gd")
const Catalog := preload("res://core/items/item_catalog.gd")
const Style := preload("res://ui/screens/blacksmith_workbench/workbench_style.gd")
const Carry := preload("res://core/economy/carry_weight_service.gd")
const MIN_BACKPACK_CELL := 96.0
var _session
var _source := "equipped"
var _selected_id := ""

@onready var character_panel: CharacterEquipmentPanel = %CharacterPanel
@onready var backpack: InventoryGridView = %Backpack
@onready var backpack_scroll: ScrollContainer = %BackpackScroll


func _ready() -> void:
	for button in [%EquippedButton, %BackpackButton]:
		button.pressed.connect(_filter.bind(button.get_meta("source")))
		_style_source_tab(button)
	backpack.entry_selected.connect(_select)
	backpack_scroll.resized.connect(_fit_backpack.call_deferred)
	for slot: String in character_panel.slot_buttons:
		character_panel.slot_buttons[slot].metadata_selected.connect(_select)
	# Local overrides preserve the approved equipment layout and the other screen's theme.
	character_panel.add_theme_stylebox_override("panel", Style.panel(0.6, 0))
	%BackpackPanel.add_theme_stylebox_override("panel", Style.panel(0.94, 12))


func configure(session) -> void:
	_session = session
	_source = "equipped"
	_selected_id = ""
	_filter("equipped")
	character_panel.show_identity(
		session.player.display_name, session.player.level, session.player.character_class_name
	)
	character_panel.character_visual.show_character(
		Presentation.hero_texture_for_player(session.player), "BRAK ILUSTRACJI POSTACI"
	)


func refresh(selected_id := "") -> void:
	_selected_id = selected_id
	if _session == null:
		return
	for slot: String in character_panel.slot_buttons:
		var button: InventoryItemSlot = character_panel.slot_buttons[slot]
		var item = _session.player.equipment.get_item(slot)
		var entry := _entry(item) if item != null else {"placeholder": "◇"}
		entry.slot_caption = EquipmentScreenClass.SLOT_NAMES[slot]
		if item == null:
			entry.tooltip = entry.slot_caption + " — puste"
		button.configure(entry)
		_decorate(button)
	var entries: Array[Dictionary] = []
	for item in _session.player.inventory.equipment_items:
		entries.append(_entry(item))
	var stack_ids: Array = _session.player.inventory.stacks.keys()
	stack_ids.sort()
	for item_id: String in stack_ids:
		var definition = Catalog.get_definition(item_id)
		(
			entries
			. append(
				{
					"title": definition.display_name,
					"icon": definition.icon,
					"rarity": definition.rarity,
					"quantity": _session.player.inventory.count(item_id),
					"tooltip": definition.display_name + "\n" + definition.description,
					"locked": true,
					"lock_reason": "Ten typ przedmiotu nie podlega ulepszaniu.",
					"lock_label": "",
					"footprint": Vector2i.ONE,
				}
			)
		)
	backpack.set_entries(entries)
	var load := Carry.carry_status(_session.player)
	%BackpackSummary.text = (
		"Udźwig %.1f / %.1f kg  ·  Zajęte miejsca: %d"
		% [load.current_kg, load.capacity_kg, entries.size()]
	)
	%BackpackSummary.tooltip_text = %BackpackSummary.text
	for button in backpack.get_children():
		if button is InventoryItemSlot and not button.is_queued_for_deletion():
			_decorate(button)


func _entry(item) -> Dictionary:
	var blocked: bool = item.upgrade_level >= 10
	return {
		"title": item.formatted_name(),
		"icon": item.definition.icon,
		"rarity": item.definition.rarity,
		"tooltip": item.formatted_name() + "\n" + item.definition.description,
		"metadata": ViewModel.payload(item),
		"drag_payload": ViewModel.payload(item),
		"locked": blocked,
		"lock_reason": "Maksymalny poziom +10.",
		"lock_label": "+10" if blocked else "",
		"footprint": Vector2i.ONE,
	}


func _decorate(button: InventoryItemSlot) -> void:
	# Use the existing tooltip/lock semantics without the heavy inventory lock banner.
	button.get_node("LockShade").hide()
	button.get_node("LockRequirement").hide()
	var selected: bool = (
		button.item_metadata.get("instance_id", "") == _selected_id and not _selected_id.is_empty()
	)
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		var style := button.get_theme_stylebox(state).duplicate() as StyleBoxFlat
		style.bg_color = Color(0.065, 0.06, 0.05, 0.9)
		style.shadow_color = Color(1, 0.55, 0.13, 0.34) if selected else Color.TRANSPARENT
		style.shadow_size = 5 if selected else 0
		button.add_theme_stylebox_override(state, style)


func select_equipped(slot: String) -> void:
	var item = _session.player.equipment.get_item(slot)
	if item != null:
		_select(ViewModel.payload(item))


func _select(data: Dictionary) -> void:
	if data.get("kind") == "upgrade_equipment":
		var entry := ViewModel.resolve(_session.player, str(data.get("instance_id", "")))
		if entry.is_empty() or (_source == "backpack" and entry.source == "Założone"):
			return
		if _source == "equipped" and entry.source == "Plecak":
			return
		item_selected.emit(data)


func _filter(source: String) -> void:
	if source not in ["equipped", "backpack"]:
		return
	_source = source
	character_panel.visible = source == "equipped"
	%BackpackPanel.visible = source == "backpack"
	for button in [%EquippedButton, %BackpackButton]:
		button.set_pressed_no_signal(button.get_meta("source") == source)
		button.add_theme_color_override(
			"font_focus_color", Color(0.07, 0.05, 0.02) if button.button_pressed else Style.TEXT
		)
	refresh(_selected_id)
	_fit_backpack.call_deferred()


func _fit_backpack() -> void:
	if _session == null or not backpack_scroll.is_visible_in_tree():
		return
	# Reserve the scrollbar gutter even when empty to prevent layout oscillation.
	var gutter := backpack_scroll.get_v_scroll_bar().get_combined_minimum_size().x + 4.0
	var available := maxf(MIN_BACKPACK_CELL, backpack_scroll.size.x - gutter)
	var columns := clampi(
		floori((available + backpack.gap) / (MIN_BACKPACK_CELL + backpack.gap)), 1, 12
	)
	var side := floorf((available - (columns - 1) * backpack.gap) / columns)
	var rows := maxi(1, floori((backpack_scroll.size.y + backpack.gap) / (side + backpack.gap)))
	if (
		backpack.columns == columns
		and backpack.visible_rows == rows
		and backpack.cell_size == Vector2(side, side)
	):
		return
	backpack.columns = columns
	backpack.visible_rows = rows
	backpack.cell_size = Vector2(side, side)
	# Only presentation entries are rebuilt; inventory instances and anvil selection stay put.
	refresh(_selected_id)


func _style_source_tab(button: Button) -> void:
	for state: String in ["normal", "hover", "pressed", "hover_pressed"]:
		var style := Style.panel(0.97, 16)
		style.border_color = Style.GOLD
		var active := state in ["pressed", "hover_pressed"]
		if active:
			style.bg_color = Style.GOLD.lightened(0.1) if state == "hover_pressed" else Style.GOLD
		elif state == "hover":
			style.bg_color = Color(0.14, 0.11, 0.06, 0.98)
		button.add_theme_stylebox_override(state, style)
		button.add_theme_color_override(
			"font_" + state + "_color" if state != "normal" else "font_color",
			Color(0.07, 0.05, 0.02) if active else Style.TEXT
		)
