class_name CityEconomyScreen
extends Control

signal back_requested
signal state_changed

const BlackMarketServiceClass := preload("res://core/economy/black_market_service.gd")
const CarryWeightServiceClass := preload("res://core/economy/carry_weight_service.gd")
const CraftingServiceClass := preload("res://core/economy/crafting_service.gd")
const EconomyServiceClass := preload("res://core/economy/economy_service.gd")
const GameSessionClass := preload("res://core/game/game_session.gd")
const GuildStorageServiceClass := preload("res://core/economy/guild_storage_service.gd")
const InnServiceClass := preload("res://core/economy/inn_service.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const RegionCatalogClass := preload("res://core/world/region_catalog.gd")
const UpgradeServiceClass := preload("res://core/economy/upgrade_service.gd")
const ItemGridLayoutClass := preload("res://ui/components/inventory_grid/item_grid_layout.gd")
const MerchantTradeViewModelClass := preload(
	"res://ui/screens/city_economy/merchant_trade_view_model.gd"
)
const ServiceViewModelClass := preload("res://ui/screens/city_economy/service_view_model.gd")
const ServiceLayout := preload("res://ui/screens/city_economy/service_layout.gd")

const NPC_TEXTURES := {
	"merchant": preload("res://assets/city/varenhold/npcs/oren_counter_v6.png"),
	"blacksmith": preload("res://assets/city/varenhold/npcs/garran_forging_v5.png"),
	"workshop": preload("res://assets/city/varenhold/npcs/mirela_counter_v3.png"),
	"inn": preload("res://assets/city/varenhold/npcs/runa_innkeeper_v7.png"),
}
const LOCATION_BACKGROUNDS := {
	"merchant":
	preload("res://assets/city/varenhold/interiors/oren_stall_anime_wide_integrated_v2.png"),
	"blacksmith":
	preload("res://assets/city/varenhold/interiors/garran_forge_anime_integrated_v4.png"),
	"workshop":
	preload("res://assets/city/varenhold/interiors/mirela_workshop_anime_integrated_v5.png"),
	"inn": preload("res://assets/city/varenhold/interiors/inn_tavern_anime_wide_integrated_v5.png"),
}
const INN_INFORMANT_BACKGROUND := preload(
	"res://assets/city/varenhold/interiors/inn_tavern_anime_wide_informant_integrated_v5.png"
)
const INFORMANT_HIGHLIGHT_CENTER := Vector2(0.755, 0.67)
const INFORMANT_HIGHLIGHT_RADIUS := Vector2(0.085, 0.20)

const SERVICE_NAMES := {
	"merchant": "Kram Orena",
	"blacksmith": "Kuźnia Garrana",
	"workshop": "Warsztat Mireli",
	"inn": "Karczma Pod Pękniętym Dzwonem",
}
const SERVICE_PRESENTATION := {
	"merchant":
	{
		"role": "OREN • KUPIEC",
		"caption": "OREN",
		"hint": "Towary codzienne, zapasy i skup łupów.",
		"greeting": "Oren poprawia towary na ladzie i czeka na twoją decyzję.",
		"action": "Otwórz sklep",
		"accent": Color(0.72, 0.51, 0.22, 0.72),
		"zoom": 1.0,
		"offset": Vector2.ZERO,
		"anchor_x": 0.63,
		"ambient_scale": 0.72,
		"ambient_shift": Vector2(0, -85),
		"clip_bottom_ratio": 1.0,
		"ambient_width": 1200.0,
		"counter_y": 0.71,
		"counter_slope": -0.04,
		"counter_right": 0.67,
		"highlight_center": Vector2(0.44, 0.45),
		"highlight_radius": Vector2(0.09, 0.21),
		"hit_polygon":
		[
			Vector2(0.435, 0.264),
			Vector2(0.452, 0.268),
			Vector2(0.465, 0.292),
			Vector2(0.460, 0.331),
			Vector2(0.451, 0.365),
			Vector2(0.475, 0.394),
			Vector2(0.492, 0.550),
			Vector2(0.515, 0.609),
			Vector2(0.520, 0.630),
			Vector2(0.404, 0.636),
			Vector2(0.382, 0.614),
			Vector2(0.365, 0.567),
			Vector2(0.364, 0.500),
			Vector2(0.377, 0.412),
			Vector2(0.413, 0.366),
			Vector2(0.420, 0.341),
			Vector2(0.418, 0.301),
			Vector2(0.425, 0.280),
		],
	},
	"blacksmith":
	{
		"role": "GARRAN • KOWAL",
		"caption": "GARRAN",
		"hint": "Ulepszanie broni i osobistego wyposażenia.",
		"greeting":
		"Garran kończy uderzenie, odkłada rozgrzany metal i spogląda na twoje wyposażenie.",
		"action": "Przejdź do ulepszania",
		"accent": Color(0.72, 0.32, 0.19, 0.72),
		"zoom": 0.9,
		"offset": Vector2(34, 10),
		"ambient_shift": Vector2(70, 8),
		"clip_bottom_ratio": 1.0,
		"ambient_width": 1000.0,
		"highlight_center": Vector2(0.36, 0.47),
		"highlight_radius": Vector2(0.15, 0.40),
		"hit_center": Vector2(0.36, 0.47),
		"hit_radius": Vector2(0.14, 0.39),
	},
	"workshop":
	{
		"role": "MIRELA • RZEMIEŚLNICZKA",
		"caption": "MIRELA",
		"hint": "Receptury regionalne i wytwarzanie przedmiotów.",
		"greeting": "Mirela odkłada fiolkę na ladę. Możesz przejrzeć jej regionalne receptury.",
		"action": "Zobacz receptury",
		"accent": Color(0.38, 0.63, 0.51, 0.72),
		"zoom": 1.0,
		"offset": Vector2.ZERO,
		"anchor_x": 0.48,
		"ambient_scale": 0.51,
		"ambient_shift": Vector2(10, 0),
		"clip_bottom_ratio": 1.0,
		"ambient_width": 860.0,
		"counter_y": 0.66,
		"counter_slope": -0.08,
		"counter_right": 0.64,
		"highlight_center": Vector2(0.26, 0.45),
		"highlight_radius": Vector2(0.10, 0.23),
		"hit_center": Vector2(0.26, 0.45),
		"hit_radius": Vector2(0.10, 0.23),
	},
	"inn":
	{
		"role": "RUNA • KARCZMARKA",
		"caption": "RUNA",
		"hint": "Nocleg, osobisty magazyn i rozwój udźwigu.",
		"greeting":
		"Runa kończy polerować kufel. Możesz wynająć pokój albo skorzystać ze swojej skrytki.",
		"action": "Przejdź do usług karczmy",
		"accent": Color(0.66, 0.39, 0.27, 0.72),
		"zoom": 0.96,
		"offset": Vector2(0, -22),
		"anchor_x": 0.28,
		"ambient_scale": 0.83,
		"ambient_shift": Vector2(144, -24),
		"clip_bottom_ratio": 1.0,
		"clip_bottom_slope": 0.0,
		"ambient_width": 860.0,
		"counter_y": 0.50,
		"counter_slope": -0.12,
		"counter_right": 0.58,
		"counter_shade": 1.0,
		"highlight_center": Vector2(0.335, 0.45),
		"highlight_radius": Vector2(0.11, 0.20),
		"hit_center": Vector2(0.335, 0.45),
		"hit_radius": Vector2(0.11, 0.20),
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
	"inn":
	[
		{"id": "inn_rest", "name": "Nocleg i odpoczynek"},
		{"id": "storage_deposit_stacks", "name": "Odłóż materiały i zapasy"},
		{"id": "storage_withdraw_stacks", "name": "Odbierz materiały i zapasy"},
		{"id": "storage_deposit_equipment", "name": "Odłóż wyposażenie"},
		{"id": "storage_withdraw_equipment", "name": "Odbierz wyposażenie"},
		{"id": "carry_upgrade", "name": "Ulepszenia udźwigu"},
	],
}

var service_layout: Node

var _session: GameSessionClass
var _service_id := "merchant"
var _entries: Array[Dictionary] = []
var _interaction_state := "ambient"
var _informant_present := false

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
@onready var location_background: TextureRect = %LocationBackground
@onready var location_shade: ColorRect = %LocationShade
@onready var npc_integrated_highlight: TextureRect = %NpcIntegratedHighlight
@onready var counter_foreground: TextureRect = %CounterForeground
@onready var columns: Control = %Columns
@onready var service_toolbar: HBoxContainer = %ServiceToolbar
@onready var close_service_button: Button = %CloseServiceButton
@onready var catalogue_panel: PanelContainer = %CataloguePanel
@onready var transaction_panel: PanelContainer = %TransactionPanel
@onready var npc_panel: PanelContainer = %NpcPanel
@onready var npc_hit_area: NpcAlphaHitButton = %NpcHitArea
@onready var npc_interaction_hint: Label = %NpcInteractionHint
@onready var npc_action_panel: PanelContainer = %NpcActionPanel
@onready var interaction_title: Label = %InteractionTitle
@onready var interaction_description: Label = %InteractionDescription
@onready var open_service_button: Button = %OpenServiceButton
@onready var close_interaction_button: Button = %CloseInteractionButton
@onready var informant_glow: TextureRect = %InformantGlow
@onready var informant_hit_area: Button = %InformantHitArea
@onready var informant_action_panel: PanelContainer = %InformantActionPanel
@onready var informant_unlock_button: Button = %InformantUnlockButton
@onready var merchant_trade_overlay: Control = %MerchantTradeOverlay
@onready var merchant_stock_grid: InventoryGridView = %MerchantStockGrid
@onready var merchant_player_grid: InventoryGridView = %MerchantPlayerGrid
@onready var merchant_stock_title: Label = %MerchantStockTitle
@onready var merchant_selection_icon: TextureRect = %MerchantSelectionIcon
@onready var merchant_selection_name: Label = %MerchantSelectionName
@onready var merchant_selection_price: Label = %MerchantSelectionPrice
@onready var merchant_quantity_box: SpinBox = %MerchantQuantityBox
@onready var merchant_action_button: Button = %MerchantActionButton


static func display_name_for(service_id: String) -> String:
	return SERVICE_NAMES.get(service_id, "Gospodarka Varenhold")


func _ready() -> void:
	%BackButton.pressed.connect(back_requested.emit)
	mode_selector.item_selected.connect(_on_mode_selected)
	item_list.item_selected.connect(_on_item_selected)
	quantity_box.value_changed.connect(_on_quantity_changed)
	action_button.pressed.connect(_perform_action)
	npc_hit_area.pressed.connect(_focus_npc)
	npc_hit_area.mouse_entered.connect(_set_npc_hover.bind(true))
	npc_hit_area.mouse_exited.connect(_set_npc_hover.bind(false))
	npc_visual.resized.connect(_queue_npc_hit_area_update)
	location_background.resized.connect(_queue_npc_hit_area_update)
	open_service_button.pressed.connect(_open_service)
	close_interaction_button.pressed.connect(_show_ambient_view)
	informant_hit_area.pressed.connect(_focus_informant)
	informant_hit_area.mouse_entered.connect(_set_informant_hover.bind(true))
	informant_hit_area.mouse_exited.connect(_set_informant_hover.bind(false))
	informant_unlock_button.pressed.connect(_meet_informant)
	%CloseInformantButton.pressed.connect(_show_ambient_view)
	close_service_button.pressed.connect(_focus_npc)
	service_grid.entry_selected.connect(_select_grid_entry)
	service_grid.entry_hovered.connect(_hover_grid_entry)
	service_grid.entry_activated.connect(_activate_grid_entry)
	merchant_stock_grid.entry_selected.connect(_select_grid_entry)
	merchant_stock_grid.entry_hovered.connect(_hover_grid_entry)
	merchant_stock_grid.entry_activated.connect(_activate_grid_entry)
	merchant_quantity_box.value_changed.connect(_on_merchant_quantity_changed)
	merchant_action_button.pressed.connect(_perform_action)
	(
		transaction_drop_zone
		. set_drag_forwarding(
			_empty_drag_data,
			_transaction_can_drop_data,
			_transaction_drop_data,
		)
	)
	service_layout = ServiceLayout.new()
	add_child(service_layout)
	service_layout.configure(self)
	_render_service()


func configure(
	session: GameSessionClass,
	service_id: String,
	informant_rng: RandomNumberGenerator = null,
) -> void:
	_session = session
	_service_id = service_id if SERVICE_NAMES.has(service_id) else "merchant"
	_informant_present = false
	if _service_id == "inn":
		var informant_result := BlackMarketServiceClass.check_informant_for_day(
			_session, informant_rng
		)
		_informant_present = bool(informant_result.present)
		if informant_result.checked:
			state_changed.emit()
	if is_node_ready():
		_render_service()


func _render_service() -> void:
	if _session == null:
		return
	status_label.text = ""
	status_label.visible = false
	title_label.text = display_name_for(_service_id)
	_render_npc()
	mode_selector.clear()
	var available_modes: Array = MODES[_service_id].duplicate(true)
	for mode: Dictionary in available_modes:
		mode_selector.add_item(mode.name)
		mode_selector.set_item_metadata(mode_selector.item_count - 1, mode.id)
	mode_selector.select(0)
	_refresh_current_mode()
	_show_ambient_view()


func _on_mode_selected(_index: int) -> void:
	_refresh_current_mode()


func _on_item_selected(_index: int) -> void:
	_configure_quantity()
	_render_details()
	if service_layout != null:
		service_layout.update_selection()


func _on_quantity_changed(_value: float) -> void:
	if not is_equal_approx(merchant_quantity_box.value, quantity_box.value):
		merchant_quantity_box.set_value_no_signal(quantity_box.value)
	_render_details()


func _on_merchant_quantity_changed(value: float) -> void:
	quantity_box.set_value_no_signal(value)
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
	if service_layout != null:
		service_layout.refresh.call_deferred()


func _render_npc() -> void:
	var presentation: Dictionary = SERVICE_PRESENTATION[_service_id]
	_apply_informant_presence()
	npc_role_label.text = str(presentation.role)
	npc_hint_label.text = str(presentation.hint)
	npc_visual.caption = str(presentation.caption)
	npc_visual.accent_color = presentation.accent
	npc_visual.character_zoom = float(presentation.zoom)
	npc_visual.character_offset = presentation.offset
	npc_visual.character_anchor_x = float(presentation.get("anchor_x", 0.5))
	npc_visual.character_clip_bottom_ratio = float(presentation.clip_bottom_ratio)
	npc_visual.character_clip_bottom_slope = float(presentation.get("clip_bottom_slope", 0.0))
	npc_visual.show_character(NPC_TEXTURES[_service_id], str(presentation.caption))
	npc_visual.self_modulate = Color(1, 1, 1, 0) if _uses_integrated_npc() else Color.WHITE
	location_shade.visible = not _uses_integrated_npc()
	_configure_integrated_highlight(presentation)
	_configure_counter_foreground(presentation)
	_queue_npc_hit_area_update()
	npc_hit_area.tooltip_text = ""
	interaction_title.text = str(presentation.caption).capitalize()
	interaction_description.text = str(presentation.greeting)
	open_service_button.text = str(presentation.action)


func _show_ambient_view() -> void:
	_set_interaction_state("ambient")


func _focus_npc() -> void:
	_set_interaction_state("focused")


func _focus_informant() -> void:
	if _service_id == "inn" and _informant_present:
		_set_interaction_state("informant")


func _open_service() -> void:
	_set_interaction_state("service")


func _set_interaction_state(state: String) -> void:
	_interaction_state = state
	var service_open := state == "service"
	var merchant_open := service_open and _service_id == "merchant"
	service_toolbar.visible = service_open
	catalogue_panel.visible = service_open and not merchant_open
	transaction_panel.visible = service_open and not merchant_open
	merchant_trade_overlay.visible = merchant_open
	npc_action_panel.visible = state == "focused"
	informant_action_panel.visible = state == "informant" and _informant_present
	counter_foreground.visible = (
		not service_open and _service_id != "blacksmith" and not _uses_integrated_npc()
	)
	npc_integrated_highlight.visible = false
	npc_interaction_hint.visible = false
	npc_hit_area.disabled = service_open
	informant_hit_area.visible = (_service_id == "inn" and _informant_present and not service_open)
	informant_hit_area.disabled = not informant_hit_area.visible
	var presentation: Dictionary = SERVICE_PRESENTATION[_service_id]
	npc_panel.size_flags_horizontal = Control.SIZE_FILL
	var npc_panel_size := npc_panel.custom_minimum_size
	npc_panel_size.x = float(presentation.ambient_width)
	npc_panel.custom_minimum_size = npc_panel_size
	_apply_npc_stage_scale()
	_queue_npc_hit_area_update()
	_set_npc_hover(false)
	_set_informant_hover(false)
	if service_layout != null:
		service_layout.refresh.call_deferred()


func _apply_npc_stage_scale() -> void:
	var presentation: Dictionary = SERVICE_PRESENTATION[_service_id]
	var base_zoom := float(presentation.zoom)
	npc_visual.character_zoom = base_zoom * float(presentation.get("ambient_scale", 1.08))
	npc_visual.character_anchor_x = float(presentation.get("anchor_x", 0.5))
	npc_visual.character_offset = (
		presentation["offset"] + presentation.get("ambient_shift", Vector2.ZERO)
	)
	npc_visual.queue_redraw()


func _queue_npc_hit_area_update() -> void:
	_update_npc_hit_area.call_deferred()


func _update_npc_hit_area() -> void:
	if not is_instance_valid(npc_hit_area) or location_background.texture == null:
		return
	var presentation: Dictionary = SERVICE_PRESENTATION[_service_id]
	if presentation.has("hit_polygon"):
		npc_hit_area.configure_art_region(
			location_background, PackedVector2Array(presentation.hit_polygon)
		)
		return
	var center: Vector2 = presentation.hit_center
	var radius: Vector2 = presentation.hit_radius
	# Hit coordinates and shader coordinates refer to the same source image, even when cropped.
	(
		npc_hit_area
		. configure_art_region(
			location_background,
			PackedVector2Array(
				[
					center - radius,
					center + Vector2(radius.x, -radius.y),
					center + radius,
					center + Vector2(-radius.x, radius.y),
				]
			)
		)
	)


func _set_npc_hover(hovered: bool) -> void:
	if _uses_integrated_npc():
		npc_visual.modulate = Color.WHITE
		npc_integrated_highlight.visible = hovered and _interaction_state != "service"
		return
	if _interaction_state == "service":
		npc_visual.modulate = Color.WHITE
		return
	npc_visual.modulate = Color.WHITE if hovered else Color(0.82, 0.86, 0.92, 1.0)


func _set_informant_hover(hovered: bool) -> void:
	informant_glow.visible = (
		hovered and _service_id == "inn" and _informant_present and _interaction_state != "service"
	)


func _meet_informant() -> void:
	if _session == null or _service_id != "inn" or not _informant_present:
		return
	var result := BlackMarketServiceClass.unlock(_session)
	status_label.text = result.message
	status_label.visible = true
	if not result.ok:
		return
	_informant_present = false
	_apply_informant_presence()
	state_changed.emit()
	_show_ambient_view()


func _apply_informant_presence() -> void:
	if not is_node_ready():
		return
	var show_informant := _service_id == "inn" and _informant_present
	location_background.texture = (
		INN_INFORMANT_BACKGROUND if show_informant else _location_texture()
	)
	counter_foreground.texture = location_background.texture
	npc_integrated_highlight.texture = location_background.texture
	informant_glow.texture = INN_INFORMANT_BACKGROUND
	var informant_material := informant_glow.material as ShaderMaterial
	if informant_material != null:
		informant_material.set_shader_parameter("glow_center", INFORMANT_HIGHLIGHT_CENTER)
		informant_material.set_shader_parameter("glow_radius", INFORMANT_HIGHLIGHT_RADIUS)
	informant_glow.visible = false
	informant_hit_area.visible = show_informant and _interaction_state != "service"
	informant_hit_area.disabled = not informant_hit_area.visible
	if not show_informant and _interaction_state == "informant":
		_interaction_state = "ambient"


func _uses_integrated_npc() -> bool:
	return _service_id in ["merchant", "blacksmith", "workshop", "inn"]


func _location_texture() -> Texture2D:
	return LOCATION_BACKGROUNDS[_service_id]


func _configure_integrated_highlight(presentation: Dictionary) -> void:
	npc_integrated_highlight.texture = location_background.texture
	npc_integrated_highlight.visible = false
	var highlight_material := npc_integrated_highlight.material as ShaderMaterial
	if highlight_material == null or not _uses_integrated_npc():
		return
	highlight_material.set_shader_parameter(
		"highlight_center", presentation.get("highlight_center", Vector2(0.5, 0.5))
	)
	highlight_material.set_shader_parameter(
		"highlight_radius", presentation.get("highlight_radius", Vector2(0.15, 0.35))
	)


func _configure_counter_foreground(presentation: Dictionary) -> void:
	counter_foreground.texture = location_background.texture
	var counter_material := counter_foreground.material as ShaderMaterial
	if counter_material == null:
		return
	counter_material.set_shader_parameter("counter_y", float(presentation.get("counter_y", 1.0)))
	counter_material.set_shader_parameter(
		"counter_slope", float(presentation.get("counter_slope", 0.0))
	)
	counter_material.set_shader_parameter("counter_left", 0.0)
	counter_material.set_shader_parameter(
		"counter_right", float(presentation.get("counter_right", 1.0))
	)
	counter_material.set_shader_parameter(
		"background_shade", float(presentation.get("counter_shade", 0.8))
	)


func _render_grid() -> void:
	var grid_entries: Array[Dictionary] = []
	for index in _entries.size():
		var entry: Dictionary = _entries[index]
		if entry.kind in ["inn_rest", "carry_upgrade"]:
			continue
		var metadata := {"kind": "service_entry", "index": index}
		var footprint := _entry_footprint(entry)
		var definition = _entry_definition(entry)
		(
			grid_entries
			. append(
				{
					"title": entry.label,
					"placeholder": _entry_placeholder(entry),
					"icon": definition.icon if definition != null else null,
					"rarity": definition.rarity if definition != null else "common",
					"quantity": _entry_quantity(entry),
					"tooltip": _entry_tooltip(entry),
					"metadata": metadata,
					"drag_payload": metadata,
					"footprint": footprint,
				}
			)
		)
	service_grid.set_entries(grid_entries)
	merchant_stock_grid.set_entries(grid_entries)
	merchant_player_grid.set_entries(
		MerchantTradeViewModelClass.build_player_grid_entries(_session.player.inventory)
	)
	var labels := ServiceViewModelClass.mode_labels(_current_mode())
	catalogue_title.text = labels.catalogue
	merchant_stock_title.text = str(labels.catalogue).to_upper()
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
		"inn_rest":
			var cost := InnServiceClass.rest_cost(_session.player)
			(
				entries
				. append(
					{
						"kind": mode,
						"label": "Nocleg i pełny odpoczynek  •  %d złota" % cost,
					}
				)
			)
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
	var definition = _entry_definition(entry)
	if definition != null:
		return ItemGridLayoutClass.footprint_for(definition.category, definition.slot)
	if entry.kind in ["carry_upgrade", "inn_rest"]:
		return Vector2i(2, 1)
	return Vector2i.ONE


func _entry_placeholder(entry: Dictionary) -> String:
	var display_name := str(entry.label)
	var definition = _entry_definition(entry)
	if definition != null:
		display_name = definition.display_name
	return _initials(display_name)


func _entry_definition(entry: Dictionary):
	if entry.has("item") and entry.item != null:
		return entry.item.definition
	if entry.has("item_id"):
		return ItemCatalogClass.get_definition(str(entry.item_id))
	if entry.kind == "workshop":
		return ItemCatalogClass.get_definition(str(entry.recipe.output_item_id))
	return null


func _entry_quantity(entry: Dictionary) -> int:
	if entry.has("owned"):
		return int(entry.owned)
	if entry.kind == "workshop":
		return int(entry.recipe.get("quantity", 1))
	return 0


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


func _configure_quantity() -> void:
	var entry := _selected_entry()
	quantity_box.min_value = 1
	quantity_box.step = 1
	quantity_box.value = 1
	quantity_box.editable = true
	merchant_quantity_box.min_value = 1
	merchant_quantity_box.step = 1
	merchant_quantity_box.set_value_no_signal(1)
	merchant_quantity_box.editable = true
	if entry.is_empty():
		quantity_box.max_value = 1
		quantity_box.editable = false
		merchant_quantity_box.max_value = 1
		merchant_quantity_box.editable = false
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
	merchant_quantity_box.max_value = quantity_box.max_value
	merchant_quantity_box.editable = quantity_box.editable


func _render_summary() -> void:
	var load := CarryWeightServiceClass.carry_status(_session.player)
	summary_label.text = (
		"Złoto %d  •  Plecak %.1f / %.1f kg"
		% [
			_session.player.gold,
			load.current_kg,
			load.capacity_kg,
		]
	)
	if _service_id == "inn":
		summary_label.text += (
			"  •  Skrytka %d / %d"
			% [_session.guild_storage.used_slots, _session.guild_storage.CAPACITY_SLOTS]
		)


func _render_details() -> void:
	var entry := _selected_entry()
	action_button.disabled = entry.is_empty()
	merchant_action_button.disabled = entry.is_empty()
	if entry.is_empty():
		details_label.text = "Brak przedmiotów dostępnych dla tej operacji."
		action_button.text = "Brak dostępnej operacji"
		selection_label.text = "Brak pozycji dla wybranej operacji."
		merchant_selection_icon.texture = null
		merchant_selection_name.text = "Brak dostępnych przedmiotów"
		merchant_selection_price.text = ""
		merchant_action_button.text = "Brak dostępnej operacji"
		return
	var quantity := int(quantity_box.value)
	var presentation := _entry_presentation(entry, quantity)
	details_label.text = presentation.details
	action_button.text = presentation.action
	merchant_action_button.text = presentation.action
	selection_label.text = "%s\n\n%s" % [entry.label, presentation.details]
	if entry.kind == "inn_rest":
		selection_label.text = presentation.details
		action_button.disabled = not InnServiceClass.get_rest_error(_session).is_empty()
	var definition = _entry_definition(entry)
	merchant_selection_icon.texture = definition.icon if definition != null else null
	merchant_selection_name.text = (
		definition.display_name if definition != null else str(entry.label)
	)
	merchant_selection_price.text = MerchantTradeViewModelClass.price_summary(entry, quantity)


func _entry_presentation(entry: Dictionary, quantity: int) -> Dictionary:
	var details := ""
	var action := "Wykonaj operację"
	match entry.kind:
		"inn_rest":
			var cost := InnServiceClass.rest_cost(_session.player)
			var rest_error := InnServiceClass.get_rest_error(_session)
			details = (
				"Pełny odpoczynek odnawia PŻ i Manę.\nCzas: %d godzin  •  Koszt: %d złota"
				% [InnServiceClass.DURATION_HOURS, cost]
			)
			if not rest_error.is_empty():
				details += "\n\n%s" % rest_error
			action = "Wynajmij pokój"
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
		"inn_rest":
			result = InnServiceClass.rest(_session)
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
	status_label.visible = true
	if result.ok:
		_session.last_activity = result.message
		if entry.kind != "inn_rest":
			_session.log_event(result.message)
		state_changed.emit()
	_refresh_current_mode()
