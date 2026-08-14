class_name CharacterSheetScreen
extends Control

signal back_requested

const GameSessionClass := preload("res://core/game/game_session.gd")
const PlayerEquipmentClass := preload("res://core/player/equipment.gd")

var _session: GameSessionClass

@onready var hero_name_label: Label = %HeroNameLabel
@onready var progression_label: Label = %ProgressionLabel
@onready var primary_stats_label: Label = %PrimaryStatsLabel
@onready var attributes_label: Label = %AttributesLabel
@onready var equipment_label: Label = %EquipmentLabel


func _ready() -> void:
	%BackButton.pressed.connect(back_requested.emit)
	_render_character()
	%BackButton.grab_focus()


func configure(session: GameSessionClass) -> void:
	_session = session
	if is_node_ready():
		_render_character()


func _render_character() -> void:
	if _session == null:
		return
	var player := _session.player
	hero_name_label.text = player.display_name
	progression_label.text = (
		"%s  •  Poziom %d\nEXP: %d/%d  •  Wolne punkty atrybutów: %d"
		% [
			player.character_class_name,
			player.level,
			player.experience,
			player.experience_to_next_level(),
			player.unspent_attribute_points,
		]
	)
	primary_stats_label.text = (
		"PŻ      %d / %d\nMANA    %d / %d\nATK     %d\nDEF     %d\nUNIK    %.1f%%"
		% [
			player.stats.current_hp,
			player.stats.max_hp,
			player.stats.current_mana,
			player.stats.max_mana,
			player.stats.attack,
			player.stats.defense,
			player.stats.dodge,
		]
	)
	attributes_label.text = (
		(
			"Siła             %d\nWitalność         %d\nInteligencja      %d\n"
			+ "Zręczność        %d\nWytrzymałość      %d"
		)
		% [
			player.attributes.strength,
			player.attributes.vitality,
			player.attributes.intelligence,
			player.attributes.dexterity,
			player.attributes.endurance,
		]
	)
	if player.character_class_code == player.CLASS_PIERROT:
		attributes_label.text += "\nSzczęście         %d" % player.attributes.luck
	equipment_label.text = (
		"Broń\n%s\n\nZbroja\n%s"
		% [
			player.get_equipped_item_name(PlayerEquipmentClass.WEAPON),
			player.get_equipped_item_name(PlayerEquipmentClass.CHEST),
		]
	)
