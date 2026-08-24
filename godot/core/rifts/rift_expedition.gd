class_name RiftExpedition
extends RefCounted

var rift_id := ""
var segment_index := 0
var party_companion_ids: Array[String] = []
var secured_rewards := {}
var pending_unique_item_id := ""
var started_day := 0
var camp_visits := 0
var defeated := false


func _init(
	initial_rift_id := "",
	initial_segment_index := 0,
	initial_party_companion_ids: Array[String] = [],
	initial_started_day := 0
) -> void:
	rift_id = initial_rift_id
	segment_index = initial_segment_index
	party_companion_ids.assign(initial_party_companion_ids)
	started_day = initial_started_day
