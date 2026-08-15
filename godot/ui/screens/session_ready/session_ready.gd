class_name SessionReadyScreen
extends Control

signal back_to_menu_requested
signal character_sheet_requested

const GameSessionClass := preload("res://core/game/game_session.gd")

var _session: GameSessionClass

@onready var hero_label: Label = %HeroLabel
@onready var details_label: Label = %DetailsLabel


func _ready() -> void:
	%BackToMenuButton.pressed.connect(back_to_menu_requested.emit)
	%CharacterSheetButton.pressed.connect(character_sheet_requested.emit)
	_render_session()
	%CharacterSheetButton.grab_focus()


func configure(session: GameSessionClass) -> void:
	_session = session
	if is_node_ready():
		_render_session()


func _render_session() -> void:
	if _session == null:
		return
	hero_label.text = "%s jest gotowy do drogi" % _session.player.titled_display_name()
	details_label.text = (
		(
			"Slot %d  •  Poziom %d  •  %d/%d PŻ\n"
			+ "Miasto: %s  •  Godzina: %02d:00\n"
			+ "Broń: %s  •  Pancerz: %s"
		)
		% [
			_session.save_slot,
			_session.player.level,
			_session.player.health,
			_session.player.max_health,
			_session.current_city_id.capitalize(),
			_session.hour,
			_session.player.get_equipped_item_name("weapon"),
			_session.player.get_equipped_item_name("chest"),
		]
	)
