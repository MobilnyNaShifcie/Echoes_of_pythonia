class_name RiftBoardScreen
extends Control

signal back_requested
signal state_changed

const GameSessionClass := preload("res://core/game/game_session.gd")
const GuildProgressionServiceClass := preload("res://core/quests/guild_progression_service.gd")
const RiftCatalogClass := preload("res://core/rifts/rift_catalog.gd")
const RiftLifecycleServiceClass := preload("res://core/rifts/rift_lifecycle_service.gd")

var _session: GameSessionClass
var _abandon_armed := false

@onready var state_label: Label = %StateLabel
@onready var title_label: Label = %TitleLabel
@onready var summary_label: Label = %SummaryLabel
@onready var intro_label: Label = %IntroLabel
@onready var modifier_label: Label = %ModifierLabel
@onready var boss_label: Label = %BossLabel
@onready var party_label: Label = %PartyLabel
@onready var status_label: Label = %StatusLabel
@onready var start_button: Button = %StartButton
@onready var abandon_button: Button = %AbandonButton


func _ready() -> void:
	%BackButton.pressed.connect(back_requested.emit)
	start_button.pressed.connect(_start_expedition)
	abandon_button.pressed.connect(_abandon_expedition)
	_render()


func configure(session: GameSessionClass) -> void:
	_session = session
	_abandon_armed = false
	if is_node_ready():
		_render()


func _start_expedition() -> void:
	if _session == null:
		return
	var rank := GuildProgressionServiceClass.rank_for_reputation(_session.guild_reputation)
	var companion_ids: Array[String] = []
	for companion in _session.party.active_companions(_session.day):
		companion_ids.append(companion.companion_id)
	var result := RiftLifecycleServiceClass.start_expedition(
		_session.rifts, _session.day, companion_ids, rank.code
	)
	status_label.text = result.message
	if result.ok:
		_session.log_event(result.message)
		state_changed.emit()
	_render()


func _abandon_expedition() -> void:
	if _session == null or _session.rifts.expedition == null:
		return
	if not _abandon_armed:
		_abandon_armed = true
		status_label.text = (
			"Potwierdź porzucenie. Szczelina znów stanie się dostępna " + "dla innych drużyn."
		)
		abandon_button.text = "Potwierdź porzucenie"
		return
	var result := RiftLifecycleServiceClass.abandon_expedition(_session.rifts, _session.day)
	status_label.text = result.message
	if result.ok:
		_session.log_event("Porzucono ekspedycję Szczeliny.")
		state_changed.emit()
	_abandon_armed = false
	_render()


func _render() -> void:
	if not is_node_ready():
		return
	start_button.visible = true
	start_button.disabled = true
	start_button.text = "Rozpocznij ekspedycję"
	abandon_button.visible = false
	abandon_button.text = "Porzuć ekspedycję"
	if _session == null:
		_render_empty("Brak aktywnej sesji.")
		return

	var state = _session.rifts
	summary_label.text = _completion_summary()
	if state.expedition != null and state.active_rift != null:
		_render_reserved_expedition()
		return
	if state.active_rift == null:
		_render_empty("Brak aktywnego alarmu Szczeliny.")
		return
	_render_active_rift()


func _render_empty(message: String) -> void:
	state_label.text = "BRAK ALARMU"
	title_label.text = message
	intro_label.text = (
		"Gildia nie wykryła obecnie stabilnej Szczeliny. "
		+ "Alarmy pojawiają się wraz z upływem czasu Pythonii."
	)
	modifier_label.text = ""
	boss_label.text = ""
	party_label.text = ""
	start_button.visible = false
	abandon_button.visible = false


func _render_active_rift() -> void:
	var rift = _session.rifts.active_rift
	var rank := GuildProgressionServiceClass.rank_for_reputation(_session.guild_reputation)
	var active_companions := _session.party.active_companions(_session.day)
	var eligibility := RiftLifecycleServiceClass.can_start_rift(
		rift, active_companions.size(), rank.code
	)
	var theme: Dictionary = RiftCatalogClass.get_theme(rift.theme_id)
	state_label.text = "AKTYWNY ALARM • RANGA %s" % rift.rank_code
	title_label.text = rift.theme_name
	intro_label.text = str(theme.intro)
	modifier_label.text = "Anomalie:\n" + _modifier_text(rift.modifier_ids)
	boss_label.text = (
		"Władca Szczeliny: %s\nDługość ekspedycji: %d segmentów\nPozostało na decyzję: %d dni Pythonii"
		% [
			rift.boss_name,
			rift.segment_count,
			RiftLifecycleServiceClass.days_remaining(rift, _session.day),
		]
	)
	party_label.text = (
		"Aktywni kompani: %d/3 • wymagani: %d\nRanga Gildii: %s"
		% [
			active_companions.size(),
			int(RiftCatalogClass.MIN_COMPANIONS[rift.rank_code]),
			rank.code,
		]
	)
	start_button.disabled = not eligibility.ok
	status_label.text = (
		"Szczelina jest gotowa do ekspedycji."
		if eligibility.ok
		else "Nie możesz rozpocząć ekspedycji: %s" % eligibility.message
	)


func _render_reserved_expedition() -> void:
	var rift = _session.rifts.active_rift
	var expedition = _session.rifts.expedition
	state_label.text = "TRWA EKSPEDYCJA • RANGA %s" % rift.rank_code
	title_label.text = rift.theme_name
	intro_label.text = (
		"Szczelina jest przypisana do twojej ekspedycji — " + "inne drużyny jej teraz nie zamkną."
	)
	modifier_label.text = "Anomalie:\n" + _modifier_text(rift.modifier_ids)
	boss_label.text = (
		"Postęp: %d/%d segmentów\nWładca Szczeliny: %s"
		% [expedition.segment_index, rift.segment_count, rift.boss_name]
	)
	party_label.text = "Związany skład:\n" + _bound_party_text(expedition.party_companion_ids)
	start_button.text = "Kontynuacja ekspedycji — Stage 6J"
	start_button.disabled = true
	abandon_button.visible = true
	status_label.text = (
		"Lifecycle i skład są zapisane. Segmenty ekspedycji oraz walka drużynowa "
		+ "zostaną podłączone w Stage 6J."
	)


func _modifier_text(modifier_ids: Array[String]) -> String:
	var lines: Array[String] = []
	for modifier_id: String in modifier_ids:
		var modifier = RiftCatalogClass.get_modifier(modifier_id)
		lines.append("• %s — %s" % [modifier.display_name, modifier.description])
	return "\n".join(lines)


func _bound_party_text(companion_ids: Array[String]) -> String:
	var names: Array[String] = []
	for companion_id: String in companion_ids:
		var companion = _session.party.companion_by_id(companion_id)
		names.append(companion.display_name if companion != null else companion_id)
	return ", ".join(names)


func _completion_summary() -> String:
	var rank_parts: Array[String] = []
	for rank_code: String in RiftCatalogClass.RANKS:
		var count := int(_session.rifts.completed_by_rank.get(rank_code, 0))
		if count > 0:
			rank_parts.append("%s: %d" % [rank_code, count])
	var details := "brak" if rank_parts.is_empty() else ", ".join(rank_parts)
	return "Zamknięte Szczeliny: %d • według rang: %s" % [_session.rifts.completed_total, details]
