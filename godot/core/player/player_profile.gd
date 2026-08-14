class_name PlayerProfile
extends RefCounted

const STARTING_LEVEL := 0
const STARTING_MAX_HEALTH := 20
const STARTING_WEAPON_ID := "starter_sword"
const STARTING_ARMOR_ID := "worn_leather_armor"

var display_name: String
var level := STARTING_LEVEL
var experience := 0
var health := STARTING_MAX_HEALTH
var max_health := STARTING_MAX_HEALTH
var gold := 0
var rubies := 0
var weapon_id := STARTING_WEAPON_ID
var armor_id := STARTING_ARMOR_ID


func _init(player_name: String) -> void:
	display_name = player_name
