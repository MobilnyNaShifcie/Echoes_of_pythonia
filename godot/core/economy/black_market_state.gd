class_name BlackMarketState
extends RefCounted

var unlocked := false
var informant_last_check_day := 0
var informant_failed_checks := 0
var informant_present_day := 0
var rotation_key := ""
var offers: Array = []
var purchased_offer_ids: Array[String] = []
var buy_negotiated_prices := {}
var sale_negotiated_prices := {}
