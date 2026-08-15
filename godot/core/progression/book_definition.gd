class_name BookDefinition
extends RefCounted

const MASTERY := "mastery"
const PATH_UNLOCK := "path_unlock"

var item_id: String
var book_type: String
var passive_code: String
var path_id: String
var character_class_code: String
var buy_price: int
var sell_price: int


func _init(
	book_item_id: String,
	type: String,
	passive := "",
	path := "",
	class_code := "",
	buy := 0,
	sell := 0
) -> void:
	item_id = book_item_id
	book_type = type
	passive_code = passive
	path_id = path
	character_class_code = class_code
	buy_price = buy
	sell_price = sell
