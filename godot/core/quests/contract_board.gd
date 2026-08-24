class_name ContractBoard
extends RefCounted

var daily_date := ""
var daily_contracts: Array = []
var daily_claimed: Array[String] = []
var weekly_key := ""
var weekly_contract = null
var weekly_claimed := false
# contract_id -> objective_index_as_string -> progress
var progress := {}


func clear_progress(contract_ids: Array[String]) -> void:
	for contract_id: String in contract_ids:
		progress.erase(contract_id)
