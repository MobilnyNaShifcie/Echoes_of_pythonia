class_name GameSession
extends RefCounted

const PlayerProfileClass := preload("res://core/player/player_profile.gd")
const AdventureLogClass := preload("res://core/game/adventure_log.gd")
const BlackMarketStateClass := preload("res://core/economy/black_market_state.gd")
const QuestLogClass := preload("res://core/quests/quest_log.gd")
const ContractBoardClass := preload("res://core/quests/contract_board.gd")
const GuildStorageClass := preload("res://core/economy/guild_storage.gd")
const RegionCatalogClass := preload("res://core/world/region_catalog.gd")
const WeatherServiceClass := preload("res://core/world/weather_service.gd")
const PartyStateClass := preload("res://core/companions/party_state.gd")
const ExpeditionPreparationStateClass := preload("res://core/world/expedition_preparation_state.gd")
const CompanionRelationshipServiceClass := preload(
	"res://core/companions/companion_relationship_service.gd"
)
const CompanionCasualtyServiceClass := preload(
	"res://core/companions/companion_casualty_service.gd"
)
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
var contract_board := ContractBoardClass.new()
var guild_reputation := 0
var guild_milestones: Array[String] = []
var adventure_log := AdventureLogClass.new()
var black_market := BlackMarketStateClass.new()
var last_activity := ""
var victories := 0
var last_inn_rest_day := 0
var guild_storage := GuildStorageClass.new()
var known_region_ids: Array[String] = []
var weather_code := WeatherServiceClass.SUNNY
var weather_remaining_hours := WeatherServiceClass.DURATION_HOURS
var camp_rest_available := true
var last_weather_changes: Array[Dictionary] = []
var party := PartyStateClass.new()
var expedition_preparation := ExpeditionPreparationStateClass.new()


func _init(slot: int, player_profile: PlayerProfileClass) -> void:
	save_slot = slot
	player = player_profile
	known_region_ids.assign(RegionCatalogClass.REGION_ORDER)


func advance_hours(hours := 1, rng: RandomNumberGenerator = null) -> bool:
	if hours < 0:
		return false
	var total_hours := hour + hours
	day += int(total_hours / 24.0)
	hour = total_hours % 24
	WeatherServiceClass.advance(self, hours, rng)
	for companion_name: String in CompanionCasualtyServiceClass.refresh_injuries(party, day):
		log_event("%s wraca do sił i znów może wyruszać z drużyną." % companion_name)
	CompanionRelationshipServiceClass.ensure_daily_party_message(party, day, player.display_name)
	for change: Dictionary in last_weather_changes:
		log_event("Pogoda zmienia się: %s." % WeatherServiceClass.display_name_for(str(change.to)))
	return true


func log_event(message: String) -> void:
	adventure_log.add(day, hour, message)


func period_code() -> String:
	return "day" if hour >= 6 and hour < 18 else "night"


func period_name() -> String:
	return "DZIEŃ" if period_code() == "day" else "NOC"


func formatted_time() -> String:
	return "Dzień %d  •  %02d:00  •  %s" % [day, hour, period_name()]
