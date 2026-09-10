class_name CharacterMenuScreen
extends Control

signal back_requested
signal class_selection_requested
signal section_changed(section_id: String)

const GameSessionClass := preload("res://core/game/game_session.gd")
const InterfaceStyle := preload("res://ui/presentation/interface_style.gd")
const CarryWeightServiceClass := preload("res://core/economy/carry_weight_service.gd")
const CHARACTER_SHEET_SCENE := preload("res://ui/screens/character_sheet/character_sheet.tscn")
const EQUIPMENT_SCENE := preload("res://ui/screens/equipment/equipment.tscn")
const SKILLS_SCENE := preload("res://ui/screens/skills/skills.tscn")
const PROGRESSION_SCENE := preload("res://ui/screens/progression/progression.tscn")

const SECTION_CHARACTER := "character"
const SECTION_EQUIPMENT := "equipment"
const SECTION_SKILLS := "skills"
const SECTION_PROGRESSION := "progression"

const VIEW_SCENES := {
	SECTION_CHARACTER: CHARACTER_SHEET_SCENE,
	SECTION_EQUIPMENT: EQUIPMENT_SCENE,
	SECTION_SKILLS: SKILLS_SCENE,
	SECTION_PROGRESSION: PROGRESSION_SCENE,
}
const EMBEDDED_HEADER_PATHS := {
	SECTION_CHARACTER: NodePath("Page/Heading"),
	SECTION_EQUIPMENT: NodePath("Page/Header"),
	SECTION_SKILLS: NodePath("Page/Heading"),
	SECTION_PROGRESSION: NodePath("Page/Heading"),
}

var _session: GameSessionClass
var _initial_section := SECTION_CHARACTER
var _active_section := ""
var _views: Dictionary = {}
var _tab_group := ButtonGroup.new()

@onready var hero_name_label: Label = %HeroNameLabel
@onready var hero_meta_label: Label = %HeroMetaLabel
@onready var resources_label: Label = %ResourcesLabel
@onready var content_host: Control = %ContentHost
@onready var back_button: Button = %BackButton
@onready var tab_buttons := {
	SECTION_CHARACTER: %CharacterTab,
	SECTION_EQUIPMENT: %EquipmentTab,
	SECTION_SKILLS: %SkillsTab,
	SECTION_PROGRESSION: %ProgressionTab,
}


func _ready() -> void:
	var header: PanelContainer = $PageMargin/Page/HeaderPanel
	header.add_theme_stylebox_override("panel", InterfaceStyle.panel(0.5, Color.TRANSPARENT))
	$PageMargin/Page/HeaderPanel/HeaderRow/Identity/Eyebrow.hide()
	$PageMargin/Page/TabsPanel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	InterfaceStyle.quiet_button(back_button)
	back_button.pressed.connect(back_requested.emit)
	for section_id: String in tab_buttons:
		var button: Button = tab_buttons[section_id]
		button.button_group = _tab_group
		button.pressed.connect(open_section.bind(section_id))
	if _session != null:
		_update_header()
		open_section(_initial_section)
	else:
		back_button.grab_focus()


func configure(session: GameSessionClass, initial_section := SECTION_CHARACTER) -> void:
	_session = session
	_initial_section = _normalized_section(initial_section)
	if not is_node_ready():
		return
	_update_header()
	open_section(_initial_section)


func open_section(section_id: String) -> void:
	if _session == null:
		return
	var normalized := _normalized_section(section_id)
	var view := _ensure_view(normalized)
	for candidate: Control in _views.values():
		var is_active := candidate == view
		candidate.visible = is_active
		candidate.process_mode = (
			Node.PROCESS_MODE_INHERIT if is_active else Node.PROCESS_MODE_DISABLED
		)
	_active_section = normalized
	_refresh_view(view)
	_update_header()
	_update_tabs()
	section_changed.emit(normalized)
	var selected_button: Button = tab_buttons[normalized]
	selected_button.grab_focus()


func active_section() -> String:
	return _active_section


func view_for_section(section_id: String) -> Control:
	return _views.get(_normalized_section(section_id)) as Control


func _ensure_view(section_id: String) -> Control:
	if _views.has(section_id):
		return _views[section_id] as Control
	var scene: PackedScene = VIEW_SCENES[section_id]
	var view := scene.instantiate() as Control
	var header_path: NodePath = EMBEDDED_HEADER_PATHS[section_id]
	var embedded_header := view.get_node_or_null(header_path) as Control
	if embedded_header != null:
		embedded_header.visible = false
	view.visible = false
	view.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	if view.has_method("configure"):
		view.call("configure", _session)
	content_host.add_child(view)
	_views[section_id] = view
	if section_id == SECTION_CHARACTER and view.has_signal("class_selection_requested"):
		view.connect("class_selection_requested", class_selection_requested.emit)
	return view


func _refresh_view(view: Control) -> void:
	if view.has_method("configure"):
		view.call("configure", _session)


func _update_header() -> void:
	if _session == null:
		return
	var player := _session.player
	var load := CarryWeightServiceClass.carry_status(player)
	hero_name_label.text = player.titled_display_name()
	hero_meta_label.text = "%s  •  POZIOM %d" % [player.character_class_name, player.level]
	resources_label.text = (
		"ZŁOTO  %d    •    UDŹWIG  %.1f / %.1f kg  (%s)"
		% [player.gold, load.current_kg, load.capacity_kg, load.display_name]
	)


func _update_tabs() -> void:
	for section_id: String in tab_buttons:
		var button: Button = tab_buttons[section_id]
		button.set_pressed_no_signal(section_id == _active_section)


func _normalized_section(section_id: String) -> String:
	return section_id if VIEW_SCENES.has(section_id) else SECTION_CHARACTER
