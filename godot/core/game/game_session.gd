class_name GameSession
extends RefCounted

const PlayerProfileClass := preload("res://core/player/player_profile.gd")
const STARTING_LOCATION_ID := "twilight_plains"
const STARTING_CITY_ID := "varenhold"
const STARTING_DAY := 1
const STARTING_HOUR := 8

var save_slot: int
var player: PlayerProfileClass
var current_location_id := STARTING_LOCATION_ID
var current_city_id := STARTING_CITY_ID
var day := STARTING_DAY
var hour := STARTING_HOUR
var is_active := true


func _init(slot: int, player_profile: PlayerProfileClass) -> void:
	save_slot = slot
	player = player_profile
