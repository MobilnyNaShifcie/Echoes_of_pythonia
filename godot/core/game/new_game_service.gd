class_name NewGameService
extends RefCounted

const GameSessionClass := preload("res://core/game/game_session.gd")
const PlayerProfileClass := preload("res://core/player/player_profile.gd")
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


func create_session(raw_name: String, save_slot: int) -> GameSessionClass:
	if not get_player_name_error(raw_name).is_empty():
		return null
	if not get_save_slot_error(save_slot).is_empty():
		return null

	var player := PlayerProfileClass.new(normalize_player_name(raw_name))
	return GameSessionClass.new(save_slot, player)
