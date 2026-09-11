class_name BlackMarketService
extends RefCounted

const BlackMarketOfferClass := preload("res://core/economy/black_market_offer.gd")
const BookCatalogClass := preload("res://core/progression/book_catalog.gd")
const CarryWeightServiceClass := preload("res://core/economy/carry_weight_service.gd")
const GuildProgressionServiceClass := preload("res://core/quests/guild_progression_service.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const MathClass := preload("res://core/math/legacy_math.gd")

const CONTACT_RANK := "C"
const INFORMANT_CHANCE := 0.20
const INFORMANT_PITY_FAILED_CHECKS := 4
const BARGAIN_SUCCESS_CHANCE := 0.30
const OFFER_COUNT := 4
const MASTERY_BOOK_CHANCE := 0.55
const PATH_BOOK_CHANCE := 0.08
const REQUIRED_DUNGEON_MILESTONES := [
	"dungeon:sunken_order_crypt",
	"dungeon:black_fleet_wreck",
]
const MARKET_GOODS := [
	{"item_id": "spark_of_life", "quantity": 1, "price": 8500},
	{"item_id": "common_essence", "quantity": 3, "price": 4800},
	{"item_id": "grandmaster_elixir", "quantity": 1, "price": 7500},
	{"item_id": "black_pearl", "quantity": 2, "price": 7000},
	{"item_id": "leviathan_scale", "quantity": 1, "price": 13000},
	{"item_id": "hearth_core", "quantity": 1, "price": 9500},
	{"item_id": "azhar_sigil", "quantity": 1, "price": 12000},
]


static func informant_eligible(session) -> bool:
	if not GuildProgressionServiceClass.has_rank(session.guild_reputation, CONTACT_RANK):
		return false
	for milestone_id: String in REQUIRED_DUNGEON_MILESTONES:
		if milestone_id in session.guild_milestones:
			return true
	return false


static func check_informant_for_day(session, rng: RandomNumberGenerator = null) -> Dictionary:
	var market = session.black_market
	if market.unlocked or not informant_eligible(session):
		return {"checked": false, "present": false}
	if market.informant_last_check_day == session.day:
		return {
			"checked": false,
			"present": market.informant_present_day == session.day,
		}

	market.informant_last_check_day = session.day
	var guaranteed: bool = market.informant_failed_checks >= INFORMANT_PITY_FAILED_CHECKS
	var present := guaranteed or _get_rng(rng).randf() < INFORMANT_CHANCE
	if present:
		market.informant_present_day = session.day
		market.informant_failed_checks = 0
	else:
		market.informant_present_day = 0
		market.informant_failed_checks += 1
	return {"checked": true, "present": present, "guaranteed": guaranteed}


static func unlock(session) -> Dictionary:
	var market = session.black_market
	if market.unlocked:
		return {"ok": false, "message": "Czarny Rynek jest już odblokowany."}
	if market.informant_present_day != session.day:
		return {"ok": false, "message": "Informatora nie ma już w Karczmie."}
	market.unlocked = true
	market.informant_present_day = 0
	var message := "Odkryto drogę na Czarny Rynek."
	session.last_activity = message
	session.log_event(message)
	return {"ok": true, "message": message}


static func current_rotation_key() -> String:
	return Time.get_date_string_from_system()


static func next_rotation_date(date_key := "") -> String:
	var current_key: String = current_rotation_key() if date_key.is_empty() else date_key
	var unix := _date_key_to_unix(current_key)
	if unix < 0:
		return ""
	return Time.get_date_string_from_unix_time(unix + 86400)


static func ensure_rotation(market, player_name: String, date_key := "") -> bool:
	if not market.unlocked:
		return false
	var key: String = current_rotation_key() if date_key.is_empty() else date_key
	if _date_key_to_unix(key) < 0:
		return false
	if market.rotation_key == key and not market.offers.is_empty():
		return false
	var rng := _rotation_rng(player_name, key)
	var offers: Array = []
	var book_roll := rng.randf()
	var book_item_id := ""
	if book_roll < PATH_BOOK_CHANCE:
		book_item_id = _choice(_path_book_ids(), rng)
	elif book_roll < MASTERY_BOOK_CHANCE:
		book_item_id = _choice(_mastery_book_ids(), rng)
	if not book_item_id.is_empty():
		var book = BookCatalogClass.get_definition(book_item_id)
		offers.append(BlackMarketOfferClass.new("%s:book" % key, book_item_id, 1, book.buy_price))

	var goods := MARKET_GOODS.duplicate(true)
	_shuffle(goods, rng)
	for good: Dictionary in goods:
		if offers.size() >= OFFER_COUNT:
			break
		(
			offers
			. append(
				(
					BlackMarketOfferClass
					. new(
						"%s:%d" % [key, offers.size()],
						good.item_id,
						good.quantity,
						good.price,
					)
				)
			)
		)
	market.rotation_key = key
	market.offers = offers
	market.purchased_offer_ids.clear()
	market.buy_negotiated_prices.clear()
	market.sale_negotiated_prices.clear()
	return true


static func effective_buy_price(market, offer) -> int:
	return int(market.buy_negotiated_prices.get(offer.offer_id, offer.base_price))


static func bargain_buy(market, offer, rng: RandomNumberGenerator = null) -> Dictionary:
	if offer.offer_id in market.purchased_offer_ids:
		return {"ok": false, "message": "Ta oferta została już wykupiona."}
	if market.buy_negotiated_prices.has(offer.offer_id):
		return {"ok": false, "message": "Cena tej oferty była już negocjowana."}
	var bargain_rng := _get_rng(rng)
	var old_price: int = offer.base_price
	var success := bargain_rng.randf() < BARGAIN_SUCCESS_CHANCE
	var factor := (
		bargain_rng.randf_range(0.85, 0.90) if success else bargain_rng.randf_range(1.05, 1.10)
	)
	var new_price := _round_price(old_price * factor)
	market.buy_negotiated_prices[offer.offer_id] = new_price
	return {
		"ok": true,
		"success": success,
		"old_price": old_price,
		"new_price": new_price,
		"message": _bargain_message(success, old_price, new_price),
	}


static func buy(session, offer_id: String) -> Dictionary:
	var market = session.black_market
	if not market.unlocked:
		return {"ok": false, "message": "Czarny Rynek nie jest odblokowany."}
	var offer = find_offer(market, offer_id)
	if offer == null:
		return {"ok": false, "message": "Nieznana oferta Czarnego Rynku."}
	if offer.offer_id in market.purchased_offer_ids:
		return {"ok": false, "message": "Ta oferta została już wykupiona."}
	var price := effective_buy_price(market, offer)
	if session.player.gold < price:
		return {
			"ok": false,
			"message": "Brakuje złota. Potrzeba %d, masz %d." % [price, session.player.gold],
		}
	var current_weight := CarryWeightServiceClass.inventory_weight(session.player.inventory)
	var added_weight := CarryWeightServiceClass.stack_weight(offer.item_id, offer.quantity)
	var capacity := CarryWeightServiceClass.carry_capacity(session.player)
	if current_weight + added_weight > capacity + 0.000000001:
		return {
			"ok": false,
			"message":
			"Brak udźwigu. Po zakupie: %.1f/%.1f kg." % [current_weight + added_weight, capacity],
		}
	if not session.player.inventory.add(offer.item_id, offer.quantity):
		return {"ok": false, "message": "Nie udało się dodać przedmiotu do plecaka."}
	session.player.gold -= price
	market.purchased_offer_ids.append(offer.offer_id)
	var definition = ItemCatalogClass.get_definition(offer.item_id)
	var message := "Czarny Rynek: kupiono %s za %d złota." % [definition.display_name, price]
	session.last_activity = message
	session.log_event(message)
	return {"ok": true, "message": message, "paid": price, "offer": offer}


static func books_in_inventory(player) -> Array[String]:
	var result: Array[String] = []
	for item_id: String in BookCatalogClass.BOOK_ORDER:
		if player.inventory.count(item_id) > 0:
			result.append(item_id)
	return result


static func effective_book_sell_price(market, item_id: String) -> int:
	var book = BookCatalogClass.get_definition(item_id)
	if book == null:
		return 0
	return int(market.sale_negotiated_prices.get(item_id, book.sell_price))


static func bargain_book_sale(
	market, item_id: String, rng: RandomNumberGenerator = null
) -> Dictionary:
	var book = BookCatalogClass.get_definition(item_id)
	if book == null:
		return {"ok": false, "message": "Nieznana księga."}
	if market.sale_negotiated_prices.has(item_id):
		return {
			"ok": false,
			"message": "Cena tej księgi była już negocjowana w tej dostawie.",
		}
	var bargain_rng := _get_rng(rng)
	var old_price: int = book.sell_price
	var success := bargain_rng.randf() < BARGAIN_SUCCESS_CHANCE
	var factor := (
		bargain_rng.randf_range(1.10, 1.15) if success else bargain_rng.randf_range(0.90, 0.95)
	)
	var new_price := _round_price(old_price * factor)
	market.sale_negotiated_prices[item_id] = new_price
	return {
		"ok": true,
		"success": success,
		"old_price": old_price,
		"new_price": new_price,
		"message": _bargain_message(success, old_price, new_price),
	}


static func sell_book(session, item_id: String) -> Dictionary:
	var market = session.black_market
	if not market.unlocked:
		return {"ok": false, "message": "Czarny Rynek nie jest odblokowany."}
	var definition = ItemCatalogClass.get_definition(item_id)
	if BookCatalogClass.get_definition(item_id) == null or definition == null:
		return {"ok": false, "message": "Nieznana księga."}
	if not session.player.inventory.has(item_id, 1):
		return {"ok": false, "message": "Nie posiadasz tej księgi."}
	var price := effective_book_sell_price(market, item_id)
	if not session.player.inventory.remove_item(item_id, 1):
		return {"ok": false, "message": "Nie udało się sprzedać księgi."}
	session.player.add_gold(price)
	var message := "Czarny Rynek: sprzedano %s za %d złota." % [definition.display_name, price]
	session.last_activity = message
	session.log_event(message)
	return {"ok": true, "message": message, "earned": price, "item_id": item_id}


static func find_offer(market, offer_id: String):
	for offer in market.offers:
		if offer.offer_id == offer_id:
			return offer
	return null


static func serialize(market) -> Dictionary:
	var offers: Array[Dictionary] = []
	for offer in market.offers:
		(
			offers
			. append(
				{
					"offer_id": offer.offer_id,
					"item_id": offer.item_id,
					"quantity": offer.quantity,
					"base_price": offer.base_price,
				}
			)
		)
	return {
		"unlocked": market.unlocked,
		"informant_last_check_day": market.informant_last_check_day,
		"informant_failed_checks": market.informant_failed_checks,
		"informant_present_day": market.informant_present_day,
		"rotation_key": market.rotation_key,
		"offers": offers,
		"purchased_offer_ids": market.purchased_offer_ids.duplicate(),
		"buy_negotiated_prices": market.buy_negotiated_prices.duplicate(true),
		"sale_negotiated_prices": market.sale_negotiated_prices.duplicate(true),
	}


static func deserialize(data: Dictionary, market) -> String:
	var validation_error := validate_serialized(data)
	if not validation_error.is_empty():
		return validation_error
	market.unlocked = data.unlocked
	market.informant_last_check_day = int(data.informant_last_check_day)
	market.informant_failed_checks = int(data.informant_failed_checks)
	market.informant_present_day = int(data.informant_present_day)
	market.rotation_key = data.rotation_key
	market.offers.clear()
	for raw_offer: Dictionary in data.offers:
		(
			market
			. offers
			. append(
				(
					BlackMarketOfferClass
					. new(
						raw_offer.offer_id,
						raw_offer.item_id,
						int(raw_offer.quantity),
						int(raw_offer.base_price),
					)
				)
			)
		)
	market.purchased_offer_ids.assign(data.purchased_offer_ids)
	market.buy_negotiated_prices = data.buy_negotiated_prices.duplicate(true)
	market.sale_negotiated_prices = data.sale_negotiated_prices.duplicate(true)
	return ""


static func validate_serialized(data: Dictionary) -> String:
	if (
		not data.get("unlocked") is bool
		or not _is_non_negative_integer(data.get("informant_last_check_day"))
		or not _is_non_negative_integer(data.get("informant_failed_checks"))
		or not _is_non_negative_integer(data.get("informant_present_day"))
		or not data.get("rotation_key") is String
		or not data.get("offers") is Array
		or not data.get("purchased_offer_ids") is Array
		or not data.get("buy_negotiated_prices") is Dictionary
		or not data.get("sale_negotiated_prices") is Dictionary
	):
		return "Zapis zawiera nieprawidłowy stan Czarnego Rynku."
	if int(data.informant_failed_checks) > INFORMANT_PITY_FAILED_CHECKS:
		return "Zapis zawiera nieprawidłowy licznik informatora."
	if (
		int(data.informant_present_day) > 0
		and (int(data.informant_present_day) != int(data.informant_last_check_day) or data.unlocked)
	):
		return "Zapis zawiera nieprawidłowy stan informatora."
	if data.offers.size() > OFFER_COUNT:
		return "Zapis zawiera zbyt wiele ofert Czarnego Rynku."
	if not data.rotation_key.is_empty() and _date_key_to_unix(data.rotation_key) < 0:
		return "Zapis zawiera nieprawidłową datę rotacji Czarnego Rynku."
	if data.rotation_key.is_empty() != data.offers.is_empty():
		return "Zapis zawiera niekompletną rotację Czarnego Rynku."
	if not data.unlocked and not data.rotation_key.is_empty():
		return "Zapis zawiera dostawę przed odblokowaniem Czarnego Rynku."
	if not data.rotation_key.is_empty() and data.offers.size() != OFFER_COUNT:
		return "Zapis nie zawiera czterech ofert Czarnego Rynku."

	var offer_ids := {}
	for raw_offer in data.offers:
		var offer_error := _validate_offer(raw_offer, data.rotation_key)
		if not offer_error.is_empty():
			return offer_error
		if offer_ids.has(raw_offer.offer_id):
			return "Zapis zawiera powtórzoną ofertę Czarnego Rynku."
		offer_ids[raw_offer.offer_id] = true
	var purchased := {}
	for offer_id_value in data.purchased_offer_ids:
		if not offer_id_value is String:
			return "Zapis zawiera nieprawidłową wykupioną ofertę."
		var offer_id := str(offer_id_value)
		if not offer_ids.has(offer_id) or purchased.has(offer_id):
			return "Zapis zawiera nieznaną albo powtórzoną wykupioną ofertę."
		purchased[offer_id] = true
	for offer_id_value in data.buy_negotiated_prices:
		var offer_id := str(offer_id_value)
		if (
			not offer_ids.has(offer_id)
			or not _is_positive_integer(data.buy_negotiated_prices[offer_id_value])
		):
			return "Zapis zawiera nieprawidłową cenę zakupu Czarnego Rynku."
	for item_id_value in data.sale_negotiated_prices:
		var item_id := str(item_id_value)
		if (
			BookCatalogClass.get_definition(item_id) == null
			or not _is_positive_integer(data.sale_negotiated_prices[item_id_value])
		):
			return "Zapis zawiera nieprawidłową cenę skupu Czarnego Rynku."
	return ""


static func _validate_offer(data, rotation_key: String) -> String:
	if (
		not data is Dictionary
		or not data.get("offer_id") is String
		or not str(data.offer_id).begins_with(rotation_key + ":")
		or not data.get("item_id") is String
		or not _is_positive_integer(data.get("quantity"))
		or not _is_positive_integer(data.get("base_price"))
	):
		return "Zapis zawiera nieprawidłową ofertę Czarnego Rynku."
	var item_id := str(data.item_id)
	var book = BookCatalogClass.get_definition(item_id)
	if book != null:
		if int(data.quantity) != 1 or int(data.base_price) != book.buy_price:
			return "Zapis zawiera zmienioną ofertę księgi."
		return ""
	for good: Dictionary in MARKET_GOODS:
		if good.item_id == item_id:
			if int(data.quantity) != good.quantity or int(data.base_price) != good.price:
				return "Zapis zawiera zmienioną ofertę towaru."
			return ""
	return "Zapis wskazuje nieznany towar Czarnego Rynku."


static func _round_price(value: float) -> int:
	return maxi(50, MathClass.python_roundi(value / 50.0) * 50)


static func _bargain_message(success: bool, old_price: int, new_price: int) -> String:
	var result := "Targowanie udane." if success else "Targowanie nieudane."
	return "%s Cena: %d → %d złota." % [result, old_price, new_price]


static func _rotation_rng(player_name: String, key: String) -> RandomNumberGenerator:
	var digest := ("EchoesOfPythonia|black-market|%s|%s" % [player_name, key]).sha256_text()
	var rng := RandomNumberGenerator.new()
	rng.seed = digest.left(15).hex_to_int()
	return rng


static func _mastery_book_ids() -> Array[String]:
	var result: Array[String] = []
	for item_id: String in BookCatalogClass.BOOK_ORDER:
		if BookCatalogClass.get_definition(item_id).book_type == "mastery":
			result.append(item_id)
	return result


static func _path_book_ids() -> Array[String]:
	var result: Array[String] = []
	for item_id: String in BookCatalogClass.BOOK_ORDER:
		if BookCatalogClass.get_definition(item_id).book_type == "path_unlock":
			result.append(item_id)
	return result


static func _choice(values: Array[String], rng: RandomNumberGenerator) -> String:
	return values[rng.randi_range(0, values.size() - 1)]


static func _shuffle(values: Array, rng: RandomNumberGenerator) -> void:
	for index in range(values.size() - 1, 0, -1):
		var swap_index := rng.randi_range(0, index)
		var current = values[index]
		values[index] = values[swap_index]
		values[swap_index] = current


static func _date_key_to_unix(date_key: String) -> int:
	var parts := date_key.split("-")
	if parts.size() != 3:
		return -1
	var date := {"year": int(parts[0]), "month": int(parts[1]), "day": int(parts[2])}
	var unix := int(Time.get_unix_time_from_datetime_dict(date))
	return unix if Time.get_date_string_from_unix_time(unix) == date_key else -1


static func _get_rng(rng: RandomNumberGenerator) -> RandomNumberGenerator:
	if rng != null:
		return rng
	var fallback := RandomNumberGenerator.new()
	fallback.randomize()
	return fallback


static func _is_integer(value) -> bool:
	return (value is int or value is float) and is_equal_approx(float(value), floorf(float(value)))


static func _is_non_negative_integer(value) -> bool:
	return _is_integer(value) and int(value) >= 0


static func _is_positive_integer(value) -> bool:
	return _is_integer(value) and int(value) > 0
