class_name BlackMarketScreen
extends Control

signal back_requested
signal state_changed

const BlackMarketServiceClass := preload("res://core/economy/black_market_service.gd")
const BookCatalogClass := preload("res://core/progression/book_catalog.gd")
const Card = preload("res://ui/screens/black_market/market_offer_card.gd")
const Palette = preload("res://ui/presentation/item_rarity_palette.gd")
const GameSessionClass := preload("res://core/game/game_session.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const InterfaceStyle := preload("res://ui/presentation/interface_style.gd")

const MODE_BUY := "buy"
const MODE_SELL := "sell"
const SOURCE_ART_SIZE := Vector2(1672.0, 941.0)
const MERCHANT_RECT := Rect2(340, 160, 275, 355)
const WINDOW_SIZE := Vector2(1120, 660)

var offer_slots: Array[Button] = []
var _session: GameSessionClass
var _mode := MODE_BUY
var _selected_id := ""
var _rotation_date := ""
var _rng := RandomNumberGenerator.new()

@onready var background: TextureRect = %Background
@onready var offer_layer: Control = %OfferLayer
@onready var offer_window: Panel = %OfferWindow
@onready var merchant_button: Button = %MerchantButton
@onready var delivery_label: Label = %DeliveryLabel
@onready var buy_tab: Button = %BuyTab
@onready var sell_tab: Button = %SellTab
@onready var sell_panel: Panel = %SellPanel
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
	for button: Button in [
		buy_tab, sell_tab, bargain_button, action_button, %BackButton, %CloseButton
	]:
		var style := InterfaceStyle.panel(0.92, Color("8d6b30"))
		style.set_corner_radius_all(5)
		button.add_theme_stylebox_override("normal", style)
		button.add_theme_font_size_override("font_size", 19)
		InterfaceStyle.button_feedback(button)
	var selected := InterfaceStyle.panel(1.0, Color("f5cf77"))
	selected.bg_color = Color("604722")
	selected.set_corner_radius_all(5)
	for button: Button in [buy_tab, sell_tab, action_button]:
		button.add_theme_stylebox_override("pressed", selected)
		button.add_theme_stylebox_override("hover_pressed", selected)
	action_button.add_theme_stylebox_override("normal", selected)
	var book_selection := InterfaceStyle.panel(0.9, Color("ae8948"))
	book_selection.bg_color = Color("30291c")
	book_selection.set_corner_radius_all(4)
	offer_list.add_theme_stylebox_override("selected", book_selection)
	offer_list.add_theme_stylebox_override("selected_focus", book_selection)
	offer_list.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	%BackButton.pressed.connect(back_requested.emit)
	%CloseButton.pressed.connect(close_offers)
	merchant_button.pressed.connect(show_buy_offers)
	%MerchantHint.pressed.connect(show_buy_offers)
	%MerchantHint.mouse_entered.connect(_merchant_feedback.bind(true))
	%MerchantHint.mouse_exited.connect(_merchant_feedback.bind(false))
	merchant_button.mouse_entered.connect(_merchant_feedback.bind(true))
	merchant_button.mouse_exited.connect(_merchant_feedback.bind(false))
	merchant_button.focus_entered.connect(_merchant_feedback.bind(true))
	merchant_button.focus_exited.connect(_merchant_feedback.bind(false))
	buy_tab.pressed.connect(_set_mode.bind(MODE_BUY))
	sell_tab.pressed.connect(_set_mode.bind(MODE_SELL))
	offer_list.item_selected.connect(_select_entry)
	bargain_button.pressed.connect(_bargain)
	action_button.pressed.connect(_perform_action)
	for index in 4:
		var card := Card.new()
		card.name = "OfferCard%d" % (index + 1)
		offer_layer.add_child(card)
		offer_slots.append(card)
		card.offer_selected.connect(_select_offer)
	resized.connect(_layout_market)
	_render()
	_layout_market()


func close_offers() -> void:
	offer_window.hide()
	%MerchantHint.show()
	merchant_button.grab_focus()


func _unhandled_key_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if offer_window.visible:
			close_offers()
		else:
			back_requested.emit()
		get_viewport().set_input_as_handled()


func _merchant_feedback(active: bool) -> void:
	# Mouse/focus exit can arrive while children are being freed during navigation.
	var hint := get_node_or_null("%MerchantHint") as Control
	if is_instance_valid(hint):
		hint.modulate = Color(1.0, 1.0, 1.0, 1.0 if active else 0.75)


func _layout_market() -> void:
	if not is_node_ready() or size.x <= 0 or size.y <= 0:
		return
	# Match the cover-fit background, including ultrawide cropping.
	var art_scale := maxf(size.x / SOURCE_ART_SIZE.x, size.y / SOURCE_ART_SIZE.y)
	var origin := (size - SOURCE_ART_SIZE * art_scale) * 0.5
	merchant_button.position = origin + MERCHANT_RECT.position * art_scale
	merchant_button.size = MERCHANT_RECT.size * art_scale
	%MerchantHint.position = merchant_button.position + Vector2(0, merchant_button.size.y + 12)
	%MerchantHint.size = Vector2(merchant_button.size.x, 32)
	var factor := minf(minf(size.x * 0.625 / WINDOW_SIZE.x, (size.y - 100) / WINDOW_SIZE.y), 1.1)
	factor = maxf(factor, 0.1)
	offer_window.scale = Vector2.ONE * factor
	offer_window.size = WINDOW_SIZE
	offer_window.position = Vector2(
		size.x - WINDOW_SIZE.x * factor - 30, (size.y - WINDOW_SIZE.y * factor) * 0.5
	)


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
	offer_window.show()
	%MerchantHint.hide()
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
	result_label.hide()
	_render_details()
	_refresh_selection()


func _select_entry(index: int) -> void:
	_selected_id = str(offer_list.get_item_metadata(index))
	result_label.hide()
	_render_details()


func _render() -> void:
	if _session == null:
		return
	var active_date: String = (
		BlackMarketServiceClass.current_rotation_key()
		if _rotation_date.is_empty()
		else _rotation_date
	)
	delivery_label.text = (
		"Dostawa %s  ·  Następna %s"
		% [
			active_date,
			BlackMarketServiceClass.next_rotation_date(active_date),
		]
	)
	buy_tab.set_pressed_no_signal(_mode == MODE_BUY)
	sell_tab.set_pressed_no_signal(_mode == MODE_SELL)
	offer_layer.visible = _mode == MODE_BUY
	sell_panel.visible = _mode == MODE_SELL
	_refresh_list()
	_refresh_offer_slots()
	_render_details()
	_refresh_selection()


func _refresh_list() -> void:
	offer_list.clear()
	if _mode == MODE_BUY:
		if BlackMarketServiceClass.find_offer(_session.black_market, _selected_id) == null:
			_selected_id = ""
			for offer in _session.black_market.offers:
				if ItemCatalogClass.get_definition(offer.item_id) != null:
					_selected_id = offer.offer_id
					break
		return
	for item_id: String in BlackMarketServiceClass.books_in_inventory(_session.player):
		var definition = ItemCatalogClass.get_definition(item_id)
		var quantity := _session.player.inventory.count(item_id)
		var row := offer_list.add_item(
			"%s ×%d" % [definition.display_name, quantity], definition.icon
		)
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
		var slot: Button = offer_slots[index]
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
					"rarity": definition.rarity,
					"price_text": _group_digits(effective_price) + " zł",
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
		%QuantityLabel.text = ""
		%DetailIcon.texture = null
		%DetailIconFrame.hide()
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
	_render_definition(definition)
	price_label.text = (
		"%s zł"
		% [
			_group_digits(BlackMarketServiceClass.effective_buy_price(market, offer)),
		]
	)
	%QuantityLabel.text = "Ilość: %d" % offer.quantity
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
	_render_definition(definition)
	price_label.text = (
		"%s zł / szt."
		% [
			_group_digits(BlackMarketServiceClass.effective_book_sell_price(market, _selected_id)),
		]
	)
	%QuantityLabel.text = "Posiadasz: %d" % _session.player.inventory.count(_selected_id)
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
	result_label.tooltip_text = result_label.text
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
	for slot: Button in offer_slots:
		if not slot.disabled:
			slot.grab_focus()
			return


func _render_definition(definition) -> void:
	title_label.text = definition.display_name
	title_label.tooltip_text = definition.display_name
	description_label.text = definition.description
	description_label.tooltip_text = definition.description
	%DetailIcon.texture = definition.icon
	%DetailIconFrame.show()
	var rarity_color := Palette.color_for(definition.rarity)
	category_label.add_theme_color_override("font_color", rarity_color)
	var frame := InterfaceStyle.panel(0.9, rarity_color)
	frame.set_corner_radius_all(4)
	%DetailIconFrame.add_theme_stylebox_override("panel", frame)


func _refresh_selection() -> void:
	for card in offer_slots:
		card.set_selected(_mode == MODE_BUY and card.offer_id == _selected_id)


func _group_digits(value: int) -> String:
	var digits := str(maxi(0, value))
	var result := ""
	for index in digits.length():
		if index > 0 and (digits.length() - index) % 3 == 0:
			result += " "
		result += digits[index]
	return result
