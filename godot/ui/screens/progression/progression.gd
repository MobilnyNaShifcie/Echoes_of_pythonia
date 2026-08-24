class_name ProgressionScreen
extends Control

signal back_requested

const GameSessionClass := preload("res://core/game/game_session.gd")
const PassiveProgressionServiceClass := preload(
	"res://core/progression/passive_progression_service.gd"
)
const TalentCatalogClass := preload("res://core/progression/talent_catalog.gd")
const TalentDefinitionClass := preload("res://core/progression/talent_definition.gd")
const TalentProgressionServiceClass := preload(
	"res://core/progression/talent_progression_service.gd"
)

var _session: GameSessionClass
var _selected_path_id := ""
var _selected_talent_id := ""
var _selected_passive_code := ""

@onready var points_label: Label = %PointsLabel
@onready var feedback_label: Label = %FeedbackLabel
@onready var path_list: ItemList = %PathList
@onready var path_description_label: Label = %PathDescriptionLabel
@onready var talent_list: ItemList = %TalentList
@onready var talent_name_label: Label = %TalentNameLabel
@onready var talent_description_label: Label = %TalentDescriptionLabel
@onready var talent_requirements_label: Label = %TalentRequirementsLabel
@onready var learn_button: Button = %LearnButton
@onready var reset_button: Button = %ResetButton
@onready var passive_list: ItemList = %PassiveList
@onready var passive_name_label: Label = %PassiveNameLabel
@onready var passive_effect_label: Label = %PassiveEffectLabel
@onready var passive_mastery_label: Label = %PassiveMasteryLabel
@onready var spend_passive_button: Button = %SpendPassiveButton
@onready var specialization_selector: OptionButton = %SpecializationSelector
@onready var choose_specialization_button: Button = %ChooseSpecializationButton


func _ready() -> void:
	%BackButton.pressed.connect(back_requested.emit)
	path_list.item_selected.connect(_on_path_selected)
	talent_list.item_selected.connect(_on_talent_selected)
	learn_button.pressed.connect(_learn_selected_talent)
	reset_button.pressed.connect(_reset_talents)
	passive_list.item_selected.connect(_on_passive_selected)
	spend_passive_button.pressed.connect(_spend_selected_passive)
	specialization_selector.item_selected.connect(_on_specialization_selected)
	choose_specialization_button.pressed.connect(_choose_specialization)
	_render_all()
	%BackButton.grab_focus()


func configure(session: GameSessionClass) -> void:
	_session = session
	if is_node_ready():
		_render_all()


func _render_all() -> void:
	if _session == null:
		return
	var player := _session.player
	points_label.text = (
		"%s  •  Poziom %d  •  Punkty drzewka: %d  •  Punkty pasywne: %d  •  Złoto: %d"
		% [
			player.character_class_name,
			player.level,
			TalentProgressionServiceClass.available_points(player),
			PassiveProgressionServiceClass.available_points(player),
			player.gold,
		]
	)
	_render_paths()
	_render_passives()


func _render_paths() -> void:
	path_list.clear()
	if _session.player.character_class_code == "none":
		path_description_label.text = "Wybierz Drogę bohatera na poziomie 5."
		_clear_talent_details()
		return
	var selected_index := 0
	for path in TalentCatalogClass.get_paths_for_class(_session.player.character_class_code):
		var unlocked := TalentProgressionServiceClass.path_is_unlocked(
			_session.player, path.path_id
		)
		path_list.add_item("%s  •  %s" % [path.display_name, "otwarta" if unlocked else "księga"])
		var index := path_list.item_count - 1
		path_list.set_item_metadata(index, path.path_id)
		if not unlocked:
			path_list.set_item_custom_fg_color(index, Color(0.5, 0.56, 0.66))
		if path.path_id == _selected_path_id:
			selected_index = index
	path_list.select(selected_index)
	_on_path_selected(selected_index)


