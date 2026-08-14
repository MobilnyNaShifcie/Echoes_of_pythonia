class_name CityHubScreen
extends Control

signal world_map_requested
signal guild_requested
signal hero_requested
signal classes_requested
signal service_requested(service_id: String)
signal main_menu_requested

const GameSessionClass := preload("res://core/game/game_session.gd")

var _session: GameSessionClass

@onready var time_label: Label = %TimeLabel
@onready var player_label: Label = %PlayerLabel
@onready var activity_label: Label = %ActivityLabel
@onready var class_button: Button = %ClassButton


func _ready() -> void:
	%GateButton.pressed.connect(world_map_requested.emit)
	%QuartermasterButton.pressed.connect(service_requested.emit.bind("quartermaster"))
	%BlacksmithButton.pressed.connect(service_requested.emit.bind("blacksmith"))
	%WorkshopButton.pressed.connect(service_requested.emit.bind("workshop"))
	%MerchantButton.pressed.connect(service_requested.emit.bind("merchant"))
	%InnButton.pressed.connect(service_requested.emit.bind("inn"))
	%GuildButton.pressed.connect(guild_requested.emit)
	%HeroButton.pressed.connect(hero_requested.emit)
	%PreparationButton.pressed.connect(service_requested.emit.bind("preparation"))
	class_button.pressed.connect(classes_requested.emit)
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
	time_label.text = _session.formatted_time()
	player_label.text = (
		"%s  •  Poziom %d  •  %s  •  PŻ %d/%d  •  Złoto %d  •  Gildia F (%d)"
		% [
			player.display_name,
			player.level,
			player.character_class_name,
			player.stats.current_hp,
			player.stats.max_hp,
			player.gold,
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
