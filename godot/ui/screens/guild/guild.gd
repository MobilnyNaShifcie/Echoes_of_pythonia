class_name GuildScreen
extends Control

signal back_requested

const GameSessionClass := preload("res://core/game/game_session.gd")
const QuestServiceClass := preload("res://core/quests/quest_service.gd")

var _session: GameSessionClass

@onready var status_label: Label = %StatusLabel
@onready var progress_label: Label = %ProgressLabel
@onready var action_button: Button = %ActionButton
@onready var result_label: Label = %ResultLabel


func _ready() -> void:
	%BackButton.pressed.connect(back_requested.emit)
	action_button.pressed.connect(_perform_quest_action)
	_render()
	%BackButton.grab_focus()


func configure(session: GameSessionClass) -> void:
	_session = session
	if is_node_ready():
		_render()


func _perform_quest_action() -> void:
	if _session == null:
		return
	var log = _session.quest_log
	if (
		not log.is_active(QuestServiceClass.STORY_QUEST_ID)
		and not log.is_completed(QuestServiceClass.STORY_QUEST_ID)
	):
		if QuestServiceClass.accept_story_quest(log):
			_session.last_activity = "Przyjęto zadanie: Ci, którzy nie wrócili."
			result_label.text = _session.last_activity
	elif QuestServiceClass.is_ready(log):
		var result := QuestServiceClass.turn_in_story_quest(_session)
		_session.last_activity = "Ukończono zadanie: Ci, którzy nie wrócili."
		result_label.text = (
			"Nagroda: +%d EXP, +%d złota, +%d reputacji Gildii.\n\n%s"
			% [
				result.experience,
				result.gold,
				result.guild_reputation,
				result.completion_text,
			]
		)
	_render()


func _render() -> void:
	if _session == null:
		return
	var log = _session.quest_log
	var quest := QuestServiceClass.STORY_QUEST
	var progress := QuestServiceClass.get_progress(log)
	progress_label.text = (
		(
			"Reputacja Gildii: %d  •  Ranga F — Nowicjusz\n"
			+ "Cel: pokonaj Wilki na Zmierzchowych Równinach  •  %d/%d\n"
			+ "Zalecany poziom: %d  •  Nagroda: %d EXP, %d złota, 40 reputacji Gildii"
		)
		% [
			_session.guild_reputation,
			progress,
			quest.required_count,
			quest.recommended_level,
			quest.reward_exp,
			quest.reward_gold
		]
	)
	if log.is_completed(QuestServiceClass.STORY_QUEST_ID):
		status_label.text = "UKOŃCZONE"
		action_button.disabled = true
		action_button.text = "Zadanie ukończone"
		return
	if log.is_active(QuestServiceClass.STORY_QUEST_ID):
		status_label.text = "GOTOWE DO ODDANIA" if QuestServiceClass.is_ready(log) else "AKTYWNE"
		action_button.disabled = not QuestServiceClass.is_ready(log)
		action_button.text = (
			"Oddaj zadanie" if QuestServiceClass.is_ready(log) else "Wróć po wykonaniu celu"
		)
		return
	status_label.text = "DOSTĘPNE NA TABLICY"
	action_button.disabled = false
	action_button.text = "Przyjmij zadanie"
