class_name BlackMarketScreen
extends Control

signal back_requested
signal state_changed

const BlackMarketServiceClass := preload("res://core/economy/black_market_service.gd")
const BookCatalogClass := preload("res://core/progression/book_catalog.gd")
const CarryWeightServiceClass := preload("res://core/economy/carry_weight_service.gd")
const GameSessionClass := preload("res://core/game/game_session.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const InterfaceStyle := preload("res://ui/presentation/interface_style.gd")

const MODE_BUY := "buy"
const MODE_SELL := "sell"
const SOURCE_ART_SIZE := Vector2(1672.0, 941.0)
const SOURCE_SLOT_CENTERS := [
	Vector2(263.0, 562.0),
	Vector2(532.0, 541.0),
	Vector2(751.0, 516.0),
	Vector2(958.0, 501.0),
]
const SOURCE_SLOT_SIZES := [
	Vector2(188.0, 136.0),
	Vector2(176.0, 130.0),
	Vector2(162.0, 122.0),
	Vector2(150.0, 116.0),
]
const SOURCE_PAD_CENTERS := [
	Vector2(271.0, 569.0),
	Vector2(525.0, 544.0),
	Vector2(751.0, 521.0),
	Vector2(949.0, 503.0),
]
# Rope mounts on the FRONT wooden lip. Boards hang below these source-art
# anchors, so neither the prices nor their cords cover the leather display mats.
const SOURCE_PRICE_ANCHORS := [
	Vector2(271.0, 628.0),
	Vector2(525.0, 599.0),
	Vector2(751.0, 573.0),
	Vector2(949.0, 550.0),
]
const SOURCE_PRICE_SIZES := [
	Vector2(154.0, 96.25),
	Vector2(148.0, 92.5),
	Vector2(142.0, 88.75),
	Vector2(136.0, 85.0),
]

var _session: GameSessionClass
var _mode := MODE_BUY
var _selected_id := ""
var _rotation_date := ""
var _rng := RandomNumberGenerator.new()

@onready var background: TextureRect = %Background
@onready var offer_layer: Control = %OfferLayer
@onready var offer_slots: Array[BlackMarketOfferSlot] = [
	$OfferLayer/OfferSlot1 as BlackMarketOfferSlot,
	$OfferLayer/OfferSlot2 as BlackMarketOfferSlot,
	$OfferLayer/OfferSlot3 as BlackMarketOfferSlot,
	$OfferLayer/OfferSlot4 as BlackMarketOfferSlot,
]
@onready var wallet_label: Label = %WalletLabel
@onready var carry_label: Label = %CarryLabel
@onready var delivery_label: Label = %DeliveryLabel
@onready var buy_tab: Button = %BuyTab
@onready var sell_tab: Button = %SellTab
@onready var sell_panel: PanelContainer = %SellPanel
@onready var offer_list: ItemList = %OfferList
@onready var category_label: Label = %CategoryLabel
@onready var title_label: Label = %ItemTitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var price_label: Label = %PriceLabel
@onready var status_label: Label = %StatusLabel
@onready var bargain_button: Button = %BargainButton
@onready var action_button: Button = %ActionButton
@onready var inventory_drop_target: BlackMarketDropTarget = %InventoryDropTarget
@onready var drop_carry_label: Label = %DropCarryLabel
@onready var result_label: Label = %ResultLabel


func _ready() -> void:
	_rng.randomize()
	for button in [buy_tab, sell_tab, bargain_button, action_button, %BackButton]:
		InterfaceStyle.button_feedback(button)
	%BackButton.pressed.connect(back_requested.emit)
	buy_tab.pressed.connect(_set_mode.bind(MODE_BUY))
	sell_tab.pressed.connect(_set_mode.bind(MODE_SELL))
	offer_list.item_selected.connect(_select_entry)
	bargain_button.pressed.connect(_bargain)
	action_button.pressed.connect(_perform_action)
	inventory_drop_target.offer_dropped.connect(_purchase_offer)
	for slot: BlackMarketOfferSlot in offer_slots:
		slot.offer_selected.connect(_select_offer)
		slot.offer_activated.connect(_purchase_offer)
	resized.connect(_layout_offer_slots)
	_render()
	call_deferred("_layout_offer_slots")


func configure(session: GameSessionClass, rotation_date := "") -> void:
	_session = session
	_rotation_date = rotation_date
	if BlackMarketServiceClass.ensure_rotation(
		_session.black_market, _session.player.display_name, _rotation_date
	):
		state_changed.emit()
	if is_node_ready():
		_render()


func show_buy_offers() -> void:
	_set_mode(MODE_BUY)


func show_book_sales() -> void:
	_set_mode(MODE_SELL)


func _set_mode(mode: String) -> void:
	_mode = mode
	_selected_id = ""
	result_label.text = ""
	result_label.hide()
	_render()
	_focus_current_mode()


func _select_offer(offer_id: String) -> void:
	if _mode != MODE_BUY or offer_id.is_empty():
		return
	_selected_id = offer_id
	_render_details()


func _select_entry(index: int) -> void:
	_selected_id = str(offer_list.get_item_metadata(index))
	_render_details()


func _render() -> void:
	if _session == null:
		return
	var load := CarryWeightServiceClass.carry_status(_session.player)
	wallet_label.text = (
		"%s  •  Złoto %s"
		% [
			_session.player.display_name,
			_group_digits(_session.player.gold),
		]
	)
	carry_label.text = (
		"Udźwig %.1f/%.1f kg  •  %s"
		% [
			load.current_kg,
			load.capacity_kg,
			load.display_name,
		]
	)
	drop_carry_label.text = "Udźwig: %.1f/%.1f kg" % [load.current_kg, load.capacity_kg]
	var active_date: String = (
		BlackMarketServiceClass.current_rotation_key()
		if _rotation_date.is_empty()
		else _rotation_date
	)
	delivery_label.text = (
		"Dostawa: %s  •  następna: %s"
		% [
			active_date,
			BlackMarketServiceClass.next_rotation_date(active_date),
		]
	)
	buy_tab.disabled = _mode == MODE_BUY
	sell_tab.disabled = _mode == MODE_SELL
	offer_layer.visible = _mode == MODE_BUY
	inventory_drop_target.visible = _mode == MODE_BUY
	sell_panel.visible = _mode == MODE_SELL
	_refresh_list()
	_refresh_offer_slots()
	_render_details()
	call_deferred("_layout_offer_slots")


func _refresh_list() -> void:
	offer_list.clear()
	if _mode == MODE_BUY:
		for offer in _session.black_market.offers:
			var definition = ItemCatalogClass.get_definition(offer.item_id)
			if definition == null:
				continue
			var sold: bool = offer.offer_id in _session.black_market.purchased_offer_ids
			var suffix := " — SPRZEDANE" if sold else ""
			var row := (
				offer_list
				. add_item(
					(
						"%s%s%s"
						% [
							definition.display_name,
							" ×%d" % offer.quantity if offer.quantity > 1 else "",
							suffix,
						]
					)
				)
			)
			offer_list.set_item_metadata(row, offer.offer_id)
	else:
		for item_id: String in BlackMarketServiceClass.books_in_inventory(_session.player):
			var definition = ItemCatalogClass.get_definition(item_id)
			var quantity := _session.player.inventory.count(item_id)
			var row := offer_list.add_item("%s ×%d" % [definition.display_name, quantity])
			offer_list.set_item_metadata(row, item_id)

	if offer_list.item_count == 0:
		_selected_id = ""
		return
	var selected_index := 0
	for index in offer_list.item_count:
		if str(offer_list.get_item_metadata(index)) == _selected_id:
			selected_index = index
	_selected_id = str(offer_list.get_item_metadata(selected_index))
	offer_list.select(selected_index)


func _refresh_offer_slots() -> void:
	if _session == null:
		return
	for index in offer_slots.size():
		var slot: BlackMarketOfferSlot = offer_slots[index]
		if index >= _session.black_market.offers.size():
			slot.clear_offer()
			continue
		var offer = _session.black_market.offers[index]
		var definition = ItemCatalogClass.get_definition(offer.item_id)
		if definition == null:
			slot.clear_offer()
			continue
		var sold: bool = offer.offer_id in _session.black_market.purchased_offer_ids
		var negotiated: bool = _session.black_market.buy_negotiated_prices.has(offer.offer_id)
		var effective_price := BlackMarketServiceClass.effective_buy_price(
			_session.black_market, offer
		)
		(
			slot
			. configure(
				{
					"offer_id": offer.offer_id,
					"item_id": offer.item_id,
					"icon": definition.icon,
					"quantity": offer.quantity,
					"base_price": offer.base_price,
					"effective_price": effective_price,
					"negotiated": negotiated,
					"sold": sold,
					"tooltip":
					(
						"%s\n%s\n\nCena: %s złota%s"
						% [
							definition.display_name,
							definition.description,
							_group_digits(effective_price),
							"  •  ilość: %d" % offer.quantity if offer.quantity > 1 else "",
						]
					),
				}
			)
		)


func _render_details() -> void:
	if _session == null:
		return
	if _selected_id.is_empty():
		category_label.text = "SKUP KSIĄG" if _mode == MODE_SELL else "DZIENNA DOSTAWA"
		title_label.text = "Brak przedmiotów"
		description_label.text = (
			"Nie masz ksiąg na sprzedaż."
			if _mode == MODE_SELL
			else "Dostawa nie zawiera prawidłowych ofert."
		)
		price_label.text = ""
		status_label.text = ""
		bargain_button.disabled = true
		action_button.disabled = true
		return
	if _mode == MODE_BUY:
		_render_buy_details()
	else:
		_render_sell_details()


func _render_buy_details() -> void:
	var market = _session.black_market
	var offer = BlackMarketServiceClass.find_offer(market, _selected_id)
	if offer == null:
		return
	var definition = ItemCatalogClass.get_definition(offer.item_id)
	var book = BookCatalogClass.get_definition(offer.item_id)
	var sold: bool = offer.offer_id in market.purchased_offer_ids
	var negotiated: bool = market.buy_negotiated_prices.has(offer.offer_id)
	category_label.text = (
		("KSIĘGA MISTRZOSTWA" if book.book_type == "mastery" else "KSIĘGA ŚCIEŻKI")
		if book != null
		else "RZADKI TOWAR"
	)
	title_label.text = definition.display_name
	description_label.text = definition.description
	price_label.text = (
		"Cena: %s złota  •  ilość: %d"
		% [
			_group_digits(BlackMarketServiceClass.effective_buy_price(market, offer)),
			offer.quantity,
		]
	)
	status_label.text = (
		"SPRZEDANE" if sold else ("CENA PO TARGOWANIU" if negotiated else "JEDNA PRÓBA TARGOWANIA")
	)
	bargain_button.text = "Cena ustalona" if negotiated else "Targuj"
	bargain_button.disabled = sold or negotiated
	action_button.text = "Sprzedane" if sold else "Kup"
	action_button.disabled = sold


func _render_sell_details() -> void:
	var market = _session.black_market
	var definition = ItemCatalogClass.get_definition(_selected_id)
	var book = BookCatalogClass.get_definition(_selected_id)
	if definition == null or book == null:
		return
	var negotiated: bool = market.sale_negotiated_prices.has(_selected_id)
	category_label.text = (
		"KSIĘGA MISTRZOSTWA" if book.book_type == "mastery" else "KSIĘGA ŚCIEŻKI"
	)
	title_label.text = definition.display_name
	description_label.text = definition.description
	price_label.text = (
		"Oferta skupu: %s złota / szt.  •  posiadasz: %d"
		% [
			_group_digits(BlackMarketServiceClass.effective_book_sell_price(market, _selected_id)),
			_session.player.inventory.count(_selected_id),
		]
	)
	status_label.text = "CENA PO TARGOWANIU" if negotiated else "JEDNA PRÓBA TARGOWANIA"
	bargain_button.text = "Cena ustalona" if negotiated else "Targuj"
	bargain_button.disabled = negotiated
	action_button.text = "Sprzedaj 1"
	action_button.disabled = false


func _bargain() -> void:
	var result := {"ok": false, "message": "Brak wybranej oferty."}
	if _mode == MODE_BUY:
		var offer = BlackMarketServiceClass.find_offer(_session.black_market, _selected_id)
		if offer != null:
			result = BlackMarketServiceClass.bargain_buy(_session.black_market, offer, _rng)
	else:
		result = BlackMarketServiceClass.bargain_book_sale(
			_session.black_market, _selected_id, _rng
		)
	_show_result(result)
	if result.ok:
		state_changed.emit()
	_render()


func _perform_action() -> void:
	var result := (
		BlackMarketServiceClass.buy(_session, _selected_id)
		if _mode == MODE_BUY
		else BlackMarketServiceClass.sell_book(_session, _selected_id)
	)
	_show_result(result)
	if result.ok:
		state_changed.emit()
	_render()


func _purchase_offer(offer_id: String) -> void:
	if _mode != MODE_BUY or offer_id.is_empty():
		return
	_selected_id = offer_id
	var result := BlackMarketServiceClass.buy(_session, offer_id)
	_show_result(result)
	if result.ok:
		state_changed.emit()
	_render()


func _show_result(result: Dictionary) -> void:
	result_label.text = str(result.get("message", ""))
	result_label.visible = not result_label.text.is_empty()
	(
		result_label
		. add_theme_color_override(
			"font_color",
			(
				Color(0.48, 0.85, 0.64, 1.0)
				if bool(result.get("ok", false))
				else Color(0.95, 0.48, 0.45, 1.0)
			),
		)
	)


func _focus_current_mode() -> void:
	if _mode == MODE_SELL:
		if offer_list.visible and offer_list.item_count > 0:
			offer_list.grab_focus()
		return
	for slot: BlackMarketOfferSlot in offer_slots:
		if not slot.disabled:
			slot.grab_focus()
			return


func _layout_offer_slots() -> void:
	if offer_slots.is_empty() or size.x <= 0.0 or size.y <= 0.0:
		return
	var scale_factor := maxf(size.x / SOURCE_ART_SIZE.x, size.y / SOURCE_ART_SIZE.y)
	var drawn_size := SOURCE_ART_SIZE * scale_factor
	var origin := (size - drawn_size) * 0.5
	for index in offer_slots.size():
		var slot: BlackMarketOfferSlot = offer_slots[index]
		var slot_size: Vector2 = SOURCE_SLOT_SIZES[index] * scale_factor
		slot.size = slot_size
		slot.position = origin + SOURCE_SLOT_CENTERS[index] * scale_factor - slot_size * 0.5
		slot.set_counter_anchor(origin + SOURCE_PAD_CENTERS[index] * scale_factor - slot.position)
		(
			slot
			. price_sign
			. hang_from_counter(
				origin + SOURCE_PRICE_ANCHORS[index] * scale_factor - slot.position,
				SOURCE_PRICE_SIZES[index] * scale_factor,
			)
		)


func _group_digits(value: int) -> String:
	var digits := str(maxi(0, value))
	var result := ""
	for index in digits.length():
		if index > 0 and (digits.length() - index) % 3 == 0:
			result += " "
		result += digits[index]
	return result
