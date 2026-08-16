class_name PartyHubScreen
extends Control

signal back_requested
signal state_changed

const CompanionServiceClass := preload("res://core/companions/companion_service.gd")
const CompanionStateClass := preload("res://core/companions/companion_state.gd")
const GameSessionClass := preload("res://core/game/game_session.gd")

var _session: GameSessionClass
var _selected_companion_id := ""

@onready var summary_label: Label = %SummaryLabel
@onready var roster_list: ItemList = %RosterList
@onready var empty_label: Label = %EmptyLabel
@onready var detail_name_label: Label = %DetailNameLabel
@onready var detail_state_label: Label = %DetailStateLabel
@onready var toggle_button: Button = %ToggleButton
@onready var solo_button: Button = %SoloButton
@onready var result_label: Label = %ResultLabel


func _ready() -> void:
	%BackButton.pressed.connect(back_requested.emit)
	roster_list.item_selected.connect(_select_companion)
	toggle_button.pressed.connect(_toggle_selected)
	solo_button.pressed.connect(_set_solo)
	_render()


func configure(session: GameSessionClass) -> void:
	_session = session
	if is_node_ready():
		_render()


func _select_companion(index: int) -> void:
	_selected_companion_id = str(roster_list.get_item_metadata(index))
	_render_details()


func _toggle_selected() -> void:
	if _session == null or _selected_companion_id.is_empty():
		return
	var companion := _session.party.companion_by_id(_selected_companion_id)
	if companion == null:
		return
	var result := (
		CompanionServiceClass
		. set_active(
			_session.party,
			companion.companion_id,
			not companion.active,
			_session.day,
		)
	)
	result_label.text = result.message
	if result.ok:
		state_changed.emit()
	_render()


func _set_solo() -> void:
	if _session == null:
		return
	var result := CompanionServiceClass.set_solo(_session.party)
	result_label.text = result.message
	if result.ok and result.changed > 0:
		state_changed.emit()
	_render()


func _render() -> void:
	if _session == null:
		summary_label.text = "Brak aktywnej sesji."
		roster_list.clear()
		return
	var active_count := _session.party.active_companions(_session.day).size()
	summary_label.text = (
		"Roster %d/%d  •  aktywny skład %d/%d"
		% [
			_session.party.companions.size(),
			CompanionServiceClass.MAX_COMPANIONS,
			active_count,
			CompanionServiceClass.MAX_ACTIVE_COMPANIONS,
		]
	)
	roster_list.clear()
	var selected_index := -1
	for companion: CompanionStateClass in _session.party.companions:
		var row := roster_list.add_item(_companion_row(companion))
		roster_list.set_item_metadata(row, companion.companion_id)
		if companion.companion_id == _selected_companion_id:
			selected_index = row
	empty_label.visible = roster_list.item_count == 0
	if roster_list.item_count > 0:
		if selected_index < 0:
			selected_index = 0
			_selected_companion_id = str(roster_list.get_item_metadata(0))
		roster_list.select(selected_index)
	_render_details()


func _render_details() -> void:
	var companion = (
		_session.party.companion_by_id(_selected_companion_id)
		if _session != null and not _selected_companion_id.is_empty()
		else null
	)
	if companion == null:
		detail_name_label.text = "Brak kompanów"
		detail_state_label.text = (
			"Kandydaci i rekrutacja pojawią się w etapie 6B. "
			+ "Nowa sesja zaczyna z pustą drużyną, zgodnie z v0.24.7."
		)
		toggle_button.disabled = true
		toggle_button.text = "Wybierz kompana"
		solo_button.disabled = true
		return
	detail_name_label.text = "%s  •  poziom %d" % [companion.display_name, companion.level]
	var state := "AKTYWNY SKŁAD" if companion.active else "VARENHOLD"
	if companion.dead:
		state = "POLEGŁY"
	elif companion.is_injured(_session.day):
		state = "CIĘŻKO RANNY • powrót do sił: %d dni" % (companion.injury_until_day - _session.day)
	detail_state_label.text = (
		"%s\nHP %d  •  Mana %d  •  Relacja %d\nTaktyka: %s"
		% [
			state,
			companion.current_hp,
			companion.current_mana,
			companion.relation,
			CompanionStateClass.tactic_display_name(companion.tactic),
		]
	)
	toggle_button.disabled = companion.dead or companion.is_injured(_session.day)
	toggle_button.text = (
		"Pozostaw w Varenhold" if companion.active else "Dodaj do aktywnego składu"
	)
	solo_button.disabled = _session.party.active_companions(_session.day).is_empty()


func _companion_row(companion: CompanionStateClass) -> String:
	var marker := "AKTYWNY" if companion.active else "VARENHOLD"
	if companion.dead:
		marker = "POLEGŁY"
	elif companion.is_injured(_session.day):
		marker = "CIĘŻKO RANNY"
	return (
		"%s  •  %s  •  poziom %d  •  %s"
		% [
			companion.display_name,
			_class_name(companion.class_code),
			companion.level,
			marker,
		]
	)


func _class_name(class_code: String) -> String:
	match class_code:
		"warrior":
			return "Wojownik"
		"hunter":
			return "Łowca"
		"mage":
			return "Mag"
		"pierrot":
			return "Pierrot"
		_:
			return "Nieznana klasa"
