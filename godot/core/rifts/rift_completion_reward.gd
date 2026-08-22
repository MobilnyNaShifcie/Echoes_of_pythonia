class_name RiftCompletionReward
extends RefCounted

var gold := 0
var experience := 0
var unique_item_id := ""
var unique_item_name := ""
var player_levels_gained := 0
var companion_levels_gained := {}


func _init(initial_gold := 0, initial_experience := 0) -> void:
	gold = initial_gold
	experience = initial_experience
