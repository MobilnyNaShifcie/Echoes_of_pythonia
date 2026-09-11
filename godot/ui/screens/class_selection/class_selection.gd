class_name ClassSelectionScreen
extends Control

signal back_requested
signal class_chosen

const CLASS_SELECTOR_SCENE := preload(
	"res://ui/components/class_carousel_selector/class_carousel_selector.tscn"
)
const ClassCarouselSelectorClass := preload(
	"res://ui/components/class_carousel_selector/class_carousel_selector.gd"
)
const GameSessionClass := preload("res://core/game/game_session.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const PlayerClassCatalogClass := preload("res://core/player/player_class_catalog.gd")

const DEFAULT_ART_GENDER_CODE := "female"
const CLASS_ART_PATHS := {
	"warrior":
	{
		"male": "res://assets/ui/class_selection/warrior_male.png",
		"female": "res://assets/ui/class_selection/warrior_female.png",
	},
	"hunter":
	{
		"male": "res://assets/ui/class_selection/hunter_male.png",
		"female": "res://assets/ui/class_selection/hunter_female.png",
	},
	"mage":
	{
		"male": "res://assets/ui/class_selection/mage_male.png",
		"female": "res://assets/ui/class_selection/mage_female.png",
	},
	"pierrot":
	{
		"male": "res://assets/ui/class_selection/pierrot_male.png",
		"female": "res://assets/ui/class_selection/pierrot_female.png",
	},
}
const CLASS_SYMBOLS := {
	"warrior": "♜",
	"hunter": "➶",
	"mage": "✦",
	"pierrot": "♦",
}
const CLASS_ACCENTS := {
	"warrior": Color(0.92, 0.28, 0.16, 1.0),
	"hunter": Color(0.38, 0.68, 0.27, 1.0),
	"mage": Color(0.36, 0.31, 0.94, 1.0),
	"pierrot": Color(0.82, 0.12, 0.29, 1.0),
}
const CLASS_SECONDARY_COLORS := {
	"warrior": Color(0.17, 0.035, 0.025, 1.0),
	"hunter": Color(0.035, 0.105, 0.055, 1.0),
	"mage": Color(0.055, 0.025, 0.15, 1.0),
	"pierrot": Color(0.14, 0.018, 0.055, 1.0),
}

var _session: GameSessionClass
var _selected_code := ""
var _art_gender_code := DEFAULT_ART_GENDER_CODE
var _selectors: Dictionary = {}
var _motion_target := Vector2.ZERO
var _motion_current := Vector2.ZERO
var _transition_tween: Tween

@onready var atmosphere: ColorRect = %Atmosphere
@onready var carousel_stage: Control = %CarouselStage
@onready var center_figure_layer: Control = %CenterFigureLayer
@onready var center_motion: Control = %CenterMotion
@onready var center_shadow: TextureRect = %CenterShadow
@onready var center_glow: TextureRect = %CenterGlow
@onready var center_art: TextureRect = %CenterArt
@onready var left_motion: Control = %LeftMotion
@onready var left_art: TextureRect = %LeftArt
@onready var left_name: Label = %LeftName
@onready var left_figure: Button = %LeftFigure
@onready var right_motion: Control = %RightMotion
@onready var right_art: TextureRect = %RightArt
@onready var right_name: Label = %RightName
@onready var right_figure: Button = %RightFigure
@onready var pedestal: ColorRect = %Pedestal
@onready var selector_row: HBoxContainer = %SelectorRow
@onready var detail_symbol: Label = %DetailSymbol
@onready var detail_class_name: Label = %DetailClassName
@onready var detail_subtitle: Label = %DetailSubtitle
@onready var description_label: Label = %DescriptionLabel
@onready var primary_attributes_label: Label = %PrimaryAttributesLabel
@onready var mana_value_label: Label = %ManaValueLabel
@onready var equipment_list: Label = %EquipmentList
@onready var lock_label: Label = %LockLabel
@onready var permanent_hint_label: Label = %PermanentHintLabel
@onready var choose_button: Button = %ChooseButton
@onready var back_button: Button = %BackButton
@onready var previous_button: Button = %PreviousButton
@onready var next_button: Button = %NextButton


func _ready() -> void:
	back_button.pressed.connect(back_requested.emit)
	choose_button.pressed.connect(_choose_selected_class)
	previous_button.pressed.connect(_select_relative.bind(-1))
	next_button.pressed.connect(_select_relative.bind(1))
	left_figure.pressed.connect(_select_relative.bind(-1))
	right_figure.pressed.connect(_select_relative.bind(1))
	carousel_stage.gui_input.connect(_on_carousel_gui_input)
	_art_gender_code = _resolve_art_gender_code()
	_populate_selectors()
	_configure_focus_neighbors()
	_select_class(PlayerClassCatalogClass.PLAYABLE_ORDER[0], false)
	_render_lock_state()
	call_deferred("_finish_layout_setup")
	set_process(true)


func configure(session: GameSessionClass) -> void:
	_session = session
	_art_gender_code = _resolve_art_gender_code()
	if not is_node_ready():
		return
	var current_code := session.player.character_class_code
	if current_code in PlayerClassCatalogClass.PLAYABLE_ORDER:
		_select_class(current_code, false)
	else:
		_refresh_carousel_art()
	_render_lock_state()


func selected_class_code() -> String:
	return _selected_code


func selector_for_class(class_code: String) -> ClassCarouselSelectorClass:
	return _selectors.get(class_code) as ClassCarouselSelectorClass


func _populate_selectors() -> void:
	for definition in PlayerClassCatalogClass.get_playable_definitions():
		var selector := CLASS_SELECTOR_SCENE.instantiate() as ClassCarouselSelectorClass
		selector.name = "%sSelector" % definition.class_code.capitalize()
		selector_row.add_child(selector)
		selector.configure(
			definition.class_code,
			definition.display_name,
			definition.base_mana,
			CLASS_SYMBOLS[definition.class_code],
			CLASS_ACCENTS[definition.class_code]
		)
		selector.class_selected.connect(_select_class)
		_selectors[definition.class_code] = selector


func _class_art_path(class_code: String) -> String:
	var gender_paths: Dictionary = CLASS_ART_PATHS[class_code]
	return str(gender_paths.get(_art_gender_code, gender_paths[DEFAULT_ART_GENDER_CODE]))


func _load_class_art(class_code: String) -> Texture2D:
	var asset_path := _class_art_path(class_code)
	if not ResourceLoader.exists(asset_path):
		return null
	return load(asset_path) as Texture2D


func _resolve_art_gender_code() -> String:
	if _session == null:
		return DEFAULT_ART_GENDER_CODE
	var gender_code: String = _session.player.gender_code
	if gender_code in ["male", "female"]:
		return gender_code
	return DEFAULT_ART_GENDER_CODE


func _select_class(class_code: String, animate := true) -> void:
	if class_code not in PlayerClassCatalogClass.PLAYABLE_ORDER:
		return
	var changed := _selected_code != class_code
	_selected_code = class_code
	for selector_code: String in _selectors:
		var selector := _selectors[selector_code] as ClassCarouselSelectorClass
		selector.set_selected(selector_code == class_code)
	_refresh_carousel_art()
	_render_details()
	_render_lock_state()
	_update_confirmation_focus()
	if changed and animate:
		_play_selection_transition()


func _select_relative(direction: int) -> void:
	var order: Array = PlayerClassCatalogClass.PLAYABLE_ORDER
	var index := order.find(_selected_code)
	if index < 0:
		index = 0
	var target_index := wrapi(index + direction, 0, order.size())
	_select_class(str(order[target_index]))
	var selector := selector_for_class(str(order[target_index]))
	if selector != null:
		selector.grab_focus()


func _refresh_carousel_art() -> void:
	if _selected_code.is_empty():
		return
	var order: Array = PlayerClassCatalogClass.PLAYABLE_ORDER
	var index := order.find(_selected_code)
	var previous_code := str(order[wrapi(index - 1, 0, order.size())])
	var next_code := str(order[wrapi(index + 1, 0, order.size())])
	var center_texture := _load_class_art(_selected_code)
	center_art.texture = center_texture
	center_glow.texture = center_texture
	center_shadow.texture = center_texture
	left_art.texture = _load_class_art(previous_code)
	right_art.texture = _load_class_art(next_code)
	left_figure.set_meta("class_code", previous_code)
	right_figure.set_meta("class_code", next_code)
	left_name.text = PlayerClassCatalogClass.get_definition(previous_code).display_name.to_upper()
	right_name.text = PlayerClassCatalogClass.get_definition(next_code).display_name.to_upper()
	_apply_class_atmosphere()


func _render_details() -> void:
	var definition = PlayerClassCatalogClass.get_definition(_selected_code)
	var equipment_names: Array[String] = []
	for item_id: String in definition.starter_equipment_ids:
		var item_definition = ItemCatalogClass.get_definition(item_id)
		if item_definition != null:
			equipment_names.append(item_definition.display_name)
	if _selected_code == "warrior":
		equipment_names.push_front("Aktualna broń")
	detail_symbol.text = CLASS_SYMBOLS[_selected_code]
	detail_symbol.add_theme_color_override(
		"font_color", CLASS_ACCENTS[_selected_code].lightened(0.16)
	)
	detail_class_name.text = definition.display_name
	detail_subtitle.text = _class_motto(_selected_code)
	description_label.text = definition.description
	primary_attributes_label.text = definition.primary_attributes
	mana_value_label.text = str(definition.base_mana)
	equipment_list.text = "  •  ".join(equipment_names)


func _apply_class_atmosphere() -> void:
	var accent: Color = CLASS_ACCENTS[_selected_code]
	var secondary: Color = CLASS_SECONDARY_COLORS[_selected_code]
	var atmosphere_material := atmosphere.material as ShaderMaterial
	if atmosphere_material != null:
		atmosphere_material.set_shader_parameter("primary_color", accent)
		atmosphere_material.set_shader_parameter("secondary_color", secondary)
	var glow_material := center_glow.material as ShaderMaterial
	if glow_material != null:
		var glow_color := accent.lightened(0.22)
		glow_color.a = 0.58
		glow_material.set_shader_parameter("glow_color", glow_color)
	var pedestal_material := pedestal.material as ShaderMaterial
	if pedestal_material != null:
		pedestal_material.set_shader_parameter("accent_color", accent.lightened(0.08))


func _render_lock_state() -> void:
	choose_button.disabled = true
	permanent_hint_label.text = "Zmienić Drogę możesz tylko rozpoczynając nową postać."
	for selector_code: String in _selectors:
		var selector := _selectors[selector_code] as ClassCarouselSelectorClass
		selector.set_permanent(
			_session != null and _session.player.character_class_code == selector_code
		)
	if _session == null:
		lock_label.text = "Wczytywanie danych postaci…"
		return
	var player := _session.player
	if player.character_class_code != player.CLASS_NONE:
		lock_label.text = "Wybrana Droga: %s. Ten wybór jest stały." % player.character_class_name
		return
	if player.level < 5:
		lock_label.text = ("Wybór odblokuje się na poziomie 5. Obecny poziom: %d." % player.level)
		return
	lock_label.text = "Wybór jest stały dla tej postaci."
	choose_button.disabled = _selected_code.is_empty()


func _choose_selected_class() -> void:
	if _session == null or _selected_code.is_empty():
		return
	var error := _session.player.get_class_choice_error(_selected_code)
	if not error.is_empty():
		lock_label.text = error
		return
	if _session.player.choose_class(_selected_code):
		_session.last_activity = "Wybrano Drogę: %s." % _session.player.character_class_name
		_render_lock_state()
		class_chosen.emit()


func _configure_focus_neighbors() -> void:
	var order: Array = PlayerClassCatalogClass.PLAYABLE_ORDER
	for index in range(order.size()):
		var selector := selector_for_class(str(order[index]))
		var previous_selector := selector_for_class(str(order[wrapi(index - 1, 0, order.size())]))
		var next_selector := selector_for_class(str(order[wrapi(index + 1, 0, order.size())]))
		selector.focus_neighbor_left = selector.get_path_to(previous_selector)
		selector.focus_neighbor_right = selector.get_path_to(next_selector)
		selector.focus_neighbor_bottom = selector.get_path_to(choose_button)
		selector.focus_next = selector.get_path_to(next_selector)
	previous_button.focus_neighbor_bottom = previous_button.get_path_to(
		selector_for_class("warrior")
	)
	next_button.focus_neighbor_bottom = next_button.get_path_to(selector_for_class("pierrot"))
	choose_button.focus_neighbor_bottom = choose_button.get_path_to(back_button)
	back_button.focus_neighbor_bottom = back_button.get_path_to(selector_for_class("warrior"))


func _update_confirmation_focus() -> void:
	var selected_selector := selector_for_class(_selected_code)
	if selected_selector == null:
		return
	choose_button.focus_neighbor_top = choose_button.get_path_to(selected_selector)


func _finish_layout_setup() -> void:
	center_figure_layer.pivot_offset = center_figure_layer.size * 0.5
	var selector := selector_for_class(_selected_code)
	if selector != null:
		selector.grab_focus()


func _play_selection_transition() -> void:
	if _transition_tween != null:
		_transition_tween.kill()
	center_figure_layer.modulate = Color(1.0, 1.0, 1.0, 0.18)
	center_figure_layer.scale = Vector2(0.93, 0.93)
	left_motion.modulate.a = 0.12
	right_motion.modulate.a = 0.12
	_transition_tween = create_tween().set_parallel(true)
	_transition_tween.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_transition_tween.tween_property(center_figure_layer, "modulate", Color.WHITE, 0.24)
	_transition_tween.tween_property(center_figure_layer, "scale", Vector2.ONE, 0.30)
	_transition_tween.tween_property(left_motion, "modulate:a", 1.0, 0.22)
	_transition_tween.tween_property(right_motion, "modulate:a", 1.0, 0.22)


func _process(delta: float) -> void:
	if not is_visible_in_tree() or carousel_stage.size.x <= 1.0 or carousel_stage.size.y <= 1.0:
		return
	var local_mouse := carousel_stage.get_local_mouse_position()
	var normalized := Vector2(
		clampf(local_mouse.x / carousel_stage.size.x, 0.0, 1.0),
		clampf(local_mouse.y / carousel_stage.size.y, 0.0, 1.0)
	)
	_motion_target = (normalized - Vector2(0.5, 0.5)) * Vector2(12.0, 7.0)
	_motion_current = _motion_current.lerp(_motion_target, minf(delta * 5.0, 1.0))
	var float_offset := sin(Time.get_ticks_msec() * 0.00125) * 2.4
	center_motion.position = _motion_current + Vector2(0.0, float_offset)
	left_motion.position = -_motion_current * 0.28 + Vector2(0.0, -float_offset * 0.35)
	right_motion.position = -_motion_current * 0.28 + Vector2(0.0, float_offset * 0.35)


func _on_carousel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_select_relative(-1)
			accept_event()
		elif mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_select_relative(1)
			accept_event()


func _unhandled_key_input(event: InputEvent) -> void:
	if not visible or not event.is_pressed() or event.is_echo():
		return
	if event.keycode == KEY_LEFT:
		_select_relative(-1)
		get_viewport().set_input_as_handled()
	elif event.keycode == KEY_RIGHT:
		_select_relative(1)
		get_viewport().set_input_as_handled()


func _class_motto(class_code: String) -> String:
	match class_code:
		"warrior":
			return "Siła. Wytrzymałość. Przetrwanie."
		"hunter":
			return "Precyzja. Sekwencje. Kontrola dystansu."
		"mage":
			return "Żywioły. Inteligencja. Splot Magii."
		"pierrot":
			return "Los. Chaos. Szczęście."
	return ""
