class_name CharacterSheetScreen
extends Control

signal back_requested
signal equipment_requested
signal class_selection_requested
signal skills_requested

const GameSessionClass := preload("res://core/game/game_session.gd")
const PlayerAttributesClass := preload("res://core/player/attributes.gd")
const PlayerEquipmentClass := preload("res://core/player/equipment.gd")
const CarryWeightServiceClass := preload("res://core/economy/carry_weight_service.gd")

var _session: GameSessionClass

@onready var hero_name_label: Label = %HeroNameLabel
@onready var progression_label: Label = %ProgressionLabel
@onready var primary_stats_label: Label = %PrimaryStatsLabel
@onready var equipment_label: Label = %EquipmentLabel
@onready var attribute_feedback_label: Label = %AttributeFeedbackLabel
@onready var class_button: Button = %ClassButton
@onready var attribute_value_labels := {
	PlayerAttributesClass.STRENGTH: %StrengthValue,
	PlayerAttributesClass.VITALITY: %VitalityValue,
	PlayerAttributesClass.INTELLIGENCE: %IntelligenceValue,
	PlayerAttributesClass.DEXTERITY: %DexterityValue,
	PlayerAttributesClass.ENDURANCE: %EnduranceValue,
	PlayerAttributesClass.LUCK: %LuckValue,
}
@onready var attribute_buttons := {
	PlayerAttributesClass.STRENGTH: %StrengthButton,
	PlayerAttributesClass.VITALITY: %VitalityButton,
	PlayerAttributesClass.INTELLIGENCE: %IntelligenceButton,
	PlayerAttributesClass.DEXTERITY: %DexterityButton,
	PlayerAttributesClass.ENDURANCE: %EnduranceButton,
	PlayerAttributesClass.LUCK: %LuckButton,
}


func _ready() -> void:
	%BackButton.pressed.connect(back_requested.emit)
	%EquipmentButton.pressed.connect(equipment_requested.emit)
	%SkillsButton.pressed.connect(skills_requested.emit)
	class_button.pressed.connect(class_selection_requested.emit)
	for attribute_code: String in attribute_buttons:
		attribute_buttons[attribute_code].pressed.connect(_spend_attribute.bind(attribute_code))
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
	var load := CarryWeightServiceClass.carry_status(player)
	hero_name_label.text = player.display_name
	progression_label.text = (
		(
			"%s  •  Poziom %d\nEXP: %d/%d  •  Wolne punkty atrybutów: %d\n"
			+ "Udźwig: %.1f/%.1f kg  •  %s  •  Plecak Kwatermistrza %d/3"
		)
		% [
			player.character_class_name,
			player.level,
			player.experience,
			player.experience_to_next_level(),
			player.unspent_attribute_points,
			load.current_kg,
			load.capacity_kg,
			load.display_name,
			player.carry_upgrade_level,
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
	for attribute_code: String in attribute_value_labels:
		attribute_value_labels[attribute_code].text = str(
			player.attributes.get_value(attribute_code)
		)
		attribute_buttons[attribute_code].disabled = player.unspent_attribute_points <= 0
	attribute_buttons[PlayerAttributesClass.LUCK].disabled = (
		player.unspent_attribute_points <= 0 or player.character_class_code != player.CLASS_PIERROT
	)
	%LuckHint.text = (
		"Szczęście wzmacnia Kości i Żetony Losu."
		if player.character_class_code == player.CLASS_PIERROT
		else "Szczęście jest dostępne wyłącznie dla Pierrota."
	)
	class_button.text = (
		"Wybierz Drogę bohatera" if player.can_choose_class else "Zobacz Drogi bohatera"
	)
	equipment_label.text = (
		"Broń\n%s\n\nDruga ręka\n%s\n\nZbroja\n%s"
		% [
			player.get_equipped_item_name(PlayerEquipmentClass.WEAPON),
			player.get_equipped_item_name(PlayerEquipmentClass.OFF_HAND),
			player.get_equipped_item_name(PlayerEquipmentClass.CHEST),
		]
	)


func _spend_attribute(attribute_code: String) -> void:
	if _session == null:
		return
	var player := _session.player
	var error := player.get_attribute_spend_error(attribute_code)
	if not error.is_empty():
		attribute_feedback_label.text = error
		return
	if not player.spend_attribute_points(attribute_code):
		attribute_feedback_label.text = "Nie udało się wydać punktu atrybutu."
		return
	var attribute_name := _attribute_display_name(attribute_code)
	attribute_feedback_label.text = "Zwiększono: %s." % attribute_name
	_session.last_activity = attribute_feedback_label.text
	_render_character()


func _attribute_display_name(attribute_code: String) -> String:
	return (
		{
			PlayerAttributesClass.STRENGTH: "Siła",
			PlayerAttributesClass.VITALITY: "Witalność",
			PlayerAttributesClass.INTELLIGENCE: "Inteligencja",
			PlayerAttributesClass.DEXTERITY: "Zręczność",
			PlayerAttributesClass.ENDURANCE: "Wytrzymałość",
			PlayerAttributesClass.LUCK: "Szczęście",
		}
		. get(attribute_code, attribute_code)
	)
