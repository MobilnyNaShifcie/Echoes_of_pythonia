class_name BlackMarketOffer
extends RefCounted

var offer_id: String
var item_id: String
var quantity: int
var base_price: int


func _init(id: String, offered_item_id: String, amount: int, price: int) -> void:
	offer_id = id
	item_id = offered_item_id
	quantity = amount
	base_price = price
