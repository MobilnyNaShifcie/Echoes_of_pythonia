class_name ClassCarouselSelector
extends Button

signal class_selected(class_code: String)

const GLOBAL_GOLD := Color(0.94, 0.69, 0.25, 1.0)

var class_code := ""
var _selected := false
var _permanent := false
var _hovered := false
var _accent := Color.WHITE
var _visual_tween: Tween

@onready var symbol_label: Label = %Symbol
@onready var name_label: Label = %ClassName
@onready var mana_label: Label = %Mana
@onready var permanent_label: Label = %PermanentLabel


func _ready() -> void:
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_refresh_visual)
	focus_exited.connect(_refresh_visual)
	resized.connect(_update_pivot)
	_update_pivot()
	_refresh_visual(false)


func configure(
	code: String,
	display_name: String,
	base_mana: int,
	symbol: String,
	accent: Color
) -> void:
	class_code = code
	_accent = accent
	symbol_label.text = symbol
	symbol_label.add_theme_color_override("font_color", accent.lightened(0.12))
	name_label.text = display_name.to_upper()
	mana_label.text = "MANA  %d" % base_mana
	_refresh_visual(false)


func set_selected(value: bool) -> void:
	_selected = value
	_refresh_visual()


func set_permanent(value: bool) -> void:
	_permanent = value
	permanent_label.visible = value


func is_selected() -> bool:
	return _selected


func is_permanent() -> bool:
	return _permanent


func _on_pressed() -> void:
	class_selected.emit(class_code)


func _on_mouse_entered() -> void:
	_hovered = true
	_refresh_visual()


func _on_mouse_exited() -> void:
	_hovered = false
	_refresh_visual()


func _refresh_visual(animate := true) -> void:
	if not is_node_ready():
		return
	var active := _hovered or has_focus()
	var target_scale := Vector2.ONE
	var background := Color(0.012, 0.025, 0.043, 0.42)
	var border := Color(0.23, 0.29, 0.37, 0.62)
	var border_width := 1
	if _selected:
		target_scale = Vector2(1.045, 1.045)
		background = Color(0.07, 0.055, 0.028, 0.9)
		border = GLOBAL_GOLD
		border_width = 3
	elif active:
		target_scale = Vector2(1.02, 1.02)
		background = Color(0.035, 0.052, 0.077, 0.88)
		border = GLOBAL_GOLD.darkened(0.18)
		border_width = 2
	_apply_style(background, border, border_width)
	name_label.add_theme_color_override(
		"font_color", Color(1.0, 0.84, 0.49, 1.0) if _selected else Color(0.82, 0.86, 0.92, 1.0)
	)
	if _visual_tween != null:
		_visual_tween.kill()
	if not animate or not is_inside_tree():
		scale = target_scale
		return
	_visual_tween = create_tween().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_visual_tween.tween_property(self, "scale", target_scale, 0.13)


func _apply_style(background: Color, border: Color, border_width: int) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.border_width_bottom = border_width
	style.corner_radius_top_left = 7
	style.corner_radius_top_right = 7
	style.corner_radius_bottom_left = 7
	style.corner_radius_bottom_right = 7
	style.content_margin_left = 11.0
	style.content_margin_top = 7.0
	style.content_margin_right = 11.0
	style.content_margin_bottom = 7.0
	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", style)
	add_theme_stylebox_override("focus", style)
	add_theme_stylebox_override("pressed", style)


func _update_pivot() -> void:
	pivot_offset = size * 0.5
