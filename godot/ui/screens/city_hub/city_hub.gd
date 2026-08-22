class_name CityHubScreen
extends Control

signal world_map_requested
signal guild_requested
signal hero_requested
signal adventure_log_requested
signal achievements_requested
signal classes_requested
signal service_requested(service_id: String)
signal main_menu_requested

const GameSessionClass := preload("res://core/game/game_session.gd")
const GuildProgressionServiceClass := preload("res://core/quests/guild_progression_service.gd")

var _session: GameSessionClass

@onready var time_label: Label = %TimeLabel
@onready var player_label: Label = %PlayerLabel
@onready var activity_label: Label = %ActivityLabel
@onready var class_button: Button = %ClassButton
@onready var black_market_button: Button = %BlackMarketButton


func _ready() -> void:
	%GateButton.pressed.connect(service_requested.emit.bind("preparation"))
	%QuartermasterButton.pressed.connect(service_requested.emit.bind("quartermaster"))
	%BlacksmithButton.pressed.connect(service_requested.emit.bind("blacksmith"))
	%WorkshopButton.pressed.connect(service_requested.emit.bind("workshop"))
	%MerchantButton.pressed.connect(service_requested.emit.bind("merchant"))
	%InnButton.pressed.connect(service_requested.emit.bind("inn"))
	%GuildButton.pressed.connect(guild_requested.emit)
	%HeroButton.pressed.connect(hero_requested.emit)
	%AdventureLogButton.pressed.connect(adventure_log_requested.emit)
	%AchievementsButton.pressed.connect(achievements_requested.emit)
	%PreparationButton.pressed.connect(service_requested.emit.bind("preparation"))
	class_button.pressed.connect(classes_requested.emit)
	black_market_button.pressed.connect(service_requested.emit.bind("black_market"))
	%MainMenuButton.pressed.connect(main_menu_requested.emit)
	_render()
	%GateButton.grab_focus()


func configure(session: GameSessionClass) -> void:
	_session = session
	if is_node_ready():
		_render()


func _render() -> void:
	if _session == null:
		return
	var player := _session.player
	var guild_rank := GuildProgressionServiceClass.rank_for_reputation(_session.guild_reputation)
	time_label.text = _session.formatted_time()
	player_label.text = (
		"%s  •  Poziom %d  •  %s  •  PŻ %d/%d  •  Złoto %d  •  Gildia %s (%d)"
		% [
			player.titled_display_name(),
			player.level,
			player.character_class_name,
			player.stats.current_hp,
			player.stats.max_hp,
			player.gold,
			guild_rank.code,
			_session.guild_reputation,
		]
	)
	activity_label.text = (
		_session.last_activity
		if not _session.last_activity.is_empty()
		else "Wybierz miejsce w mieście albo wyrusz przez Bramę Zachodnią."
	)
	if player.character_class_code == player.CLASS_NONE:
		class_button.text = (
			"Wybierz Drogę bohatera" if player.can_choose_class else "Droga bohatera — poziom 5"
		)
	else:
		class_button.text = "Droga: %s" % player.character_class_name
	black_market_button.disabled = not _session.black_market.unlocked
	black_market_button.text = (
		"Czarny Rynek" if _session.black_market.unlocked else "Czarny Rynek — zablokowany"
	)
