class_name CharacterSheetScreen
extends Control

signal back_requested
signal equipment_requested
signal class_selection_requested
signal skills_requested
signal progression_requested

const GameSessionClass := preload("res://core/game/game_session.gd")
const PlayerAttributesClass := preload("res://core/player/attributes.gd")
const PlayerEquipmentClass := preload("res://core/player/equipment.gd")
const CarryWeightServiceClass := preload("res://core/economy/carry_weight_service.gd")

var _session: GameSessionClass

@onready var hero_name_label: Label = %HeroNameLabel
@onready var progression_label: Label = %ProgressionLabel
@onready var attribute_points_value_label: Label = %AttributePointsValue
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
	%ProgressionButton.pressed.connect(progression_requested.emit)
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
	hero_name_label.text = player.titled_display_name()
	progression_label.text = (
		(
			"%s  •  Poziom %d\nEXP: %d/%d\n"
			+ "Udźwig: %.1f/%.1f kg  •  %s  •  Plecak Kwatermistrza %d/3"
		)
		% [
			player.character_class_name,
			player.level,
			player.experience,
			player.experience_to_next_level(),
			load.current_kg,
			load.capacity_kg,
			load.display_name,
			player.carry_upgrade_level,
		]
	)
	attribute_points_value_label.text = str(player.unspent_attribute_points)
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
		_configure_attribute_button(attribute_code)
	attribute_feedback_label.text = (
		"Wybierz +1, aby wydać wolny punkt."
		if player.unspent_attribute_points > 0
		else "Brak wolnych punktów atrybutów. Kolejne otrzymasz po awansie."
	)
	%LuckHint.text = (
		"Szczęście wzmacnia Kości i Żetony Losu."
		if player.character_class_code == player.CLASS_PIERROT
		else "Szczęście jest dostępne wyłącznie dla Pierrota."
	)
	class_button.text = (
		"Wybierz Drogę bohatera" if player.can_choose_class else "Zobacz Drogi bohatera"
	)
	var equipment_lines: Array[String] = []
	var slot_names := {
		PlayerEquipmentClass.WEAPON: "Broń",
		PlayerEquipmentClass.OFF_HAND: "Druga ręka",
		PlayerEquipmentClass.HEAD: "Hełm",
		PlayerEquipmentClass.CHEST: "Zbroja",
		PlayerEquipmentClass.HANDS: "Rękawice",
		PlayerEquipmentClass.FEET: "Buty",
		PlayerEquipmentClass.BELT: "Pas",
		PlayerEquipmentClass.NECKLACE: "Naszyjnik",
		PlayerEquipmentClass.BRACELET: "Bransoleta",
		PlayerEquipmentClass.EARRINGS: "Kolczyki",
		PlayerEquipmentClass.RING: "Pierścień",
	}
	for slot: String in slot_names:
		equipment_lines.append("%s: %s" % [slot_names[slot], player.get_equipped_item_name(slot)])
	equipment_label.text = "\n".join(equipment_lines)


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
	var feedback := "Zwiększono: %s." % _attribute_display_name(attribute_code)
	_session.last_activity = feedback
	_render_character()
	attribute_feedback_label.text = feedback


func _configure_attribute_button(attribute_code: String) -> void:
	var player := _session.player
	var button: Button = attribute_buttons[attribute_code]
	var error := player.get_attribute_spend_error(attribute_code)
	var can_spend := error.is_empty()
	button.disabled = not can_spend
	button.flat = not can_spend
	button.text = "+1" if can_spend else ""
	button.focus_mode = Control.FOCUS_ALL if can_spend else Control.FOCUS_NONE
	button.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND if can_spend else Control.CURSOR_ARROW
	)
	button.tooltip_text = "Przydziel 1 punkt." if can_spend else error


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
