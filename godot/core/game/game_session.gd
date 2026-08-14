class_name GameSession
extends RefCounted

const PlayerProfileClass := preload("res://core/player/player_profile.gd")
const QuestLogClass := preload("res://core/quests/quest_log.gd")
const GuildStorageClass := preload("res://core/economy/guild_storage.gd")
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
var prologue_stage := 0
var prologue_completed := false
var quest_log := QuestLogClass.new()
var guild_reputation := 0
var last_activity := ""
var victories := 0
var last_inn_rest_day := 0
var guild_storage := GuildStorageClass.new()


func _init(slot: int, player_profile: PlayerProfileClass) -> void:
	save_slot = slot
	player = player_profile


func advance_hours(hours := 1) -> bool:
	if hours < 0:
		return false
	var total_hours := hour + hours
	day += int(total_hours / 24.0)
	hour = total_hours % 24
	return true


func period_code() -> String:
	return "day" if hour >= 6 and hour < 18 else "night"


func period_name() -> String:
	return "DZIEŃ" if period_code() == "day" else "NOC"


func formatted_time() -> String:
	return "Dzień %d  •  %02d:00  •  %s" % [day, hour, period_name()]
