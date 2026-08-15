class_name ContractDefinition
extends RefCounted

const DAILY := "daily"
const WEEKLY := "weekly"

var contract_id: String
var category: String
var period_key: String
var title: String
var description: String
var recommended_level: int
var objectives: Array
var reward_exp: int
var reward_gold: int
var reward_item_id: String
var reward_item_quantity: int


func _init(id: String, data: Dictionary) -> void:
	contract_id = id
	category = str(data.get("category", DAILY))
	period_key = str(data.get("period_key", ""))
	title = str(data.get("title", id))
	description = str(data.get("description", ""))
	recommended_level = int(data.get("recommended_level", 0))
	objectives = data.get("objectives", []).duplicate()
	reward_exp = int(data.get("reward_exp", 0))
	reward_gold = int(data.get("reward_gold", 0))
	reward_item_id = str(data.get("reward_item_id", ""))
	reward_item_quantity = int(data.get("reward_item_quantity", 0))