func _on_path_selected(index: int) -> void:
	if index < 0 or index >= path_list.item_count:
		return
	_selected_path_id = str(path_list.get_item_metadata(index))
	var path = TalentCatalogClass.get_path_definition(_selected_path_id)
	var status := "Ścieżka otwarta."
	if not TalentProgressionServiceClass.path_is_unlocked(_session.player, _selected_path_id):
		status = "Wymaga Księgi Ścieżki dla specjalizacji „%s”." % path.display_name
	path_description_label.text = "%s\n%s" % [path.description, status]
	_render_talents()


func _render_talents() -> void:
	talent_list.clear()
	var selected_index := 0
	for talent: TalentDefinitionClass in TalentCatalogClass.get_talents_for_path(_selected_path_id):
		var rank := TalentProgressionServiceClass.talent_rank(_session.player, talent.talent_id)
		talent_list.add_item("%s  •  %d/%d" % [talent.display_name, rank, talent.max_rank])
		var index := talent_list.item_count - 1
		talent_list.set_item_metadata(index, talent.talent_id)
		if (
			not (
				TalentProgressionServiceClass
				. get_learn_error(_session.player, talent.talent_id)
				. is_empty()
			)
			and rank <= 0
		):
			talent_list.set_item_custom_fg_color(index, Color(0.55, 0.61, 0.7))
		if talent.talent_id == _selected_talent_id:
			selected_index = index
	if talent_list.item_count <= 0:
		_clear_talent_details()
		return
	talent_list.select(selected_index)
	_on_talent_selected(selected_index)


func _on_talent_selected(index: int) -> void:
	if index < 0 or index >= talent_list.item_count:
		return
	_selected_talent_id = str(talent_list.get_item_metadata(index))
	var talent: TalentDefinitionClass = TalentCatalogClass.get_talent(_selected_talent_id)
	var rank := TalentProgressionServiceClass.talent_rank(_session.player, talent.talent_id)
	var error := TalentProgressionServiceClass.get_learn_error(_session.player, talent.talent_id)
	talent_name_label.text = "%s  •  %d/%d" % [talent.display_name, rank, talent.max_rank]
	talent_description_label.text = talent.description
	talent_requirements_label.text = _talent_requirements_text(talent)
	learn_button.disabled = not error.is_empty()
	learn_button.tooltip_text = error
	reset_button.disabled = TalentProgressionServiceClass.spent_points(_session.player) <= 0
	reset_button.text = (
		"Resetuj drzewko — %d złota" % TalentProgressionServiceClass.reset_cost(_session.player)
	)


func _talent_requirements_text(talent: TalentDefinitionClass) -> String:
	var requirements: Array[String] = []
	for required_id: String in talent.prerequisites:
		var required: TalentDefinitionClass = TalentCatalogClass.get_talent(required_id)
		requirements.append(
			"%s %d" % [required.display_name, int(talent.prerequisites[required_id])]
		)
	if not talent.active_skill_id.is_empty():
		requirements.append("Odblokowuje umiejętność: %s" % talent.active_skill_id)
	return (
		"Wymagania: brak."
		if requirements.is_empty()
		else "Wymagania: %s." % "  •  ".join(requirements)
	)


func _learn_selected_talent() -> void:
	var result := TalentProgressionServiceClass.learn(_session.player, _selected_talent_id)
	_set_feedback(result.message, result.ok)
	_session.last_activity = result.message
	_render_all()


func _reset_talents() -> void:
	var result := TalentProgressionServiceClass.reset(_session.player)
	_set_feedback(result.message, result.ok)
	_session.last_activity = result.message
	_render_all()


func _render_passives() -> void:
	passive_list.clear()
	var selected_index := 0
	for passive_code: String in PassiveProgressionServiceClass.PASSIVE_ORDER:
		var rank := PassiveProgressionServiceClass.rank(_session.player, passive_code)
		var cap := PassiveProgressionServiceClass.max_rank(_session.player, passive_code)
		passive_list.add_item(
			"%s  •  %d/%d" % [PassiveProgressionServiceClass.PASSIVE_NAMES[passive_code], rank, cap]
		)
		var index := passive_list.item_count - 1
		passive_list.set_item_metadata(index, passive_code)
		if passive_code == _selected_passive_code:
			selected_index = index
	passive_list.select(selected_index)
	_on_passive_selected(selected_index)


