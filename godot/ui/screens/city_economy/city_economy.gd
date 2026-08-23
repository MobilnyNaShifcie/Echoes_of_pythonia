class_name CityEconomyScreen
extends Control

signal back_requested

const CarryWeightServiceClass := preload("res://core/economy/carry_weight_service.gd")
const CraftingServiceClass := preload("res://core/economy/crafting_service.gd")
const EconomyServiceClass := preload("res://core/economy/economy_service.gd")
const GameSessionClass := preload("res://core/game/game_session.gd")
const GuildStorageServiceClass := preload("res://core/economy/guild_storage_service.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const RegionCatalogClass := preload("res://core/world/region_catalog.gd")
const UpgradeServiceClass := preload("res://core/economy/upgrade_service.gd")
const ItemGridLayoutClass := preload("res://ui/components/inventory_grid/item_grid_layout.gd")

const SERVICE_NAMES := {
	"merchant": "Kram Orena",
	"blacksmith": "Kuźnia Garrana",
	"workshop": "Warsztat Mireli",
	"quartermaster": "Kwatermistrz Gildii",
}
const SERVICE_PRESENTATION := {
	"merchant":
	{
		"role": "OREN • KUPIEC",
		"caption": "OREN",
		"hint": "Towary codzienne, zapasy i skup łupów.",
		"accent": Color(0.72, 0.51, 0.22, 0.72),
	},
	"blacksmith":
	{
		"role": "GARRAN • KOWAL",
		"caption": "GARRAN",
		"hint": "Ulepszanie broni i osobistego wyposażenia.",
		"accent": Color(0.72, 0.32, 0.19, 0.72),
	},
	"workshop":
	{
		"role": "MIRELA • RZEMIEŚLNICZKA",
		"caption": "MIRELA",
		"hint": "Receptury regionalne i wytwarzanie przedmiotów.",
		"accent": Color(0.38, 0.63, 0.51, 0.72),
	},
	"quartermaster":
	{
		"role": "KWATERMISTRZ GILDII",
		"caption": "KWATERMISTRZ",
		"hint": "Magazyn Gildii i rozwój udźwigu.",
		"accent": Color(0.38, 0.51, 0.72, 0.72),
	},
}
const MODES := {
	"merchant":
	[
		{"id": "merchant_buy", "name": "Kup przedmioty"},
		{"id": "merchant_sell_stacks", "name": "Sprzedaj materiały i zapasy"},
		{"id": "merchant_sell_equipment", "name": "Sprzedaj wyposażenie z plecaka"},
	],
	"blacksmith": [{"id": "blacksmith", "name": "Ulepsz wyposażenie +0–+10"}],
	"workshop":
	[
		{"id": "workshop_twilight_plains", "name": "Zmierzchowe Równiny"},
		{"id": "workshop_black_forest", "name": "Czarny Bór"},
		{"id": "workshop_silent_water_marshes", "name": "Mokradła Głuchej Wody"},
		{"id": "workshop_ashen_borderlands", "name": "Popielne Pogranicze"},
		{"id": "workshop_ice_coast", "name": "Lodowe Wybrzeże"},
	],
	"quartermaster":
	[
		{"id": "storage_deposit_stacks", "name": "Odłóż materiały i zapasy"},
		{"id": "storage_withdraw_stacks", "name": "Odbierz materiały i zapasy"},
		{"id": "storage_deposit_equipment", "name": "Odłóż wyposażenie"},
		{"id": "storage_withdraw_equipment", "name": "Odbierz wyposażenie"},
		{"id": "carry_upgrade", "name": "Ulepszenia udźwigu"},
	],
}

var _session: GameSessionClass
var _service_id := "merchant"
var _entries: Array[Dictionary] = []

@onready var title_label: Label = %TitleLabel
@onready var summary_label: Label = %SummaryLabel
@onready var mode_selector: OptionButton = %ModeSelector
@onready var item_list: ItemList = %ItemList
@onready var details_label: Label = %DetailsLabel
@onready var quantity_box: SpinBox = %QuantityBox
@onready var action_button: Button = %ActionButton
@onready var status_label: Label = %StatusLabel
@onready var service_grid: InventoryGridView = %ServiceGrid
@onready var transaction_drop_zone: PanelContainer = %TransactionDropZone
@onready var drop_hint_label: Label = %DropHintLabel
@onready var selection_label: Label = %SelectionLabel
@onready var catalogue_title: Label = %CatalogueTitle
@onready var transaction_title: Label = %TransactionTitle
@onready var npc_role_label: Label = %NpcRoleLabel
@onready var npc_hint_label: Label = %NpcHintLabel
@onready var npc_visual: CharacterPaperdoll = %NpcVisual


static func display_name_for(service_id: String) -> String:
	return SERVICE_NAMES.get(service_id, "Gospodarka Varenhold")


func _ready() -> void:
	%BackButton.pressed.connect(back_requested.emit)
	mode_selector.item_selected.connect(_on_mode_selected)
	item_list.item_selected.connect(_on_item_selected)
	quantity_box.value_changed.connect(_on_quantity_changed)
	action_button.pressed.connect(_perform_action)
	service_grid.entry_selected.connect(_select_grid_entry)
	service_grid.entry_hovered.connect(_hover_grid_entry)
	service_grid.entry_activated.connect(_activate_grid_entry)
	(
		transaction_drop_zone
		. set_drag_forwarding(
			_empty_drag_data,
			_transaction_can_drop_data,
			_transaction_drop_data,
		)
	)
	_render_service()


func configure(session: GameSessionClass, service_id: String) -> void:
	_session = session
	_service_id = service_id if SERVICE_NAMES.has(service_id) else "merchant"
	if is_node_ready():
		_render_service()


func _render_service() -> void:
	if _session == null:
		return
	title_label.text = display_name_for(_service_id)
	_render_npc()
	mode_selector.clear()
	for mode: Dictionary in MODES[_service_id]:
		mode_selector.add_item(mode.name)
		mode_selector.set_item_metadata(mode_selector.item_count - 1, mode.id)
	mode_selector.select(0)
	_refresh_current_mode()


func _on_mode_selected(_index: int) -> void:
	_refresh_current_mode()


func _on_item_selected(_index: int) -> void:
	_configure_quantity()
	_render_details()


func _on_quantity_changed(_value: float) -> void:
	_render_details()


func _current_mode() -> String:
	if mode_selector.item_count == 0:
		return ""
	return str(mode_selector.get_item_metadata(mode_selector.selected))


func _selected_entry() -> Dictionary:
	var selected := item_list.get_selected_items()
	if selected.is_empty() or selected[0] < 0 or selected[0] >= _entries.size():
		return {}
	return _entries[selected[0]]


func _refresh_current_mode() -> void:
	_entries = _build_entries(_current_mode())
	item_list.clear()
	for entry: Dictionary in _entries:
		item_list.add_item(entry.label)
	_render_grid()
	if not _entries.is_empty():
		item_list.select(0)
	_configure_quantity()
	_render_summary()
	_render_details()


func _render_npc() -> void:
	var presentation: Dictionary = SERVICE_PRESENTATION[_service_id]
	npc_role_label.text = str(presentation.role)
	npc_hint_label.text = str(presentation.hint)
	npc_visual.caption = str(presentation.caption)
	npc_visual.accent_color = presentation.accent
	npc_visual.queue_redraw()


func _render_grid() -> void:
	var grid_entries: Array[Dictionary] = []
	for index in _entries.size():
		var entry: Dictionary = _entries[index]
		var metadata := {"kind": "service_entry", "index": index}
		var footprint := _entry_footprint(entry)
		(
			grid_entries
			. append(
				{
					"title": entry.label,
					"placeholder": _entry_placeholder(entry),
					"tooltip": _entry_tooltip(entry),
					"metadata": metadata,
					"drag_payload": metadata,
					"footprint": footprint,
				}
			)
		)
	service_grid.set_entries(grid_entries)
	var labels := _mode_labels(_current_mode())
	catalogue_title.text = labels.catalogue
	transaction_title.text = labels.transaction
	drop_hint_label.text = labels.drop_hint


func _select_grid_entry(metadata: Dictionary) -> void:
	var index := int(metadata.get("index", -1))
	if index < 0 or index >= _entries.size():
		return
	item_list.select(index)
	_on_item_selected(index)


func _hover_grid_entry(metadata: Dictionary) -> void:
	var index := int(metadata.get("index", -1))
	if index >= 0 and index < _entries.size():
		details_label.text = _entry_tooltip(_entries[index])


func _activate_grid_entry(metadata: Dictionary) -> void:
	_select_grid_entry(metadata)
	_perform_action()


func _empty_drag_data(_at_position: Vector2) -> Variant:
	return null


func _transaction_can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary or data.get("kind", "") != "service_entry":
		return false
	var index := int(data.get("index", -1))
	return index >= 0 and index < _entries.size()


func _transaction_drop_data(_at_position: Vector2, data: Variant) -> void:
	if not _transaction_can_drop_data(Vector2.ZERO, data):
		return
	_select_grid_entry(data)
	_perform_action()


func _build_entries(mode: String) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if mode.begins_with("workshop_"):
		var region_id := mode.trim_prefix("workshop_")
		for recipe: Dictionary in CraftingServiceClass.get_recipes(region_id):
			(
				entries
				. append(
					{
						"kind": "workshop",
						"recipe": recipe,
						"label": recipe.name,
					}
				)
			)
		return entries
	match mode:
		"merchant_buy":
			for stock: Dictionary in EconomyServiceClass.get_stock():
				var definition = ItemCatalogClass.get_definition(stock.item_id)
				(
					entries
					. append(
						{
							"kind": mode,
							"item_id": stock.item_id,
							"price": stock.buy_price,
							"label": "%s  •  %d złota" % [definition.display_name, stock.buy_price],
						}
					)
				)
		"merchant_sell_stacks", "storage_deposit_stacks":
			for item_id: String in _sorted_stack_ids(_session.player.inventory):
				if (
					mode == "merchant_sell_stacks"
					and EconomyServiceClass.get_stack_sell_price(item_id) < 0
				):
					continue
				entries.append(_stack_entry(mode, item_id, _session.player.inventory))
		"storage_withdraw_stacks":
			for item_id: String in _sorted_stack_ids(_session.guild_storage.inventory):
				entries.append(_stack_entry(mode, item_id, _session.guild_storage.inventory))
		"merchant_sell_equipment", "storage_deposit_equipment":
			entries = _equipment_entries(mode, _session.player.inventory)
		"storage_withdraw_equipment":
			entries = _equipment_entries(mode, _session.guild_storage.inventory)
		"blacksmith":
			for slot: String in _session.player.equipment.slots:
				var item = _session.player.equipment.slots[slot]
				(
					entries
					. append(
						{
							"kind": mode,
							"item": item,
							"label": "Założone • %s" % item.formatted_name(),
						}
					)
				)
			for item in _session.player.inventory.equipment_items:
				entries.append(
					{"kind": mode, "item": item, "label": "Plecak • %s" % item.formatted_name()}
				)
		"carry_upgrade":
			var upgrade := CarryWeightServiceClass.next_upgrade(_session.player)
			if not upgrade.is_empty():
				(
					entries
					. append(
						{
							"kind": mode,
							"upgrade": upgrade,
							"label": "%s  •  %d złota" % [upgrade.name, upgrade.gold],
						}
					)
				)
	return entries


func _stack_entry(mode: String, item_id: String, inventory) -> Dictionary:
	var definition = ItemCatalogClass.get_definition(item_id)
	return {
		"kind": mode,
		"item_id": item_id,
		"owned": inventory.count(item_id),
		"label": "%s ×%d" % [definition.display_name, inventory.count(item_id)],
	}


func _equipment_entries(mode: String, inventory) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for index in inventory.equipment_items.size():
		var item = inventory.equipment_items[index]
		entries.append({"kind": mode, "index": index, "item": item, "label": item.formatted_name()})
	return entries


func _sorted_stack_ids(inventory) -> Array[String]:
	var ids: Array[String] = []
	for item_id: String in inventory.stacks:
		if int(inventory.stacks[item_id]) > 0:
			ids.append(item_id)
	ids.sort_custom(
		func(first: String, second: String) -> bool:
			return (
				ItemCatalogClass.get_definition(first).display_name
				< ItemCatalogClass.get_definition(second).display_name
			)
	)
	return ids


func _entry_footprint(entry: Dictionary) -> Vector2i:
	if entry.has("item"):
		return ItemGridLayoutClass.footprint_for("equipment", entry.item.slot)
	if entry.has("item_id"):
		var definition = ItemCatalogClass.get_definition(str(entry.item_id))
		if definition != null:
			return ItemGridLayoutClass.footprint_for(definition.category, definition.slot)
	if entry.kind in ["workshop", "carry_upgrade"]:
		return Vector2i(2, 1)
	return Vector2i.ONE


func _entry_placeholder(entry: Dictionary) -> String:
	var display_name := str(entry.label)
	if entry.has("item"):
		display_name = entry.item.formatted_name()
	elif entry.has("item_id"):
		var definition = ItemCatalogClass.get_definition(str(entry.item_id))
		if definition != null:
			display_name = definition.display_name
	elif entry.kind == "workshop":
		display_name = str(entry.recipe.name)
	return _initials(display_name)


func _entry_tooltip(entry: Dictionary) -> String:
	var presentation := _entry_presentation(entry, 1)
	return "%s\n\n%s" % [entry.label, presentation.details]


func _initials(display_name: String) -> String:
	var code := ""
	for word: String in display_name.replace("+", " ").split(" ", false):
		if word.is_empty() or word.is_valid_int() or word.begins_with("•"):
			continue
		code += word.left(1).to_upper()
		if code.length() >= 2:
			break
	return code if not code.is_empty() else "?"


func _mode_labels(mode: String) -> Dictionary:
	var labels := {
		"catalogue": "Ulepszenia",
		"transaction": "Zamówienie",
		"drop_hint": "PRZECIĄGNIJ TUTAJ\nABY ZATWIERDZIĆ",
	}
	if mode == "merchant_buy":
		labels = {
			"catalogue": "Towary Orena",
			"transaction": "Zakup",
			"drop_hint": "PRZECIĄGNIJ TUTAJ\nABY KUPIĆ",
		}
	elif mode.begins_with("merchant_sell"):
		labels = {
			"catalogue": "Twój plecak",
			"transaction": "Sprzedaż",
			"drop_hint": "PRZECIĄGNIJ TUTAJ\nABY SPRZEDAĆ",
		}
	elif mode == "blacksmith":
		labels = {
			"catalogue": "Wyposażenie do ulepszenia",
			"transaction": "Stół kowalski",
			"drop_hint": "PRZECIĄGNIJ TUTAJ\nABY ULEPSZYĆ",
		}
	elif mode.begins_with("workshop"):
		labels = {
			"catalogue": "Receptury regionu",
			"transaction": "Stół rzemieślniczy",
			"drop_hint": "PRZECIĄGNIJ TUTAJ\nABY WYTWORZYĆ",
		}
	elif mode.begins_with("storage_deposit"):
		labels = {
			"catalogue": "Twój plecak",
			"transaction": "Magazyn Gildii",
			"drop_hint": "PRZECIĄGNIJ TUTAJ\nABY ODŁOŻYĆ",
		}
	elif mode.begins_with("storage_withdraw"):
		labels = {
			"catalogue": "Magazyn Gildii",
			"transaction": "Twój plecak",
			"drop_hint": "PRZECIĄGNIJ TUTAJ\nABY ODEBRAĆ",
		}
	return labels


func _configure_quantity() -> void:
	var entry := _selected_entry()
	quantity_box.min_value = 1
	quantity_box.step = 1
	quantity_box.value = 1
	quantity_box.editable = true
	if entry.is_empty():
		quantity_box.max_value = 1
		quantity_box.editable = false
		return
	match entry.kind:
		"merchant_sell_stacks", "storage_deposit_stacks", "storage_withdraw_stacks":
			quantity_box.max_value = maxi(1, int(entry.owned))
		"blacksmith":
			quantity_box.max_value = maxi(
				1, UpgradeServiceClass.MAX_UPGRADE_LEVEL - entry.item.upgrade_level
			)
		"merchant_buy":
			quantity_box.max_value = 99
		_:
			quantity_box.max_value = 1
			quantity_box.editable = false


func _render_summary() -> void:
	var load := CarryWeightServiceClass.carry_status(_session.player)
	summary_label.text = (
		"%s  •  poziom %d  •  złoto %d  •  udźwig %.1f/%.1f kg (%s)  •  magazyn %d/%d"
		% [
			_session.player.display_name,
			_session.player.level,
			_session.player.gold,
			load.current_kg,
			load.capacity_kg,
			load.display_name,
			_session.guild_storage.used_slots,
			_session.guild_storage.CAPACITY_SLOTS,
		]
	)


func _render_details() -> void:
	var entry := _selected_entry()
	action_button.disabled = entry.is_empty()
	if entry.is_empty():
		details_label.text = "Brak przedmiotów dostępnych dla tej operacji."
		action_button.text = "Brak dostępnej operacji"
		selection_label.text = "Brak pozycji dla wybranej operacji."
		return
	var quantity := int(quantity_box.value)
	var presentation := _entry_presentation(entry, quantity)
	details_label.text = presentation.details
	action_button.text = presentation.action
	selection_label.text = "%s\n%s" % [entry.label, presentation.action]


func _entry_presentation(entry: Dictionary, quantity: int) -> Dictionary:
	var details := ""
	var action := "Wykonaj operację"
	match entry.kind:
		"merchant_buy":
			var definition = ItemCatalogClass.get_definition(entry.item_id)
			details = (
				"%s\n\nCena: %d × %d = %d złota\nPosiadasz: %d"
				% [
					definition.description,
					entry.price,
					quantity,
					int(entry.price) * quantity,
					_session.player.inventory.count(entry.item_id),
				]
			)
			action = "Kup wybraną ilość"
		"merchant_sell_stacks":
			var price := EconomyServiceClass.get_stack_sell_price(entry.item_id)
			details = (
				"Cena sprzedaży: %d × %d = %d złota\nPosiadasz: %d"
				% [price, quantity, price * quantity, entry.owned]
			)
			action = "Sprzedaj wybraną ilość"
		"merchant_sell_equipment":
			var price := EconomyServiceClass.get_equipment_sell_price(entry.item)
			details = (
				"%s\n\nCena sprzedaży: %d złota" % [entry.item.definition.description, price]
			)
			action = "Sprzedaj egzemplarz"
		"blacksmith":
			var plan := UpgradeServiceClass.get_upgrade_plan(entry.item, quantity)
			details = _format_upgrade_plan(entry.item, plan)
			action = "Ulepsz do +%d" % plan.get("target_level", entry.item.upgrade_level)
		"workshop":
			details = _format_recipe(entry.recipe)
			action = "Wytwórz przedmiot"
		"storage_deposit_stacks", "storage_withdraw_stacks":
			details = (
				"Wybrano: %d z %d szt.\nWaga: %.2f kg"
				% [
					quantity,
					entry.owned,
					CarryWeightServiceClass.stack_weight(entry.item_id, quantity),
				]
			)
			action = (
				"Odłóż do magazynu"
				if entry.kind == "storage_deposit_stacks"
				else "Odbierz z magazynu"
			)
		"storage_deposit_equipment", "storage_withdraw_equipment":
			details = (
				"%s\nWaga: %.1f kg\nIdentyfikator: %s"
				% [
					entry.item.definition.description,
					CarryWeightServiceClass.item_unit_weight(entry.item.item_id),
					entry.item.instance_id,
				]
			)
			action = (
				"Odłóż do magazynu"
				if entry.kind == "storage_deposit_equipment"
				else "Odbierz z magazynu"
			)
		"carry_upgrade":
			var upgrade: Dictionary = entry.upgrade
			details = (
				"Bonus: +%.0f kg\nKoszt: %d złota\nWymagana ranga Gildii: %s\nTwoja ranga: %s"
				% [
					upgrade.bonus_kg,
					upgrade.gold,
					upgrade.required_rank,
					CarryWeightServiceClass.guild_rank_for_reputation(_session.guild_reputation),
				]
			)
			action = "Kup ulepszenie udźwigu"
	return {"details": details, "action": action}


func _format_upgrade_plan(item, plan: Dictionary) -> String:
	if not plan.ok:
		return plan.message
	var lines: Array[String] = [
		"%s: +%d → +%d" % [item.display_name, plan.start_level, plan.target_level],
		"Koszt: %d złota" % plan.gold,
		"Materiały:",
	]
	for item_id: String in plan.materials:
		(
			lines
			. append(
				(
					"• %s %d/%d"
					% [
						ItemCatalogClass.get_definition(item_id).display_name,
						_session.player.inventory.count(item_id),
						plan.materials[item_id],
					]
				)
			)
		)
	return "\n".join(lines)


func _format_recipe(recipe: Dictionary) -> String:
	var region = RegionCatalogClass.get_definition(recipe.region_id)
	var lines: Array[String] = [
		"Region: %s" % (region.display_name if region != null else recipe.region_id),
		"Wynik: %s ×%d" % [recipe.name, recipe.quantity],
		"Koszt: %d złota" % int(recipe.get("gold_cost", 0)),
		"Składniki:",
	]
	for item_id: String in recipe.ingredients:
		(
			lines
			. append(
				(
					"• %s %d/%d"
					% [
						ItemCatalogClass.get_definition(item_id).display_name,
						_session.player.inventory.count(item_id),
						recipe.ingredients[item_id],
					]
				)
			)
		)
	if recipe.has("note"):
		lines.append("\n%s" % recipe.note)
	return "\n".join(lines)


func _perform_action() -> void:
	var entry := _selected_entry()
	if entry.is_empty():
		return
	var quantity := int(quantity_box.value)
	var result := {"ok": false, "message": "Nieobsługiwana operacja."}
	match entry.kind:
		"merchant_buy":
			result = EconomyServiceClass.buy_item(_session.player, entry.item_id, quantity)
		"merchant_sell_stacks":
			result = EconomyServiceClass.sell_stack(_session.player, entry.item_id, quantity)
		"merchant_sell_equipment":
			result = EconomyServiceClass.sell_equipment(_session.player, int(entry.index))
		"blacksmith":
			result = UpgradeServiceClass.upgrade_item(
				_session.player, entry.item, quantity, _session
			)
		"workshop":
			result = CraftingServiceClass.craft(_session.player, entry.recipe.recipe_id)
		"storage_deposit_stacks":
			result = GuildStorageServiceClass.deposit_stack(
				_session.player, _session.guild_storage, entry.item_id, quantity
			)
		"storage_withdraw_stacks":
			result = GuildStorageServiceClass.withdraw_stack(
				_session.player, _session.guild_storage, entry.item_id, quantity
			)
		"storage_deposit_equipment":
			result = GuildStorageServiceClass.deposit_equipment(
				_session.player, _session.guild_storage, int(entry.index)
			)
		"storage_withdraw_equipment":
			result = GuildStorageServiceClass.withdraw_equipment(
				_session.player, _session.guild_storage, int(entry.index)
			)
		"carry_upgrade":
			result = CarryWeightServiceClass.purchase_upgrade(
				_session.player, _session.guild_reputation
			)
	status_label.text = result.message
	if result.ok:
		_session.last_activity = result.message
		_session.log_event(result.message)
	_refresh_current_mode()
