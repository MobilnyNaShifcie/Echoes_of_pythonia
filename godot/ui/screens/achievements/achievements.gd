class_name AchievementsScreen
extends Control

signal back_requested
signal state_changed

const AchievementCatalogClass := preload("res://core/progression/achievement_catalog.gd")
const AchievementServiceClass := preload("res://core/progression/achievement_service.gd")
const GameSessionClass := preload("res://core/game/game_session.gd")

var _session: GameSessionClass
var _definitions: Array = []

@onready var summary_label: Label = %SummaryLabel
@onready var achievement_list: ItemList = %AchievementList
@onready var achievement_name_label: Label = %AchievementNameLabel
@onready var achievement_status_label: Label = %AchievementStatusLabel
@onready var achievement_description_label: Label = %AchievementDescriptionLabel
@onready var reward_label: Label = %RewardLabel
@onready var title_selector: OptionButton = %TitleSelector
@onready var equip_button: Button = %EquipButton
@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	%BackButton.pressed.connect(back_requested.emit)
	achievement_list.item_selected.connect(_render_selected_achievement)
	title_selector.item_selected.connect(_on_title_selected)
	equip_button.pressed.connect(_equip_selected_title)
	_render()
	%BackButton.grab_focus()


func configure(session: GameSessionClass) -> void:
	_session = session
	if is_node_ready():
		_render()


func _render() -> void:
	if _session == null:
		return
	_definitions = AchievementCatalogClass.get_all()
	achievement_list.clear()
	for definition in _definitions:
		var unlocked: bool = _session.player.achievement_book.is_unlocked(definition.achievement_id)
		achievement_list.add_item(
			"%s  %s" % ["[ZDOBYTE]" if unlocked else "[NIEZDOBYTE]", definition.display_name]
		)
	achievement_list.select(0)
	_render_selected_achievement(0)
	_render_titles()
	summary_label.text = (
		"%s  •  %d/%d osiągnięć  •  aktywny tytuł: %s"
		% [
			_session.player.titled_display_name(),
			_session.player.achievement_book.unlocked_ids.size(),
			_definitions.size(),
			_session.player.achievement_book.equipped_title,
		]
	)


func _render_selected_achievement(index: int) -> void:
	if index < 0 or index >= _definitions.size() or _session == null:
		return
	var definition = _definitions[index]
	var unlocked: bool = _session.player.achievement_book.is_unlocked(definition.achievement_id)
	achievement_name_label.text = definition.display_name
	achievement_status_label.text = "ZDOBYTE" if unlocked else "NIEZDOBYTE"
	achievement_status_label.modulate = (
		Color(0.45, 0.85, 0.62) if unlocked else Color(0.58, 0.64, 0.73)
	)
	achievement_description_label.text = definition.description
	reward_label.text = "Nagroda: tytuł „%s”" % definition.title


func _render_titles() -> void:
	title_selector.clear()
	var titles := _session.player.achievement_book.available_titles()
	var selected_index := 0
	for index in titles.size():
		title_selector.add_item(titles[index])
		if titles[index] == _session.player.achievement_book.equipped_title:
			selected_index = index
	title_selector.select(selected_index)
	_on_title_selected(selected_index)


func _on_title_selected(_index: int) -> void:
	if _session == null or title_selector.item_count == 0:
		equip_button.disabled = true
		return
	var selected_title := title_selector.get_item_text(title_selector.selected)
	equip_button.disabled = selected_title == _session.player.achievement_book.equipped_title


func _equip_selected_title() -> void:
	if _session == null or title_selector.item_count == 0:
		return
	var title := title_selector.get_item_text(title_selector.selected)
	var result := AchievementServiceClass.equip_title(_session, title)
	status_label.text = result.message
	if result.ok:
		state_changed.emit()
		_render()
