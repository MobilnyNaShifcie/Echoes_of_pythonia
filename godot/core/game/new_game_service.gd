class_name NewGameService
extends RefCounted

const GameSessionClass := preload("res://core/game/game_session.gd")
const PlayerFactoryClass := preload("res://core/player/player_factory.gd")
const PlayerProfileClass := preload("res://core/player/player_profile.gd")
const WeatherServiceClass := preload("res://core/world/weather_service.gd")
const MINIMUM_NAME_LENGTH := 2
const MAXIMUM_NAME_LENGTH := 20
const SAVE_SLOT_COUNT := 4


func normalize_player_name(raw_name: String) -> String:
	return raw_name.strip_edges()


func get_player_name_error(raw_name: String) -> String:
	var normalized_name := normalize_player_name(raw_name)
	if normalized_name.length() < MINIMUM_NAME_LENGTH:
		return "Imię musi mieć co najmniej %d znaki." % MINIMUM_NAME_LENGTH
	if normalized_name.length() > MAXIMUM_NAME_LENGTH:
		return "Imię może mieć maksymalnie %d znaków." % MAXIMUM_NAME_LENGTH
	return ""


func get_save_slot_error(save_slot: int) -> String:
	if save_slot < 1 or save_slot > SAVE_SLOT_COUNT:
		return "Wybierz slot zapisu od 1 do %d." % SAVE_SLOT_COUNT
	return ""


func get_gender_error(gender_code: String) -> String:
	if gender_code not in PlayerProfileClass.SELECTABLE_GENDERS:
		return "Wybierz płeć postaci."
	return ""


func create_session(
	raw_name: String,
	save_slot: int,
	rng: RandomNumberGenerator = null,
	gender_code := "",
) -> GameSessionClass:
	if not get_player_name_error(raw_name).is_empty():
		return null
	if not get_save_slot_error(save_slot).is_empty():
		return null
	if not gender_code.is_empty() and not get_gender_error(gender_code).is_empty():
		return null

	var player := PlayerFactoryClass.create_player(normalize_player_name(raw_name))
	if not gender_code.is_empty() and not player.choose_gender(gender_code):
		return null
	var session := GameSessionClass.new(save_slot, player)
	WeatherServiceClass.initialize(session, rng)
	session.log_event("Rozpoczęto przygodę.")
	return session
