class_name RiftInstance
extends RefCounted

var rift_id := ""
var rank_code := "F"
var theme_id := ""
var theme_name := ""
var modifier_ids: Array[String] = []
var discovered_day := 1
var expires_day := 1
var seed := 0
var segment_count := 0
var boss_id := ""
var boss_name := ""
var closed := false
var closed_by := ""


func _init(data: Dictionary = {}) -> void:
	rift_id = str(data.get("rift_id", ""))
	rank_code = str(data.get("rank_code", "F"))
	theme_id = str(data.get("theme_id", ""))
	theme_name = str(data.get("theme_name", ""))
	modifier_ids.assign(data.get("modifier_ids", []))
	discovered_day = int(data.get("discovered_day", 1))
	expires_day = int(data.get("expires_day", 1))
	seed = int(data.get("seed", 0))
	segment_count = int(data.get("segment_count", 0))
	boss_id = str(data.get("boss_id", ""))
	boss_name = str(data.get("boss_name", ""))
	closed = bool(data.get("closed", false))
	closed_by = str(data.get("closed_by", ""))
