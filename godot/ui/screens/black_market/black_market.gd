class_name BlackMarketScreen
extends ScrollContainer

signal back_requested
signal state_changed

const BlackMarketServiceClass := preload("res://core/economy/black_market_service.gd")
const BookCatalogClass := preload("res://core/progression/book_catalog.gd")
const GameSessionClass := preload("res://core/game/game_session.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")

const MODE_BUY := "buy"
const MODE_SELL := "sell"

var _session: GameSessionClass
var _mode := MODE_BUY
var _selected_id := ""
var _rotation_date := ""
var _rng := RandomNumberGenerator.new()

@onready var wallet_label: Label = %WalletLabel
@onready var delivery_label: Label = %DeliveryLabel
@onready var buy_tab: Button = %BuyTab
@onready var sell_tab: Button = %SellTab
@onready var offer_list: ItemList = %OfferList
@onready var category_label: Label = %CategoryLabel
@onready var title_label: Label = %ItemTitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var price_label: Label = %PriceLabel
@onready var status_label: Label = %StatusLabel
@onready var bargain_button: Button = %BargainButton
@onready var action_button: Button = %ActionButton
@onready var result_label: Label = %ResultLabel


func _ready() -> void:
	_rng.randomize()
	%BackButton.pressed.connect(back_requested.emit)
	buy_tab.pressed.connect(_set_mode.bind(MODE_BUY))
	sell_tab.pressed.connect(_set_mode.bind(MODE_SELL))
	offer_list.item_selected.connect(_select_entry)
	bargain_button.pressed.connect(_bargain)
	action_button.pressed.connect(_perform_action)
	_render()
	offer_list.grab_focus()


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
	_render()
	offer_list.grab_focus()


func _select_entry(index: int) -> void:
	_selected_id = str(offer_list.get_item_metadata(index))
	_render_details()


func _render() -> void:
	if _session == null:
		return
	wallet_label.text = "%s  •  Złoto %d" % [_session.player.display_name, _session.player.gold]
	var active_date: String = (
		BlackMarketServiceClass.current_rotation_key()
		if _rotation_date.is_empty()
		else _rotation_date
	)
	delivery_label.text = (
		"Obecna dostawa: %s  •  następna: %s"
		% [
			active_date,
			BlackMarketServiceClass.next_rotation_date(active_date),
		]
	)
	buy_tab.disabled = _mode == MODE_BUY
	sell_tab.disabled = _mode == MODE_SELL
	_refresh_list()
	_render_details()


func _refresh_list() -> void:
	offer_list.clear()
	if _mode == MODE_BUY:
		for offer in _session.black_market.offers:
			var definition = ItemCatalogClass.get_definition(offer.item_id)
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
		"Cena: %d złota  •  ilość: %d"
		% [BlackMarketServiceClass.effective_buy_price(market, offer), offer.quantity]
	)
	status_label.text = (
		"SPRZEDANE" if sold else ("CENA PO TARGOWANIU" if negotiated else "JEDNA PRÓBA TARGOWANIA")
	)
	bargain_button.text = "Cena już negocjowana" if negotiated else "Spróbuj się targować"
	bargain_button.disabled = sold or negotiated
	action_button.text = "Oferta wykupiona" if sold else "Kup"
	action_button.disabled = sold


func _render_sell_details() -> void:
	var market = _session.black_market
	var definition = ItemCatalogClass.get_definition(_selected_id)
	var book = BookCatalogClass.get_definition(_selected_id)
	var negotiated: bool = market.sale_negotiated_prices.has(_selected_id)
	category_label.text = (
		"KSIĘGA MISTRZOSTWA" if book.book_type == "mastery" else "KSIĘGA ŚCIEŻKI"
	)
	title_label.text = definition.display_name
	description_label.text = definition.description
	price_label.text = (
		"Oferta skupu: %d złota / szt.  •  posiadasz: %d"
		% [
			BlackMarketServiceClass.effective_book_sell_price(market, _selected_id),
			_session.player.inventory.count(_selected_id),
		]
	)
	status_label.text = "CENA PO TARGOWANIU" if negotiated else "JEDNA PRÓBA TARGOWANIA"
	bargain_button.text = "Cena już negocjowana" if negotiated else "Spróbuj się targować"
	bargain_button.disabled = negotiated
	action_button.text = "Sprzedaj 1 egzemplarz"
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
	result_label.text = result.message
	if result.ok:
		state_changed.emit()
	_render()


func _perform_action() -> void:
	var result := (
		BlackMarketServiceClass.buy(_session, _selected_id)
		if _mode == MODE_BUY
		else BlackMarketServiceClass.sell_book(_session, _selected_id)
	)
	result_label.text = result.message
	if result.ok:
		state_changed.emit()
	_render()
