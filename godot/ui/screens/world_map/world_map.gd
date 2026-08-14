class_name WorldMapScreen
extends Control

signal back_requested
signal encounter_requested(enemy_id: String)

const AdventureServiceClass := preload("res://core/world/adventure_service.gd")
const GameSessionClass := preload("res://core/game/game_session.gd")
const QuestServiceClass := preload("res://core/quests/quest_service.gd")

var _session: GameSessionClass
var _rng := RandomNumberGenerator.new()

@onready var time_label: Label = %TimeLabel
@onready var player_label: Label = %PlayerLabel
@onready var event_label: Label = %EventLabel
@onready var quest_label: Label = %QuestLabel


func _ready() -> void:
	%BackButton.pressed.connect(back_requested.emit)
	%ExploreButton.pressed.connect(_explore)
	_rng.randomize()
	_render()
	%ExploreButton.grab_focus()


func configure(session: GameSessionClass) -> void:
	_session = session
	if is_node_ready():
		_render()


func _explore() -> void:
	if _session == null:
		return
	var result := AdventureServiceClass.explore_twilight_plains(_session, _rng)
	_render()
	if result.enemy_id.is_empty():
		event_label.text = result.message
	else:
		event_label.text = result.message
		encounter_requested.emit(result.enemy_id)


func _render() -> void:
	if _session == null:
		return
	var player := _session.player
	time_label.text = _session.formatted_time()
	player_label.text = (
		"%s  •  Poziom %d  •  PŻ %d/%d  •  ATK %d  •  DEF %d"
		% [
			player.display_name,
			player.level,
			player.stats.current_hp,
			player.stats.max_hp,
			player.stats.attack,
			player.stats.defense,
		]
	)
	event_label.text = (
		_session.last_activity
		if not _session.last_activity.is_empty()
		else "Wybierz „Wyrusz na wyprawę”. Każda wyprawa przesuwa czas o godzinę."
	)
	var log = _session.quest_log
	if log.is_active(QuestServiceClass.STORY_QUEST_ID):
		quest_label.text = (
			"Śledzona misja: Ci, którzy nie wrócili  •  Wilki %d/2"
			% QuestServiceClass.get_progress(log)
		)
	elif log.is_completed(QuestServiceClass.STORY_QUEST_ID):
		quest_label.text = "Misja „Ci, którzy nie wrócili” ukończona."
	else:
		quest_label.text = "Nowa misja fabularna czeka w Gildii Poszukiwaczy."