func _on_passive_selected(index: int) -> void:
	if index < 0 or index >= passive_list.item_count:
		return
	_selected_passive_code = str(passive_list.get_item_metadata(index))
	var player := _session.player
	var rank := PassiveProgressionServiceClass.rank(player, _selected_passive_code)
	var cap := PassiveProgressionServiceClass.max_rank(player, _selected_passive_code)
	passive_name_label.text = (
		"%s  •  %d/%d"
		% [PassiveProgressionServiceClass.PASSIVE_NAMES[_selected_passive_code], rank, cap]
	)
	passive_effect_label.text = PassiveProgressionServiceClass.effect_description(
		player, _selected_passive_code
	)
	var has_mastery := _selected_passive_code in player.unlocked_passive_mastery_ids
	passive_mastery_label.text = (
		"Mistrzostwo odblokowane — limit 10/10."
		if has_mastery
		else "Limit 5/5. Rangi 6–10 wymagają Księgi Mistrzostwa."
	)
	var spend_error := PassiveProgressionServiceClass.get_spend_error(
		player, _selected_passive_code
	)
	spend_passive_button.disabled = not spend_error.is_empty()
	spend_passive_button.tooltip_text = spend_error
	_populate_specializations()


func _populate_specializations() -> void:
	specialization_selector.clear()
	for specialization_id: String in (
		PassiveProgressionServiceClass.SPECIALIZATION_ORDER[_selected_passive_code]
	):
		var data: Dictionary = PassiveProgressionServiceClass.SPECIALIZATIONS[specialization_id]
		specialization_selector.add_item(data.name)
		var index := specialization_selector.item_count - 1
		specialization_selector.set_item_metadata(index, specialization_id)
	var chosen := PassiveProgressionServiceClass.specialization_for(
		_session.player, _selected_passive_code
	)
	if not chosen.is_empty():
		for index in specialization_selector.item_count:
			if str(specialization_selector.get_item_metadata(index)) == chosen:
				specialization_selector.select(index)
				break
	_on_specialization_selected(specialization_selector.selected)


func _on_specialization_selected(index: int) -> void:
	if index < 0 or index >= specialization_selector.item_count:
		choose_specialization_button.disabled = true
		return
	var specialization_id := str(specialization_selector.get_item_metadata(index))
	var error := PassiveProgressionServiceClass.get_specialization_error(
		_session.player, _selected_passive_code, specialization_id
	)
	choose_specialization_button.disabled = not error.is_empty()
	choose_specialization_button.tooltip_text = error
	%SpecializationDescriptionLabel.text = (
		PassiveProgressionServiceClass.SPECIALIZATIONS[specialization_id].description
	)


func _spend_selected_passive() -> void:
	var result := PassiveProgressionServiceClass.spend(_session.player, _selected_passive_code)
	_set_feedback(result.message, result.ok)
	_session.last_activity = result.message
	_render_all()


func _choose_specialization() -> void:
	var specialization_id := str(
		specialization_selector.get_item_metadata(specialization_selector.selected)
	)
	var result := PassiveProgressionServiceClass.choose_specialization(
		_session.player, _selected_passive_code, specialization_id
	)
	_set_feedback(result.message, result.ok)
	_session.last_activity = result.message
	_render_all()


func _set_feedback(message: String, succeeded: bool) -> void:
	feedback_label.text = message
	feedback_label.modulate = Color(0.42, 0.78, 0.56) if succeeded else Color(0.92, 0.48, 0.48)


func _clear_talent_details() -> void:
	talent_list.clear()
	talent_name_label.text = "Brak dostępnego drzewka"
	talent_description_label.text = "Najpierw wybierz klasę postaci."
	talent_requirements_label.text = ""
	learn_button.disabled = true
	reset_button.disabled = true
