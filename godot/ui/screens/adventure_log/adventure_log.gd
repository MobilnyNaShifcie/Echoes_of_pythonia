class_name AdventureLogScreen
extends Control

signal back_requested

const GameSessionClass := preload("res://core/game/game_session.gd")

var _session: GameSessionClass

@onready var summary_label: Label = %SummaryLabel
@onready var entry_list: ItemList = %EntryList
@onready var empty_label: Label = %EmptyLabel


func _ready() -> void:
	%BackButton.pressed.connect(back_requested.emit)
	_render()
	%BackButton.grab_focus()


func configure(session: GameSessionClass) -> void:
	_session = session
	if is_node_ready():
		_render()


func _render() -> void:
	if _session == null:
		return
	entry_list.clear()
	var recent_entries := _session.adventure_log.recent()
	for entry: String in recent_entries:
		entry_list.add_item(entry)
	entry_list.visible = not recent_entries.is_empty()
	empty_label.visible = recent_entries.is_empty()
	summary_label.text = (
		"%s  •  Dzień %d, %02d:00  •  %d/%d zapisanych wydarzeń"
		% [
			_session.player.titled_display_name(),
			_session.day,
			_session.hour,
			_session.adventure_log.entries.size(),
			_session.adventure_log.MAX_ENTRIES,
		]
	)
	if entry_list.item_count > 0:
		entry_list.select(entry_list.item_count - 1)
		entry_list.ensure_current_is_visible()
