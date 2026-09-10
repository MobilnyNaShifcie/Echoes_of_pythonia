class_name ClassCard
extends Button

signal class_selected(class_code: String)

const NORMAL_SCALE := Vector2.ONE
const HOVER_SCALE := Vector2(1.02, 1.02)
const SELECTED_SCALE := Vector2(1.027, 1.027)
const GOLD_BORDER := Color(0.92, 0.68, 0.27, 1.0)
const GOLD_BORDER_HOVER := Color(0.78, 0.55, 0.2, 1.0)

var class_code := ""
var _selected := false
var _permanent := false
var _hovered := false
var _accent_color := Color(0.84, 0.68, 0.31, 1.0)
var _art_offset := Vector2.ZERO
var _art_scale := 1.0
var _visual_tween: Tween

@onready var artwork_container: Control = %ArtworkContainer
@onready var character_art: TextureRect = %CharacterArt
@onready var placeholder: CenterContainer = %Placeholder
@onready var placeholder_symbol: Label = %PlaceholderSymbol
@onready var class_icon: Label = %ClassIcon
@onready var class_name_label: Label = %ClassName
@onready var mana_label: Label = %ManaLabel
@onready var permanent_badge: PanelContainer = %PermanentBadge


func _ready() -> void:
	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(_on_focus_changed)
	focus_exited.connect(_on_focus_changed)
	resized.connect(_update_pivot)
	artwork_container.resized.connect(_update_art_layout)
	_update_pivot()
	_refresh_visual(false)


func configure(
	code: String,
	display_name: String,
	base_mana: int,
	texture: Texture2D,
	symbol: String,
	accent_color: Color,
	art_offset: Vector2 = Vector2.ZERO,
	art_scale: float = 1.0
) -> void:
	class_code = code
	_accent_color = accent_color
	_art_offset = art_offset
	_art_scale = maxf(1.0, art_scale)
	class_name_label.text = display_name.to_upper()
	mana_label.text = "◉  Bazowa Mana: %d" % base_mana
	class_icon.text = symbol
	class_icon.add_theme_color_override("font_color", _accent_color.lightened(0.12))
	placeholder_symbol.text = "%s\n\nGRAFIKA KLASY" % symbol
	set_character_art(texture)
	tooltip_text = ""
	_refresh_visual(false)


func set_character_art(texture: Texture2D) -> void:
	character_art.texture = texture
	character_art.visible = texture != null
	placeholder.visible = texture == null
	call_deferred("_update_art_layout")


func set_selected(value: bool) -> void:
	if _selected == value:
		return
	_selected = value
	_refresh_visual()


func set_permanent(value: bool) -> void:
	_permanent = value
	permanent_badge.visible = value


func is_selected() -> bool:
	return _selected


func uses_placeholder() -> bool:
	return character_art.texture == null


func _on_pressed() -> void:
	class_selected.emit(class_code)


func _on_mouse_entered() -> void:
	_hovered = true
	_refresh_visual()


func _on_mouse_exited() -> void:
	_hovered = false
	_refresh_visual()


func _on_focus_changed() -> void:
	_refresh_visual()


func _refresh_visual(animate := true) -> void:
	if not is_node_ready():
		return
	var active := _hovered or has_focus()
	var target_scale := NORMAL_SCALE
	var target_art_modulate := Color(0.76, 0.78, 0.82, 1.0)
	if _selected:
		target_scale = SELECTED_SCALE
		target_art_modulate = Color(1.0, 1.0, 1.0, 1.0)
	elif active:
		target_scale = HOVER_SCALE
		target_art_modulate = Color(0.94, 0.95, 0.98, 1.0)
	z_index = 2 if _selected else (1 if active else 0)
	_apply_button_styles(active)
	if _visual_tween != null:
		_visual_tween.kill()
	if not animate or not is_inside_tree():
		scale = target_scale
		character_art.modulate = target_art_modulate
		return
	_visual_tween = create_tween().set_parallel(true)
	_visual_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_visual_tween.tween_property(self, "scale", target_scale, 0.12)
	_visual_tween.tween_property(character_art, "modulate", target_art_modulate, 0.12)


func _apply_button_styles(active: bool) -> void:
	var border := Color(0.28, 0.35, 0.44, 0.95)
	var background := Color(0.018, 0.032, 0.052, 0.98)
	var width := 1
	if _selected:
		border = GOLD_BORDER
		background = Color(0.05, 0.049, 0.042, 0.99)
		width = 3
	elif active:
		border = GOLD_BORDER_HOVER
		background = Color(0.035, 0.054, 0.078, 0.99)
		width = 2
	var style := _card_style(border, background, width)
	add_theme_stylebox_override("normal", style)
	add_theme_stylebox_override("hover", style)
	add_theme_stylebox_override("focus", style)
	add_theme_stylebox_override(
		"pressed", _card_style(GOLD_BORDER, background.lightened(0.05), 3)
	)


func _card_style(border: Color, background: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_corner_radius_all(8)
	style.content_margin_left = 7.0
	style.content_margin_top = 7.0
	style.content_margin_right = 7.0
	style.content_margin_bottom = 7.0
	return style


func _update_pivot() -> void:
	pivot_offset = size * 0.5


func _update_art_layout() -> void:
	if not is_node_ready() or character_art.texture == null:
		return
	var stage_size := artwork_container.size
	var source_size := character_art.texture.get_size()
	if stage_size.x <= 0.0 or stage_size.y <= 0.0 or source_size.x <= 0.0 or source_size.y <= 0.0:
		return
	var cover_scale := maxf(stage_size.x / source_size.x, stage_size.y / source_size.y)
	var rendered_size := source_size * cover_scale * _art_scale
	character_art.size = rendered_size
	character_art.position = Vector2(
		(stage_size.x - rendered_size.x) * 0.5 + stage_size.x * _art_offset.x,
		stage_size.y * _art_offset.y
	)
