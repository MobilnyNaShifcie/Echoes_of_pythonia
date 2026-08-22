class_name RiftState
extends RefCounted

const RiftInstanceClass := preload("res://core/rifts/rift_instance.gd")
const RiftExpeditionClass := preload("res://core/rifts/rift_expedition.gd")

var active_rift: RiftInstanceClass
var expedition: RiftExpeditionClass
var next_spawn_day := 2
var last_resolution_day := 0
var completed_total := 0
var completed_by_rank := {}
var last_notice := ""


func has_active_expedition() -> bool:
	return active_rift != null and expedition != null
